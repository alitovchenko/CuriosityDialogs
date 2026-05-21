#!/usr/bin/env Rscript

required_packages <- c(
  "jsonlite",
  "dplyr",
  "tidyr",
  "purrr",
  "stringr",
  "readr",
  "tibble",
  "forcats",
  "broom",
  "ggplot2"
)

install_if_missing <- function(pkgs) {
  installed <- rownames(installed.packages())
  missing <- setdiff(pkgs, installed)
  if (length(missing) > 0) {
    install.packages(missing, repos = "https://cloud.r-project.org")
  }
}

install_if_missing(required_packages)
message("Setup complete. Installed/validated packages: ", paste(required_packages, collapse = ", "))
