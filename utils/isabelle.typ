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

#let vscode = {
  box(emph[Isabelle/VSCode])
}

#let jedit = {
  box(emph[Isabelle/jEdit])
}
