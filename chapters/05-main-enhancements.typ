#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

#import "@preview/fletcher:0.5.1" as fletcher: diagram, node, edge

= Enhancements and New Features

== Decorations on File Switch <enhance:decorations>

Previously, when switching theories within #vscode[], the dynamic syntax highlighting would not persist. It was possible to get the highlighting to work again by changing the buffer's content; however, until this was done, it never recovered by itself. This was a problem when working on multiple theory files.

To understand how #vscode[] does dynamic syntax highlighting, we will first take a look at the structure of the `PIDE/decoration` notifications. Recall that the primary data of notifications is sent within a `params` field. In this case, this field contains two components: A `uri` field with the relevant theory file's URI, and a list of decorations called `entries`. Each of these entries then consists of a `type` and a list of ranges called `content`. The `type` is a string identifier for an Isabelle decoration type. This includes things like `text_skolem` for Skolem variables and `dotted_warning` for things that should have a dotted underline. Each entry in the `content` list is another list of 4 integers describing the line start, line end, column start, and column end of the range the specified decoration type should be applied to. @pide-decoration-json shows an example of what a `PIDE/decoration` message may look like.

Since this is not part of the standard LSP specification, a language client must implement a special handler for such decoration notifications. Additionally, it was not possible to explicitly request these decorations from the language server. Instead, the language server would send new decorations whenever it deemed necessary, e.g., because the caret moved into areas of the text that haven't been decorated yet or because the document's content has changed.

#figure(
  box(width: 90%)[
    ```json
    "jsonrpc": "2.0",
    "method": "PIDE/decoration",
    "params": {
        "uri": "file:///home/user/Documents/Example.thy",
        "entries": [
            {
                "type": "text_main",
                "content": [
                    { "range": [1, 23, 1, 41] },
                    { "range": [5, 10, 5, 11] }
                ]
            },
            {
                "type": "text_operator",
                "content": [
                    { "range": [7, 6, 7, 7] }
                ]
            }
        ]
    }
    ```
  ],
  caption: [Example `PIDE/decoration` notification sent by the language server.],
  kind: raw,
  placement: auto,
) <pide-decoration-json>

On the VSCode side, these decorations were applied via the `TextEditor.setDecoration` API function #footnote[https://code.visualstudio.com/api/references/vscode-api#TextEditor.setDecorations], which does not inherently cache these decorations on file switch. Thus, when switching theories, VSCode did not cache the previously set decorations, nor did the language server send them again, causing the highlighting to disappear.

There were two primary ways to fix this issue:
1. Implement caching of decorations manually in the VSCode extension.

2. Add the ability to request new decorations from the server and do so on file switch.

The main advantage of option 1 is performance. If the client handles caching of decorations, then the server won't have to calculate the decorations anew (which is a rather expensive operation), nor will another round of JSON Serialization and Deserialization have to happen. However, the trade-off is that more work needs to be done on the client side, making new client implementations for other editors potentially harder.

Because of this, we instead introduced a new `PIDE/decoration_request` notification, sent by the client to explicitly signal to the server that it should send a `PIDE/decoration` notification back.

Note that this system is atypical for the LSP. The `PIDE/decoration_request` notification is, semantically speaking, a request and intends a response from the server, yet from the perspective of the LSP, it is a unidirectional notification, while its response is also a unidirectional `PIDE/decoration` notification. We chose this approach for two reasons:
1. There was already precedent for such behavior in the Isabelle language server, specifically with `PIDE/preview_request`.

2. `PIDE/preview_response` notifications, and, the `PIDE/decoration` notification is not only sent after a request. The original automatic sending behavior that existed before is still present and was not altered. If we were to implement `PIDE/decoration_request`s as an LSP request instead, this would only result in extra implementation work on the client side because a client would need to implement the same decoration application logic for both the `PIDE/decoration` notification and the `PIDE/decoration_request` response. By defining `PIDE/decoration_request`s as notifications, the client only needs to implement a singular handler for `PIDE/decoration` notifications and automatically covers both scenarios simultaneously.

