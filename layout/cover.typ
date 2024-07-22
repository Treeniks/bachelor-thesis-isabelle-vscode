#import "/layout/fonts.typ": *

#let cover(
  title: "",
  degree: "",
  program: "",
  author: "",
) = {
  set page(
    margin: (left: 30mm, right: 30mm, top: 40mm, bottom: 40mm),
    numbering: none,
    number-align: center,
  )

  set text(
    font: body-font,
    size: 12pt,
    lang: "en",
  )


  // --- Cover ---
  align(center, image("/figures/logo.png", width: 26%))

  v(5mm)

  align(center, upper(text(font: title-font, 22pt, weight: "bold", [Technical University of Munich])))

  v(5mm)

  align(center, upper(text(font: title-font, 18pt, weight: "regular", [School of Computation,\ Information and Technology\ -- Informatics --])))

  v(15mm)

  align(center, text(font: title-font, 16pt, weight: "thin", degree + "’s Thesis in " + program))

  v(15mm)

  align(center, text(font: title-font, 20pt, weight: "bold", title))

  v(10mm)

  align(center, text(font: title-font, 18pt, weight: "regular", author))

  pagebreak()
}
