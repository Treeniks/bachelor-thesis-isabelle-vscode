#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

= Related Work

#vscode() was originally created in 2017 by #cite(<markarius-isabelle-vscode-2017>, form: "prose"). Lacking features like highlighting in _Output_ and _State_ panels, #cite(<denis-paluca>, form: "prose") continued the work on #vscode() in 2021. Since then, further improvements were made to #vscode(), including the introduction of a custom _UTF-8-Isabelle_ encoding for VSCode to improve performance.

As mentioned in @motivation, Mathias Fleury introduced the unofficial Isabelle fork `isabelle-emacs` #footnote[https://github.com/m-fleury/isabelle-emacs] to support the Emacs text editor, already introducing some of the features we will discuss in this thesis. While Fleury's work focuses primarily on building enough support in the language server for Emacs, this thesis's goal is to get the language server flexible enough to be usable for virtually any code editor that supports the LSP, as well as improving more fundamental usability issues. If the changes introduced in this thesis get merged upstream into the official Isabelle distribution, the changes to the language server introduced by `isabelle-emacs` should become redundant (although the work done for the Emacs language client will not).

There is also language server implementations for other theorem provers, like VsCoq #footnote[https://github.com/coq-community/vscoq] for the Coq proof assistant #footnote[https://coq.inria.fr/], as well as `vscode-lean` #footnote[https://github.com/leanprover/vscode-lean4] for the Lean theorem prover #footnote[https://lean-lang.org/] @lean4-system.

#cite(<lsp-spec-extension>, form: "prose") explored extensions to the LSP specification to support more types of semantic languages, including theorem provers. With these extensions implemented in both the specification and language clients, it may be possible to update the Isabelle language server to use these new LSP extensions and support other language clients with almost no additional work (i.e. no custom handlers for custom LSP messages).