Later we found that client-side caching was already implemented for the Isabelle VSCode extension; however, incorrectly so. The caching was implemented with the help of a JavaScript `Map` #footnote[https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map]. This `Map` used `URI`s #footnote[https://code.visualstudio.com/api/references/vscode-api#Uri] as keys and the content list from the decoration messages as values. However, the `URI` type does not explicitly implement an equality function, thus resulting in an inconsistent equality check where two `URI`s referencing the same file may not have passed an equality check. Switching the key to using string representations of the URIs fixed the issue. However, we decided to keep the `PIDE/decoration_request` notification. While it may not be in use by #vscode[] directly, other Isabelle language client implementations may make use of this functionality.

// #TODO[
//   - currently breaks when switching files/tabs
//   - originally solved by implementing decoration request and requesting them every time we switch file/tab
//   - later found that client-side caching was implemented, but used URI as key instead of URI strings which didn't work
//   - decoration request kept in, in case a different client needs it (Foreshadowing to Sublime Text implementation which used it)
// ]

== Non-HTML Content for Panels <enhance:non-html>

The output and state panels in #vscode[] were previously always sent as HTML content by the language server. The server sends #box[`PIDE/dynamic_output`] and #box[`PIDE/state_output`] notifications with output and state content respectively. We will focus on content for the output panel in this section, however everything is almost equivalently done for state panel content.

The structure of a #box[`PIDE/dynamic_output`] notification was rather simple: The notification only contained a single `content` value, which was a string containing the panel's content. As mentioned, this content used to be HTML content that was displayed by #vscode[] in a WebView. However, not every code editor has the ability to natively display HTML content, and there used to be no way for a language client to get pure text content instead.

We added a new Isabelle system option called `vscode_html_output` which skips the conversion to HTML in the language server and makes it send text content instead. However, this poses a new problem: The conversion to HTML additionally added highlighting to the panel content. The conversion takes the source XML body, extracts the relevant decoration markup and uses it to generate equivalent HTML markup. Skipping this conversion and sending pure text instead also meant the language client got no highlighting within these panels. The Neovim language client prototype mentioned in @intro:motivation had this problem, as seen in @fig:neovim-no-decs.

#columns(2)[
  #figure(
    box(stroke: 1pt, image("/resources/neovim-no-decs-light.png", width: 100%)),
    kind: image,
    caption: [Neovim Isabelle client\ without decorations in output panel.],
    // placement: bottom,
  ) <fig:neovim-no-decs>
  #colbreak()
  #figure(
    box(stroke: 1pt, image("/resources/neovim-with-decs-light.png", width: 100%)),
    kind: image,
    caption: [Neovim Isabelle client\ with decorations in output panel.],
    // placement: bottom,
  ) <fig:neovim-with-decs>
]

Decorations within state and output panels is quite important, as it is more than just superficial visuals. There are many cases when writing Isabelle proofs where a single name is used for two or more individual variables. Isabelle also often generates its own names within proofs, and that generation may introduce further overlaps of identifiers. This may create goals like #isabellebox[#text(blue)[`x`]` = `#text(green)[`x`]] that are not provable because the left #isabellebox[#text(blue)[`x`]] is a different variable than the right #isabellebox[#text(green)[`x`]]. The only way to differentiate these variables in these cases is by their color. If the colors are missing, the goal will look like #isabelle("x = x").

To fix this, we added an optional additional `decorations` value to #box[`PIDE/dynamic_output`] and #box[`PIDE/state_output`] notifications, one that is only given when HTML output is disabled. The form of this value is the same as the `entries` value of the #box[`PIDE/decoration`] notifications described in @enhance:decorations. That way, even when the server sends non-HTML panel content, the client can additionally apply the given decorations to the respective panel. The result of adding this functionality into Neovim's language client prototype can be seen in @fig:neovim-with-decs.

// To extract the decoration markup from the output and state XML bodies, we used Isabelle's internal `Markup_Tree` module.

// #TODO[
//   - currently server sends output always in HTML format
//   - VSCode can display HTML, but not all clients can
//   - now can disable HTML output and send pure text instead with option
//   - added decorations to the message if HTML is disabled (biggest usability win in neovim)
// ]

== Symbol Handling <symbol-options>

As described in @background:isabelle-symbols, Isabelle utilizes its own #utf8isa[] encoding to deal with Isabelle Symbols. It is important to distinguish between 3 different domains:

