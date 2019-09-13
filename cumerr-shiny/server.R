
# A stripped-down app for showing only how error propagates along with uncertainty 
# across scales: pixel to node, node to reach. 
#

# default_data_url <- "https://osu.box.com/shared/static/9ng2ys6kubcbkqu8riar0l89uzk101zr.rdata"
# run_manifest <- read.csv("./roruns.csv", stringsAsFactors = FALSE) %>% 
#   dplyr::filter(!is.na(rtviz_url),
#                 nchar(rtviz_url) > 0) 


load("cache/rtnodes_master.RData")
load("cache/gdnodes_master.RData")
load("cache/reachvaldf_master.RData")
load("cache/pixdf.RData")
# load("cache/gdempixdf.RData")

# TODO: combine validation across tiles for pass that spans both swaths. 

####------------------------------------
#### START OF SERVER FUNCTION ----------
####------------------------------------
function(input, output, session) {
  
  #### DATA INPUT ####
  
  # purgedNodes <- numeric(0) # Keep track of which nodes get manually purged
  # purgeCounter <- 0
  # restoreCounter <- 0 # Track whether node restoration has been triggered.
  
  # subset of data given by side panel selections

  nodedata_in <- reactive({ 
    rt_nodes <- rtnodes_master %>% 
      filter(refdem == input$refdemselect,
             agg == input$aggselect)
    gdem_nodes <- gdnodes_master
    
    if (input$flagnodes) gdem_nodes <- gdem_nodes %>% 
      filter(!ambiguous)
    
    
    return(list(rt_nodes = rt_nodes, gdem_nodes = gdem_nodes))    
  })
  
  nodedata_
  
  selected_run <- reactive({
    unique(nodedata_in()$rt_nodes$run)[1] # TODO: get from plot selection
  })
  
  # Node selection and purging--now needs to track both nodes and run number
  # implement as a list with 1 element for each row of reachvaldf_master.
  
  # On purge, create a new reach validation--updating nodes from the current reach only.
  # 
  purgedNodes_rct <- reactive({
    input$nodePurge
    input$nodeRestore

    # These if statements are apparently not enough to trigger the reactive.
    # Hence the explicit mention above.
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

    # TODO: add purging of nodes

    selreach <- reachvaldf_shared$data(withSelection = TRUE) %>% 
      filter(selected_)
    if (!nrow(selreach)) return(NULL)
    
    rtnodes <- nodedata_in()$rt_nodes %>% 
      dplyr::filter(run == selreach$run,
                    reach_id == selreach$reach_id)
    gdnodes <- nodedata_in()$gdem_nodes %>% 
      dplyr::filter(run == selreach$run,
                    reach_id == selreach$reach_id)
    
    out <- list(rt_nodes = rtnodes, gdem_nodes = gdnodes)
    out
  })
  
  
  # Color palette for reaches, days
  reachpal <- reactive({
    reachids <- sort(unique(reachvaldf_master$reach_id))
    nreaches <- length(reachids)
    # viridisLite::viridis(n = nreaches) 
    dkcols <- RColorBrewer::brewer.pal(n = 8, name = "Dark2")
    pal <- leaflet::colorNumeric(palette = rep(dkcols, length.out = nreaches), 
                                 domain = reachids)
    pal
  })
  reachcolvec <- reactive({
    reachids <- sort(unique(reachvaldf_master$reach_id))
    setNames(reachpal()(reachids), reachids)
  })
  
  daypal <- reactive({
    days <- sort(unique(reachvaldf_master$day))
    ndays <- length(days)
    # viridisLite::viridis(n = nreaches) 
    dkcols <- RColorBrewer::brewer.pal(n = 8, name = "Dark2")
    pal <- leaflet::colorNumeric(palette = rep(dkcols, length.out = ndays), 
                                 domain = days)
    pal
  })
  daycolvec <- reactive({
    days <- sort(unique(reachvaldf_master$day))
    setNames(daypal()(days), days)
  })
  
  
  # subset of pixdf for maps
  pcv_selected <- reactive({
    input$nodePlot
    pixdf %>% 
      filter(run == selected_run(), node_index %in% selNode)
  })
  
  # Data frame with locations of selected nodes' gdem pixc(vec)
  pcv_gdem_selected <- reactive({
    if (!input$map_gdem) return(NULL)
    
    plotdf <- gdempixdf %>%
      filter(run == selected_run(), node_index %in% selNode)
    plotdf
  })
  
  
  #### VALIDATION ####
  
  # Data objects 
  valdata_node <- reactive({
    # browser()
    if (is.null(rtdata())) return(NULL)
    rt_valdata_df(obs = rtdata()$rt_nodes, truth = rtdata()$gdem_nodes)
  })
  
  valdata_reach_orig <- reactive({
    
    reachvaldf_master %>% 
      filter(refdem == input$refdemselect,
             variable == input$varselect,
             agg == input$aggselect) %>% 
      mutate(relerr = pixc_err / sigma_est,
             day = as.factor(day))
  })
  reachvaldf_shared <- SharedData$new(valdata_reach_orig)
  
  
  #### REACH SCATTERPLOT ####
  
  # plotly object for scatterplot
  output$reach_errplot <- renderPlotly({
    # event.data <- event_data("plotly_click", source = "select")
    # browser()
    gg <- ggplot(reachvaldf_shared, aes(x = reach_id)) +
      geom_ribbon(aes(ymin = -1.96, ymax = 1.96), color = "#dddddd") +
      geom_ribbon(aes(ymin = -1, ymax = 1), color = "#bbbbbb") +
      geom_point(aes(y = relerr), color = "#ddbbbb", 
                 data = valdata_reach_orig()) +
      geom_point(aes(y = relerr, color = day)) +
      scale_color_manual(values = daycolvec())
    
    ggplotly(gg, tooltip = "text")
    
  })
  
  
  #### ERROR ACCUMULATION PLOT ####
  nodeaccumdf <- reactive({
    if (is.null(valdata_node()) || nrow(valdata_node()) == 0) return(NULL)
    scalearg <- ifelse(input$err_rel, "none", "unc")
    out <- try(rt_cumulplot(valdata_node(), var = input$varselect, 
                            plot = FALSE))
    # if (inherits(out, "try-error")) browser()
    out
  })
  nodeaccum_shared <- SharedData$new(nodeaccumdf)
  output$node_accum <- renderPlotly({
    
    
    gg <- ggplot(nodeaccum_shared, 
                 aes(x = node_id, y = y, color = reach_id)) + 
      geom_line(size = 0.1) + 
      geom_point(aes(text = node_id), size = 0.5) + 
      facet_grid(rows = vars(errtype), scales = "free_y")
    
    ggplotly(gg, tooltip = "text") %>% 
      layout(dragmode = "select") %>% 
      hide_legend() %>% 
      highlight(on = "plotly_selected")
  })
  
  # selected nodes, for map
  selNode <- numeric(0)
  observe({
    if (is.null(nodeaccum_shared$data())) return()
    seldf <- try(nodeaccum_shared$data(withSelection = TRUE))
    if (inherits(seldf, "try-error")) browser()
    # browser()
    selNodes_cur <- filter(seldf, selected_) %>%
      pull(node_id)
    
    if (length(selNodes_cur)) selNode <<- selNodes_cur
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
  
  # Base map with tiles, nodes, selected pixc
  output$rtmap <- renderLeaflet({
    locs <- riverNodeLocations()
    if (is.null(locs)) locs <- gdnodes_master
    basemap <- leaflet() %>%
      addTiles() %>%
      fitBounds(min(locs$longitude), min(locs$latitude),
                max(locs$longitude), max(locs$latitude)) %>% 
      mapOptions(zoomToLimits = "first")
    basemap
  })
  
  # Observer for pcv
  observe({
    pcvdf <- pcv_selected()
    proxy <- leafletProxy("rtmap",
                          data = pcvdf)    
    if (nrow(pcvdf) == 0)
      return(proxy)
    proxy %>%
      addCircles(~longitude, ~latitude, stroke = FALSE,
                 radius = ~sqrt(pixel_area / pi),
                 fillOpacity = 0.9,
                 popup = ~paste(sprintf("reach: %s\nnode: %s",
                                        reach_index, node_index)),
                 fillColor = ~classpal(classification),
                 group = "pcv", data = pcvdf)
  })
  
  # Observer for node locations
  observe({
    locations <- riverNodeLocations()
    proxy <- leafletProxy("rtmap",
                          data = locations) %>% 
      clearGroup("nodes")
    if (!length(locations))
      return(leafletProxy("rtmap"))

    selpal <- colorFactor("Set1", c(TRUE, FALSE)) #TODO: change this

    proxy %>%
      addCircleMarkers(
        ~longitude,
        ~latitude,
        popup = ~paste(sprintf("reach: %s\nnode: %s", reach_id, node_id)),
        opacity = 0.3,
        group = "nodes",
        # color = "blue",
        radius = 2
      )
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
                   fillOpacity = 0.8,
                   color = ~classpal(1),
                   group = "pcv_gdem")
    }
  })

  
  # Observer for rezooming
  observe({
    pcvdf <- pcv_selected()
    leafletProxy("rtmap") %>%
      leaflet::flyToBounds(lng1 = min(pcvdf$longitude),
                           lng2 = max(pcvdf$longitude),
                           lat1 = min(pcvdf$latitude),
                           lat2 = max(pcvdf$latitude))
  })

  # Observer for pcv points legend
  observe({

    proxy <- leafletProxy("rtmap", data = pcv_selected())
    # Remove any existing legend, and only if the legend is
    # enabled, create a new one.
    proxy %>% clearControls()
    if (length(selNode)) {
      proxy %>% addLegend(position = "topright",
                          colors = classpal(classes),
                          labels = classlabs)
    }
  })
  
  #### SLANT-PLANE MAP ####
  
  output$slantmap <- renderPlot({
    pixc_slantmap(pcv_selected(), maxpoints = 1e6)
  })
  
}


