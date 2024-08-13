#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

== Desync on File Changes <didchange>

While building the Neovim Isabelle client mentioned in @intro:motivation, the language server frequently got out of sync with the actual contents of the file. For example, it might have happened that the user wanted to write `apply auto`, but wrote `apply autt` by accident instead. If the user then corrected their mistake by removing the additional `t` and replacing it with an `o`, it could happen that the language server would think the content of the file was `apply autto`. Somewhat awkwardly, this problem _only_ occurred when using Neovim, it did not happen in VSCode.

Document synchronization is done primarily through `textDocument/didChange` and `textDocument/didOpen` notifications. We will discuss the `textDocument/didOpen` notification in more detail in @symbol-handling, but this desyncing issue results from the handling of the `textDocument/didChange` notifications. Its content is outlined in @did-change-interface.

#figure(
  box(width: 90%)[
    ```typescript
    interface DidChangeTextDocumentParams {
        textDocument: VersionedTextDocumentIdentifier;
        contentChanges: TextDocumentContentChangeEvent[];
    }
    ```
  ],
  caption: [`DidChangeTextDocumentParams` interface definition @lsp-spec.],
  kind: raw,
  // placement: auto,
) <did-change-interface>

The exact details of how these `contentChanges` are structured are not of interest, however what is of interest is that there can be multiple such content changes within a single notification. It is possible for the client to decide to group multiple content changes into a single `textDocument/didChange` notification. The desyncing problem now arises from the fact that such a list of content changes is not commutative. The LSP spec says the following about the order of application of these content changes:

#quote(block: true, attribution: <lsp-spec>)[
  The content changes describe single state changes to the document. So if there are two content changes $c_1$ (at array index $0$) and $c_2$ (at array index $1$) for a document in state $S$ then $c_1$ moves the document from $S$ to $S'$ and $c_2$ from $S'$ to $S''$. So $c_1$ is computed on the state $S$ and $c_2$ is computed on the state $S'$.

  To mirror the content of a document using change events use the following approach:
  - start with the same initial content
  - apply the `textDocument/didChange` notifications in the order you receive them.
  - apply the `TextDocumentContentChangeEvent`s in a single notification in the order you receive them.
]

The language server had code that _normalized_ the `contentChanges` list, sorting them by different types of changes, before applying them. Simply removing this normalization was enough to fix the original desyncing issue. We are still unsure why the issue did not occur in VSCode, however most likely VSCode simply groups together document changes far less frequently than Neovim does.
