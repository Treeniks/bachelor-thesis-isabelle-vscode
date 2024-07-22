#import "/utils/todo.typ": TODO

= Changes to the Language Server (Isabelle)

== Desync on file changes

#TODO[explanation of the `textDocument/didChange` notification and desync problem]

The cause of this issue was related to how the changes coming in from the language client were interpreted withing the language server. The specific issue was that the language server first sorted the changes:
```scala
@tailrec def norm(chs: List[LSP.TextDocumentChange]): Unit = {
  if (chs.nonEmpty) {
    val (full_texts, rest1) = chs.span(_.range.isEmpty)
    val (edits, rest2) = rest1.span(_.range.nonEmpty)
    norm_changes ++= full_texts
    norm_changes ++= edits.sortBy(_.range.get.start)(Line.Position.Ordering).reverse
    norm(rest2)
  }
}
```

This normalization was not intended according to the LSP specficiation:
#quote[
  The actual content changes. The content changes describe single state changes to the document. So if there are two content changes c1 (at array index 0) and c2 (at array index 1) for a document in state S then c1 moves the document from S to S' and c2 from S' to S''. So c1 is computed on the state S and c2 is computed on the state S'.

  To mirror the content of a document using change events use the following approach:
  - start with the same initial content
  - apply the `textDocument/didChange` notifications in the order you receive them.
  - apply the `TextDocumentContentChangeEvent`s in a single notification in the order you receive them.
]

Thus, all that needed to be done to fix the common desyncs was to remove said normalization and instead apply the changes in the order they are received.

== State Init rework <state-init>

#TODO[
  - originally State Init would expect the client to know what ID it is
  - VSCode implmentation never used the ID for anything itself
  - now is a request instead of a notification which returns the newly created ID
]

== Decoration Notification Send All Decorations

#TODO[
  - currently only send some decorations, now send all
]

== Disable HTML Output

#TODO[
  - currently server sends output always in HTML format
  - VSCode can display HTML, but not all clients can
  - now can disable HTML output and send pure text instead with option
  - added decorations to the message if HTML is disabled (biggest usability win in neovim)
]

== Symbols Request

#TODO[
  - currently client was expected to just know what symbols are available, but this is dynamic
  - now client can request a list of all symbols from server
    - gives the same list used by VSCode during compilation, meaning dynamic symbol additions still don't work (Future Work)
]

== Symbol Conversions

#TODO[
  - flush_edits used to automatically convert symbols based on `vscode_unicode_symbols`
  - but now the code for it was just unused, so it was removed
  - now symbol conversion is a request
    - client can easily convert whole document to unicode with that
]

== Code Actions

#TODO[
  - explanation of active markup
  - adding support for clicking is somewhat difficult and goes way beyond the LSP Spec
  - code actions are a way for the server to send different options to client, and the client to then be able to select one
    - can include just text edits, client commands or even server commands
    - thus very flexible
    - most clients already implement logic for it, so no need for manual implementation on client
  - now works for sendbacks (insertions)
    - example with sledgehammer/try0
    - indentation is copied from current line
      - indentation on JEdit is handled via global indent function
      - uses internal JEdit buffers, thus not easily translatable to server
  - TODO look into git history for more difficulties
]

== Completions

#TODO[
  - completions were reworked
]
