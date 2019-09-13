# Moving water algorithm. 

library(fastmatch)

#' modify along_reach to continue across reach boundaries and coerce 
#'  downstream-ness across node boundaries
#'  
#'  @export

adjust_along <- function(alongvals, nodeinds) {
  along_split <- split(alongvals, nodeinds)
  along_rezero <- map(along_split, function(x) x - min(x))
  shifts <- c(0, map_dbl(along_rezero, max))[1:length(along_split)] %>% 
    cumsum()
  along <- map2(along_rezero, shifts, function(x, y) x + y) %>% 
    unsplit(nodeinds)
  along
}


#' Upstream-downstream algorithm
#' 
#' @param pcdf As returned by \code{pixcvec_read} or \code{join_pixc}
#' @param verbose Display progress updates?
#' @importFrom fastmatch fmatch
#' @export
us_ds <- function(pcdf, start = c("midstream", "ends"), verbose = FALSE) {
  
  start <- match.arg(start)
  
  rangeinds <- as.numeric(pcdf$range_index)
  aziminds <- as.numeric(pcdf$azimuth_index)
  reachinds <- as.numeric(pcdf$reach_index)
  nodeinds <- as.numeric(pcdf$node_index)
  pixcinds <- as.numeric(pcdf$pixc_index)
  
  along <- adjust_along(as.numeric(pcdf$along_reach), nodeinds)
  
  # Lookup table for range-azimuth combos
  ra_table <- rangeinds * 1e5 + aziminds
  match_range_azim <- function(r_inds, a_inds) {
    # tomatch <- outer(r_inds * 1e5, a_inds, "+")
    tomatch <- rep(r_inds * 1e5, length(a_inds)) + 
      rep(a_inds, each = length(r_inds))
    
    out <- fmatch(tomatch, ra_table)
    out[!is.na(out)]
  }
  
  # Find indices of up/downstream neighbors for a given index
  stream_neighbors <- function(index, upstream = FALSE, nn = 2L) {
    this_range <- rangeinds[index]
    this_azimuth <- aziminds[index]
    this_along <- along[index]
    neighborinds <- match_range_azim(this_range + -nn:nn, 
                                     this_azimuth + -nn:nn)
    nbrmask <- along[neighborinds] > this_along
    if (upstream) nbrmask <- !nbrmask
    out_inds <- neighborinds[nbrmask]
    out_inds
  }

  # Initialize connectivity vectors to prep for recursion
  uscount <- 1
  dscount <- 1
  
  if (start == "ends") {
    startinds_us <- which(pcdf$node_index == max(pcdf$node_index))
    startinds_ds <- which(pcdf$node_index == min(pcdf$node_index))
  } else {
    startinds_us <- which(abs(pcdf$cross_reach) < 5)
    startinds_ds <- startinds_us
  }

  
  connect_all <- function(startinds, upstream = FALSE) {
    front_cur <- startinds # Indices coprising current front
    frontno <- integer(length(rangeinds)) # Track which front each pixel belongs to
    frontno[front_cur] <- 1L
    
    connected <- rep(FALSE, length(rangeinds))
    
    # This will move the "front" of connected pixels one neighborhood distance further
    advance_front <- function(front, upstream = FALSE) {
      if (!length(front)) return()
      new_front <- numeric(length(front) * 30L) # allocate a conservatively large new front
      starti <- 1
      for (index in front) {
        new_nbrs <- stream_neighbors(index, upstream = upstream, nn = 2L)
        if (!(n_new_nbrs <- length(new_nbrs))) next
        endi <- starti + n_new_nbrs - 1
        new_front[starti:endi] <- new_nbrs
        starti <- endi + 1
      }
      if (!exists("endi")) return() # case where front has no streamwise neighbors
      setdiff(new_front[1:endi], which(connected))
    }
    
    connected[startinds] <- TRUE
    count_cur <- 1L # Count of how many iterations (how many different fronts)
    while(length(front_cur)) {
      # for (i in 1:600) {
      front_cur <- advance_front(front_cur, upstream = upstream)
      connected[front_cur] <- TRUE
      
      # Track the front movement--not necessary for algorithm to work
      count_cur <- count_cur + 1L
      frontno[front_cur] <- count_cur
      
      if (verbose && (count_cur %% 100 == 0)) {
        cat(sum(connected), length(front_cur), "\n")
      }
    }
    out <- data.frame(connected = connected, frontno = frontno)
    out
  }
  
  # Move downstream
  dsdf <- connect_all(startinds_ds, upstream = FALSE)
  names(dsdf) <- paste0(names(dsdf), "_ds")
  if (verbose) message("Downstream connection complete")
  
  # Move upstream
  usdf <- connect_all(startinds_us, upstream = TRUE)
  names(usdf) <- paste0(names(usdf), "_us")
  if (verbose) message("Upstream connection complete")
  
  # Create final data frame and return
  out <- cbind(data.frame(connected = dsdf$connected_ds & 
                                      usdf$connected_us, 
                          along = along),
               dsdf, usdf, 
               pcdf[c("range_index", "azimuth_index")])
  out
}


