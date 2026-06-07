#' Plot estimates from one or more did_multiplegt_stat models
#'
#' Takes a named list of `did_multiplegt_stat` objects and plots the aggregated
#' estimates (AOSS, WAOSS, or IV-WAOSS) with 95% confidence intervals.
#' Placebo estimates are shown as hollow points when available.
#'
#' @param models Named list of `did_multiplegt_stat` objects.
#' @param estimator Character vector. Which estimators to display
#'   (`"aoss"`, `"waoss"`, `"ivwaoss"`). Default `NULL` auto-detects from
#'   each model's stored arguments.
#' @param show_placebo Logical. Show placebo estimates when available?
#'   Set to `FALSE` to suppress them even if `placebo = TRUE` was used.
#'   Default `TRUE`.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' \dontrun{
#' m1 <- did_multiplegt_stat(df, Y = "y", ID = "id", Time = "t", D = "d",
#'                            exact_match = TRUE, placebo = TRUE)
#' m2 <- did_multiplegt_stat(df, Y = "y", ID = "id", Time = "t", D = "d",
#'                            exact_match = FALSE, placebo = TRUE)
#' plot_stat(list(m1 = m1, m2 = m2))
#' }
plot_stat <- function(
  models,
  estimator    = NULL,
  show_placebo = TRUE
) {

  # Determine which estimators to plot for a given model
  resolve_estimators <- function(m) {
    if (!is.null(estimator)) return(estimator)
    if (is.null(m$args$estimator) && is.null(m$args$Z)) c("aoss", "waoss")
    else if (is.null(m$args$estimator)) "ivwaoss"
    else m$args$estimator
  }

  # Build a short config label from model args (used in x-axis annotation)
  make_label <- function(m) {
    a          <- m$args
    parts      <- c()
    if (isTRUE(a$exact_match))     parts <- c(parts, "exact match")
    if (isTRUE(a$noextrapolation)) parts <- c(parts, "no extrap.")
    if (!is.null(a$switchers))     parts <- c(parts, paste0(a$switchers, " switchers"))
    em         <- if (is.null(a$estimation_method)) "dr" else a$estimation_method
    method_map <- c(ra = "RA", dr = "DR", ps = "PS")
    parts      <- c(parts, method_map[em])
    paste(parts, collapse = ", ")
  }

  # Extract one aggregated row from the results table
  extract_one <- function(m, model_name, row_name, type, is_placebo) {
    tbl <- if (is_placebo) m$results$table_placebo else m$results$table
    if (is.null(tbl) || !(row_name %in% rownames(tbl))) return(NULL)
    r <- tbl[row_name, ]
    tibble::tibble(
      model   = model_name,
      type    = type,
      placebo = is_placebo,
      est     = as.numeric(r[["Estimate"]]),
      lb      = as.numeric(r[["LB CI"]]),
      ub      = as.numeric(r[["UB CI"]])
    )
  }

  rows_for_model <- function(m, model_name) {
    estims      <- resolve_estimators(m)
    has_placebo <- isTRUE(m$args$placebo) && isTRUE(show_placebo)
    row_map     <- c(aoss = "AOSS", waoss = "WAOSS", ivwaoss = "IVWAOSS")
    out <- list()
    for (e in estims) {
      rn  <- row_map[e]
      out <- c(out, list(extract_one(m, model_name, rn, toupper(e), FALSE)))
      if (has_placebo)
        out <- c(out, list(extract_one(m, model_name, rn, toupper(e), TRUE)))
    }
    dplyr::bind_rows(Filter(Negate(is.null), out))
  }

  df <- purrr::imap_dfr(models, rows_for_model)

  # x-axis: "m1\n(exact match, RA)"
  x_labels <- purrr::imap_chr(models, ~ paste0(.y, "\n(", make_label(.x), ")"))

  # Title: outcome, treatment, unit — from the first model's stored args
  a0         <- models[[1]]$args
  plot_title <- paste0("Y: ", a0$Y, "   |   D: ", a0$D, "   |   Unit: ", a0$ID)

  ggplot2::ggplot(df, ggplot2::aes(x = model, y = est, colour = type, shape = placebo)) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", colour = "grey40") +
    ggplot2::geom_point(position = ggplot2::position_dodge(0.5), size = 3) +
    ggplot2::geom_errorbar(
      ggplot2::aes(ymin = lb, ymax = ub),
      position = ggplot2::position_dodge(0.5), width = 0.2
    ) +
    ggplot2::scale_x_discrete(labels = x_labels) +
    ggplot2::scale_shape_manual(
      values = c(`FALSE` = 16, `TRUE` = 1),
      labels = c(`FALSE` = "Estimate", `TRUE` = "Placebo")
    ) +
    ggplot2::labs(
      title  = plot_title,
      x      = NULL,
      y      = "Estimate",
      colour = "Estimator",
      shape  = NULL
    ) +
    ggplot2::theme_minimal()
}
