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
us_ds <- function(pcdf, verbose = FALSE) {
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
  
  startinds_us <- which(pcdf$node_index == max(pcdf$node_index))
  startinds_ds <- which(pcdf$node_index == min(pcdf$node_index))
  
  connect_all <- function(startinds, upstream = FALSE) {
    front_cur <- startinds # Indices coprising current front
    frontno <- integer(length(rangeinds)) # Track which front each pixel belongs to
    frontno[front_cur] <- 1L
    
    connected <- rep(FALSE, length(rangeinds))
    
    # This will move the "front" of connected pixels one neighborhood distance further
    advance_front <- function(front, upstream = FALSE) {
      new_front <- numeric(length(front) * 30L) # allocate a conservatively large new front
      starti <- 1
      for (index in front) {
        new_nbrs <- stream_neighbors(index, upstream = upstream, nn = 2L)
        if (!(n_new_nbrs <- length(new_nbrs))) next
        endi <- starti + n_new_nbrs - 1
        new_front[starti:endi] <- new_nbrs
        starti <- endi + 1
      }
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
  out <- cbind(data.frame(connected = dsdf$connected_ds & usdf$connected_us,
                    along = along),
               dsdf, usdf)
  out
}

