
# A stripped-down app for showing only how error propagates along with uncertainty 
# across scales: pixel to node, node to reach. 
#

default_data_url <- "https://osu.box.com/shared/static/9ng2ys6kubcbkqu8riar0l89uzk101zr.rdata"
run_manifest <- read.csv("./roruns.csv", stringsAsFactors = FALSE) %>% 
  dplyr::filter(!is.na(rtviz_url),
                nchar(rtviz_url) > 0) 

####------------------------------------
#### START OF SERVER FUNCTION ----------
####------------------------------------
function(input, output, session) {
  
  #### DATA INPUT ####
  
  purgedNodes <- numeric(0) # Keep track of which nodes get manually purged
  purgeCounter <- 0
  restoreCounter <- 0 # Track whether node restoration has been triggered.
  
  # Full dataset from get_rivertile_data()
  data_in <- reactive({ 
    load("cache/sac18.RData")
    # load(url(default_data_url))
    rtdata_in$rt_nodes <- rtdata_in$rt_nodes %>% 
      add_nodelen() %>% add_offset(reachdata = rtdata_in$rt_reaches)
    rtdata_in$gdem_nodes <- rtdata_in$gdem_nodes %>% 
      add_nodelen() %>% add_offset(reachdata = rtdata_in$gdem_reaches)
    rtdata_in$rt_pixc$pixel_id <- 1:nrow(rtdata_in$rt_pixc) # manually assign pixel ID
    
    purgedNodes <<- numeric(0) # reset purgedNodes
    # purgeCounter <<- 0
    # restoreCounter <<- 0
    
    return(list(rtdata_in = rtdata_in, badnodes_in = badnodes_in))    
  })
  
  # Node selection and purging
  purgedNodes_rct <- reactive({
    
    if (input$nodePurge > purgeCounter) {
      # purging has just been triggered
      purgeCounter <<- purgeCounter + 1
      if (!length(selNode)) {
        message("No nodes selected.")
      } else {
        purgedNodes <<- unique(c(purgedNodes, selNode))
      }
    } else if (input$nodeRestore > restoreCounter) {
      # Resetoring has just been triggered
      purgedNodes <<- numeric(0)
      restoreCounter <<- restoreCounter + 1
    }
    
    purgedNodes
  })

  # Current dataset (subset of data_in)
  rtdata <- reactive({

    # isolate(nodeaccum_shared$clearSelection())
    
    topurge <- purgedNodes_rct()
    
    out <- purge_nodes(data_in()$rtdata_in, 
                       purgenodes = purgedNodes_rct(), 
                       redo_reaches = TRUE)
    out
  })
  
  
  # Color palette for reaches
  reachpal <- reactive({
    reachids <- sort(unique(data_in()$rtdata_in$rt_reaches$reach_id))
    nreaches <- length(reachids)
    # viridisLite::viridis(n = nreaches) 
    dkcols <- RColorBrewer::brewer.pal(n = 8, name = "Set3")
    pal <- leaflet::colorNumeric(palette = rep(dkcols, length.out = nreaches), 
                                 domain = reachids)
    pal
  })

  #### MAPPING ####

  # Unlike the larger shiny app, this one uses crosstalk, and for some unknown
  # reason that doesn't work in a leafletProxy. So the actual leaflet map must
  # contain pixels as well as nodes and tiles. 
  # Proxies will contain gdem pixels and rezoom events. 
  
  # Locations of nodes for a particular case
  riverNodeLocations <- reactive({
    if (is.null(rtdata())) return(NULL)
    nodedf <- rtdata()$gdem_nodes[c("reach_id", "node_id", "latitude", "longitude")]
    nodedf
  })
  
  # Observer for node locations
  valdata_shared_map <- debounce(
    reactive(
      valdata_shared$data(withSelection = TRUE)[c("reach_id", "selected_")]
    ), 250)
  
  # Pixel data and sared version for crosstalk
  pixeldata_forplot <- reactive({
    nodeaccum_shared$selection()
    rtdata()$rt_pixc %>% 
      dplyr::filter(node_id %in% selNode) %>% 
      group_by(node_id) %>% 
      dplyr::arrange(desc(water_frac)) %>% 
      mutate(cum_area = cumsum(pixel_area), 
             area_lag = dplyr::lag(cum_area, default = 0), 
             classification = as.factor(classification)) %>% 
      ungroup()
  })
  
  pixeldata_shared <- highlight_key(pixeldata_forplot)
  
  # Base map with tiles, nodes, selected pixc
  output$rtmap <- renderLeaflet({
    
    basemap <- leaflet() %>% 
      addTiles() %>% 
      mapOptions(zoomToLimits = "first")
      

    pcvdf <- pixeldata_forplot()
    if (nrow(pcvdf) == 0)
      return(basemap)
    
    basemap %>% 
      addCircles(~longitude, ~latitude, stroke = FALSE,
                 radius = ~sqrt(pixel_area / pi),
                 fillOpacity = 0.9,
                 popup = ~paste(sprintf("reach: %s\nnode: %s",
                                        reach_id, node_id)),
                 fillColor = ~classpal(classification),
                 group = "pcv", data = pixeldata_shared)
  })
  
  # Observer for node locations, showing selected using a crosstalk hack
  observe({
    locations <- riverNodeLocations() %>% 
      left_join(valdata_shared_map(), by = "reach_id")
    proxy <- leafletProxy("rtmap", 
                          data = locations)
    if (!length(locations))
      return(leafletProxy("rtmap"))
    
    selpal <- colorFactor("Set1", c(TRUE, FALSE)) #TODO: change this
    
    proxy %>%
      addCircleMarkers(
        ~longitude,
        ~latitude,
        popup = ~paste(sprintf("reach: %s\nnode: %s", reach_id, node_id)),
        opacity = 0.8,
        color = ~selpal(selected_),
        radius = 2
      ) 
  })
  

  # Data frame with locations of selected nodes' gdem pixc(vec)  
  pcv_gdem_selected <- reactive({
    if (!input$map_gdem) return(NULL)
    
    plotdf <- rtdata()$gdem_pixc %>% 
      dplyr::filter(node_id %in% selNode)
    plotdf
  })
  
  # Observer to add gdem pcv points
  observe({
    
    if (!input$map_gdem || 
        is.null(pcv_gdem_selected()) || 
        (nrow(pcv_gdem_selected()) == 0)) {
      leafletProxy("rtmap") %>% 
        clearGroup("pcv_gdem")
    } else {
      leafletProxy("rtmap", data = pcv_gdem_selected()) %>% 
        clearGroup("pcv_gdem") %>% 
        addCircles(~longitude, ~latitude, radius = ~sqrt(pixel_area / pi), 
                   stroke = FALSE,
                   popup = ~paste(sprintf("reach: %s\nnode: %s", 
                                          reach_id, node_id)),
                   fillOpacity = 0.8,
                   color = ~classpal(1), 
                   group = "pcv_gdem")  
    }
  })
  
  #### VALIDATION ####
  
  # Data objects 
  valdata_node <- reactive({
    rt_valdata_df(obs = rtdata()$rt_nodes, truth = rtdata()$gdem_nodes)
  })
  valdata_reach_orig <- reactive({
    rt_valdata_df(obs = data_in()$rtdata_in$rt_reaches, 
                  truth = data_in()$rtdata_in$gdem_reaches) %>% 
      filter(variable == "area_total") %>% 
      mutate(relerr = pixc_err / sigma_est)
  })
  valdata_reach <- reactive({
    rt_valdata_df(obs = rtdata()$rt_reaches, truth = rtdata()$gdem_reaches) %>% 
      filter(variable == "area_total") %>% 
      mutate(relerr = pixc_err / sigma_est,
             relerr_orig = valdata_reach_orig()$relerr)
  })
  valdata_shared <- SharedData$new(valdata_reach)
  
  ## Plots

  # plotly object for scatterplot
  output$reach_relerrplot <- renderPlotly({
    # event.data <- event_data("plotly_click", source = "select")
    
    gg <- ggplot(valdata_shared, aes(x = reach_id)) +
      geom_ribbon(ymin = -1.96, ymax = 1.96, color = "#dddddd") +
      geom_ribbon(ymin = -1, ymax = 1, color = "#bbbbbb") +
      geom_point(aes(y = relerr), color = "black")# +
      # geom_point(aes(y = relerr_orig), color = "#ddbbbb")
    ggplotly(gg, tooltip = "text")
  })
  
  # Node accumulation plot
  nodeaccumdf <- reactive({
    # browser()
    rt_nodewise_error(valdata_node(), variable = "area_total", plot = FALSE) %>% 
      filter(variable %in% c("cumul_err", "rel_err"))
  })
  nodeaccum_shared <- SharedData$new(nodeaccumdf)
  output$node_accum <- renderPlotly({
    
    gg <- ggplot(nodeaccum_shared, aes(x = node_id, y = value)) +
      geom_point(aes(text = node_id)) +
      geom_line(aes(y = uncert), color = "red") +
      geom_line(aes(y = -uncert), color = "red") +
      geom_line(aes(y = 1.96 * uncert), color = "red", linetype = 2) +
      geom_line(aes(y = -1.96 * uncert), color = "red", linetype = 2) +
      # facet_wrap(~reach_id, scales = "free_x") +
      facet_grid(variable ~ ., scales = "free", space = "free_x")    # gg
    ggplotly(gg, tooltip = "text") %>% 
      layout(dragmode = "select") %>% 
      highlight(on = "plotly_selected")
  })

  # Node area plot
  selNode <- numeric(0)
  observe({
    seldf <- nodeaccum_shared$data(withSelection = TRUE)
    selNode <<- filter(seldf, selected_) %>% 
      pull(node_id)
  })
  
  options(opacityDim = 0.5)
  output$nodearea_plot <- renderPlotly({
    if (nrow(pixeldata_forplot()) == 0) return(NULL)
    gg <- ggplot(pixeldata_shared) +
      geom_rect(aes(xmin = area_lag, xmax = cum_area, text = pixel_id,
                    ymin = 0, ymax = water_frac, fill = classification)) +
      geom_point(aes(x = cum_area, y = water_frac, color = classification), size = 0.1) +
      scale_fill_manual(values = classcolvec) +
      scale_color_manual(values = classcolvec) +
      xlab("Cumulative Pixel Area (m^2)") + ylab("Pixel Water Fraction") + 
      facet_wrap(~node_id, scales = "free_x") +
      guides(color = FALSE, fill = FALSE)
    
    
    # gg <- gg + 
    #   geom_rect(aes(xmin = 0, ymin = 0, xmax = true_area, ymax = 1), 
    #             fill = NA, color = "gray30", linetype = 2)
    
    ggplotly(gg, tooltip = "text") %>% 
      layout(dragmode = "select") %>%
      hide_legend() %>% 
      highlight(on = "plotly_selected")
  })
  
  # Observer for rezooming
  observe({
    pcvdf <- pixeldata_forplot()
    leafletProxy("rtmap") %>%
      leaflet::flyToBounds(lng1 = min(pcvdf$longitude),
                           lng2 = max(pcvdf$longitude),
                           lat1 = min(pcvdf$latitude),
                           lat2 = max(pcvdf$latitude))
  })
  
  # Observer for pcv points legend
  observe({
    
    proxy <- leafletProxy("rtmap", data = pixeldata_forplot())
    # Remove any existing legend, and only if the legend is
    # enabled, create a new one.
    proxy %>% clearControls()
    if (length(selNode)) {
      proxy %>% addLegend(position = "topright",
                          colors = classpal(classes),
                          labels = classlabs)
    }
  })  
}


