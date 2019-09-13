
ui <- dashboardPage(
  dashboardHeader(title = "SWOT Cumulative Error"),
  dashboardSidebar(
    radioButtons("varselect", "Variable", 
                 choices = c("area_total", "width", "wse"), 
                 selected = "width"),
    radioButtons("refdemselect", "Reference DEM", choices = c("GDEM", "SRTM"),
                 selected = "GDEM"),
    radioButtons("aggselect", "Pixel Aggregation", 
                 choices = c("simple", "frac", "composite"), selected = "frac"),
    checkboxInput("flagnodes", "Remove Ambiguous Nodes", value = FALSE)
  ),
  dashboardBody(
    fluidRow(
      column(width = 6,
        box(title = "Reach Errors", width = NULL,
            plotlyOutput("reach_errplot")),
        box(title = "Map", width = NULL,
            checkboxInput("map_gdem", "Show GDEM Truth"), 
            leafletOutput("rtmap"))),
      column(width = 6,
        box(title = "Node Accumulation", width = NULL,
            actionButton("nodePlot", "Plot"),
            # actionButton("nodePurge", "Purge"),
            # actionButton("nodeRestore", "Restore All"),
            checkboxInput("err_rel", "Standardize"),
            plotlyOutput("node_accum")),
        box(title = "Slantplane Map", width = NULL,
            plotOutput("slantmap"))
            # uiOutput("waterfrac_slider"))
            # filter_slider("wfrac", "Water Fraction", testpixc_shared, ~water_frac))
            )
    )
  )
)

