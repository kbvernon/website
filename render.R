library(extera)
library(httr2)
library(jsonlite)
library(tynding)

collections <- c("article", "manuscript", "presentation")

# setup directories ------------------------------------------------------
data_dir <- "data"
if (!dir.exists(data_dir)) {
  dir.create(data_dir)
}

site_dir <- "_site"
if (!dir.exists(site_dir)) {
  dir.create(site_dir)
}

# do not run jekyll on gh pages
writeLines("", file.path(site_dir, ".nojekyll"))

# map custom domain to gh pages
writeLines("www.kbvernon.io", file.path(site_dir, "CNAME"))


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
    file.path(data_dir, paste0(collection, ".json"))
  )

  # download and write bibtex
  writeLines(
    download_zotero(collection, "bibtex"),
    file.path(data_dir, paste0(collection, ".bib"))
  )
}

json_files <- file.path(data_dir, paste0(collections, ".json"))
bibs <- lapply(json_files, read_json)
bibs <- lapply(bibs, \(x) x[["items"]])
bibs <- setNames(bibs, collections)

# render website ---------------------------------------------------------
tera <- new_engine("templates/*.html")
tera$autoescape_off()

metadata <- read_json("metadata.json")

tera$render(
  "index.html",
  outfile = file.path(site_dir, "index.html"),
  meta = metadata[["meta"]],
  name = metadata[["name"]],
  links = metadata[["links"]],
  position = metadata[["position"]],
  articles = bibs[["article"]],
  manuscripts = bibs[["manuscript"]],
  presentations = bibs[["presentation"]]
)

# render cv --------------------------------------------------------------
typst_compile(
  "templates/cv.typ",
  output = sprintf("pdfs/%s", metadata[["links"]][["cv"]]),
  font_path = "typst/fonts/",
  root = "."
)

# clean up ---------------------------------------------------------------
# remove json now that everything has compiled
file.remove(json_files)

# copy files to _site/ ---------------------------------------------------
file.copy(
  c("data", "pdfs", "web"),
  to = site_dir,
  recursive = TRUE,
  overwrite = TRUE
)