/ Physical: This is the contents of the file. It's essentially a list of bytes, which need to be interpreted. Certainly, a theory file contains text, meaning the bytes represent some list of symbols. However, even then the exact interpretation of the bytes can vary depending on the encoding used. For example, the two subsequent bytes `0xC2` and `0xA5` mean different symbols in different encodings. If the encoding is #box[_UTF-8_], those two bytes stand for the symbol for Japanese Yen #isabelle("¥"). If, however, the encoding is #box[_ISO-8859-1 (Western Europe)_], the bytes are interpreted as #isabelle("Â¥"). The file itself does not note the supposed encoding, meaning without knowing the encoding, the meaning of a file's contents may be lost.

/ Isabelle System: This is where the language server lives. Here, an Isabelle symbol is simply an instance of an interal struct whose layout is outlined in @symbol-data-example.

/ Editor: This is where the language client lives. When opening a file in a code editor, it gets loaded into some internal structure the editor uses for its text buffers. During this loading, the editor will need to know the encoding to use, which will also affect what bytes the editor will write back to disk.

When using #jedit[] and loading a theory with the #utf8isa[] encoding, the bytes of the file will be interpreted as UTF-8, and additionally ASCII representations of symbols will be interpreted as their UTF-8 counterparts. When writing back to disk, this conversion is done in reverse. Thus, as long as all symbols within a theory are valid Isabelle symbols, which all have ASCII representations, a file saved with the #utf8isa[] encoding can be viewed as plain ASCII.

With #vscode[], we get the additional problem that the *Isabelle System* does not have direct access to our editor's buffer. As mentioned in @background:isabelle-vscode, Isabelle patches VSCodium to include a new #utf8isa[] encoding, so loading the file works virtually the same as in #jedit[].
// #footnote[One particular difference between #vscode['s] and #jedit['s] implementation of the #utf8isa[] encoding is that the set of Isabelle symbols that #vscode[] understands is static. It is possible to extend this set and #jedit[] can deal with newly defined symbols while #vscode[] can not, although this is rarely a problem in practice.]
However, the language server must still obtain the contents of the file.

// #info[One particular difference between #vscode['s] and #jedit['s] implementation of the #utf8isa[] encoding is that the set of Isabelle Symbols that #vscode[] understands is static. It is possible to extend this set and #jedit[] can deal with newly defined symbols while #vscode[] can not, although this is rarely a problem in practice.]

Recall from @didchange that the LSP specification defines multiple notifications for text document synchronization, like the `textDocument/didOpen` and `textDocument/didChange` notifications, both of which contain data that informs the language server about the contents of a file. We will focus on `textDocument/didOpen` for now. This notification's `params` field contains a "`TextDocumentItem`" instance, whose interface definition is seen in @text-document-item.

#figure(
  box(width: 90%)[
    ```typescript
    interface TextDocumentItem {
        uri: DocumentUri;
        languageId: string;
        version: integer;
        text: string;
    }
    ```
  ],
  caption: [`TextDocumentItem` interface definition @lsp-spec.],
  kind: raw,
  // placement: auto,
) <text-document-item>

The most relevant data is the `text` field which contains the content of the entire text document that was opened. Aside from the header which is plain ASCII, the JSON data sent between client and server is interpreted as UTF-8, thus the `text` string is also interpreted as UTF-8 content. The exact content of this string depends on the text editor. In #vscode[], thanks to the custom #utf8isa[] encoding, the language server will receive the full UTF-8 encoded content of the file (i.e. #isabelle("⟹") instead of #isabelle("\<Longrightarrow>")), however this may not be the case for another editor. Thankfully, the Isabelle system internally deals with all types of Isabelle Symbol representations equally, so the editor is free to mix and match whichever representation is most convenient for it.

Every code editor may handle Isabelle symbols differently. Some editors may have the ability to add custom encodings, others may not. For example, in the Neovim code editor, it is possible to programmatically change how certain symbol sequences are displayed to the user using a feature called _conceal_. #footnote[https://neovim.io/doc/user/options.html#'conceallevel'] Through this feature, Neovim is able to have the ASCII representation (#isabelle("\<Longrightarrow>")) within the file and buffer, and still display the Unicode representation (#isabelle("⟹")) to the user, without the need of a custom encoding. All in all, the language server should not make assumptions about the implementation details of Isabelle symbols in the language client.

