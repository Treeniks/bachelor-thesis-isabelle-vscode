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
  box([Isabelle/VSCode#suffix.pos().join()])
}

#let jedit(..suffix) = {
  box([Isabelle/jEdit#suffix.pos().join()])
}

#let isar(..suffix) = {
  box([Isabelle/Isar#suffix.pos().join()])
}

#let utf8isa(..suffix) = {
  box([UTF-8-Isabelle#suffix.pos().join()])
}
