# Write_rdata.R
# Script to create relevant R objects and save them as .RData files. 

source("~/Documents/swot-rtval/rivertile-viz/global.R")

refdf <- read.csv("~/Documents/swot-error/src/roruns.csv")

dirlist <- paste0("~/Documents/swot-error/", refdf$outdir)


# Directory on box server
library(boxr)
box_auth()
boxdir <- box_search("rtval_RData", type = "folder")[[1]]$id
boxlsdf <- as.data.frame(box_ls(boxdir))


for (i in 2:length(dirlist)) {
  diri <- dirlist[i]
  dirspl <- strsplit(diri, "/")[[1]]
  dir_short <- dirspl[length(dirspl)]
  rtdata_in <- get_rivertile_data(diri)
  badnodes_in <-  c(mismatch_nodes(rtdata_in$rt_nodes, 
                                   rtdata_in$gdem_nodes),
                   ambiguous_nodes(diri))
  
  namei <- paste0(dir_short, ".RData")
  box_save(rtdata_in, badnodes_in, dir_id = boxdir, file_name = namei)
  print(namei)
}
