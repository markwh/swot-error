# Objects for use in riverproducts app.


# Functions ---------------------------------------------------------------

cache_rp <- function (..., list = character(), 
                      cachedir = "~/Documents/riverproducts/rdata",
                      envir = parent.frame()) {
  dots <- match.call(expand.dots = FALSE)$...
  if (length(dots) && !all(vapply(dots, function(x) is.symbol(x) || 
                                  is.character(x), NA, USE.NAMES = FALSE))) 
    stop("... must contain names or character strings")
  names <- vapply(dots, as.character, "")
  if (length(names) == 0L) 
    names <- character()
  list <- .Primitive("c")(list, names)
  
  files <- file.path(cachedir, paste0(list, ".RData"))
  purrr::map2(files, list, ~save(list = .y, file = .x, envir = envir))
}

# Spatial data on passes --------------------------------------------------

passes <- c(249, 264, 527)

passes_files <- sprintf("%s/SWOT_ephemeris2015_science_full_%04d.nc",
                        "~/Documents/swot-error/data/orbits",
                        passes)

sacpases_list <- map(passes_files, ~orbit_read(.)) %>% 
  setNames(passes)

sacpasses_df <- sacpases_list %>% 
  map(~data.frame(.)) %>% 
  bind_rows(.id = "pass")


sacgeoms <- Reduce(f = c, x = map(sacpases_list, ~pull(., geometry)))
sacpasses_sf <- mutate(sacpasses_df, geometry = allgeoms) %>% 
  st_as_sf()

cache_rp(sacpasses_sf)


# Tiles spatial data ------------------------------------------------------
alltvp <- fs::path(rodir(51:54), "pixel_cloud.nc") %>% 
  map(~pixc_read(ncfile = ., group = "tvp")) %>% 
  setNames(51:54)
nadir1 <- map(alltvp, ~c(.$longitude[1], .$latitude[1])) %>% 
  Reduce(rbind, .)
nadir2 <- map(alltvp, ~c(.$longitude[nrow(.)], .$latitude[nrow(.)])) %>% 
  Reduce(rbind, .)
hdg <- map_dbl(alltvp, ~median(.$velocity_heading))
halves <- ro_manifest()[51:54, ] %>% pull("tile") %>% substr(4, 4)
tilesfc <- getTilePolygons(nadir1, nadir2, hdg, halves)
tilesf <- st_sf(data.frame(run = 51:54, geometry = tilesfc))

cache_rp(tilesf)

add_swot_tile <- function(map, nadir1, nadir2, heading, half, ...) {
  # browser()
  crnrs <- getTileCorners(nadir1, nadir2, heading, half = half)
  lat <- crnrs[, 2]
  lng <- crnrs[, 1]
  
  addPolygons(map = map, lng = lng, lat = lat, ...)
}
cache_rp(add_swot_tile)
cache_rp(getTileCorners)
tilelist <- map(list(nadir1 = nadir1, nadir2 = nadir2, heading = hdg, 
                      half = halves), ~split(., 1:4)) %>% 
  purrr::transpose() %>% 
  setNames(51:54)
cache_rp(tilelist)


# Simulation info ---------------------------------------------------------

rundf <- ro_manifest() %>% 
  filter(refdem == "GDEM", refdem_res == "10m", priordb == "$PRIORLOC4")

rundf$date <- lubridate::ymd(sprintf("2009%04d", rundf$day))

cache_rp(rundf)

# Prior database spatial data ---------------------------------------------

# centerlines
reaches1 <- path(rodir(40), "rt.nc") %>% 
  rt_read(group = "reaches") %>% 
  pull(reach_id)

allrts <- path(rodir(51:54), "rt.nc")
reaches2 <- purrr::map(allrts, ~pull(rt_read(.), "reach_id")) %>% 
  Reduce(unique, .)

priorncfile1 <- "D:/data/SWOT-prior/PriorDistributionFolder/netcdfV4/NA07.nc"
priorncfile2 <- path("~/Documents/swot-error/data/priordb-update/Sac_sample_db15.nc")

clsf1 <- priorcl_read(priorncfile1, reachids = reaches1, as_sf = TRUE) 
clsf2 <- priorcl_read(priorncfile2, reachids = reaches2, as_sf = TRUE) 

cache_rp(clsf1, clsf2)

# Nodes
nodesf1 <- priornode_read(priorncfile1, reachids = reaches1, as_sf = TRUE)
nodesf2 <- priornode_read(priorncfile2, reachids = reaches2, as_sf = TRUE)

cache_rp(nodesf1, nodesf2)


# Cross-track distances to prior nodes ------------------------------------
# This is a hack using rivertile data.

allval <- rundf$outno %>% 
  rt_valdata_multi()
xtkdf <- allval %>% 
  select(run, node_id, xtrk_dist, pass, tile) %>% 
  left_join(rundf, 
            by = c("run" = "outno", pass = "pass", tile = "tile")) %>% 
  mutate(pass = as.factor(pass)) %>% 
  group_by(pass, tile, date) %>% 
  summarize(min_xtk = min(abs(xtrk_dist)), max_xtk = max(abs(xtrk_dist)))

xtk_gg <- ggplot(xtkdf, aes(x = date, ymin = min_xtk, ymax = max_xtk)) + 
  geom_linerange(aes(color = pass, linetype = tile),
                 size = 1.5,
                 position = position_dodge(width = 1.5))
cache_rp(xtkdf, xtk_gg)


# Files for a given tile

filenames <- c("pixel_cloud.nc", "pixc_vec.nc", "rivertile.nc",
               "nodes.shp", "reaches.shp")
