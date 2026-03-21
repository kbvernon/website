library(extera)
library(httr2)
library(jsonlite)

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

# download zotero data ---------------------------------------------------
download_zotero <- function(x, format) {
  collection <- paste0("ZOTERO_", toupper(x))

  zotero_request <- req_url_path_append(
    request("https://api.zotero.org"),
    "users",
    Sys.getenv("ZOTERO_ID"),
    "collections",
    Sys.getenv(collection),
    "items"
  )

  zotero_request <- req_url_query(
    zotero_request,
    key = Sys.getenv("ZOTERO_KEY"),
    itemType = "-note",
    format = format,
    sort = "date",
    direction = "desc",
    limit = 99L
  )

  zotero_response <- req_perform(zotero_request)

  ext <- if (format == "csljson") "json" else "bib"

  writeLines(
    resp_body_string(zotero_response),
    file.path(data_dir, paste0(x, ".", ext))
  )
}

for (collection in collections) {
  download_zotero(collection, "csljson")
  download_zotero(collection, "bibtex")
}

# inject note fields into csljson ----------------------------------------
inject_note_fields <- function(items) {
  lapply(items, function(item) {
    note <- item[["note"]]
    if (is.null(note)) {
      return(item)
    }
    lines <- gsub("\\\\", "", strsplit(note, "\n")[[1]])
    for (line in lines) {
      item[[sub(":.*", "", line)]] <- sub(".*: ", "", line)
    }
    item
  })
}

json_files <- file.path(data_dir, paste0(collections, ".json"))

bibs <- lapply(json_files, read_json)
bibs <- lapply(bibs, \(bib) inject_note_fields(bib[["items"]]))
bibs <- setNames(bibs, collections)

# render website ---------------------------------------------------------
tera <- new_engine("_templates/*.html")
tera$autoescape_off()

tera$render(
  "index.html",
  outfile = file.path(site_dir, "index.html"),
  articles = bibs[["article"]],
  manuscripts = bibs[["manuscript"]],
  presentations = bibs[["presentation"]]
)

# render cv --------------------------------------------------------------
system("typst compile --font-path fonts/ _templates/cv.typ pdfs/cv-vernon.pdf")

# clean up ---------------------------------------------------------------
# remove json now that everything has compiled
file.remove(json_files)

# copy files to _site/ ---------------------------------------------------
lapply(
  c("assets", "data", "pdfs"),
  file.copy,
  to = site_dir,
  recursive = TRUE,
  overwrite = TRUE
)
