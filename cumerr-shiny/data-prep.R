# Prep data for app

# modifying code from validation-objects.Rmd


valnums <- ro_manifest() %>% 
  filter(notes == "manuscript") %>% 
  filter(outno != 74, outno != 87) %>% # Remove this if/when the run is fixed.
  pull(outno)


# node flags --------------------------------------------------------------

ambignodes <- rodir(valnums) %>% 
  map(~data.frame(node_id = ambiguous_nodes(.))) %>% 
  bind_rows(.id = "runno") %>% 
  mutate(runno = as.numeric(runno),
         ambiguous = TRUE) %>% 
  rename(run = runno)


# nodes -------------------------------------------------------------------

refdemdf <- ro_manifest() %>% 
  transmute(run = outno, refdem)
  
rtnodes_simple <- valnums %>% 
  rodir("simple", "rt.nc") %>% 
  map(rt_read, group = "nodes") %>% 
  bind_rows(.id = "run") %>% 
  mutate(run = as.numeric(run))
rtnodes_composite <- valnums %>% 
  rodir("composite", "rt.nc") %>% 
  map(rt_read, group = "nodes") %>% 
  bind_rows(.id = "run") %>% 
  mutate(run = as.numeric(run))
rtnodes_frac <- valnums %>% 
  rodir("frac", "rt.nc") %>% 
  map(rt_read, group = "nodes") %>% 
  bind_rows(.id = "run") %>% 
  mutate(run = as.numeric(run))

rtnodes_master <- list(simple = rtnodes_simple,
                     composite = rtnodes_composite,
                     frac = rtnodes_frac) %>% 
  bind_rows(.id = "agg") %>% 
  left_join(refdemdf, by = "run")


gdnodes_master <- valnums %>% 
  rodir("rt_gdem.nc") %>% 
  map(rt_read, group = "nodes") %>% 
  bind_rows(.id = "run") %>% 
  mutate(run = as.numeric(run)) %>% 
  left_join(ambignodes, by = c("node_id", "run")) %>% 
  mutate(ambiguous = ifelse(is.na(ambiguous), FALSE, ambiguous)) %>% 
  left_join(refdemdf, by = "run")

save(rtnodes_master, file = "cumerr-shiny/cache/rtnodes_master.RData")
save(gdnodes_master, file = "cumerr-shiny/cache/gdnodes_master.RData")


# reaches -----------------------------------------------------------------

reachvaldf_simple <- rodir(valnums, "simple") %>% 
  rt_valdata_multi(group = "reaches", flag_out_nodes = FALSE)
reachvaldf_composite <- rodir(valnums, "composite") %>% 
  rt_valdata_multi(group = "reaches", flag_out_nodes = FALSE)
reachvaldf_frac <- rodir(valnums, "frac") %>% 
  rt_valdata_multi(group = "reaches", flag_out_nodes = FALSE)

reachvaldf_master <- list(simple = reachvaldf_simple,
                          composite = reachvaldf_composite,
                          frac = reachvaldf_frac) %>% 
  bind_rows(.id = "agg") %>% 
  filter(run != 71) # TODO: check on why 71 has mismatched times.

save(reachvaldf_master, file = "cumerr-shiny/cache/reachvaldf_master.RData")


# pixels ------------------------------------------------------------------

# gdem joined pixc -- identical across aggregation types
gdempixcols <- c("range_index", "azimuth_index", "classification",
                 "latitude", "longitude", "pixel_area", "node_index",
                 "reach_index")
gdempixdf <- rodir(valnums, "composite") %>% 
  map(~join_pixc(., pcvname = "pcv_gdem.nc", 
                 pixcname = "../fake_pixc.nc")[gdempixcols]) %>% 
  bind_rows(.id = "run")

save(gdempixdf, file = "cumerr-shiny/cache/gdempixdf.RData")

# simulated joined pixc -- also identical! 
pixcols <- c("range_index", "azimuth_index", "classification",
                 "latitude", "longitude", "latitude_vectorproc",
             "longitude_vectorproc", "pixel_area", "node_index",
             "reach_index", "water_frac", "water_frac_uncert")
pixdf <- rodir(valnums, "composite") %>% 
  map(~join_pixc(., pcvname = "pcv.nc", 
                 pixcname = "../pixel_cloud.nc")[pixcols]) %>% 
  bind_rows(.id = "run")

save(pixdf, file = "cumerr-shiny/cache/pixdf.RData")