=== Symbol Options

There are many messages sent from the server to the client containing different types of content potentially containing Isabelle symbols. #box[`window/showMessage`] notifications sent by the server asking the client to display a particular message, text edits sent for completions, text inserts sent for code actions, content sent for output and state panels, and many more.

Previously, there was a single Isabelle option called `vscode_unicode_symbols` which was supposed to control whether these messages sent by the server should send Isabelle symbols in their Unicode or ASCII representations, however this option only affected a few messages (like hover information and diagnostics). Things like completions were hard-coded to always use Unicode, as that is what #vscode[] requires.

When viewing #vscode[] in its entirety, this is not a problem. If the VSCode Isabelle client expects Unicode symbols in certain scenarios and the language server is hard-coded to do so, then it works for #vscode[]. However, once you move to a different client, this is a problematic limitation. In the case of Neovim's _conceal_ feature, it would be desirable to have messages sent by the server use ASCII for consistency.

Another important consideration is that, even if Neovim may want ASCII representations of symbols within the theory file, this may not necessarily be the case for output and state panels. While there are many different types of content sent by the server, it can generally be grouped into two categories: Content that is only supposed to get _displayed_ and content that is supposed to be _placed_ within the theory file.

To this end, we replaced the original `vscode_unicode_symbols` option by two new options: `vscode_unicode_symbols_output` for _displayed_ content, and `vscode_unicode_symbols_edits` for _placed_ content. Additionally, we made use of these new options in the respective places within the language server code base, removing the previously hard-coded values.

// #TODO[
//   - difference between ASCII representation of Symbols and Unicode representation of Symbols
//     - not always the case
//     - Isabelle internally makes no difference
//     - add Encoding graphic and explanation here
//   - before: `vscode_unicode_symbols`
//     - inconsistently used throughout the server codebase
//     - badly defined which symbols this affects
//   - now: two settings `vscode_unicode_symbols_output` and `vscode_unicode_symbols_edits`
//     - output for all output (e.g. panels, messages)
//     - edits for all edits (TextEdit objects, e.g. for autocompletion/code actions)
// ]

// #{
//   import "@preview/fletcher:0.5.1" as fletcher: diagram, node, edge
//
//   let h = 20mm
//
//   diagram(
//     spacing: (10mm, 5mm), // wide columns, narrow rows
//     node-stroke: 1pt, // outline node shapes
//     edge-stroke: 1pt, // make lines thicker
//     mark-scale: 60%, // make arrowheads smaller
//     node-corner-radius: 5pt,
//     debug: true,
//
//     node((0, 0), height: h, align(top + center)[Physical]),
//     node((-1, 0), height: h, align(top + center)[Language Server]),
//
//     node((1, 0), height: h, align(top + center)[Editor Logical], name: <elogic>),
//     node((2, 0), height: h, align(top + center)[Editor Display], name: <edisplay>),
//
//     node(align(top + center)[Editor], enclose: (<elogic>, <edisplay>)),

    // edge((-2,0), "r,u,r", "-|>", $f$, label-side: left),
    // edge((-2,0), "r,d,r", "..|>", $g$),
    // node((0,-1), $F(s)$),
    // node((0,+1), $G(s)$),
    // node(enclose: ((0,-1), (0,+1)), stroke: teal, inset: 10pt, snap: false), // prevent edges snapping to this node
    // edge((0,+1), (1,0), "..|>", corner: left),
    // edge((0,-1), (1,0), "-|>", corner: right),
    // node((1,0), text(white, $ plus.circle $), inset: 2pt, fill: black),
    // edge("-|>"),
//   )
// }

=== Symbols Request

The list of existing Isabelle symbols is not static, a user may augment this list in a #box[`$ISABELLE_HOME_USER/etc/symbols`] file~@manual-jedit[§2.2]. The issue is that previously, there was no way for a language client to get information about which symbols exist. So even if it is possible to hard-code the _default_ set of Isabelle symbols into an Isabelle language extension, that would not be correct in light of user additions.

