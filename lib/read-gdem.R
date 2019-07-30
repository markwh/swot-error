# Functions for reading entire GDEM files
# Migrated from rivertile package, where they weren't being used. 



#' Read in only a subset of a netcdf variable
#'
#' @param nc netcdf with variable of interest
#' @param varid passed to \code{ncvar_get}
#' @param inds Vector or matrix giving indices for which the variable value is desired.
#'
#' @importFrom stats df dnorm pchisq qnorm setNames
#' @export
ncvar_ss <- function(nc, varid=NA, inds) {
  if (length(dim(inds)) > 2) stop("dimensionality > 2 not supported.")
  if (length(dim(inds)) == 0) {
    return(ncvar_ss_1d(nc, varid, inds))
  }
  indlist <- split(inds[, 1], f = inds[, 2])
  
  pb <- progress::progress_bar$new(total = length(indlist))
  pb$tick(0)
  
  vals <- list()
  for (i in 1:length(indlist)) {
    pb$tick()
    vals[[i]] <- ncvar_ss_1d(nc, varid = varid, indvec = indlist[[i]],
                             inds2 = as.numeric(names(indlist)[i]))
  }
  out <- unlist(vals)
  out
}

ncvar_ss_1d <- function(nc, varid=NA, indvec, inds2 = NULL) {
  stopifnot(is.numeric(indvec) && is.vector(indvec))
  
  minind <- min(indvec)
  maxind <- max(indvec)
  indcnt <- maxind - minind + 1
  newinds <- indvec - minind + 1
  
  if (!is.null(inds2)) {
    minind <- cbind(minind, inds2)
    indcnt <- cbind(indcnt, 1)
  }
  
  out <- ncvar_get(nc, varid = varid, start = minind, count = indcnt)
  
  out <- as.vector(out[newinds])
  out
}

#' Check for inefficiencies in ncdf subset read function.
#'
#' Result should be close to 1.
#'
#' @param inds Matrix giving rows and columns of indices
#' @export
check_ineff <- function(inds) {
  num1 <- nrow(inds)
  num2 <- as.data.frame(inds) %>%
    group_by(col) %>%
    summarize(nret = max(row) - min(row) + 1) %>%
    summarize(sum = sum(nret)) %>%
    `[[`("sum")
  out <- num2 / num1
  out
}



#' Read a gdem netcdf
#'
#' @param ncfile gdem netcdf file
#'
#' @export
gdem_read <- function(ncfile) {
  pixc_nc <- nc_open(ncfile)
  on.exit(nc_close(pixc_nc))
  
  ltype <- ncvar_get(pixc_nc, "landtype")
  waterpix <- which(!is.na(ltype) & ltype == 1, arr.ind = TRUE)
  
  lats <- ncvar_ss(pixc_nc, "latitude", inds = waterpix)
  lons <- ncvar_ss(pixc_nc, "longitude", inds = waterpix)
  
  out <- data.frame(latitude = lats, longitude = lons)
  out <- adjust_longitude(out)
  out
}
