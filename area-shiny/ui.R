
ui <- dashboardPage(
  dashboardHeader(title = "SWOT Area Error"),
  dashboardSidebar(
    radioButtons("runselect", "Flow Condition", choices = c("High", "Low"))
  ),
  dashboardBody(
    fluidRow(
      column(width = 6,
        box(title = "Reach Area Relative Error", width = NULL,
            plotlyOutput("reach_relerrplot")),
        box(title = "Map", width = NULL,
            checkboxInput("map_gdem", "Show GDEM Truth"), 
            leafletOutput("rtmap"))),
      column(width = 6,
        box(title = "Node Accumulation", width = NULL,
            actionButton("nodePlot", "Plot"),
            actionButton("nodePurge", "Purge"),
            actionButton("nodeRestore", "Restore All"),
            checkboxInput("err_rel", "Relative"),
            plotlyOutput("node_accum")),
        box(title = "Node Area", width = NULL,
            plotlyOutput("nodearea_plot"))
            # uiOutput("waterfrac_slider"))
            # filter_slider("wfrac", "Water Fraction", testpixc_shared, ~water_frac))
            )
    )
  )
)

