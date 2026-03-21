// ── Packages ──────────────────────────────────────────────────────────────────
#import "@preview/fontawesome:0.6.0": fa-icon
#import "@preview/use-academicons:0.1.0": *

// ── Fonts & Colors ────────────────────────────────────────────────────────────
#let sans = "Noto Sans"
#let mono = "IBM Plex Mono"

#let ink    = black
#let muted  = rgb("#555555")
#let border = rgb("#cccccc")

#let data-font-size = 0.9em
#let meta(body) = text(fill: muted, size: data-font-size, body)

// ── Page Setup ────────────────────────────────────────────────────────────────
#let base-size = 10.5pt  // change this to scale everything
#let date-fmt = "[month repr:long] [year]"

#set document(title: "Kenneth Blake Vernon — CV")
#set page(
  paper: "us-letter",
  margin: (x: 0.8in, y: 0.8in),
  footer: context if counter(page).get().first() == 1 [
    #align(right, text(size: 0.7em, fill: muted)[
      Last updated: #datetime.today().display(date-fmt)
    ])
  ],
)
#set text(font: sans, size: base-size, fill: ink)
#set par(leading: 0.8em, spacing: 0.75em)

// ── Helpers ───────────────────────────────────────────────────────────────────
#let icon-box(ico) = box(width: 1.1em, align(center, ico))

#let cv-section(name) = block(sticky: true)[
  #v(1.4em)
  #text(font: mono, size: 0.82em, weight: "bold")[#upper(name)]
  #v(-2pt)
  #line(length: 100%, stroke: 0.2pt + border)
  #v(0.4em)
]

// year is a string; pass "" to suppress display (collapsed row)
#let entry(year, body, bspace: 1em) = {
  block(breakable: false, grid(
    columns: (3em, 1fr),
    column-gutter: 0.75em,
    align(top + right, pad(top: 0.1em, text(font: mono, size: data-font-size, fill: muted, year))),
    align(top, body),
  ))
  v(bspace)
}

#let plain-entry(body) = {
  block(breakable: false, grid(
    columns: (3em, 1fr),
    column-gutter: 0.75em,
    [],
    body,
  ))
  v(0.45em)
}

// ── Data Helpers ──────────────────────────────────────────────────────────────
#let fmt-authors(authors) = {
  let names = authors.map(a => {
    a.at("given", default: "") + " " + a.at("family", default: "")
  }).join(", ")
  if names == "" { return "" }
  fa-icon("people-group", size: 0.75em) + h(0.3em) + names
}

#let get-year(item) = {
  let issued = item.at("issued", default: none)
  if issued == none { return "n.d." }
  let parts = issued.at("date-parts", default: ((0,),))
  str(parts.at(0).at(0, default: "n.d."))
}

#let fmt-article(item) = {
  let title   = item.at("title", default: "")
  let authors = fmt-authors(item.at("author", default: ()))
  let journal = item.at("container-title", default: "")
  let volume  = item.at("volume", default: "")
  let issue   = item.at("issue", default: "")
  let page    = item.at("page", default: "")
  let doi     = item.at("DOI", default: "")

  let ref-line = journal
  if volume != "" { ref-line += " " + volume }
  if issue  != "" { ref-line += "(" + issue + ")" }
  if page   != "" { ref-line += ":" + page }

  [
    *#title* \
    #if ref-line != "" [
      #meta[#ref-line] \
    ]
    #meta[#authors] \
    #if doi != "" [
      #meta[
        #ai-icon("doi", size: 0.75em)#h(0.3em)#link("https://doi.org/" + doi)[#doi]
      ]
    ]
  ]
}

#let fmt-presentation(item) = {
  let title   = item.at("title", default: "")
  let authors = fmt-authors(item.at("author", default: ()))
  let event   = item.at("event-title", default: item.at("publisher", default: ""))
  let place   = item.at("event-place", default: "")

  let venue = event
  if place != "" and event != "" { venue += ", " + place }
  else if place != "" { venue = place }

  [
    *#title* \
    #if venue != "" [
      #meta[#venue] \
    ]
    #if authors != "" [
      #meta[#authors]
    ]
  ]
}

