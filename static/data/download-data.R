library(httr2)
library(jsonlite)

collections <- c("article", "manuscript", "presentation")

# download and process zotero data ---------------------------------------
download_zotero <- function(x, format) {
  collection <- paste0("ZOTERO_", toupper(x))

  zotero_endpoint <- req_url_path_append(
    request("https://api.zotero.org"),
    "users",
    Sys.getenv("ZOTERO_ID"),
    "collections",
    Sys.getenv(collection),
    "items"
  )

  zotero_request <- req_url_query(
    zotero_endpoint,
    key = Sys.getenv("ZOTERO_KEY"),
    itemType = "-note",
    format = format,
    sort = "date",
    direction = "desc",
    limit = 99L
  )

  zotero_response <- req_perform(zotero_request)

  resp_body_string(zotero_response)
}

for (collection in collections) {
  # download csl json
  zotero <- parse_json(download_zotero(collection, "csljson"))
  items <- zotero[["items"]]

  # unnest note field
  for (i in seq_along(items)) {
    item <- items[[i]]
    note <- item[["note"]]
    if (!is.null(note)) {
      lines <- gsub("\\\\", "", strsplit(note, "\n")[[1]])
      for (line in lines) {
        key <- sub(":.*", "", line)
        value <- sub(".*: ", "", line)
        item[[key]] <- value
      }
    }
    items[[i]] <- item
  }

  # inject year into manuscript items
  if (collection == "manuscript") {
    for (i in seq_along(items)) {
      year <- as.integer(format(Sys.Date(), "%Y"))
      items[[i]][["issued"]][["date-parts"]][[1]][[1]] <- year
    }
  }

  # zotero api sort is not fully deterministic, so do additional sort
  if (collection == "manuscript") {
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
  writeLines(
    download_zotero(collection, "bibtex"),
    file.path("static", "data", paste0(collection, ".bib"))
  )
}

json_files <- file.path("static", "data", paste0(collections, ".json"))
bibs <- lapply(json_files, read_json)
bibs <- lapply(bibs, \(x) x[["items"]])
bibs <- setNames(bibs, collections)
