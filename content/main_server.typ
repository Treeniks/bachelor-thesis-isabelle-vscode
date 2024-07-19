#import "/utils/todo.typ": TODO

= Changes to the Language Server

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
