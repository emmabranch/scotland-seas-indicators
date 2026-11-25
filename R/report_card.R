# report_card.R --------------------------------------------------------------
# Builds the homepage tiles and the "at a glance" box on each indicator page
# from one file: data/lookup/indicator_status.csv. Update the CSV as each
# analysis is finished and the whole site updates.

source(here::here("R", "theme_seas.R"))

read_status <- function() {
  readr::read_csv(here::here("data", "lookup", "indicator_status.csv"),
                  show_col_types = FALSE) |>
    dplyr::left_join(status_key, by = "status") |>
    dplyr::left_join(trend_key,  by = "trend")
}

tile_html <- function(row, prefix = "") {
  featured <- if (isTRUE(row$featured)) " featured" else ""
  htmltools::HTML(sprintf(
    '<a class="report-tile%s" href="%sindicators/%s.html" style="--status-col:%s"
        aria-label="%s: %s. %s.">
       <div class="tile-theme">%s</div>
       <div class="tile-title">%s</div>
       <div class="tile-status"><span class="tile-icon" aria-hidden="true">%s</span>%s</div>
       <div class="tile-trend"><span aria-hidden="true">%s</span> %s</div>
       <div class="tile-headline">%s</div>
       <div class="tile-meta"><span>%s</span>
         <span class="conf-dots" title="Confidence: %s">Confidence <span aria-hidden="true">%s</span></span></div>
     </a>',
    featured, prefix, row$id, row$col,
    row$title, row$label, row$trend_label,
    row$theme, row$title, row$icon, row$label,
    row$arrow, row$trend_label, row$headline,
    row$period, row$confidence, conf_dots(row$confidence)
  ))
}

report_card <- function() {
  s <- read_status() |> dplyr::arrange(dplyr::desc(featured), order)
  tiles <- lapply(seq_len(nrow(s)), \(i) tile_html(s[i, ]))
  htmltools::div(class = "report-grid", tiles)
}

status_legend <- function() {
  keys <- lapply(seq_len(nrow(status_key)), \(i) htmltools::HTML(sprintf(
    '<span class="key"><span class="tile-icon" style="background:%s;width:1.3rem;height:1.3rem;font-size:.8rem;color:#fff;border-radius:50%%;display:inline-grid;place-items:center" aria-hidden="true">%s</span>%s</span>',
    status_key$col[i], status_key$icon[i], status_key$label[i])))
  htmltools::div(class = "status-legend", keys)
}

# "At a glance" box for the top of each indicator page
glance_box <- function(indicator_id) {
  r <- read_status() |> dplyr::filter(id == indicator_id)
  htmltools::HTML(sprintf(
    '<div class="glance" style="--status-col:%s">
       <div><div class="glance-label">Status</div><div class="glance-value">%s %s</div></div>
       <div><div class="glance-label">Trend</div><div class="glance-value">%s %s</div></div>
       <div><div class="glance-label">Confidence</div><div class="glance-value">%s %s</div></div>
       <div><div class="glance-label">Period</div><div class="glance-value">%s</div></div>
     </div>',
    r$col, r$icon, r$label, r$arrow, r$trend_label,
    conf_dots(r$confidence), tools::toTitleCase(r$confidence), r$period))
}

# Map key shown below a leaflet map, so it never covers the data
map_key <- function(labels, colours, title = NULL) {
  items <- lapply(seq_along(labels), \(i) htmltools::tags$span(
    class = "key",
    htmltools::tags$span(class = "swatch", style = paste0("background:", colours[i])),
    labels[i]))
  htmltools::div(class = "map-key",
                 if (!is.null(title)) htmltools::tags$strong(title),
                 items)
}
