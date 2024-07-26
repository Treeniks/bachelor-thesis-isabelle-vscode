#import "/layout/cover.typ": *
#import "/layout/titlepage.typ": *
#import "/layout/disclaimer.typ": *
#import "/layout/acknowledgement.typ": *
#import "/layout/abstract.typ": *
#import "/layout/fonts.typ": *

#let thesis(
  title: "",
  titleGerman: "",
  degree: "",
  program: "",
  supervisor: "",
  advisors: (),
  author: "",
  startDate: datetime,
  submissionDate: datetime,
  abstract_en: "",
  abstract_de: "",
  body,
) = {
  cover(
    title: title,
    degree: degree,
    program: program,
    author: author,
  )

  titlepage(
    title: title,
    titleGerman: titleGerman,
    degree: degree,
    program: program,
    supervisor: supervisor,
    advisors: advisors,
    author: author,
    startDate: startDate,
    submissionDate: submissionDate,
  )

  disclaimer(
    title: title,
    degree: degree,
    author: author,
    submissionDate: submissionDate,
  )

  acknowledgement()

  abstract(lang: "en")[#abstract_en]
  abstract(lang: "de")[#abstract_de]

  set page(
    margin: (left: 30mm, right: 30mm, top: 40mm, bottom: 40mm),
    numbering: "1",
    number-align: center,
  )

  set text(
    font: body-font,
    size: 12pt,
    lang: "en",
  )

  show math.equation: set text(weight: 400, font: math-font)

  // --- Headings ---
  show heading: set block(below: 1em, above: 2em)
  show heading: set text(font: body-font)
  set heading(numbering: "1.1")

  // Reference first-level headings as "chapters"
  show heading.where(level: 1): set heading(supplement: [Chapter])
  show heading.where(level: 1): set text(size: 20pt)
  // Put chapters on new page and add extra spacing
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    v(3em)
    it
  }

  // --- Paragraphs ---
  set par(leading: 0.6em)
  // set block(spacing: 0.8em)

  // --- Citations ---
  // use default instead
  // set cite(style: "alphanumeric")

  // --- Figures ---
  show figure: set text(size: 0.85em)

  // --- Table of Contents ---
  outline(
    title: {
      text(font: body-font, 1.5em, weight: 700, "Contents")
      v(15mm)
    },
    indent: 2em,
  )


  v(2.4fr)
  pagebreak()


  // Main body.
  // set par(justify: true, first-line-indent: 1em)
  set par(justify: true)
  set list(indent: 1em)
  set enum(indent: 1em)

  body

  // List of figures.
  pagebreak()
  outline(
    title: "List of Figures",
    target: figure.where(kind: image),
  )

  // List of tables.
  pagebreak()
  outline(
    title: "List of Tables",
    target: figure.where(kind: table)
  )

  // Appendix.
  // pagebreak()
  // heading(numbering: none)[Appendix A: Supplementary Material]
  // include("/layout/appendix.typ")

  pagebreak()
  bibliography("/biblio.yml")
}