#vscode[] uses such a hard-coded list of symbols. This list is added into the custom #utf8isa[] encoding while building the patched VSCodium. It also only includes the default set of symbols Isabelle offers out of the box, it does not include custom user additions. As this list is hard-coded, any change in the list of symbols would also require recompiling #vscode[]. This is different to #jedit[], where the code of the #utf8isa[] encoding exists within #scala[] and has therefore access to the complete list of symbols.

In order to eliminate the need of hard-coded lists of symbols for language clients, we added a #box[`PIDE/symbols_request`] request. When this request is sent, the language server responds with a list of all defined symbols. Note that, at the time of writing, this list _also_ only includes the default set without user additions in order to be in line with the set that is used by #vscode[]. This may be worth changing in the future, which we will discuss in @future-work.

=== Symbols Conversion

Another issue is that different language clients may want different symbol representations within files. While the typical way of handling symbols in Isabelle is to have symbols in their ASCII representation within files, some editors may want Unicode representations instead. In order for the client to freely choose which of the two it wants to use, it would be useful if there was some way for it to convert the symbols from one representation into the other. Within #scala[], this is easily done with the help of the interal `Symbol` module, and to pass this functionality to the language client, we added a new #box[`PIDE/symbols_convert_request`] request.

This request gets a string it should convert, as well as whether symbols in it should be converted into Unicode or ASCII representations. The language server then converts the symbols and sends the converted string back as its response. An example conversion request and response can be seen in @list:symbols-convert-request.

By allowing the client to request the conversion for any string, it allows a client implementation to offer more flexible functionality. For example, an Isabelle language extension may allow the user to select an area of the text and only convert the selected area, instead of the whole file.

Both the `PIDE/symbols_request` and `PIDE/symbols_convert_request` requests are not currently used by #vscode[]. They are only offered by the language server for use in other language clients, and have already seen use in them. For example, our current Neovim Isabelle client prototype supports a `SymbolsConvert` command to convert the symbols in the current buffer.

#figure(
  {
    import "@preview/codly:1.0.0": *
    show raw: set text(size: 10pt, font: "Isabelle DejaVu Sans Mono")
    show raw: it => block(width: 100%, it)
    table(
      columns: (1.8fr, 1fr),
      stroke: none,
      inset: (x: 0pt, y: 5pt),
      table.header([*Request*], [*Response*]),
      local(
        lang-format: none,
        ```json
        "jsonrpc": "2.0",
        "id": 58,
        "method": "PIDE/symbols_convert_request",
        "params": {
            "text": "A \<Longrightarrow> B",
            "unicode": true
        }
        ```
      ),
      local(
        number-format: none,
        ```json
        "jsonrpc": "2.0",
        "id": 58,
        "result": {
            "text": "A ⟹ B"
        }


        ```
      ),
    )
  },
  kind: raw,
  caption: [`PIDE/symbols_convert_request` example request and response.],
  placement: auto,
) <list:symbols-convert-request>

// #TODO[
//   - currently client was expected to just know what symbols are available, but this is dynamic
//   - now client can request a list of all symbols from server
//     - gives the same list used by VSCode during compilation, meaning dynamic symbol additions still don't work (Future Work)
// ]
//
// #TODO[
//   - flush_edits used to automatically convert symbols based on `vscode_unicode_symbols`
//   - but now the code for it was just unused, so it was removed
//   - now symbol conversion is a request
//     - client can easily convert whole document to unicode with that
// ]

== Code Actions for Active Markup

One feature of #jedit[] that was missing entirely in #vscode[] is Isabelle's _active markup_. Active markup, generally speaking, describes parts of the theory, state or output content that is clickable. The action taken when the user clicks on an active markup can vary, as many different kinds of active markup exist. One type of active markup the user will probably come across frequently is the so called _sendback_ markup. This type of markup appears primarily in the output panel and clicking on it inserts its text into the source theory. It appears, for example, when issuing a `sledgehammer` command.
#footnote[The `sledgehammer` command is an Isabelle command that calls different external automatic theorem provers in hopes of one of them finding a proof. Isabelle then translates the found proof back into an Isabelle proof.]
When this command finds a proof, it is displayed in the output panel with a gray background. The user can then click on it and Isabelle inserts the proof into the document. This example can be seen in @active-markup-sledgehammer-jedit. As mentioned, there are other types of active markup as well, but we will focus exclusively on sendback markup.

