#import "/utils/todo.typ": TODO

= Summary
// #TODO[
//   This chapter includes the status of your thesis, a conclusion and an outlook about future work.
// ]

// == Status
// #TODO[
//   Describe honestly the achieved goals (e.g. the well implemented and tested use cases) and the open goals here. if you only have achieved goals, you did something wrong in your analysis.
// ]

// === Realized Goals
// #TODO[
//   Summarize the achieved goals by repeating the realized requirements or use cases stating how you realized them.
// ]

// === Open Goals
// #TODO[
//   Summarize the open goals by repeating the open requirements or use cases and explaining why you were not able to achieve them. Important: It might be suspicious, if you do not have open goals. This usually indicates that you did not thoroughly analyze your problems.
// ]

== Conclusion
#TODO[
  Sublime Text prototype
]
// #TODO[
//   Recap shortly which problem you solved in your thesis and discuss your *contributions* here.
// ]

== Future Work <future-work>
#TODO[
  - more clients (Zed, the Atom fork, better Sublime Text)
  - update State ID handling in VSCode
  - update VSCode version
  - dynamic Symbol additions should be handleable
    - refer to previous section that SymbolsRequest only gives compile-time symbols, not all actually current symbols
    - in VSCode difficult, but in neovim possible to add these dynamically as new symbols
  - code actions for other types of active markup
  - indentation as LSP format provider
    - in general, extract indentation logic from jEdit
    - then also ability to use that logic for Code Actions

  idea: ability to update isabelle options through language server, making synchronization of VSCode settings and preferences potentially doable
]
