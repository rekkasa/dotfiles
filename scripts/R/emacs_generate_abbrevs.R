generate_abbrev_lambdas <- function(pkgs, outfile = "~/.emacs.d/global_r_abbrevs.el") {
  lines <- c(
    ";; Auto-generated abbrevs using lambda insertion for all modes",
    "(define-abbrev-table 'global-abbrev-table '())"
  )

  total_abbrevs <- 0

  for (pkg in pkgs) {
    message(sprintf("Processing package: %s", pkg))
    abbrev_count <- 0
    failed_count <- 0

    ns <- tryCatch(getNamespace(pkg), error = function(e) {
      message(sprintf("Failed to load namespace for '%s': %s", pkg, e$message))
      return(NULL)
    })
    if (is.null(ns)) next

    fns <- getNamespaceExports(ns)

    for (fn in fns) {
      if (exists(fn, envir = ns)) {
        f <- get(fn, envir = ns)
        if (is.function(f)) {
          args <- names(formals(f))
          if (!is.null(args)) {
            abbrev <- paste0(pkg, fn)  # e.g. "dplyrfilter"
            args_string <- paste0("  ", args, collapse = ",\n")
            body <- sprintf("%s::%s(\n%s\n)", pkg, fn, args_string)
            body <- gsub("\\\\", "\\\\\\\\", body)
            body <- gsub("\"", "\\\\\"", body)
            lines <- c(lines, sprintf(
              "(define-abbrev global-abbrev-table \"%s\" \"\"\n  (lambda () (insert \"%s\") t))",
              abbrev, body
            ))
            abbrev_count <- abbrev_count + 1
          }
        } else {
          failed_count <- failed_count + 1
        }
      } else {
        failed_count <- failed_count + 1
      }
    }

    total_abbrevs <- total_abbrevs + abbrev_count
    message(sprintf("%d abbrevs generated from %s", abbrev_count, pkg))
    if (failed_count > 0) {
      message(sprintf("%d symbols skipped (not functions or not found)", failed_count))
    }
  }

  writeLines(lines, outfile)
  message(sprintf("\nAll done. Total abbrevs written: %d", total_abbrevs))
  message(sprintf("Output file: %s", normalizePath(outfile)))
}



packages <- readLines("packages.txt")

generate_abbrev_lambdas(packages)