// renders a list of items, showing the year only when it changes
#let bib-block(items, fmt) = {
  let prev-year = ""
  for item in items {
    let year = get-year(item)
    entry(if year != prev-year { year } else { "" }, fmt(item))
    prev-year = year
  }
}

// ── Load Data ─────────────────────────────────────────────────────────────────
#let articles      = json("data/article.json").items
#let manuscripts   = json("data/manuscript.json").items
#let presentations = json("data/presentation.json").items

// ── Header ────────────────────────────────────────────────────────────────────

#text(font: mono, size: 1.55em, weight: "bold")[Kenneth Blake Vernon]
#v(0.5em)
#text(size: data-font-size)[
  #grid(
    columns: (1fr, auto),
    column-gutter: 1em,
    [
      Scientific Computing and Imaging Institute \
      University of Utah \
      72 So. Central Campus Drive Room 3750 \
      Salt Lake City, Utah 84112
    ],
    align(right)[
      #link("https://www.kbvernon.io/")[kbvernon.io]
      #h(0.4em) #icon-box(fa-icon("image-portrait")) \
      #link("https://github.com/kbvernon")[kbvernon]
      #h(0.4em) #icon-box(fa-icon("github")) \
      #link("https://orcid.org/0000-0003-0098-5092")[0000-0003-0098-5092]
      #h(0.4em) #icon-box(fa-icon("orcid")) \
      #link("https://scholar.google.com/citations?user=2PE4za4AAAAJ")[2PE4za4AAAAJ]
      #h(0.4em) #icon-box(ai-icon("google-scholar"))
    ],
  )
]

// ── Professional Appointments ─────────────────────────────────────────────────
#cv-section("Professional Appointments")

#entry("2025")[
  *One-U Responsible AI Postdoctoral Fellow* \
  #meta[
    Scientific Computing and Imaging Institute; School of Environment, Society, and Sustainability, University of Utah
  ]
]
#entry("2022")[
  *Post-Doctoral Associate* \
  #meta[
    Center for Collaborative Synthesis in Archaeology, CU Boulder
  ]
]
#entry("2018")[
  *Assistant Director* \
  #meta[
    University of Utah Archaeological Center
  ]
]

// ── Education ─────────────────────────────────────────────────────────────────
#cv-section("Education")

#entry("2022")[*PhD in Anthropology* #h(0.3em) #text(fill: muted)[ | University of Utah, Salt Lake City, UT]]
#entry("2009")[*MA in Philosophy* #h(0.3em) #text(fill: muted)[ | Northern Illinois University, DeKalb, IL]]
#entry("2006")[*BA in History and Philosophy* #h(0.3em) #text(fill: muted)[ | University of Central Arkansas, Conway, AR]]

// ── Peer-reviewed Articles ────────────────────────────────────────────────────
#cv-section("Peer-reviewed Journal Articles")

#bib-block(articles, fmt-article)

// ── Manuscripts ───────────────────────────────────────────────────────────────
#cv-section("Manuscripts")

#bib-block(manuscripts, fmt-article)

// ── Grants, Fellowships, and Awards ──────────────────────────────────────────
#cv-section("Grants, Fellowships, and Awards")

