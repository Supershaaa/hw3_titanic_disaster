# src/r/install_packages.R
pkgs <- c("data.table", "stringr")
inst <- installed.packages()[, "Package"]
to_install <- setdiff(pkgs, inst)
if (length(to_install)) {
  install.packages(to_install, repos = "https://cloud.r-project.org")
}
