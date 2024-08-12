#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

= Conclusion

The primary objective of this thesis was to refine and enhance the functionality of #vscode, trying to mimic #jedit if possible while also adding features that make supporting Isabelle in other code editors possible. We looked at different ways of implementing the unique features required by Isabelle into a language server/client setup.

In the process, we discovered that, by migrating away from #jedit's exact functionality, certain features can be built without needing any custom handlers in the language client, like how we used LSP code actions to implement Isabelle's active markup.

We also found existing issues in the language server, like frequent desyncs of theory contents or strongly limited options regarding symbol handling, and implemented improvements to those areas in order to make the language server more robust. That way, we found that usage of the language server outside of #vscode became viable, like with our Neovim language client prototype.

In order to further assess the server's new flexibility, we built another prototype language client for the Sublime Text #footnote[https://www.sublimetext.com/] code editor. Utilizing the Sublime LSP package #footnote[https://lsp.sublimetext.io/], we found that a working Sublime Text Isabelle language package was doable in only $~200$ lines of python code, the result of which can be seen in @fig:sublime-isabelle. This package gave support for dynamic highlighting, a working output panel with highlighting, active markup via code actions, completions for symbols, and conversion of symbols from ASCII representations to Unicode. All that on top of more typical LSP features like diagnostics.

Lastly, it became apparent that great care must be taken in the handling of Isabelle symbols, as it consistently proved challenging to deal with. We extended the language server to allow for more granular control over how symbols are sent, making it more flexible. Thus, a language client now has more freedom when choosing how it wants to deal with these symbols.

All in all, Isabelle is a uniquely monolithic system. This is both its greatest strength and its greatest weakness. It gives it the power to build a large set of tools, which are all consistent with one another, and do things that seem magical. However, once you want to venture outside its system, it becomes all the more difficult to integrate, yet not impossible.

#figure(
  box(stroke: 1pt, image("/resources/sublime-isabelle-light.png", width: 80%)),
  kind: image,
  caption: [Sublime Text with prototype Isabelle language client.],
  placement: auto,
) <fig:sublime-isabelle>

// #TODO[
//   Recap shortly which problem you solved in your thesis and discuss your *contributions* here.
//
//   Sublime Text prototype
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
