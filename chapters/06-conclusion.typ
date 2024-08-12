#import "/utils/todo.typ": TODO

= Conclusion
#TODO[
  Recap shortly which problem you solved in your thesis and discuss your *contributions* here.

  Sublime Text prototype
]

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
