#import "/layout/fonts.typ": *

#let titlepage(
  title: "",
  titleGerman: "",
  degree: "",
  program: "",
  supervisor: "",
  advisors: (),
  author: "",
  startDate: datetime,
  submissionDate: datetime,
) = {
  // Quality checks
  assert(degree in ("Bachelor", "Master"), message: "The degree must be either 'Bachelor' or 'Master'")

  set page(
    margin: (left: 30mm, right: 30mm, top: 40mm, bottom: 40mm),
    numbering: none,
    number-align: center,
  )

  set text(
    font: body-font,
    size: 12pt,
    lang: "en"
  )


  // --- Title Page ---
  align(center, image("/figures/logo.png", width: 26%))

  v(5mm)

  align(center, smallcaps(text(font: title-font, 22pt, weight: "bold", [Technical University of Munich])))

  v(5mm)

  align(center, smallcaps(text(font: title-font, 18pt, weight: "regular", [School of Computation,\ Information and Technology\ -- Informatics --])))

  v(15mm)

  align(center, text(font: title-font, 16pt, weight: "thin", degree + "’s Thesis in " + program))

  v(10mm)

  align(center, text(font: title-font, 20pt, weight: "bold", title))
  align(center, text(font: title-font, 20pt, weight: "regular", titleGerman))

  v(10mm)

  let entries = ()
  entries.push(("Author: ", author))
  entries.push(("Supervisor: ", supervisor))
  // Only show advisors if there are any
  if advisors.len() > 0 {
    entries.push(("Advisors: ", advisors.join(", ")))
  }
  entries.push(("Start Date: ", startDate.display("[day].[month].[year]")))
  entries.push(("Submission Date: ", submissionDate.display("[day].[month].[year]")))

  align(
    center,
    grid(
      columns: 2,
      gutter: 0.6em,
      align: (left, left),
      ..for (term, desc) in entries {
        (strong(term), desc)
      }
    )
  )

  pagebreak()
}
