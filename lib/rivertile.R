# Functions that might go into rivertile package

#' Nodewise error and cumulative error
#' 
#' Plots node series of a bunch of (un)scaled and (non-)cumulative errors
rt_nodewise_error <- function(valdata, variable = "area_total", plot = TRUE, breaks = 20) {
  varbl <- variable
  plotdf <- valdata %>% 
    dplyr::filter(variable == varbl) %>% 
    group_by(reach_id) %>% 
    arrange(node_id) %>% 
    transmute(node_id, 
              pixc_err,
              rel_err = pixc_err / sigma_est,
              cumul_err = cumsum(pixc_err),
              cumul_uncert = sqrt(cumsum(sigma_est^2)),
              cumul_relerr = cumul_err / cumul_uncert,
              sigma_est) %>% 
    ungroup() %>% 
    gather(key = "variable", value = "value", -reach_id, -node_id, -cumul_uncert, -sigma_est) %>% 
    mutate(uncert = case_when(variable == "pixc_err" ~ sigma_est,
                              variable == "rel_err" | variable == "cumul_relerr" ~ 1,
                              variable == "cumul_err" ~ cumul_uncert))
  if (!plot) return(plotdf)
  nodebreaks <- unique(plotdf$node_id) %>% `[`(.%%breaks == 0)
  
  out <- ggplot(plotdf, aes(x = node_id, y = value)) +
    geom_line() + 
    geom_line(aes(y = uncert), color = "red") +
    geom_line(aes(y = -uncert), color = "red") +
    geom_line(aes(y = 1.96 * uncert), color = "red", linetype = 2) +
    geom_line(aes(y = -1.96 * uncert), color = "red", linetype = 2) +
    # facet_wrap(~reach_id, scales = "free_x") +
    facet_grid(variable~reach_id, scales = "free", space = "free_x") +
    scale_x_continuous(breaks = nodebreaks, expand = expand_scale(0, 0)) +
    theme(panel.spacing = unit(2, "points"))
  out
}



#' QQ plot for validation
#' 
#' @export

rt_val_qq <- function(valdf, vars = "all", plot = TRUE, groupvars = "variable") {
  
  # groupvars <- enquo(groupvars)
  if (length(vars) > 1 || vars != "all") {
    valdf <- valdf %>%
      dplyr::filter(variable %in% vars)
  }
  # browser()
  qqgg1 <- valdf %>%
    # group_by(!!!groupvars) %>% 
    group_by_at(groupvars) %>% 
    mutate(rel_err = pixc_err / sigma_est, 
           theoretical = qqnorm(rel_err, plot.it = FALSE)$x) %>% 
    ungroup()
  if (!plot) return(qqgg1)
  out <- ggplot(qqgg1, aes(x = theoretical, y = rel_err)) +
    geom_point() +
    facet_wrap(~variable, scales = "free_y") +
    geom_abline(slope = 1, intercept = 0)
  out
}