#figure(
  table(
    columns: 2,
    stroke: none,
    table.header([*Before*], [*After*]),
    box(stroke: 1pt, image("/resources/jedit-active-sledgehammer-before.png")),
    box(stroke: 1pt, image("/resources/jedit-active-sledgehammer-after.png")),
  ),
  kind: image,
  caption: [Active markup in #jedit[] when using sledgehammer.\ Before and after clicking on sendback markup.],
  placement: auto,
) <active-markup-sledgehammer-jedit>

Unlike other features discussed in this work, active markups are a concept that has no comparable feature within typical code editors. Clicking on parts of code may exist in the form of _Goto Definition_ actions or clicking on hyperlinks, but inserting things from some output panel into the code is unique. Hence, there is also no existing precedent on how to handle this type of interaction within the LSP specification. Because of this, the first question that needed to be answered is how we intend to tackle this problem in terms of user experience. That is, should the #vscode[] implementation work the same way as it does in #jedit[] (i.e. by clicking with the mouse), or should the interaction work completely differently.

There exist two major problems when trying to replicate the user experience of #jedit[]:
1. For the sake of accessibility, it is usually possible to control VSCode completely with the Keyboard. To keep this up, we decided it should also be possible to interact with active markup entirely with the keyboard.

2. It would need a completely custom solution for both the language server and language client, increasing complexity and reducing the barrier of entry for new potential Isabelle IDEs. We would potentially need to reimagine the way that output panel content is sent to the client, and if so, it would be very difficult expanding the functionality to other types of active markup that live within the theory.

Instead, we decided to utilize existing LSP features where possible. And luckily, the LSP spec defines a concept called _code actions_ which we could use for active markup.

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

The big advantage of using code actions, is that code actions are a part of the normal LSP specification, meaning most language clients support them out of the box. If the Isabelle language server supports interaction with active markup through code actions, there is no extra work necessary for the client.

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
1. Find all #isar[] commands within the given `range`.

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
  caption: [Active markup in #vscode[] when using sledgehammer.\ Code action initiated with "`Ctrl+.`". Before and after accepting code action.],
  // placement: auto,
) <active-markup-sledgehammer-vscode>

Once the list of these code actions is sent to the language client, the server's work is done. The LSP text edit objects exist in a format standardized in the LSP, so the actual execution of the text edit can be done entirely by the client.

We also considered how to deal with correct indentation for the inserted text. In #jedit[], when a sendback markup gets inserted, the general indentation function that exists in #jedit[] is called right after to correctly indent the newly inserted text. Since this internal indentation function uses direct access to the underlying jEdit buffer, we could not easily use this function from the language server. However, simply ignoring the indentation completely results in a subpar user experience. A proper solution would reimplement #jedit['s] indentation logic for the language server, which we will discuss in @future-work as it exceeds the scope of this thesis. For our contribution, the language server instead just copies the source command's indentation to the inserted text. This will potentially give slightly different indentations compared to #jedit[], however the result is acceptable in practice.

An example of the resulting implementation for #vscode[] can be seen in @active-markup-sledgehammer-vscode.

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

== Isabelle System Options as VSCode Settings

Isabelle has many options that can be set to adjust different aspects of the interactive sessions. For example, the option `editor_output_state` defines whether the current state should additionally be printed within the output panel.

The options, including their default values, are generally defined within `etc/options` files scattered throughout the codebase. The user can overwrite these options by adding respective entries into a `$ISABELLE_HOME_USER/etc/preferences` file. When using #jedit[], the user will also find many of these options within #jedit['s] settings, as seen in @jedit-settings. These settings and the content of the `preferences` file are kept in sync @manual-jedit.

#figure(
  image("/resources/jedit-settings.png", width: 80%),
  kind: image,
  caption: [Isabelle options inside of #jedit[].],
  // placement: auto,
) <jedit-settings>

The Isabelle language server offers one additional way of overwriting Isabelle system options: Via CLI arguments. When starting the Isabelle language server with `isabelle vscode_server`, one may add additional option overwrites with `-o NAME=VAL` arguments. The order of priority for Isabelle options for the language server is then as follows:
1. CLI arguments.
2. User preferences defined in the `preferences` file.
3. Isabelle defaults.

