# Globals for shiny app

# library(shinyFiles)
library(shinythemes)
library(shinydashboard)
# library(rivertile)
devtools::load_all("~/Documents/rivertile")
source("../lib/rivertile.R")
library(ncdf4)
library(fs)
library(ggplot2)
library(leaflet)
library(purrr)
library(dplyr)
library(plotly)
library(crosstalk)


theme_set(theme_bw())

## server.R objects

# Variable selection
pixc_vars_tokeep <- c("azimuth_index", "range_index", "classification", 
                      "num_rare_looks", "latitude", "longitude", "height", 
                      "pixel_area", "water_frac", "cross_track", "num_med_looks")
pixcvec_vars_tokeep <- c("azimuth_index", "range_index", "latitude_vectorproc", 
                         "longitude_vectorproc", "height_vectorproc", "node_index", 
                         "reach_index")

# Colors
nodecolor_unsel <- "#668cff"
nodecolor_sel <- "#0039e6"

# Pixc(vec) color legend
classes <- c(1, 2, 3, 4, 22, 23, 24)
classlabs <- c("gdem water", "land near water", "water near land", 
               "open water", "land near dark water", 
               "dark water edge", "dark water")
classpal <- colorFactor(palette = "Set1", domain = classes)
classcolvec <- setNames(classpal(classes), classes)

# Data funcitons
get_rivertile_data <- function(dir, truth = "gdem") {
  rt_nodes <- rt_read(path(dir, "rt.nc"), group = "nodes")
  rt_reaches <- rt_read(path(dir, "rt.nc"), group = "reaches")
  gdem_nodes <- rt_read(path(dir, sprintf("rt_%s.nc", truth)), 
                        group = "nodes")
  gdem_reaches <- rt_read(path(dir, sprintf("rt_%s.nc", truth)), 
                          group = "reaches")
  
  rt_pixcvec <- pixcvec_read(path(dir, "pcv.nc"))[pixcvec_vars_tokeep] %>% 
    dplyr::rename(node_id = node_index, reach_id = reach_index)
  
  gdem_pixcvec <- pixcvec_read(path(dir, sprintf("pcv_%s.nc", truth))) %>% 
    `[`(pixcvec_vars_tokeep) %>% 
    dplyr::rename(node_id = node_index, reach_id = reach_index)
  
  rt_pixc <- pixc_read(path(dir, "pixel_cloud.nc"))[pixc_vars_tokeep] %>% 
    left_join(rt_pixcvec, y = ., by = c("azimuth_index", "range_index")) %>% 
    mutate(pixel_id = 1:nrow(.))
  gdem_pixc <- pixc_read(path(dir, "fake_pixc.nc"))[pixc_vars_tokeep] %>% 
    inner_join(gdem_pixcvec, y = ., by = c("azimuth_index", "range_index"))
  
  out <- list(rt_nodes = rt_nodes, rt_reaches = rt_reaches, 
              gdem_nodes = gdem_nodes, gdem_reaches = gdem_reaches,
              rt_pixc = rt_pixc, gdem_pixc = gdem_pixc)
  out
}

redo_reach <- function(reachdata, nodedata, weight = TRUE) {
  # browser()
  reachdf0 <- nodedata %>% 
    reach_agg(weight = weight)
  commonnames <- intersect(names(reachdata), names(reachdf0))
  reachdata[commonnames] <- reachdf0[commonnames]
  reachdata
}

#' Function to remove nodes from an rtdata set--that is, a list of data.frames.
purge_nodes <- function(rtdata, purgenodes = numeric(0), 
                        redo_reaches = TRUE) {
  # browser()
  if (length(purgenodes) == 0) return(rtdata)
  reachinds <- grep("reach", names(rtdata))
  purgefun <- function(x) x[!(x[["node_id"]] %in% purgenodes), ]
  
  out <- rtdata
  out[-reachinds] <- lapply(rtdata[-reachinds], purgefun)
  if (redo_reaches) {
    out$rt_reaches <- redo_reach(rtdata$rt_reaches, out$rt_nodes)
    out$gdem_reaches <- redo_reach(rtdata$gdem_reaches, out$gdem_nodes, weight = FALSE)
  }
  out
}


# Test data
testpixc <- join_pixc("~/Documents/swot-error/output/sac18/") %>% 
  rename(node_id = node_index) %>% 
  filter(node_id == 300) %>% 
  dplyr::arrange(desc(water_frac)) %>% 
  mutate(cum_area = cumsum(pixel_area), area_lag = 
           dplyr::lag(cum_area, default = 0), 
         classification = as.factor(classification)) %>% 
  ungroup()

testpixc_shared <- highlight_key(testpixc)

