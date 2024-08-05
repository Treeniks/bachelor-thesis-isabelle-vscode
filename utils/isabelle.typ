#let isabelle(body) = {
  show raw: set text(font: "Isabelle DejaVu Sans Mono", size: 10pt)
  box(
    radius: 2pt,
    inset: (x: 3pt),
    outset: (y: 3pt),
    fill: luma(235),
    raw(body)
  )
}

#let vscode(..suffix) = {
  box(emph[Isabelle/VSCode#suffix.pos().join()])
}

#let jedit(..suffix) = {
  box(emph[Isabelle/jEdit#suffix.pos().join()])
}

#let isar(..suffix) = {
  box(emph[Isabelle/Isar#suffix.pos().join()])
}
