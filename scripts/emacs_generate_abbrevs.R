generate_abbrev_lambdas <- function(pkgs, outfile = "~/.emacs.d/global_r_abbrevs.el") {
  lines <- c(
    ";; Auto-generated abbrevs using lambda insertion for all modes",
    "(define-abbrev-table 'global-abbrev-table '())"
  )

  for (pkg in pkgs) {
    ns <- getNamespace(pkg)
    fns <- getNamespaceExports(ns)

    for (fn in fns) {
      if (exists(fn, envir = ns, mode = "function")) {
        f <- get(fn, envir = ns)
        args <- names(formals(f))
        if (!is.null(args)) {
          abbrev <- paste0(pkg, fn)  # No slash
          args_string <- paste0("  ", args, collapse = ",\n")
          body <- sprintf("%s::%s(\n%s\n)", pkg, fn, args_string)
          # Escape backslashes and double quotes
          body <- gsub("\\\\", "\\\\\\\\", body)
          body <- gsub("\"", "\\\\\"", body)
          lines <- c(lines, sprintf(
            "(define-abbrev global-abbrev-table \"%s\" \"\"\n  (lambda () (insert \"%s\") t))",
            abbrev, body
          ))
        }
      }
    }
  }

  writeLines(lines, outfile)
}

generate_abbrev_lambdas(
  c(
    "dplyr",
    "ggplot2",
    "Matrix",
    "lubridate",
    "DatabaseConnector"
  )
)
