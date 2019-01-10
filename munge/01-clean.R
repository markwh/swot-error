# 01-clean.R
# Mark Hagemann
# 11/27/2018
# Load and clean data from swot simulator and truth files (from Rui)


# Pixel cloud -------------------------------------------------------------

pixnc <- nc_open("data/sac-pixc/109_ellip_off_heights_sac_cycle_0001_pass_0249_presum2.125.AzPTR.Presum.Noise.LeftSwath.Unflat.Multilook_L2PIXC.nc")

getvec <- function(...) {
  out0 <- ncvar_get(...)
  out <- as.vector(out0)
  out
}
pixc_df <- data.frame(
  lat = getvec(pixnc, "latitude_medium"),
  lon = getvec(pixnc, "longitude_medium"),
  height = getvec(pixnc, "height_medium"),
  class = getvec(pixnc, "classification"),
  xtrack = getvec(pixnc, "cross_track_medium"),
  nlooks = getvec(pixnc, "num_looks"),
  dhdphi = getvec(pixnc, "dheight_dphase_medium") # meters per radian
)

# calculate variance from Brent's math
if_real <- ncvar_get(pixnc, varid = "ifgram_real")
if_imag <- ncvar_get(nc = pixnc, varid = "ifgram_imag")
pwr1 <- ncvar_get(pixnc, varid = "power_left")
pwr2 <- ncvar_get(pixnc, varid = "power_right")
nlooks <- ncvar_get(pixnc, "num_looks")
nc_close(pixnc)

coh_denom_log <- 1/2 * (log(pwr1) + log(pwr2))
coh_denom <- exp(coh_denom_log)
if_norm <- sqrt(if_real^2 + if_imag^2)
# coh_calc_log <- log(if_norm) - coh_denom_log
coh_calc <- if_norm / coh_denom
var_approx <- 1 / (2 * nlooks) * (1 - coh_calc^2) / coh_calc^2

pixc_df$phase_var = as.vector(var_approx)

pixc_sf <- pixc_df %>% 
  filter(lat > 0) %>% # purge anomalous points in southern hemisphere
  st_as_sf(coords = c("lon", "lat"), crs = 4326) %>% 
  mutate(h_var_pix = phase_var * dhdphi^2)


# Node and reach shapefiles -----------------------------------------------

node_shp <- st_read("data/sac-nodedb/Sacramento-NodeDatabase.shp")
reach_shp <- st_read("data/sac-reachdb/Sacramento-ReachDatabase.shp")

spts <- as(node_shp$geometry, "Spatial")
node_voroni_sf <- st_as_sf(voronoi(spts))

# Aggregate pixc to node --------------------------------------------------

anywhich <- function(x) ifelse(length(which(x)) < 1, NA, which(x))

pixc_agnode <- pixc_sf %>% 
  st_within(node_voroni_sf, sparse = FALSE)

whichnode <- apply(pixc_agnode, 1, anywhich)

pixc_sf$nodeid <- whichnode

pixc_ag_sf <- pixc_sf %>% 
  group_by(nodeid) %>% 
  summarize(height = mean(height), medheight = median(height),
            h_var_node = mean(h_var_pix))


cache("pixc_sf")
cache("pixc_ag_sf")


# "true" values for validation --------------------------------------------

sac_node_truth <- st_read("data/sac-truth/SWOT_L2_HR_River_SP_001_249_Sac_20090109T000000_Node_Truth/SWOT_L2_HR_River_SP_001_249_Sac_20090109T000000_Node_Truth/SWOT_L2_HR_River_SP_001_249_Sac_20090109T000000_Node_Truth.shp") %>% 
  sf:::select.sf(reach_id, node_id, height, width)
nodemap <- st_within(sac_node_truth, node_voroni_sf, sparse = FALSE)
sac_node_truth$nodeid <- apply(nodemap, 1, anywhich)

cache("sac_node_truth")


