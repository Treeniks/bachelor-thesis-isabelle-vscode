#import "/utils/isabelle.typ": *

#import "@preview/polylux:0.3.1": *
#import themes.clean: *
#import "@preview/fletcher:0.5.1" as fletcher: diagram, node, edge
#import "@preview/codly:1.0.0": *

#set page(paper: "presentation-16-9")

#let tum-blue = rgb(0, 101, 189)
#let date = datetime(year: 2024, month: 08, day: 26)

#show: clean-theme.with(
  footer: [Thomas Lindae],
  short-title: [Improving Isabelle/VSCode],
  logo: image("/resources/tum-logo.svg"),
  color: tum-blue,
)

#set text(font: "STIX Two Text", size: 22pt)
#show math.equation: set text(font: "STIX Two Math")
#show raw: set text(font: "JetBrains Mono", size: 1em)

#show: codly-init.with()
#codly(
  zebra-fill: luma(245),
  stroke: 2pt + luma(230),
  lang-stroke: none,
)

#title-slide(
  title: [Improving Isabelle/VSCode],
  subtitle: [Towards Better Prover IDE Integration\ via Language Server],
  authors: "Thomas Lindae",
  date: date.display(),
)

#slide(title: [Language Server Protocol])[
  #align(horizon + center)[
    #diagram(
      edge-stroke: 2pt,

      node((0, 0), [Code Editor], height: 10em, width: 4em, stroke: 2pt),
      node((1, 0), [Client], height: 10em, width: 4em, stroke: 2pt),
      node((5, 0), [Server], height: 10em, width: 4em, stroke: 2pt),

      edge((0, 0), (1, 0)),
      edge((1, 0), (5, 0), "<{-}>", [jsonrpc]),
    )
  ]
]

#new-section-slide("State and Output Panels")

#slide(title: [Comparison State Panels])[
  #table(
    columns: (1fr, 1fr),
    stroke: none,
    align: center,
    table.header([#jedit], [#only(1, vscode)#only(2)[#vscode (new)]]),
    box(stroke: 2pt + luma(150), image("/resources-presentation/jedit-state-panel.png")),
    [
      #only(1, box(stroke: 2pt + luma(150), image("/resources-presentation/vscode-state-panel.png")))
      #only(2, box(stroke: 2pt + luma(150), image("/resources-presentation/vscode-state-panel2.png")))
    ]
  )
]

#slide(title: [Disabling HTML])[
  #only(2, align(horizon + center, box(stroke: 2pt + luma(150), image(height: 85%, "/resources-presentation/neovim-html.png"))))
  #only(3, align(horizon + center, box(stroke: 2pt + luma(150), image(height: 85%, "/resources/neovim-no-decs-light.png"))))
  #only(4, align(horizon + center, box(stroke: 2pt + luma(150), image(height: 85%, "/resources/neovim-with-decs-light.png"))))
]

#new-section-slide("Decorations on File Switch")

#slide(title: [])[
  #v(1fr)
  #align(center)[
    #columns(2)[
      #set text(size: 32pt)
      *Caching*
      #colbreak()
      *Request*
    ]
  ]
  #v(1fr)
]

#slide(title: [Decorations on File Switch])[
  ```typescript
  /* decoration for document node */

  type Content = Range[] | DecorationOptions[]
  const document_decorations = new Map<Uri, Map<string, Content>>()
  ```
  #pause
  ```typescript
  /* decoration for document node */

  type Content = Range[] | DecorationOptions[]
  const document_decorations = new Map<string, Map<string, Content>>()
  ```
]

#new-section-slide("Further Improvements")

#slide(title: [Further Improvements])[
  - Desync on File Changes
  #pause
  - State Panel IDs
  #pause
  - Completions
  #pause
  - Symbol Handling
  #pause
  - Code Actions for Active Markup
  #pause
  - Isabelle System Options as VSCode Settings
]

#focus-slide(background: tum-blue)[
  _Focus!_

  This is very important.
]
