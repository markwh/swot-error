# Write_rdata.R
# Script to create relevant R objects and save them as .RData files. 

source("~/Documents/swot-rtval/rivertile-viz/global.R")

rtdata_default <- get_rivertile_data(defaultdir)

badnodes_default <- c(min(rtdata_default$rt_nodes$node_id), 
                      max(rtdata_default$rt_nodes$node_id),
                      flag_nodes(defaultdir))



refdf <- read.csv("~/Documents/swot-error/src/roruns.csv")

dirlist <- paste0("~/Documents/swot-error/", refdf$outdir)


# Directory on box server
boxdir <- box_search("rtval_RData", type = "folder")[[1]]$id


for (i in 3:length(dirlist)) {
  diri <- dirlist[i]
  dirspl <- strsplit(diri, "/")[[1]]
  dir_short <- dirspl[length(dirspl)]
  rtdata_in <- get_rivertile_data(diri)
  badnodes_in <-  c(min(rtdata_default$rt_nodes$node_id), 
                   max(rtdata_default$rt_nodes$node_id),
                   flag_nodes(diri))
  boxr::box_save(rtdata_in, badnodes_in, dir_id = boxdir, file_name = paste0(dir_short, ".RData"))
  
  
}