The same is true for #vscode[]. When starting #vscode[] with `isabelle vscode`, the user can add option overwrites as CLI arguments. However, previously there was no method to set Isabelle options through #vscode['s] UI. We wanted to alleviate this discrepancy between #vscode[] and #jedit[] by adding options that are relevant to #vscode[] to its settings.

Ideally, the settings in #vscode[] would be kept in-sync with the user's `preferences` file, like #jedit[] does. However, to do so, we would need be able to parse and understand the `preferences` file from within the VSCode extension, yet this file is supposed to be managed by #scala[] exclusively. Therefore, we instead chose to use the #vscode[] settings as pure overwrites.

=== Passing Options from VSCode to the Language Server

#vscode[] itself has no use for Isabelle system options. These options are used by Isabelle internally, not by the code editor. That means that only the language server needs to know the options set by the user.

When using #vscode[], the user does not manually start the language server. Instead, they start `isabelle vscode`, which starts an instance of Isabelle's patched VSCodium with an Isabelle extension installed, which then starts the language server once the user opens an Isabelle theory.

The `isabelle vscode` command optionally takes option overwrites as CLI arguments and converts these into an environment variable called "`ISABELLE_VSCODIUM_ARGS`", such that the extension can read this environment variable later. On top of that, the extension used to add a few hard-coded options that are needed for #vscode[] to function properly. This set of options is finally given to the language server as CLI arguments. @vscode-options-flow-previous shows this process.

#figure(
  diagram(
    edge-stroke: 1pt,

    edge((-1, -1.5), (-1, -0.7), "-}>", [CLI arguments], label-side: left),
    node((-1, -0.7), [Isabelle System], height: 40pt, stroke: 1pt),

    edge((-1, -0.7), (-1, 0)),
    node((-1, 0), [`ISABELLE_VSCODIUM_ARGS`]),
    edge((-1, 0), (0, 0), "-}>"),

    node((0, 0), [VSCodium\ Extension], height: 40pt, stroke: 1pt),
    edge((0, 0), (2, 0), "-}>", align(center, [CLI\ arguments]), label-anchor: "center", label-sep: 0pt),
    node((2, 0), [Language Server], height: 40pt, stroke: 1pt),
  ),
  kind: image,
  caption: [Previous passing of option overwrites.],
) <vscode-options-flow-previous>

The language server gets its option values by first taking the Isabelle default, overwriting those with whatever the user specified in their `preferences` file, and overwriting those again with whatever was given as CLI arguments.

In order to additionally consider VSCode settings, we must add them from within the extension, as we do not have access to the VSCode settings from within the language server nor the original Isabelle process that starts VSCodium. Therefore, the only part we can actually affect with VSCode settings is the CLI arguments sent to the server by the extension. Here, we must decide whether the user's CLI arguments or VSCode settings have priority. This limits the possible order of priority to two different possibilities, seen in @priority-order-options.

#figure(
  table(
    columns: 2,
    align: left,
    stroke: (x, y) => (
      left: if x > 0 { .5pt } else { 0pt },
      right: 0pt,
      top: if y > 0 { .5pt } else { 0pt },
      bottom: 0pt,
    ),
    table.header([*Option 1*], [*Option 2*]),
    enum(indent: 0pt, [CLI], [VSCode Settings], [Preferences], [Defaults]),
    enum(indent: 0pt, [VSCode Settings], [CLI], [Preferences], [Defaults]),
  ),
  caption: [Different possibilities for Isabelle system option priority order.],
  kind: table,
) <priority-order-options>

Of these, we chose to proceed with option 1, as CLI option overwrites are more explicit than the user's VSCode settings and should be prioritized.

#figure(
  diagram(
    edge-stroke: 1pt,

    edge((-1, -1.65), (-1, -0.85), "-}>", [CLI arguments], label-side: left),
    node((-1, -0.85), [Isabelle System], height: 40pt, stroke: 1pt),

    edge((-1, -0.85), (-1, -0.15)),
    node((-1, -0.15), [`ISABELLE_VSCODIUM_ARGS`]),
    edge((-1, -0.15), (0, -0.15), "-}>"),

    node((-1, 0.15), [VSCode settings]),
    edge((-1, 0.15), "r", "-}>"),

    node((0, 0), [VSCodium\ Extension], height: 40pt, stroke: 1pt),
    edge((0, 0), (2, 0), "-}>", align(center, [CLI\ arguments]), label-anchor: "center", label-sep: 0pt),
    node((2, 0), [Language Server], height: 40pt, stroke: 1pt),
  ),
  kind: image,
  caption: [Passing of option overwrites with VSCode settings.],
) <vscode-options-flow-after>

