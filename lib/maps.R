# Mapping rivertile and pixc data

#' Convert linear distance to lat/lon distance
#' 
#' Helper for map_node_pixc.
to_latlon <- function(x, lat, lon) {
  lon_m <- cos(lat * pi / 180) * 110567
  lat_m <- 111000 # approximately
  out <- x * sqrt(1 / (lat_m * lon_m))
  out
}
#' #' Map pixel cloud for given nodes
#' #' 
#' #' @param pixdf from \code{pixcvec_read()} or \code{join_pixc()}
#' #' @param ... passed to \code{geom_point()} or \code{geom_circle()}
#' map_node_pixc <- function(pixdf, 
#'                           nodes, 
#'                           gdemdf = NULL,
#'                           buffer = 5, scale = FALSE, 
#'                           real_area = FALSE, 
#'                           gdsize = 0.5, pixcsize = 5 * gdsize,
#'                           ...) {
#'   
#'   pixdf <- pixdf %>% 
#'     filter(node_index %in% (nodes + -buffer:buffer)) %>% 
#'     mutate(sizescale = 1,
#'            classification = as.factor(classification),
#'            innodes = node_index %in% nodes,
#'            alpha = ifelse(innodes, 0.75, 0.3))#,
#'            # radius_m = sqrt(pixel_area / pi),
#'            # radius_ll = to_latlon(radius_m,
#'            #                       latitude_vectorproc,
#'            #                       longitude_vectorproc))
#'   
#'   # if (scale) {
#'   #   pixdf <- pixdf %>% 
#'   #     mutate(sizescale = water_frac,
#'   #            radius_ll = radius_ll * water_frac)
#'   }
#'   
#'   if (!is.null(gdemdf)) {
#'     gdemdf <- gdemdf %>% 
#'       filter(node_index %in% (nodes + -buffer:buffer)) %>% 
#'       mutate(innodes = node_index %in% nodes,
#'              alpha = ifelse(innodes, 1, 0.3),
#'              radius_m = sqrt(pixel_area / pi),
#'              radius_ll = to_latlon(radius_m, latitude, longitude))
#'   }
#'   
#'   # Calculate actual pixel sizes, if directed to.
#'   if (real_area) {
#'     # convert pixel area to radius in meters, then to lat/lon
#'     pixradius_m <- sqrt(pixdf$pixel_area / pi)
#'     gdradius_m <- sqrt(gdemdf$pixel_area / pi)
#'     
#'     pixdf <- pixdf %>% 
#'       mutate(radius_ll = to_latlon(pixradius_m, 
#'                                    latitude_vectorproc, 
#'                                    longitude_vectorproc))
#'     if (scale) pixdf$radius_ll <- pixdf$radius_ll * pixdf$water_frac
#'   } 
#'   
#'   
#'   # Construct ggplot object
#'   mapgg <- pixdf %>% 
#'     ggplot()
#'   
#'   # add truth, if supplied.
#'   if (!is.null(gdemdf)) {
#'     if (real_area) {
#'       
#'       
#'     } else {
#'       
#'     }
#'   }
#'   
#'   if (real_area) {
#'     if (!is.null(gdemdf)) {
#'       mapgg <- mapgg + 
#'         geom_circle(aes(x0 = longitude, y0 = latitude,
#'                         r = radius_ll,
#'                         alpha = alpha),
#'                     fill = "black", n = 6,
#'                     data = gdemdf, size = gdsize, linetype = 0)
#'     }
#'     
#'     
#'     mapgg <- mapgg + 
#'       geom_circle(aes(x0 = longitude_vectorproc, y0 = latitude_vectorproc,
#'                       alpha = alpha, 
#'                       fill = classification, 
#'                       r = radius_ll),
#'                   n = 8, linetype = 0)
#'   } else { # use points instead of circles
#'     if (!is.null(gdemdf)) {
#'       mapgg <- mapgg + 
#'         geom_point(aes(x = longitude, y = latitude,
#'                        alpha = alpha),
#'                    color = "black",
#'                    data = gdemdf, size = gdsize)
#'     }
#'     
#'     
#'     mapgg <- mapgg + 
#'       geom_point(aes(x = longitude_vectorproc, y = latitude_vectorproc,
#'                      alpha = alpha, 
#'                      color = classification, 
#'                      size = pixcsize * sizescale),
#'                  shape = 20) + 
#'       scale_size_identity()
#'     
#'   }
#'   
#'   mapgg <- mapgg + 
#'     scale_alpha_identity() +
#'     coord_map()
#'   
#'   mapgg
#' }