#' Flag sloughs in pixel clouds in a given directory.
#' 
#' Uses \code{us_ds()} to connect pixels, adds a flag to those not connected.
#' 
#' @param dir directory containing RiverObs output
#' @param pixcflag value to use for classifying sloughs in pixel cloud
#' @param gdemflag value to use for classifying sloughs in gdem pixel cloud
#' 
#' @export
flag_sloughs <- function(dir, pixcflag = 9L,
                         gdemflag = 0L) {
  
  # create files to contain new classification
  file.copy(paste0(dir, "/pixel_cloud.nc"), 
            paste0(dir, "/pixel_cloud_flagged.nc"), overwrite = TRUE)
  file.copy(paste0(dir, "/fake_pixc.nc"), 
            paste0(dir, "/pixc_gdem_flagged.nc"), overwrite = TRUE)
  
  # connect pixels
  message("Connecting pixel cloud")
  pixccon <- us_ds(pixcvec_read(paste0(dir, "/pcv.nc")))
  message("Connecting gdem pixel cloud")
  gdemcon <- us_ds(pixcvec_read(paste0(dir, "/pcv_gdem.nc")))
  message("Connected.")
  
  # Match connections to pixel cloud by range, azimuth
  pixcnc <- nc_open(paste0(dir, "/pixel_cloud_flagged.nc"), write = TRUE)
  # on.exit(nc_close(pixcnc))
  
  pixcclass <- ncvar_get(pixcnc, "pixel_cloud/classification")
  pixcclass_out <- rep(pixcflag, length(pixcclass))
  pixcrange <- ncvar_get(pixcnc, "pixel_cloud/range_index")
  pixcazim <- ncvar_get(pixcnc, "pixel_cloud/azimuth_index")
  pixcrangeazim <- pixcrange * 1e6 + pixcazim
  
  flagrangeazim <- with(pixccon[pixccon$connected, ], 
                        range_index * 1e6 + azimuth_index)
  flaginds <- match(flagrangeazim, pixcrangeazim)
  
  # Assign to classification
  pixcclass_out[flaginds] <- pixcclass[flaginds]
  ncvar_put(pixcnc, varid = "pixel_cloud/classification", pixcclass_out)    
  nc_close(pixcnc)
  
  # Now gdem fake pixel cloud
  gdemnc <- nc_open(paste0(dir, "/pixc_gdem_flagged.nc"), write = TRUE)
  # on.exit(nc_close(gdemnc))
  
  gdemclass <- ncvar_get(gdemnc, "pixel_cloud/classification")
  gdemclass_out <- rep(gdemflag, length(gdemclass))
  gdemrange <- ncvar_get(gdemnc, "pixel_cloud/range_index")
  gdemazim <- ncvar_get(gdemnc, "pixel_cloud/azimuth_index")
  gdemrangeazim <- gdemrange * 1e6 + gdemazim
  
  flagrangeazim <- with(gdemcon[gdemcon$connected, ], 
                        range_index * 1e6 + azimuth_index)
  flaginds <- match(flagrangeazim, gdemrangeazim)
  
  # Assign to classification
  # browser()
  gdemclass_out[flaginds] <- gdemclass[flaginds]
  ncvar_put(gdemnc, varid = "pixel_cloud/classification", gdemclass_out)
  nc_close(gdemnc)
  
}