@vscode-options-flow-after shows the new flow of Isabelle options when starting #vscode[]. The VSCode Isabelle extension has access to both the CLI arguments given to the `isabelle vscode` command, and whatever settings are set in VSCode.

These two get merged, prioritizing the options within the `ISABELLE_VSCODIUM_ARGS` variable, and this merged set of option overwrites gets passed to the language server.

=== Option Types

Isabelle system options all have a type, which can be `string`, `int`, `real` or `bool`. It might be tempting to use the same type for the VSCode extension's settings. However, since we ultimately want the user to be able to _overwrite_ these options, this is not optimal. Taking the `editor_output_state` as an example, which is of type `bool`, the respective VSCode setting would be of type `boolean`. In the UI, this would make it a checkbox, giving it two states. However, we actually need three states: Don't overwrite, `off` and `on`. If the type of the VSCode setting were `boolean` with a default value of `off`, there would be no difference between the user not wanting VSCode to overwrite their user preferences and wanting to overwrite it with `off`.

Instead, we made all #vscode[] settings of type `string`. For Isabelle options of type `bool`, the respective VSCode setting will have possible values `""`, `"off"` and `"on"`, meaning dont-override, overwrite with `off` and overwrite with `on` respectively. For Isabelle options of any other type, the empty string `""` means don't overwrite and any other value is the value the option should be overwritten with.

This system has another advantage for numerical options: The types of VSCode settings are just JavaScript types. Isabelle makes a difference between `real` and `int` options, but JavaScript only has a singular `numeric` type. If the VSCode option were to take such `numeric` values, the extension would need to convert this value to a string to pass it to the language server as a CLI argument. By keeping it a string from the start, we skip potential conversion errors that may occur otherwise.

=== Extending #vscode['s] Settings

Many Isabelle options are annotated with a tag, thus creating grouping of similar options. For example, the `content` tag includes options such as `names_long`, `names_short` and `names_unique` which affect how names (like function names) are printed within output and state panels.

Many of the options Isabelle exposes are not relevant for #vscode[]. For example, one of the option tags available is the `jedit` tag which, as the name suggests, includes options relevant specifically for #jedit[].

The first options that we deemed relevant are the options specifically designed for VSCode and the language server. These options are defined within `src/Tools/VSCode/etc/options`. To easily access these options, we added and assigned a new `vscode` option tag to these options.

The second set of relevant options are options tagged with the aforementioned `content` tag.

The third set are manually chosen options helpful for #vscode[], but not included in either of the previous two tags. The list of options we chose is:
#columns(2)[
  - `editor_output_state`
  - `auto_time_start`
  - `auto_time_limit`
  - `auto_nitpick`
  - `auto_sledgehammer`
  #colbreak()
  - `auto_methods`
  - `auto_quickcheck`
  - `auto_solve_direct`
  - `sledgehammer_provers`
  - `sledgehammer_timeout`
]

To add custom settings to VSCode with a VSCode extension, one can add a `contributes.configuration` entry into the extensions `package.json` file @extension-api. Since the options available in the given tags may change in the future, simply adding them manually to the `package.json` file was unsatisfactory. Instead, the options are dynamically added while building the extension with `isabelle component_vscode_extension`. To do so, the `package.json` file includes a `"ISABELLE_OPTIONS": {},` marker which is replaced with the appropriate JSON format of the given options by the Isabelle system during build.

Additionally, we gave the options that were previously hard-coded into the extension a respective default value during this build process instead. That way, the user is able to change these settings if they want to, which was not possible before.

// == New Default Settings and Word Pattern

// #TODO[
//   - completions don't work properly if word pattern is not set the way it is now
// ]

// #TODO[
//   - renderWhitespace to none because the space render is not monospaced in the font
//   - quickSuggestions strings to on, because everything in quotes is set to be a string by the static syntax
//   - wordBasedSuggestions to off
// ]
