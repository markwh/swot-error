# roruns.R
# functions for accessing RiverObs runs, based on info stored in src/roruns.csv
# modified from work in notebook20190404.Rmd

roruns <- read.csv("src/roruns.csv", stringsAsFactors = FALSE)

#' Find roruns that are similar to a given rorun.
#' 
#' @param rorow Row number in roruns.csv to reference
#' @param vary vector of roruns.csv columns that are allowed to vary; 
#'   other (relevant) columns will match rorow exactly.
romatch <- function(rorow, vary) {
  relcols <- c("priordb", "case", "pass", "bndry_cond", "smearing",
               "land_sig0", "water_sig0", "gdem_name")
  keepcols <- setdiff(relcols, vary)
  rowstrings <- apply(roruns[, keepcols], 1, paste0, collapse = "")
  matchrow <- paste0(roruns[rorow, keepcols], collapse = "")
  out <- setdiff(which(matchrow == rowstrings), rorow)
  out
}

#' Fetch the directory path for a given rorun, specified as a row number of roruns.csv.
#' 
#' @param rorow Row number in roruns.csv to reference
rodir <- function(rorow, 
                  basedir = getOption("ro_basedir", 
                                      "~/Documents/swot-error/")) {
  out <- normalizePath(fs::path(basedir, roruns$outdir[rorow]))
  names(out) <- roruns$outno[rorow]
  out
}