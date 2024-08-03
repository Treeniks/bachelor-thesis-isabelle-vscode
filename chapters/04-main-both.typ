#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *
#import "@preview/gentle-clues:0.9.0": *

= Changes to both Server and Client

As mentioned in @isabelle-vscode, #vscode() describes multiple Isabelle components working in unison to support Isabelle within VSCode. As such, the work done on #vscode() can be roughly categorized on whether it deals with the language server, the language client (i.e. the VSCode extension), or both, the latter of which we will look at first.

== Decorations on File Switch

Previously, when switching theories within #vscode(), the dynamic syntax highlighting would not persist. It was possible to get the highlighting to work again by changing the buffer's content; however, until this was done, it never recovered by itself. This was a problem when working on multiple theory files.

#figure(
  [
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
          "content": [ { "range": [7, 6, 7, 7] } ]
        }
      ]
    }
    ```
  ],
  caption: [Example `PIDE/decoration` notification sent by the language server.],
  kind: raw,
  placement: auto,
) <pide-decoration-json>

To understand how #vscode() does dynamic syntax highlighting, we will first take a look at the structure of the `PIDE/decoration` notifications. Recall that the primary data of notifications is sent within a `params` field. In this case, this field contains two components: A `uri` field with the relevant theory file's URI, and a list of decorations called `entries`. Each of these entries then consists of a `type` and a list of ranges called `content`. The `type` is a string identifier for an Isabelle decoration type. This includes things like `text_skolem` for Skolem variables and `dotted_warning` for things that should have a dotted underline. Each entry in the `content` list is another list of 4 integers describing the line start, line end, column start, and column end of the range the specified decoration type should be applied to. @pide-decoration-json shows an example of what a `PIDE/decoration` message may look like.

Since this is not part of the standard LSP specification, a language client must implement a special handler for such decoration notifications. Additionally, it was not possible to explicitly request these decorations from the language server. Instead, the language server would send new decorations whenever it deemed necessary, e.g., because the caret moved into areas of the text that haven't been decorated yet or because the document's content has changed.

On the VSCode side, these decorations were applied via the `TextEditor.setDecoration` API function #footnote[https://code.visualstudio.com/api/references/vscode-api#TextEditor.setDecorations], which does not inherently cache these decorations on file switch. Thus, when switching theories, VSCode did not cache the previously set decorations, nor did the language server send them again, causing the highlighting to disappear.

There were two primary ways to fix this issue:
1. Implement caching of decorations manually in the VSCode extension.

2. Add the ability to request new decorations from the server and do so on file switch.

The main advantage of option 1 is performance. If the client handles caching of decorations, then the server won't have to calculate the decorations anew (which is a rather expensive operation), nor will another round of JSON Serialization and Deserialization have to happen. However, the trade-off is that more work needs to be done on the client side, making new client implementations for other editors potentially harder.

Because of this, we instead introduced a new `PIDE/decoration_request` notification, sent by the client to explicitly signal to the server that it should send a `PIDE/decoration` notification back no matter what. Note that this system is atypical for the LSP. The `PIDE/decoration_request` notification is, semantically speaking, a request and intends a response from the server, yet from the perspective of the LSP, it is a unidirectional notification, while its response is also a unidirectional `PIDE/decoration` notification.

The reason for this is twofold: There was already precedent for such behavior in the Isabelle language server, specifically with `PIDE/preview_request` and `PIDE/preview_response` notifications, and, the `PIDE/decoration` notification is not only sent after a request. The original automatic sending behavior that existed before is still present and was not altered. If we were to implement `PIDE/decoration_request`s as an LSP request instead, this would only result in extra implementation work on the client side because a client would need to implement the same decoration application logic for both the `PIDE/decoration` notification and the `PIDE/decoration_request` response. By defining `PIDE/decoration_request`s as notifications, the client only needs to implement a singular handler for `PIDE/decoration` notifications and automatically covers both scenarios simultaneously.

Later on, we found that client-side caching was already implemented for the Isabelle VSCode extension; however, incorrectly so. The caching was done via a JavaScript `Map` #footnote[https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map], with files as keys and the content list from the decoration messages as values. For the keys, the specific value used was of type `URI` #footnote[https://code.visualstudio.com/api/references/vscode-api#Uri], which does not explicitly implement an equality function, thus resulting in an inconsistent equality check where two URIs pointing to the same file may not have been the same URI in TypeScript-land. Switching the key to using string representations of the URIs fixed the issue. However, we decided to keep the `PIDE/decoration_request` notification. While it may not be in use by #vscode() directly, other Isabelle language client implementations may make use of this functionality anyway.

// #TODO[
//   - currently breaks when switching files/tabs
//   - originally solved by implementing decoration request and requesting them every time we switch file/tab
//   - later found that client-side caching was implemented, but used URI as key instead of URI strings which didn't work
//   - decoration request kept in, in case a different client needs it (Foreshadowing to Sublime Text implementation which used it)
// ]

== Pretty Formatting for Panels

Isabelle uses an internal module called `Pretty` to manage the formatting of content in State and Output panels. Specifically, this module is responsible for adding line breaks and indentation to these outputs if the panels are not wide enough to display something in a single line. The language server did not use the `Pretty` module at all, meaning that it was the responsibility of the client to add correct line breaks, which #vscode() did not do. The result, seen in @state-comparison, was that #vscode() used its default word wrap linebreaks, instead of the semantic-aware linebreaks seen in #jedit().

#figure(
  {
    show raw: set text(size: 8pt)
    show "Γ": set text(green)
    show "τ": set text(green)
    show "a1": set text(green)
    show "a2": set text(green)

    box(
      fill: luma(235),
      radius: 5%,
      table(
        columns: 2,
        align: left,
        stroke: (x, y) => (
          left: if x > 0 { .5pt } else { 0pt },
          right: 0pt,
          top: if y > 0 { .5pt } else { 0pt },
          bottom: 0pt,
        ),
        table.header([*jEdit State Panel*], [*VSCode State Panel*]),
        [
          #show raw: set text(font: "Isabelle DejaVu Sans Mono")
`proof (state)
`#text(eastern)[`goal`]` (4 subgoals):
 1. ⋀Γ `#text(green)[`i`]`. Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval (Ic `#text(green)[`i`]`) `#text(blue)[`s`]`)
 2. ⋀Γ `#text(green)[`r`]`. Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval (Rc `#text(green)[`r`]`) `#text(blue)[`s`]`)
 3. ⋀Γ `#text(green)[`x`]`. Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval (V `#text(green)[`x`]`) `#text(blue)[`s`]`)
 4. ⋀Γ a1 τ a2.
       Γ ⊢ a1 : τ ⟹
       (Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval a1 `#text(blue)[`s`]`)) ⟹
       Γ ⊢ a2 : τ ⟹
       (Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval a2 `#text(blue)[`s`]`)) ⟹
       Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval (Plus a1 a2) `#text(blue)[`s`]`)`
        ],
        [
          #show raw: set text(font: "Noto Sans Mono")
`proof (state)
`#text(purple)[`goal`]` (4 subgoals):
 1. ⋀Γ `#text(green)[`i`]`. Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval (Ic `#text(green)[`i`]`) `#text(blue)[`s`]`)
 2. ⋀Γ `#text(green)[`r`]`. Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval (Rc `#text(green)[`r`]`) `#text(blue)[`s`]`)
 3. ⋀Γ `#text(green)[`x`]`. Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval (V `#text(green)[`x`]`) `#text(blue)[`s`]`)
 4. ⋀Γ a1 τ a2. Γ ⊢ a1 : τ ⟹ (Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval a1 `#text(blue)[`s`]`)) ⟹ Γ ⊢ a2 : τ ⟹ (Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval a2 `#text(blue)[`s`]`)) ⟹ Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval (Plus a1 a2) `#text(blue)[`s`]`)`
        ]
      )
    )
  },
  caption: [Comparison of #jedit() State display and previous #vscode() State display],
  kind: table,
  placement: auto,
) <state-comparison>

=== Isabelle's Internal XML

Isabelle internally represents almost all content with untyped XML trees. An "`XML.Body`" is defined as a list of "`XML.Tree`", which can be either an "`XML.Text`" containing some text, or an "`XML.Elem`" containing some markup and a child body. At the end of the day, the actual content of an `XML.Body` is determined exclusively through such `XML.Text` instances, essentially the leafs of XML trees. The markup portion of `XML.Elem` on the other hand stores all kinds of semantic information Isabelle might need about its child body. This information can include what type of highlighting the text should have (e.g. `text_skolem`), whether it is _Active Markup_ that should do something when the user clicks on it, or where to go when the user initiates a _Goto Definition_. These XML bodies are so fundamental to Isabelle's inner workings, that even the theory code itself is saved as XML.

_Output_ panel content is also created as such XML bodies. An Isabelle theory consists of many _Commands_, each _Command_ has some _Command Result_, and when the caret is above a _Command_, the content of its _Command Result_ is displayed on the _Output_ panel, and these _Command Results_ are just XML bodies. _State_ panel content is similarly just an XML body.

The `Pretty` module acts primarily on these XML bodies. There are 2 relevant functions within the module: "`separate`" and "`formatted`". `separate` takes an XML body and adds an XML element with a separator markup between each tree in the body. `formatted` applies the aforementioned line breaks to the XML body, as such this function also requires knowledge about the width of the area the content should be displayed in, further called the margin. To get correctly formatted panel output as seen in @state-comparison, an XML body must first go through `separate` and then through `formatted`.

Lastly, Isabelle's `XML` module includes a "`content`" function, which reduces an XML body down into a string, using the information stored within the markups where applicable (like adding the correct separation character for a separator markup).

=== Using `Pretty` for #vscode()

The problem with adding support for correct formatting of these panels to #vscode() is that, for `Pretty` to be able to correctly format some output, it needs to know the margin of the panel in question. In #jedit() this is a non-issue, since the #jedit() UI and the `Pretty` module all exist within the same Scala codebase. With #vscode() however, this is not possible.

Once again, there are several possibilities that we considered:
1. Rebuild the `Pretty` module within the VSCode extension.

2. Give access to the `Pretty` API through LSP messages.

3. Notify the language server about the current margin of each panel.

Option 1 would've required fundamentally changing the format in which the language client receives _State_ and _Output_ content. Previously, the language client would get HTML code that it could just display inside a WebView. While generating this HTML code, information stored within the XML body's markup was used to create highlighting as well as hyperlinks, such that the user can click on some elements and be transported to its definition (e.g. for functions). In order for the language client to correctly format this content, it would instead need access to Isabelle's underlying XML. Such a change would've also required significantly more work for every Isabelle language client implementation, and was thus not pursued.

Option 2 is promising in that it allows a language client to use the `Pretty` module the same way #jedit() would. However, the problem of requiring Isabelle's underlying XML content remains. Whenever the content of a panel were to change, the following would need to happen:
1. The language server sends the panel's XML body to the client.
2. The client then proceeds to send a `Pretty/separate` request to call the `Pretty` module's `separate` function on the XML body. The server calls said function and sends the resulting XML body back to the client.
3. The client sends a `Pretty/formatted` request to the server, the server calls `formatted` and sends the result back.
4. The client sends a `XML/content` request to the server, the server calls `content` and sends the result back.

In step 3 the client can easily send over the current panel's margin in its request, thus solving the original problem. This solution clearly requires a lot of work from the client and introduces several roundtrips for each panel. However, it also allows for the greatest flexibility for the client and gives a clear distinction between UI and logic. The language server exists exclusively for the internal Isabelle logic, while correct displaying of the internal information is the pure responsibility of the client. Because of this, when the UI is modified, like changing the width of the _Output_ panel, only steps 4 and 5 need to be repeated. The language server does not need to be informed about the change in UI, the panel's content does not need to be newly generated and sent to the client, and the client can handle exactly _when_ reformatting of the content is necessary.

Option 3 however requires the least amount of work for the language client. For this option, the client only needs to inform the server about the current panel margin and the server can decide completely on its own whether a re-send of the panel's content is necessary. From the perspective of a language client, it is thus the simplest solution, because all the actual output logic is done by the language server.

Due to its simplicity, Option 3 is the option we chose to implement. To this end, a new "`Pretty_Text_Panel`" module was added to #vscode(), which implements the output logic, as well as two new notifications: "`PIDE/output_set_margin`" and "`PIDE/state_set_margin`". Both _Output_ and _State_ internally save one such `Pretty_Text_Panel` and simply tell it to refresh whenever the margin or content has changed. The `Pretty_Text_Panel` can then decide for itself if the actual content has changed and only send the appropriate notification to the client if it did.

While this solution has worked well in practice, note that one has to be careful how to send these margin updates. In VSCode for example, panel width can only be polled in pixels. The Isabelle language server however requires the margin to be in symbols, i.e. how many symbols currently fit horizontally into the panel. Since Isabelle symbols are not necessarily all monospaced, this instigates a unique problem: How do we measure symbol width? In #jedit(), this is solved by using the test string "mix", measuring its width and dividing that width by 3, thus we did the same in #vscode(). Additionally, we added a limit on how often the margin update notifications are sent. If we were to send this notification for every single change in panel width, we would send a notification for every single pixel, which is extremely wasteful. In Neovim, by its terminal based nature, neither of these problems exist, because all characters have the same width and the width of a Neovim window only exists within discrete character counts.

// === Server
//
// #TODO[
//   - new introduction of Pretty Panel module
//   - manages the formatting of output, including extracting the decorations if HTML is disabled
//   - now client can send margins for both state and output panels
//     - pretty panel manages if new message needs to be sent or not (i.e. if output has actually changed)
// ]
//
// === Client
//
// #TODO[
//   - "mix" as test string for symbol sizes, same as in jEdit
//   - send with a timeout, otherwise there is a message for every pixel
//   - add headroom
// ]

== Symbol Options

As described in @isabelle-symbols, Isabelle utilizes its own _UTF-8-Isabelle_ encoding to deal with Isabelle Symbols. It is important to distinguish between 3 different domains:

#{
  set par(hanging-indent: 1em)

  [
    *Physical.*
      This is the actual contents of the file. It's really just a list of bytes, which need to be interpreted. Certainly, a theory file contains text, meaning the bytes represent some list of symbols. However, even then the exact interpretation of the bytes can vary depending on the encoding used. For example, the two subsequent bytes `0xC2` and `0xA5` can mean different symbols depending on the encoding used. If the encoding is #box[_UTF-8_], those two bytes stand for the symbol for Japanese Yen #isabelle("¥"). If, however, the encoding is #box[_ISO-8859-1 (Western Europe)_], the bytes are interpreted as #isabelle("Â¥"). The file itself does not note the supposed encoding, meaning without knowing the encoding, the meaning of a file's contents may be lost.

    *Isabelle System.*
      This is where the language server lives. Here, an Isabelle Symbol is simply an instance of an interal struct whose layout is outlined in @symbol-data-example.

    *Editor.*
      This is where the language client lives. When opening a file in a code editor, it gets loaded into some internal structure the editor uses for its text buffers. During this loading, the editor will need to know the encoding to use, which will also affect what bytes the editor will write back to disk.
  ]
}

When using #jedit() and loading a theory with the _UTF-8-Isabelle_ encoding, the bytes of the file will be interpreted as UTF-8, and additionally ASCII representations of symbols will be interpreted as their UTF-8 counterparts. When writing back to disk, this conversion is done in reverse. Thus, as long as all symbols within a theory are valid Isabelle symbols, which all have ASCII representations, a file saved with the _UTF-8-Isabelle_ encoding can be viewed as plain ASCII.

When we get to #vscode(), we get the additional problem that the *Isabelle System* does not have direct access to our editor's buffer. As mentioned in @isabelle-vscode, Isabelle patches VSCodium to include a new _UTF-8-Isabelle_ encoding, so loading the file works virtually the same as in #jedit().
// #footnote[One particular difference between #vscode(suffix: ['s]) and #jedit(suffix: ['s]) implementation of the _UTF-8-Isabelle_ encoding is that the set of Isabelle Symbols that #vscode() understands is static. It is possible to extend this set and #jedit() can deal with newly defined symbols while #vscode() can not, although this is rarely a problem in practice.]
However, the language server must still somehow get the file's contents.

#info[One particular difference between #vscode(suffix: ['s]) and #jedit(suffix: ['s]) implementation of the _UTF-8-Isabelle_ encoding is that the set of Isabelle Symbols that #vscode() understands is static. It is possible to extend this set and #jedit() can deal with newly defined symbols while #vscode() can not, although this is rarely a problem in practice.]

The LSP specification defines multiple notifications for text document synchronization, like the `textDocument/didOpen` and `textDocument/didChange` notifications, both of which contain data that informs the language server about the contents of a file. We will look at the `textDocument/didChange` notification in more detail in @didchange, so we will focus on `textDocument/didOpen` for now. This notification's `params` field contains a "`TextDocumentItem`" instance, whose interface definition is seen in @text-document-item.

#figure(
  [
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

The most relevant piece of data in there is the `text` field which contains the content of the entire text document that was opened. Aside from the header which is plain ASCII, the json data sent between client and server is interpreted as UTF-8, thus the `text` string is also interpreted as UTF-8 content. The exact content of this string depends on the text editor. In #vscode(), thanks to the custom _UTF-8-Isabelle_ encoding, the language server will receive full UTF-8 encoded content of the file (i.e. #isabelle("⟹") instead of #isabelle("\<Longrightarrow>")), however this may not be the case for another editor.

Thankfully, the Isabelle system internally deals with all types of Isabelle Symbol representations equally, so the editor is free to mix and match whichever representation is most convenient for it.

#TODO[
  - difference between ASCII representation of Symbols and Unicode representation of Symbols
    - not always the case
    - Isabelle internally makes no difference
    - add Encoding graphic and explanation here
  - before: `vscode_unicode_symbols`
    - inconsistently used throughout the server codebase
    - badly defined which symbols this affects
  - now: two settings `vscode_unicode_symbols_output` and `vscode_unicode_symbols_edits`
    - output for all output (e.g. panels, messages)
    - edits for all edits (TextEdit objects, e.g. for autocompletion/code actions)
]