#entry("2025")[
  *extendr: Community-focused development for scientific computing with Rust and R* \
  #meta[ISC Grant | R Consortium \
  PI: Kenneth B. Vernon, Josiah Parry, Mossa M. Reimert | \$4,000]
]
#entry("2022")[
  *Archaeological Survey of Cottonwood Wash, San Rafael Desert, Emery County, Utah* \
  #meta[Cooperative Agreement (L20AC00267) | Bureau of Land Management \
  PI: Brian F. Codding, Jerry D. Spangler | \$18,698]
]
#entry("2020")[
  *Developing a Modular Online Introduction to the R Environment* \
  #meta[Cross-College Training Grant | University of Utah College of Social and Behavioral Sciences \
  PI: Simon Brewer, Brian F. Codding, Kenneth B. Vernon | \$21,020]
]
#entry("")[
  *Advancing Stewardship with Theory and Models* \
  #meta[David C. Williams Memorial Graduate Fellowship | University of Utah \
  PI: Kenneth B. Vernon | \$6,000]
]
#entry("2019")[
  *Graduate Research* \
  #meta[Earl and Elies Skidmore Endowed Graduate Fellowship | University of Utah \
  PI: Kenneth B. Vernon | \$7,500]
]
#entry("")[
  *Advancing Stewardship with Theory and Models* \
  #meta[David C. Williams Memorial Graduate Fellowship | University of Utah \
  PI: Kenneth B. Vernon | \$8,500]
]
#entry("2018")[
  *Why Were Prehistoric Agricultural Societies in Utah Unable to Adapt to the Medieval Megadroughts?* \
  #meta[Interdisciplinary Faculty Research Seed Grant | University of Utah Global Change and Sustainability Center \
  PI: Brian F. Codding, Simon Brewer | \$20,000]
]
#entry("")[
  *Advancing Stewardship with Theory and Models* \
  #meta[David C. Williams Memorial Graduate Fellowship | University of Utah \
  PI: Kenneth B. Vernon | \$1,000]
]
#entry("2017")[
  *Human Plant Use in Red Butte Canyon* \
  #meta[Research Grant | Friends of Red Butte \
  PI: Kenneth B. Vernon | \$2,000]
]
#entry("")[
  *Human Plant Use in Red Butte Canyon* \
  #meta[Research Grant | University of Utah Global Change and Sustainability Center \
  PI: Kenneth B. Vernon | \$3,000]
]
#entry("")[
  *Archaeological Sites as Endangered Species: Using Next Generation Models to Predict and Protect Cultural Properties on the Grand Staircase-Escalante National Monument* \
  #meta[Grand Staircase-Escalante National Monument Cooperative Agreement | Bureau of Land Management \
  PI: Brian F. Codding | \$22,066]
]

// ── Presentations ─────────────────────────────────────────────────────────────
#cv-section("Presentations")

#bib-block(presentations, fmt-presentation)

// ── Teaching ──────────────────────────────────────────────────────────────────
#cv-section("Teaching")

#plain-entry[
  #text(fill: muted)[
    Teaching interests: Behavioral Ecology, Urban Science, Environmental Data Science, Statistics,
    Geography, Conservation & Sustainability, Human Prehistory, North American Prehistory.
  ]
]

#plain-entry[
  *University of Utah* \
  #text(fill: muted)[
    ANTH 1010: Culture and the Human Experience \
    ANTH 1030: Introduction to World Prehistory \
    ANTH 5850: Quantitative Analysis of Archaeological Data
  ]
]

// ── Professional Affiliations ─────────────────────────────────────────────────
#cv-section("Professional Affiliations")

#entry("2016", bspace: 0.3em)[Great Basin Anthropological Association]
#entry("2014", bspace: 0.3em)[Society for American Archaeology]
#entry("2022", bspace: 0.3em)[Coalition for Archaeological Synthesis]
#entry("2023", bspace: 0.3em)[European Association of Archaeologists]

// ── Service ───────────────────────────────────────────────────────────────────
#cv-section("Service, Outreach, and Other Activities")

#entry("2022")[
  *Studio Lab* | University of Colorado, Boulder, 2022--2024 \
  #meta[Mentor. Supporting undergraduate research.]
]
#entry("2018")[
  *Undergraduate Research Opportunities Program* | University of Utah, 2018--2022 \
  #meta[Mentor. Supporting undergraduate research.]
]
#entry("")[
  *Journal Club: Problems in Evolutionary Anthropology* | University of Utah, 2018--2022 \
  #meta[Organizer.]
]
#entry("")[
  *Hopi Tribe v Donald J. Trump, Utah Diné Bikéyah v Donald J. Trump, Natural Resources Defense Council v Donald J. Trump* \
  #meta[Brief Amici Curiae of Archaeological Organizations in Support of Plaintiffs. Contributor.]
]

// ── References ────────────────────────────────────────────────────────────────
#cv-section("References")

#text(style: "italic")[Available upon request.]
