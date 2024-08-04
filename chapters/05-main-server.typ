#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

= Changes to the Language Server

== Desync on File Changes <didchange>

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

== Disable HTML Output <html-panel-output>

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

== Code Actions for Active Markup

One feature of #jedit() that was missing entirely in #vscode() is Isabelle's _Active Markup_. Active Markup, generally speaking, describes parts of the theory, state or output content that is clickable. The action taken when the user clicks on an active markup can vary, as there is many different kinds of active markup, but the type of active markup most users will probably come across most frequently is the so called _sendback_ markup. This type of markup appears primarily in the output panel and clicking on it inserts its text into the source theory. It appears, for example, when issuing a `sledgehammer` command which finds a proof. This example can be seen in @active-markup-sledgehammer-jedit. As mentioned, there are other types of Active Markup as well, but we will focus exclusively on these sendback markups.

#figure(
  table(
    columns: 2,
    stroke: none,
    box(stroke: 1pt, image("/resources/jedit-active-markup-sledgehammer-before.png")),
    box(stroke: 1pt, image("/resources/jedit-active-markup-sledgehammer-after.png")),
  ),
  kind: image,
  caption: [Active Markup in #jedit() when using sledgehammer.\ Before and after clicking on the area with gray background.],
) <active-markup-sledgehammer-jedit>

// // #place(
// //   auto,
// //   float: true,
// #{
//   set par(justify: false)
//   table(
//     columns: 2,
//     align: left,
//     stroke: none,
//     [#figure(
//       box(stroke: 1pt, image("/resources/jedit-active-markup-sledgehammer-before.png")),
//       caption: [Active Markup in jEdit when using sledgehammer, seen with gray background\ in output panel.],
//       kind: image,
//     ) <active-markup-sledgehammer-jedit-before>],
//     [#figure(
//       box(stroke: 1pt, image("/resources/jedit-active-markup-sledgehammer-after.png")),
//       caption: [State after clicking on active markup\ with proof inserted into theory.],
//       kind: image,
//     ) <active-markup-sledgehammer-jedit-after>],
//   )
// }
// // )

Unlike other features discussed in this work, Active Markups are a concept that has no comparable feature within typical code editors. Clicking on parts of code may exist in the form of _Goto Definition_ actions or clicking on hyperlinks, but inserting things from some output panel into the code unique. Hence, there is also no existing precedent on how to handle this type of interaction within the LSP specification. Because of this, the first question that needed to be answered is how we want to tackle this problem on a user experience level. That is, do we intend for #vscode(suffix: ['s]) implementation to work the same way as it does in #jedit() (i.e. by clicking with the mouse), or should the interaction work completely differently.

There exist two major problems when trying to replicate the user experience of #jedit():
1. For the sake of accessibility, it is usually possible to control VSCode completely with the Keyboard. To keep this up, we decided it should also be possible to interact with Active Markup entirely with the keyboard.
2. It would need a completely custom solution for both the language server and language client, increasing complexity and reducing the barrier of entry for new potential Isabelle IDEs. We would potentially need to reimagine the way that output panel content is sent to the client, and if so, it would be very difficult expanding the functionality to other types of Active Markup that live within the theory.

Instead, we decided to explore completely new interaction methods, utilizing existing LSP features where possible. And luckily, the LSP spec defines a concept called _"Code Actions"_ which we could utilize for Active Markup.

The intended use case of Code Actions is to support more complicated IDE features acting on specific ranges of code that may result in beautifications or refactors of said code. For example, when using the `rust-analyzer` language server #footnote[https://rust-analyzer.github.io/] which serves as a server for the Rust programming language #footnote[https://www.rust-lang.org/], it is possible to use a Code Action to fill out match arms of a match expression, an example of which can be seen in @rust-match-action.

#figure(
  table(
    columns: 2,
    stroke: none,
    box(stroke: 1pt, image("/resources/sublime-rust-match-fill-before.png")),
    box(stroke: 1pt, image("/resources/sublime-rust-match-fill-after.png")),
  ),
  kind: image,
  caption: [`rust-analyzer`'s "Fill match arms" code action in Sublime Text.],
) <rust-match-action>

The big advantage to using Code Actions, is that Code Actions are a part of the normal LSP specification, meaning most language client support them out of the box. If the Isabelle language server support interaction with Active Markup through Code Actions, there is no extra work necessary for the client.

To initiate a Code Action, the language client sends a `textDocument/codeAction` request to the server. The request's response then contains a list of possible Code Actions. Each Code Action may be either an _edit_, a _command_ or both. For our use case of supporting _sendback_ Active Markup, which only inserts text, the _edit_ type suffices, although to support other types of Active Markup, the _command_ type may become necessary. When the client sends this `textDocument/codeAction` request, it also sends the relevant text area whose Code Actions it wants to see.

=== Implementation for the Isabelle Language Server

#figure(
  table(
    columns: 2,
    stroke: none,
    box(stroke: 1pt, image("/resources/vscode-active-markup-sledgehammer-before.png")),
    box(stroke: 1pt, image("/resources/vscode-active-markup-sledgehammer-after.png")),
  ),
  kind: image,
  caption: [Active Markup in #vscode() when using sledgehammer.\ Code Action initiated with "`Ctrl+.`". Before and after accepting Code Action.],
  placement: auto,
) <active-markup-sledgehammer-vscode>

When the Isabelle language server receives a Code Action request, the generation of the Code Actions list for its response is roughly done in these four steps:
1. Find all #isar() commands within the given range.
2. Get the command results of all these commands.
3. Extract all sendback markup out of these command results.
4. Create LSP text edit json objects, inserting the sendback markup's content at the respective command's position.

Once the list of these Code Actions is sent to the language client, the server's work is done. The LSP text edit objects exist in a format standardized in the LSP, so the actual execution of the text edit can be done entirely in the client.

We also considered how to deal with correct indentation for the inserted text. In #jedit(), when a sendback markup gets inserted, the general indentation function that exists in #jedit() is called right after to correctly indent the newly inserted text. Since this internal indentation function uses direct access to the underlying jEdit buffer, we could not easily use this function from the language server. However, simply ignoring the indentation completely results in a subpar user experience. A proper solution would reimplement #jedit(suffix: ['s]) indentation logic for the language server, however this would require additional work. For our contribution, the language server instead just copies the source command's indentation to the inserted text. This will potentially give slightly different indentations compared to #jedit(), however the result is acceptable in practice.

An example of the resulting implementation for #vscode() can be seen in @active-markup-sledgehammer-vscode.

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
      - indentation on jEdit is handled via global indent function
      - uses internal jEdit buffers, thus not easily translatable to server
  - TODO look into git history for more difficulties
]

== Completions

#TODO[
  - completions were reworked
]
