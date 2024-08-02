#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

= Changes to both Server and Client

As mentioned in @isabelle-vscode, #vscode describes multiple Isabelle components working in unison to support Isabelle within VSCode. As such, the work done on #vscode can be roughly categorized on whether it deals with the language server, the language client (i.e. the VSCode extension), or both, the latter of which we will look at first.

== Decorations on File Switch

Previously, when switching theories within #vscode, the dynamic syntax highlighting would not persist. It was possible to get the highlighting to work again by changing the buffer's content; however, until this was done, it never recovered by itself. This was a problem when working on multiple theory files.

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

To understand how #vscode does dynamic syntax highlighting, we will first take a look at the structure of the `PIDE/decoration` notifications. Recall that the primary data of notifications is sent within a `params` field. In this case, this field contains two components: A `uri` field with the relevant theory file's URI, and a list of decorations called `entries`. Each of these entries then consists of a `type` and a list of ranges called `content`. The `type` is a string identifier for an Isabelle decoration type. This includes things like `text_skolem` for Skolem variables and `dotted_warning` for things that should have a dotted underline. Each entry in the `content` list is another list of 4 integers describing the line start, line end, column start, and column end of the range the specified decoration type should be applied to. @pide-decoration-json shows an example of what a `PIDE/decoration` message may look like.

Since this is not part of the standard LSP specification, a language client must implement a special handler for such decoration notifications. Additionally, it was not possible to explicitly request these decorations from the language server. Instead, the language server would send new decorations whenever it deemed necessary, e.g., because the caret moved into areas of the text that haven't been decorated yet or because the document's content has changed.

On the VSCode side, these decorations were applied via the `TextEditor.setDecoration` API function #footnote[https://code.visualstudio.com/api/references/vscode-api#TextEditor.setDecorations], which does not inherently cache these decorations on file switch. Thus, when switching theories, VSCode did not cache the previously set decorations, nor did the language server send them again, causing the highlighting to disappear.

There were two primary ways to fix this issue:
1. Implement caching of decorations manually in the VSCode extension.

2. Add the ability to request new decorations from the server and do so on file switch.

The main advantage of option 1 is performance. If the client handles caching of decorations, then the server won't have to calculate the decorations anew (which is a rather expensive operation), nor will another round of JSON Serialization and Deserialization have to happen. However, the trade-off is that more work needs to be done on the client side, making new client implementations for other editors potentially harder.

Because of this, we instead introduced a new `PIDE/decoration_request` notification, sent by the client to explicitly signal to the server that it should send a `PIDE/decoration` notification back no matter what. Note that this system is atypical for the LSP. The `PIDE/decoration_request` notification is, semantically speaking, a request and intends a response from the server, yet from the perspective of the LSP, it is a unidirectional notification, while its response is also a unidirectional `PIDE/decoration` notification.

The reason for this is twofold: There was already precedent for such behavior in the Isabelle language server, specifically with `PIDE/preview_request` and `PIDE/preview_response` notifications, and, the `PIDE/decoration` notification is not only sent after a request. The original automatic sending behavior that existed before is still present and was not altered. If we were to implement `PIDE/decoration_request`s as an LSP request instead, this would only result in extra implementation work on the client side because a client would need to implement the same decoration application logic for both the `PIDE/decoration` notification and the `PIDE/decoration_request` response. By defining `PIDE/decoration_request`s as notifications, the client only needs to implement a singular handler for `PIDE/decoration` notifications and automatically covers both scenarios simultaneously.

Later on, we found that client-side caching was already implemented for the Isabelle VSCode extension; however, incorrectly so. The caching was done via a JavaScript `Map` #footnote[https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map], with files as keys and the content list from the decoration messages as values. For the keys, the specific value used was of type `URI` #footnote[https://code.visualstudio.com/api/references/vscode-api#Uri], which does not explicitly implement an equality function, thus resulting in an inconsistent equality check where two URIs pointing to the same file may not have been the same URI in TypeScript-land. Switching the key to using string representations of the URIs fixed the issue. However, we decided to keep the `PIDE/decoration_request` notification. While it may not be in use by #vscode directly, other Isabelle language client implementations may make use of this functionality anyway.

// #TODO[
//   - currently breaks when switching files/tabs
//   - originally solved by implementing decoration request and requesting them every time we switch file/tab
//   - later found that client-side caching was implemented, but used URI as key instead of URI strings which didn't work
//   - decoration request kept in, in case a different client needs it (Foreshadowing to Sublime Text implementation which used it)
// ]

== Pretty Formatting for Panels

Isabelle uses an internal module called `Pretty` to manage the formatting of content in State and Output panels. Specifically, this module is responsible for adding line breaks and indentation to these outputs if the panels are not wide enough to display something in a single line. The language server did not use the `Pretty` module at all, meaning that it was the responsibility of the client to add correct line breaks, which #vscode did not do. The result, seen in @state-comparison, was that #vscode used its default word wrap linebreaks, instead of the semantic-aware linebreaks seen in #jedit.

