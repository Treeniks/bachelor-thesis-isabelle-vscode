#import "/utils/isabelle.typ": *

#import "/template.typ": thesis

#import "@preview/codly:1.0.0": *
#import "@preview/gentle-clues:0.9.0": *

#set text(font: "STIX Two Text", size: 11pt)
#show math.equation: set text(font: "STIX Two Math")
#show raw: set text(font: "JetBrains Mono", size: 1.1em)

#let acknowledgements = [
  There are several people I would like to thank:

  *Prof. Dr. Tobias Nipkow* for giving me the opportunity to work on a tool as big and prominent as Isabelle.

  *My advisor Fabian Huch* for meeting with me weekly, helping me understand the inner workings of Isabelle, discussing design and implementation details and lending me his time for other silly questions.

  *My father Andreas Lindae* for doing his best rubber duck impression and letting me waste his time by explaining the contents of this thesis to him to sort out my thoughts.

  *My friends Adrian Stein and Alexander Treml* for their valuable feedback on various sections of this thesis and helping me with its overall structure.

  *Many more of my fellow student friends* for joining me in my visits to the cafeteria and providing mental and emotional respite during lunch.
]

#let abstract = [The primary interface for interacting with the Isabelle proof assistant is the #jedit prover IDE. #vscode was developed as an alternative, implementing a language server for the Language Server Protocol (LSP) and a language client for Visual Studio Code. However, #vscode did not provide a user experience comparable to #jedit. This thesis explores and implements several improvements to address these shortcomings by refining existing functionality and augmenting #vscode with new features. Key enhancements include improved completions, persistent decorations on file switch, code actions for interacting with active markup, and better formatting for state and output panels. Additionally, we implemented more granular control over symbol handling and an Isabelle system option to turn off HTML output, increasing compatibility with potential new language clients. We developed prototype language clients for the Neovim and Sublime Text code editors to evaluate the improved language server's versatility. While an Isabelle language client for these editors was previously infeasible, our enhancements made them viable. Our work not only brings #vscode closer to feature parity with #jedit, but also paves the way for future integrations with a broader range of development environments.]

#let appendix = none

#show: thesis.with(
  title-primary: [Improving Isabelle/VSCode:\ Towards Better Prover IDE Integration\ via Language Server],
  title-secondary: [Verbesserung von Isabelle/VSCode:\ In Richtung besserer Prover IDE Integration\ mithilfe eines Language Servers],
  degree: "Bachelor",
  program: "Informatics: Games Engineering",
  supervisor: "Prof. Dr. Stephan Krusche",
  advisors: ("Prof. Dr. Tobias Nipkow", "M.Sc. Fabian Huch"),
  author: "Thomas Lindae",
  start-date: datetime(day: 15, month: 04, year: 2024),
  submission-date: datetime(day: 15, month: 08, year: 2024),
  acknowledgements: acknowledgements,
  abstract: abstract,
  appendix: appendix,
)

#show: codly-init.with()
#codly(
  zebra-fill: luma(245),
  stroke: 2pt + luma(230),
  lang-stroke: none,
)

#show "VSCode": it => box(it)
#show "VSCodium": it => box(it)

// Sei $x in (a, b)$ und $h in RR without {0}$ mit $x + h in [a, b]$. Es gilt:
// $ (F(x + h) - F(x))/h &= 1/h (integral^(x + h)_a f(t) d t - integral^x_a f(t) d t) = 1/h integral^(x + h)_x f(t) d t\
//                       &= 1/h f(xi_h) dot h = f(xi_h), quad xi_h in [x, x + h] $

#include "/chapters/01-introduction.typ"
#include "/chapters/02-background.typ"
#include "/chapters/03-related-work.typ"
#include "/chapters/04-main-refinements.typ"
#include "/chapters/05-main-enhancements.typ"
#include "/chapters/06-conclusion.typ"
