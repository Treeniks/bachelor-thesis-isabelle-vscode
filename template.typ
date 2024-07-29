#import "@preview/codly:1.0.0": *

#let thesis(
  title-primary: [],
  title-secondary: [],
  degree: "",
  program: "",
  supervisor: "",
  advisors: (),
  author: "",
  start-date: datetime,
  submission-date: datetime,
  acknowledgements: [],
  abstract: [],
  appendix: none,
  doc,
) = {
  show: codly-init.with()

  set document(title: title-primary, author: author, date: submission-date)
  set page(margin: (left: 30mm, right: 30mm, top: 40mm, bottom: 40mm))

  // default
  show par: set block(spacing: 1.2em)

  show heading: set block(below: 1.6em, above: 2.4em)
  // Reference first-level headings as "chapters"
  show heading.where(level: 1): set heading(supplement: [Chapter])
  show heading.where(level: 1): set text(size: 1.4em)
  show heading.where(level: 2): set text(size: 1.2em)
  show heading.where(level: 3): set text(size: 1.1em)
  show heading.where(level: 4): set text(size: 1.05em)
  // Put chapters on new page and add extra spacing
  show heading.where(level: 1): it => {
    // reset footnote counter
    counter(footnote).update(0)
    pagebreak(weak: true)
    v(3em)
    it
  }

  show figure.caption: set text(size: 0.85em)

  set list(indent: 1em)
  set enum(indent: 1em)

  let cit = upper(text(size: 24pt, [School of Computation,\ Information and Technology\ -- Informatics --]))
  let tum = upper(text(size: 14pt, [Technical University of Munich]))
  let degree-program = text(size: 16pt, degree + "’s Thesis in " + program)
  let title1 = text(weight: "bold", size: 20pt, title-primary)
  let title2 = text(weight: "regular", size: 20pt, title-secondary)

  // ===== Cover =====
  {
    set align(center)
    image("/resources/tum-logo.svg", width: 30%)
    cit
    v(0mm)
    tum
    v(10mm)
    degree-program
    v(10mm)
    title1
    v(10mm)
    text(size: 16pt, author)
    pagebreak(weak: true)
  }
  // ===== Cover =====

  // ===== Title Page =====
  {
    set align(center)
    image("/resources/tum-logo.svg", width: 30%)
    cit
    v(0mm)
    tum
    v(10mm)
    degree-program
    v(10mm)
    title1
    v(0mm)
    title2

    v(1fr)

    let entries = ()
    entries.push(("Author: ", author))
    entries.push(("Supervisor: ", supervisor))
    if advisors.len() > 0 {
      entries.push(("Advisors: ", advisors.join(", ")))
    }
    entries.push(("Start Date: ", start-date.display("[day].[month].[year]")))
    entries.push(("Submission Date: ", submission-date.display("[day].[month].[year]")))

    set text(size: 11pt)
    grid(
      columns: 2,
      gutter: 0.6em,
      align: (left, left),
      ..for (term, desc) in entries {
        (strong(term), desc)
      }
    )

    pagebreak(weak: true)
  }
  // ===== Title Page =====

  set par(justify: true)

  // ===== Disclaimer =====
  {
    v(1fr)
    text("I confirm that this " + lower(degree) + "'s thesis is my own work and I have documented all sources and material used.")
    v(3em)
    grid(
      columns: 2,
      gutter: 1fr,
      "Munich, " + submission-date.display("[day].[month].[year]"), author,
    )
    pagebreak(weak: true)
  }
  // ===== Disclaimer =====

  set page(numbering: "i")
  set page(margin: (left: 50mm, right: 50mm, top: 40mm, bottom: 60mm))

  // ===== Acknowledgement =====
  {
    show heading: set align(center)

    heading("Acknowledgements")
    acknowledgements
    pagebreak(weak: true)
  // ===== Acknowledgement =====

  // ===== Abstract =====
    heading("Abstract")
    abstract
    pagebreak(weak: true)
  }
  // ===== Abstract =====

  set page(margin: (left: 30mm, right: 30mm, top: 30mm, bottom: 60mm))

  // ===== TOC =====
  {
    show outline.entry.where(level: 1): it => {
      v(2em, weak: true)
      link(
        it.element.location(),
        strong({
          it.body
          h(1fr)
          it.page
        }),
      )
    }

    outline(
      title: {
        text(size: 1.4em, weight: "bold", "Contents")
        v(2em)
      },
      indent: auto,
    )

    pagebreak(weak: true)
  }
  // ===== TOC =====

  set heading(numbering: "1.1")
  set page(numbering: "1")
  counter(page).update(1)

  doc

  outline(
    title: "List of Figures",
    target: figure.where(kind: image),
  )

  outline(
    title: "List of Tables",
    target: figure.where(kind: table),
  )

  bibliography("/biblio.bib", style: "association-for-computing-machinery")

  // Appendix
  if appendix != none {
    pagebreak(weak: true)
    set heading(numbering: none)
    heading(numbering: none)[Appendix]
    appendix
  }
}
