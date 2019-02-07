# netcdf.R
# Process netcdf outputs of RiverObs
# modified from notebook20190204.Rmd.


#' Get data from a rivertile netcdf
#' @importFrom ncdf4 nc_open nc_close ncvar_get
#' @importFrom purrr map map_lgl

rt_read <- function(ncfile, group = c("nodes", "reaches"),
                    keep_na_vars = FALSE) {
  group <- match.arg(group)
  
  rt_nc <- nc_open(ncfile)
  on.exit(nc_close(rt_nc))
  
  grepstr <- sprintf("^%s/", group)
  
  grpvars <- names(rt_nc$var)[grepl(grepstr, names(rt_nc$var))]
  grpnames <- splitPiece(grpvars, "/", 2, fixed = TRUE)
  
  outvals_list <- map(grpvars, ~as.vector(ncvar_get(rt_nc, .))) %>% 
    setNames(grpnames)
  
  outvals_df <- as.data.frame(outvals_list)
  if (! keep_na_vars) {
    nacols <- map_lgl(outvals_list, ~sum(!is.na(.)) == 0)
    outvals_df <- outvals_df[!nacols]
  }
  outvals_df
}



#' Get a validation dataset from a set of RiverObs runs

rt_valdata <- function(dir, group = c("nodes", "reaches"),
                       rtname = "rt.nc", gdname = "rt_gdem.nc"){
  
  group <- match.arg(group)
  rt_nc <- nc_open(paste0(dir, "/", ))
}
