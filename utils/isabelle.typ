#let isabelle(body) = {
  show raw: set text(font: "Isabelle DejaVu Sans Mono", size: 10pt)
  set text(font: "Isabelle DejaVu Sans Mono", size: 10pt)
  box(
    radius: 2pt,
    inset: (x: 3pt),
    outset: (y: 3pt),
    fill: luma(235),
    body,
  )
}

#let vscode = box[Isabelle/VSCode]
#let jedit = box[Isabelle/jEdit]
#let isar = box[Isabelle/Isar]
#let scala = box[Isabelle/Scala]
#let utf8isa = box[UTF-8-Isabelle]
#let utf8 = box[UTF-8]
