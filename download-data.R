library(httr2)
library(jsonlite)

collections <- c("papers", "drafts", "talks")

zotero_request <- function(...) {
  request("https://api.zotero.org") |>
    req_headers(
      "Zotero-API-Key" = Sys.getenv("ZOTERO_KEY"),
      "Zotero-API-Version" = "3"
    ) |>
    req_retry(max_tries = 3) |>
    req_url_path_append("users", Sys.getenv("ZOTERO_ID"), ...)
}

for (collection in collections) {
  key <- Sys.getenv(paste0("ZOTERO_", toupper(collection)))
  top <- zotero_request("collections", key, "items", "top") |>
    req_url_query(
      itemType = "-note",
      sort = "date",
      direction = "desc",
      limit = 99L
    )

  # download csl json
  zotero <- top |>
    req_url_query(format = "csljson") |>
    req_perform() |>
    resp_body_json()
  items <- zotero[["items"]]

  # extract github and status from note field
  for (i in seq_along(items)) {
    note <- gsub("\\\\", "", items[[i]][["note"]] %||% "")
    for (field in c("github", "status")) {
      pattern <- paste0("(?<=", field, ": )[^\r\n]+")
      value <- regmatches(note, regexpr(pattern, note, perl = TRUE))
      if (length(value)) items[[i]][[field]] <- value
    }
  }

  # download pdf attachments
  folder <- file.path("static", collection)
  unlink(folder, recursive = TRUE)
  dir.create(folder)
  ids <- vapply(items, \(x) sub(".*/", "", x[["id"]]), character(1))
  attachments <- zotero_request("collections", key, "items") |>
    req_url_query(itemType = "attachment", format = "json", limit = 99L) |>
    req_perform() |>
    resp_body_json()
  for (attachment in attachments) {
    a <- attachment[["data"]]
    if (identical(a[["contentType"]], "application/pdf")) {
      zotero_request("items", a[["key"]], "file") |>
        req_perform(path = file.path(folder, a[["filename"]]))
      i <- match(a[["parentItem"]], ids)
      items[[i]][["pdf"]] <- a[["filename"]]
    }
  }

  # inject year into draft items
  if (collection == "drafts") {
    for (i in seq_along(items)) {
      year <- as.integer(format(Sys.Date(), "%Y"))
      items[[i]][["issued"]][["date-parts"]][[1]][[1]] <- year
    }
  }

  # zotero api sort is not fully deterministic, so do additional sort
  if (collection == "drafts") {
    status <- vapply(items, \(x) x[["status"]] %||% "", character(1))
    title <- vapply(items, \(x) x[["title"]] %||% "", character(1))
    idx <- order(-xtfrm(status), title)
  } else {
    date_parts <- lapply(items, \(x) x[["issued"]][["date-parts"]][[1]])
    year <- vapply(date_parts, \(x) as.integer(x[[1]]) %||% 0L, integer(1))
    title <- vapply(items, \(x) x[["title"]] %||% "", character(1))
    idx <- order(-year, title)
  }
  zotero[["items"]] <- items[idx]

  # write json
  writeLines(
    toJSON(zotero, auto_unbox = TRUE),
    file.path("static", "data", paste0(collection, ".json"))
  )

  # download and write bibtex
  top |>
    req_url_query(format = "bibtex") |>
    req_perform(path = file.path("static", "data", paste0(collection, ".bib")))
}
