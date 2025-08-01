packages <- readLines("packages.txt")

renv::install(packages, lock = TRUE)

renv::snapshot()
