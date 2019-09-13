# roruns.R
# functions for accessing RiverObs runs, based on info stored in src/roruns.csv
# modified from work in notebook20190404.Rmd

roruns <- read.csv("src/roruns.csv", stringsAsFactors = FALSE)

ro_manifest <- function(files = paste0("~/Documents/swot-error/src/",
                                       c("roruns.csv", "roruns37.csv", 
                                         "roruns61.csv", "roruns65.csv",
                                         "roruns84.csv"))) {
  runnames <- gsub("\\..+$", "", gsub("^.*(.*/)+", "", files))
  out <- purrr::map(files, ~read.csv(., stringsAsFactors = FALSE)) %>% 
    setNames(runnames) %>% 
    bind_rows(.id = "runset")
}

#' Find roruns that are similar to a given rorun.
#' 
#' @param runno Run number in roruns manifest to reference
#' @param vary vector of roruns.csv columns that are allowed to vary; 
#'   other (relevant) columns will match rorow exactly.
romatch <- function(runno, vary, manifest = ro_manifest()) {
  rorow <- match(runno, manifest$outno)
  relcols <- c("priordb", "case", "pass", "day", "smearing",
               "land_sig0", "water_sig0", "gdem_name", "refdem",
               "refdem_res")
  keepcols <- setdiff(relcols, vary)
  rowstrings <- apply(manifest[, keepcols], 1, paste0, collapse = "")
  matchrow <- paste0(manifest[rorow, keepcols], collapse = "")
  outrows <- setdiff(which(matchrow == rowstrings), rorow)
  out <- manifest$outno[outrows]
  out
}

#' Fetch the directory path for a given rorun, specified as a row number of roruns.csv.
#' 
#' @param runno Run number in roruns manifest to reference
#' @param manifest as returned by \code{ro_manifest()}
#' @param ... passed to \code{fs::path()}
rodir <- function(runno, ..., manifest = ro_manifest(),
                  basedir = getOption("ro_basedir", 
                                      "~/Documents/swot-error/")) {
  rorow <- match(runno, manifest$outno)
  out <- normalizePath(fs::path(basedir, manifest$outdir[rorow], ...))
  names(out) <- roruns$outno[rorow]
  out
}


#' Get a bound data.frame for multiple runs. 
#' 
#' @param ... passed to \code{rodir()}
#' 
rt_valdata_multi <- function(runnos, group = c("nodes", "reaches"), 
                             ...,
                             manifest = ro_manifest(),
                             basedir = getOption("ro_basedir"),
                             flag_out_nodes = TRUE) {
  group <- match.arg(group)
  dirs <- rodir(runnos, ...,
                manifest = manifest,
                basedir = basedir)
  # browser()
  valdfs <- purrr::map(dirs, ~rt_valdata(dir = .,
                                           group = group, 
                                           flag_out_nodes = flag_out_nodes)) %>% 
    setNames(runnos)
  out <- bind_rows(valdfs, .id = "run") %>% 
    mutate(run = as.numeric(run)) %>% 
    left_join(manifest, by = c(run = "outno"))
  out
}
