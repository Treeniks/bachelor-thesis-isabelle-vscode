#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

= Evaluation

Our original goal included enhancing the Isabelle language server's flexibility and enabling the development of language clients for other code editors. In order to assess the server's new flexibility with our advancements, we built two prototype language clients for the Neovim and Sublime Text code editors.

== Neovim

Originally the motivation behind this thesis, our Neovim language plugin has seen significant usability improvements. We found the greatest boon in user experience to be the highlighting in output and state panels. Especially state content has become significantly easier to read thanks to proper highlighting.

While #vscode and our Neovim Isabelle plugin still differ in the details, they are now comparable in functionality. Other users have also already used the plugin with success, and it can be found publicly on GitHub. #footnote[https://github.com/Treeniks/isabelle-lsp.nvim]

== Sublime Text

// #figure(
//   box(stroke: 1pt, image("/resources/sublime-isabelle-light.png", width: 80%)),
//   kind: image,
//   caption: [Sublime Text with prototype Isabelle language client.],
//   // placement: auto,
// ) <fig:sublime-isabelle>

Utilizing the Sublime LSP package #footnote[https://lsp.sublimetext.io/], we found that a working Sublime Text Isabelle language package was doable in only $~200$ lines of Python code/* , the result of which can be seen in @fig:sublime-isabelle */. This package supports dynamic highlighting, a working output panel with highlighting, active markup via code actions, completions for symbols, and conversion of symbols from ASCII representations to Unicode---all that on top of more typical LSP features like diagnostics. Although still rough around the edges, we found this package already usable for basic theories.

= Conclusion

The primary objective of this thesis was to refine and enhance the functionality of #vscode, trying to mimic #jedit while also adding features that make supporting Isabelle in other code editors possible. We discussed different ways of implementing the unique features required by Isabelle into a language server/client setup.

In the process, we discovered that, by migrating away from #jedit's exact functionality, certain features can be built without needing any custom handlers in the language client, like how we used LSP code actions to implement Isabelle's active markup.

We also found existing issues in the language server, like frequent desyncs of theory contents or limited options regarding symbol handling, and implemented improvements to those areas to make the language server more robust. That way, we found that usage of the language server outside of #vscode became viable, like with our Neovim and Sublime Text language client prototypes.

Lastly, it became apparent that great care must be taken in the handling of Isabelle symbols, as it consistently proved challenging to deal with. We extended the language server to allow for more granular control over how symbols are sent, making it more flexible. Thus, a language client now has more freedom when choosing how to deal with these symbols.

All in all, Isabelle is a uniquely monolithic system. This is both its greatest strength and its greatest weakness. It gives it the power to build a large set of tools, which are all consistent with one another, and do things that seem magical. However, once you want to venture outside its system, it becomes all the more difficult to integrate. Nevertheless, our work shows that it is not impossible.

// in Adrian's words: "kinda useless"

// #TODO[
//   Recap shortly which problem you solved in your thesis and discuss your *contributions* here.
//
//   Sublime Text prototype
// ]

= Future Work <future-work>

#vscode is still far from perfect, and there are many things that future projects may improve upon. To name just a few:

/ More Clients: Now that the language server offers enough flexibility for other clients, it would be interesting to build Isabelle support for many more editors.

  / Sublime Text: We already mentioned a working prototype for Sublime Text. However, this prototype needs a lot more work before it can be reliably used. It does not retain decorations when switching files; in fact, it often completely breaks when switching files. There is also no way to open state panels.

  / Zed #footnote[https://zed.dev/]: Developed by the creators of Atom #footnote[https://atom-editor.cc/] and Tree-sitter #footnote[https://tree-sitter.github.io/tree-sitter/], Zed is a relatively new code and text editor. At the time of writing, the capabilities of extensions are still fairly limited, although language extensions, in particular, are now possible~@zed-lsp. It could be interesting to investigate a possible Isabelle language extension for Zed.

  / Pulsar #footnote[https://pulsar-edit.dev/]: While the once-popular code editor Atom has been abandoned, a community-led fork called Pulsar has emerged. While the user base is pretty small, it is a very extensible code editor for which an Isabelle client is certainly conceivable.

  / Helix #footnote[https://helix-editor.com/]: A modern terminal-based text editor with support for the LSP out of the box. Its plugin system is still in the works #footnote[https://github.com/helix-editor/helix/pull/8675], so an Isabelle client is currently not realistically doable. However, once it is, it may be a nice candidate.

/ Minor Advancements: Many further small improvements could be made to the language server. These are things that are relatively easy and obvious to build but just require some additional work.

  / Multiple State Panels for VSCode: We already mentioned in @state-init that #vscode does not currently support using multiple state panels. This would require some work in the Isabelle VSCode extension. However, since most users tend to use only one auto-updated state panel, this feature is not of particularly high priority.

  / Update VSCode Version: As previously noted, #vscode is based on a rather old version of VSCode: `1.70.1` released on 11 August 2022. Because Isabelle adds its own patches, upgrading #vscode to a newer version is not entirely trivial. Users may run into compatibility issues with newer extensions in the meantime.

/ Custom Symbols: The `PIDE/symbols_request` notification currently does not relay custom symbols defined by the user. Instead, it only sends the default set of symbols defined in the Isabelle distribution. This makes it virtually impossible for a language client to support such custom symbols and should be changed. Ideally, #vscode would also support user symbols. However, that is much more difficult to achieve due to the use of the #utf8isa encoding. In this context, it may be worth exploring other ideas for symbol handling in #vscode that do not rely on a custom encoding.

/ More Active Markup: Currently, the only active markup supported with code actions is sendback active markup. However, there are also other kinds of active markup: `browser`, `theory_exports`, and `simp_trace_panel`, to name a few. The latter, for example, is supposed to open a window that shows Isabelle's simplifier trace. Some of these other active markup types may also be possible to support with the language server, but further work is needed.

/ Indentation Support: As mentioned in @correct-formatting, #jedit has an internal function to automatically indent a theory document. This function uses jEdit buffers and other internal data and is not usable outside of #jedit. However, the actual indentation logic could be extracted, and the feature could be added to the language server. The LSP specifies a `textDocument/formatting` client request for formatting source files, which could be used here. Once such an indentation function is available within the language server, correct indentation for sendback active markup would also be possible.

/ Updating Options Through Language Server: One potentially useful API to offer a client is the permanent changing of Isabelle system options. That way, the client could send notifications to the server, which then writes the appropriate entries into the user's `preferences` file. It could also offer a request to get the value of certain options. That way, synchronization of #vscode settings and Isabelle preferences would become feasible.

// #TODO[
//   - more clients (Zed, the Atom fork, better Sublime Text)
//   - update State ID handling in VSCode
//   - update VSCode version
//   - dynamic Symbol additions should be handleable
//     - refer to previous section that SymbolsRequest only gives compile-time symbols, not all actually current symbols
//     - in VSCode difficult, but in neovim possible to add these dynamically as new symbols
//   - code actions for other types of active markup
//   - indentation as LSP format provider
//     - in general, extract indentation logic from jEdit
//     - then also ability to use that logic for Code Actions
//
//   idea: ability to update isabelle options through language server, making synchronization of VSCode settings and preferences potentially doable
// ]
