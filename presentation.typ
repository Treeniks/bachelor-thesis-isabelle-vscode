#import "/utils/isabelle.typ": *

#import "@preview/cetz:0.2.2"
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
    #v(1fr) // so that align horizon actually works for some reason...
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
  #grid(
    columns: (1fr, 1fr),
    rows: (auto, 1fr),
    gutter: 15pt,
    align: horizon + center,
    uncover(2, text(size: 1.5em)[*Client*]),
    uncover(2, text(size: 1.5em)[*Server*]),
    {
      only(1, [Caching])
      only(2, rect(width: 50%, height: 100%)[Caching])
    },
    {
      only(1)[Request]
      only(2, rect(width: 50%, height: 100%)[Request])
    },
  )
]

// #slide(title: [])[
//   #align(horizon + center)[
//     #cetz.canvas({
//       import cetz.draw: *

//       line((0, 0), (20, 0), name: "line")
//       content(
//         ("line.start", 5%, "line.end"), anchor: "south", padding: .4, [Client]
//       )
//       content(
//         ("line.start", 95%, "line.end"), anchor: "south", padding: .4, [Server]
//       )
//     })
//     #v(1fr)
//   ]
// ]

#slide(title: [Decorations on File Switch])[
  #only(1)[
    ```typescript
    /* decoration for document node */

    type Content = Range[] | DecorationOptions[]
    const document_decorations = new Map<Uri, Map<string, Content>>()
    ```
  ]
  #only((2, 3))[
    #codly(highlights: (
      (line: 3, start: 38, end: 38, fill: green),
    ))
    ```typescript
    /* decoration for document node */

    type Content = Range[] | DecorationOptions[]
    const document_decorations = new Map<Uri , Map<string, Content>>()
    ```
  ]
  #only(3)[
    #codly(highlights: (
      (line: 3, start: 38, end: 38, fill: green),
    ))
    ```typescript
    /* decoration for document node */

    type Content = Range[] | DecorationOptions[]
    const document_decorations = new Map<string , Map<string, Content>>()
    ```
  ]
]

#new-section-slide("Further Improvements")

#slide(title: [Further Improvements])[
  #uncover((beginning: 1))[- #only(1)[*Fixed File Content Desyncs*]#only((beginning: 2))[Fixed File Content Desyncs]]
  #uncover((beginning: 2))[- #only(2)[*Improved Handling of State Panel IDs*]#only((beginning: 3))[Improved Handling of State Panel IDs]]
  #uncover((beginning: 3))[- #only(3)[*Completions for Abbreviations*]#only((beginning: 4))[Completions for Abbreviations]]
  #uncover((beginning: 4))[- #only(4)[*More Granular Symbol Options*]#only((beginning: 5))[More Granular Symbol Options]]
  #uncover((beginning: 5))[- #only(5)[*Code Actions for Active Markup*]#only((beginning: 6))[Code Actions for Active Markup]]
  #uncover((beginning: 6))[- *Isabelle System Options\ as VSCode Settings*]

  #only(3)[
    #place(
      horizon + center,
      dy: 50pt,
      box(stroke: 2pt, image(width: 80%, "/resources-presentation/completions.png")))
  ]

  #only(4)[
    #place(
      horizon + right,
      dy: 25pt,
      box(stroke: 2pt, image(width: 50%, "/resources-presentation/symbol-handling.png")))
  ]

  #only(5)[
    #place(
      horizon + right,
      dy: 25pt,
      box(stroke: 2pt, image(width: 50%, "/resources/vscode-action-active-sledgehammer-light-before.png"))
    )
  ]

  #only(6)[
    #place(
      horizon + right,
      dy: 25pt,
      box(stroke: 2pt, image(width: 50%, "/resources-presentation/vscode-settings.png"))
    )
  ]
]

#focus-slide(background: tum-blue)[
  *Questions?*
]
