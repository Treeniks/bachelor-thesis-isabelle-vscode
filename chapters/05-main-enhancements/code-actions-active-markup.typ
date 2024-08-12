#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

== Code Actions for Active Markup

One feature of #jedit that was missing entirely in #vscode is Isabelle's _active markup_. Active markup, generally speaking, describes parts of the theory, state or output content that is clickable. The action taken when the user clicks on an active markup can vary, as many different kinds of active markup exist. One type of active markup the user will probably come across frequently is the so called _sendback_ markup. This type of markup appears primarily in the output panel and clicking on it inserts its text into the source theory. It appears, for example, when issuing a `sledgehammer` command.
#footnote[The `sledgehammer` command is an Isabelle command that calls different external automatic theorem provers in hopes of one of them finding a proof. Isabelle then translates the found proof back into an Isabelle proof.]
When this command finds a proof, it is displayed in the output panel with a gray background. The user can then click on the suggested proof and Isabelle inserts it into the document. This example can be seen in @active-markup-sledgehammer-jedit. As mentioned, there are other types of active markup as well, but we will focus exclusively on sendback markup.

#figure(
  table(
    columns: 2,
    stroke: none,
    table.header([*Before*], [*After*]),
    box(stroke: 1pt, image("/resources/jedit-active-sledgehammer-before.png")),
    box(stroke: 1pt, image("/resources/jedit-active-sledgehammer-after.png")),
  ),
  kind: image,
  caption: [Active markup in #jedit when using sledgehammer.\ Before and after clicking on sendback markup.],
  placement: auto,
) <active-markup-sledgehammer-jedit>

Unlike other features discussed in this work, active markup is a concept that has no comparable feature within typical code editors. Clicking on parts of code may exist in the form of _Goto Definition_ actions or clicking on hyperlinks, but inserting things from some output panel into the code is unique. Hence, there is also no existing precedent on how to handle this type of interaction within the LSP specification. Because of this, the first question that needed to be answered is how we intend to tackle this problem in terms of user experience. That is, whether the #vscode implementation should work the same way as it does in #jedit (i.e. by clicking with the mouse), or the interaction should work completely differently.

There exist two major problems when trying to replicate the user experience of #jedit:
1. For the sake of accessibility, it is usually possible to control VSCode completely with the keyboard. In order to retain this property, we decided it should also be possible to interact with active markup entirely with the keyboard.

2. It would need a completely custom solution for both the language server and language client, increasing complexity and the barrier of entry for new Isabelle IDEs. We would potentially need to reimagine the way that output panel content is sent to the client and it would be very difficult expanding the functionality to other types of active markup that live within the theory instead.

Instead, we decided to deviate from #jedit and utilize existing LSP features where possible. And luckily, the LSP spec defines a concept called _code actions_ which are suitable for active markup.

The intended use case of code actions is to support more complicated IDE features acting on specific ranges of code that may result in beautifications or refactors of said code. For example, when using the `rust-analyzer` language server #footnote[https://rust-analyzer.github.io/] which serves as a server for the Rust programming language #footnote[https://www.rust-lang.org/], it is possible to use a code action to fill out the arms of a match expression, an example of which can be seen in @rust-match-action.

#figure(
  table(
    columns: 2,
    stroke: none,
    table.header([*Before*], [*After*]),
    box(stroke: 1pt, image("/resources/sublime-action-rust-light-before.png")),
    box(stroke: 1pt, image("/resources/sublime-action-rust-light-after.png")),
  ),
  kind: image,
  caption: [`rust-analyzer`'s "Fill match arms" code action in Sublime Text.],
  placement: auto,
) <rust-match-action>

The big advantage of using code actions, is that code actions are a part of the normal LSP specification, meaning most language clients support them out of the box. If the Isabelle language server supports interacting with active markup through code actions, there is no extra work necessary for the client.

To initiate a code action, the language client sends a `textDocument/codeAction` request to the server whose content can be seen in @action-request-interface. The request's response then contains a list of possible code actions. Each code action may be either an _edit_, a _command_ or both. For our use case of supporting _sendback_ active markup, which only inserts text, the _edit_ type suffices. Although to support other types of active markup, the _command_ type may become necessary.

The `range` data sent in the code action request is the text range from which the client wants to get code actions from. Code actions are quite dependent on caret position. Different parts of the document may exhibit different code actions. Most of the time, the `range` just includes the current position of the caret, however most clients will also allow the user to do a selection or even create multiple carets and request code actions for the selected range.

#figure(
  box(width: 90%)[
    ```typescript
    interface CodeActionParams {
        textDocument: TextDocumentIdentifier;
        range: Range;
        context: CodeActionContext;
    }
    ```
  ],
  caption: [`CodeActionParams` interface definition @lsp-spec.],
  kind: raw,
) <action-request-interface>

=== Implementation for the Isabelle Language Server

When the Isabelle language server receives a code action request, the generation of the code actions list for its response is roughly done in these four steps:
1. Find all #isar commands within the given `range`.

2. Get the command results of all these commands.

3. Extract all sendback markup out of these command results.

4. Create LSP text edit JSON objects, inserting the sendback markup's content at the respective command's position.

#figure(
  table(
    columns: 2,
    stroke: none,
    table.header([*Before*], [*After*]),
    box(stroke: 1pt, image("/resources/vscode-action-active-sledgehammer-light-before.png")),
    box(stroke: 1pt, image("/resources/vscode-action-active-sledgehammer-light-after.png")),
  ),
  kind: image,
  caption: [Active markup in #vscode when using sledgehammer.\ Code action initiated with "`Ctrl+.`". Before and after accepting code action.],
  // placement: auto,
) <active-markup-sledgehammer-vscode>

Once the list of these code actions is sent to the language client, the server's work is done. The LSP text edit objects exist in a format standardized in the LSP, so the actual execution of the text edit can be done entirely by the client.

We also considered how to deal with correct indentation for the inserted text. In #jedit, when a sendback markup gets inserted, the general indentation function that exists in #jedit is called right after to correctly indent the newly inserted text. Since this internal indentation function uses direct access to the underlying jEdit buffer, we could not easily use this function from the language server. However, simply ignoring the indentation completely results in a subpar user experience. A proper solution would reimplement #jedit's indentation logic for the language server, which we will discuss in @future-work as it exceeds the scope of this thesis. For our contribution, the language server instead just copies the source command's indentation to the inserted text. This will potentially give slightly different indentations compared to #jedit, however the result is acceptable in practice.

An example of the resulting implementation for #vscode can be seen in @active-markup-sledgehammer-vscode.

// #TODO[
//   - explanation of active markup
//   - adding support for clicking is somewhat difficult and goes way beyond the LSP Spec
//   - code actions are a way for the server to send different options to client, and the client to then be able to select one
//     - can include just text edits, client commands or even server commands
//     - thus very flexible
//     - most clients already implement logic for it, so no need for manual implementation on client
//   - now works for sendbacks (insertions)
//     - example with sledgehammer/try0
//     - indentation is copied from current line
//       - indentation on jEdit is handled via global indent function
//       - uses internal jEdit buffers, thus not easily translatable to server
//   - TODO look into git history for more difficulties
// ]