#figure(
  {
    show raw: set text(size: 8pt)
    show "Γ": set text(green)
    show "τ": set text(green)
    show "a1": set text(green)
    show "a2": set text(green)

    table(
      columns: 2,
      align: left,
      stroke: (x, y) => (
        left: if x > 0 { .5pt } else { 0pt },
        right: 0pt,
        top: if y > 0 { .5pt } else { 0pt },
        bottom: 0pt,
      ),
      fill: (_, y) => if y == 1 { luma(235) } else { none },
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
  },
  caption: [Comparison of #jedit State display and previous #vscode State display],
  kind: table,
  placement: auto,
) <state-comparison>

=== Isabelle's Internal XML

Isabelle internally represents almost all content with untyped XML trees. An `XML.Body` is defined as a list of `XML.Tree`s, which can be either an instance `XML.Text` containing some text, or an `XML.Elem` containing some markup and a child body. At the end of the day, the actual content of an XML body is determined exclusively through such XML text instances, essentially the leafs of XML trees. The markup portion of XML elements on the other hand stores all kinds of semantic information Isabelle might need about its child body. This information can include what type of highlighting the text should have (e.g. `text_skolem`), whether it is _Active Markup_ that should do something when the user clicks on it, or where to go when the user initiates a _Goto Definition_. These XML bodies are so fundamental to Isabelle's inner workings, that even the theory code itself is saved as XML internally.

_Output_ panel content is also created as such XML bodies. An Isabelle theory consists of many _Commands_, each _Command_ has some _Command Result_, and when the caret is above a command, the content of its _Command Result_ is displayed on the _Output_ panel. And these _Command Results_ are also just XML bodies. Similarly, _State_ panel content is also originally just an XML body.

The `Pretty` module acts primarily on these XML bodies. There are 2 relevant functions within the module: `separate`, `formatted`. `separate` takes an XML body and adds an XML element with a separator markup between each element in the body. `formatted` applies the aforementioned indenting and line breaks to the XML body, as such this function also requires knowledge about the width of the area the content should be displayed at, further called the margin. Lastly, the `XML` module includes a `content` function, which reduces an XML body down into a String, using the information stored within the markups where applicable (like adding the correct separation character for a separator markup).

=== Using `Pretty` for #vscode

The problem with adding support for correct formatting of these panels to #vscode is that, for `Pretty` to be able to correctly format some output, it needs to know the margin of the panel in question. In #jedit, this is a non-issue, since the #jedit UI and the `Pretty` module all exist within the same Scala codebase. With #vscode however, there is a clear-cut between the UI (VSCode) and #box[_Isabelle/Scala_] (the language server). Once again, there are several possibilities that we considered:
1. rebuild the `Pretty` module within the VSCode extension

2. give access to the `Pretty` API through LSP messages

3. notify the language server about the current margin of each panel

Option 1 would've required fundamentally changing the format in which the language client receives _State_ and _Output_ content. Previously, the language client would get HTML code that it could just display inside a WebView. While generating this HTML code, information stored within the XML body's markup was used to create hyperlinks, such that the user can click on some elements and be transported to its definition (e.g. for functions). In order for the language client to correctly format this content, it would instead need access to Isabelle's underlying XML. Such a change would've also required significantly more work for every Isabelle language client implementation, and was thus not pursued.

Option 2 is promising in that it allows a language client to use the `Pretty` module the same way #jedit would. However, the problem of requiring Isabelle's underlying XML content remains. Whenever the content of a panel were to change, the following would need to happen:
1. the language server sends the panel's XML body to the client

2. the client then proceeds to send a `Pretty/separate` request to call the `Pretty` module's `separate` function on the XML body, the server calls said function and sends the resulting XML body back to the client

3. the client sends a `Pretty/formatted` request to the server, the server calls `formatted` and sends the result back

4. the client sends a `XML/content` request to the server, the server calls `content` and sends the result back

In step 3 the client can easily send over the current panel's margin in its request, thus solving the original problem. This solution clearly requires a lot of work from the client and introduces several roundtrips for each panel, however it also allows for the greatest flexibility for the client. It also gives a clear distinction between UI and logic. The language server exists purely for the internal Isabelle logic, while correct displaying of the internal information is the pure responsibility of the client. Because of this, when the UI is modified, like changing the width of the _Output_ panel, only steps 4 and 5 need to be repeated. The language server does not need to be informed about the change in UI, the panel's content does not need to be newly generated and sent to the client, and the client can handle exactly _when_ reformatting of the content is necessary.

Option 3 however requires the least amount of work for the language client. For this option, the client only needs to inform the server about the current panel margin and the server can decide completely on its own whether a re-send of the panel's content is necessary. From the perspective of a language client, it is thus the simplest solution, because all the actual output logic is done by the language server, and is thus the option we chose to implement. To this end, a new `Pretty_Text_Panel` module was added to #vscode, which implements this exact logic. Both _Output_ and _State_ internally save one such `Pretty_Text_Panel` and simply tell it to refresh whenever the margin or content has changed. The `Pretty_Text_Panel` can then decide for itself if the actual content has changed and only send the appropriate notification to the client if it did.

While this option has worked well in practice, note that one has to be careful how to send these margin updates. In VSCode for example, panel width can only be polled in pixels. The Isabelle language server however requires the margin to be in symbols, i.e. how many symbols currently fit horizontally into the panel. Since Isabelle symbols are not necessarily all monospaced, this instigates a unique problem: How do we measure symbol width? In #jedit, this is solved by using the text string "mix", measuring its width and dividing that width by 3, thus we did the same in #vscode. Additionally, we added a limit on how often the margin update notifications are sent. If we were to send this notification for every single change in panel width, we would send a notification for every single pixel, which is extremely wasteful. In Neovim, by its terminal based nature, neither of these problems exist, because all characters have the same width and the width of a Neovim window only exists within discrete character counts.

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
