# Utility functions

#' Load development rivertile package
loadall <- function(dir = "rivertile") {
  dir <- fs::path("~/Documents/", dir)
  devtools::load_all(dir)
}
