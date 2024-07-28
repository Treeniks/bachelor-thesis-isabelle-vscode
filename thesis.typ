#import "/template.typ": thesis

#set text(font: "STIX Two Text")
#show math.equation: set text(font: "STIX Two Math")
#show raw: set text(font: "JetBrains Mono")

#let acknowledgements = [#lorem(150)]
#let abstract = [#lorem(150)]

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

// Sei $x in (a, b)$ und $h in RR without {0}$ mit $x + h in [a, b]$. Es gilt:
// $ (F(x + h) - F(x))/h &= 1/h (integral^(x + h)_a f(t) d t - integral^x_a f(t) d t) = 1/h integral^(x + h)_x f(t) d t\
//                       &= 1/h f(xi_h) dot h = f(xi_h), quad xi_h in [x, x + h] $

#include "/chapters/01-introduction.typ"
#include "/chapters/02-background.typ"
#include "/chapters/03-related-work.typ"
#include "/chapters/04-main-both.typ"
#include "/chapters/05-main-server.typ"
#include "/chapters/06-main-client.typ"
// #include "/chapters/07-evaluation.typ"
#include "/chapters/08-summary.typ"
