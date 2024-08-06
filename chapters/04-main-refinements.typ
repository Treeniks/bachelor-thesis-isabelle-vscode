#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

= Refinements to Existing Functionality

The work presented in this thesis on #vscode[] can be roughly categorized into two areas: The refinement of existing features and the introduction of new ones. This chapter focuses on the former. In both categories, #jedit[] serves as the primary reference implementation. Whether addressing a problem or filling a gap in functionality, the aim has been to replicate the behavior of #jedit[] closely. While it could be argued that certain features in #jedit[] also warrant improvements, this thesis does not engage with those considerations.

== Desync on File Changes <didchange>

While building the Neovim Isabelle client mentioned in @motivation, the language server frequently got out of sync with the actual contents of the file. For example, it might have happened that the user wanted to write `apply auto`, but wrote `apply autt` by accident instead. If the user then corrected their mistake by removing the additional `t` and replacing it with an `o`, it could happen that the language server would think the content of the file was `apply autto`. Somewhat awkwardly, this problem _only_ occurred when using Neovim, it did not happen in VSCode.

Document synchronization is done primarily through `textDocument/didChange` and `textDocument/didOpen` notifications. We will discuss the `textDocument/didOpen` notification in more detail in @symbol-options, but this desyncing issue results from the handling of the `textDocument/didChange` notifications. Its content is outlined in @did-change-interface.

#figure(
  ```typescript
  interface DidChangeTextDocumentParams {
    textDocument: VersionedTextDocumentIdentifier;
    contentChanges: TextDocumentContentChangeEvent[];
  }
  ```,
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

== State Panel IDs <state-init>

As mentioned in @background:output-and-state-panels, it is possible to open multiple state panels in #jedit[]. While users typically want to see the proof state at the position of their caret, there may be cases where one wants to permanently see the proof state of a different position.

The language server already had support for multiple state panels. Internally, the language server stored a `Map` from IDs to state panels. Additionally, all state related messages had to include the ID of the panel that they are referring to. For example, to disable the _Auto update_ property
#footnote[The _Auto update_ property enables automatic updating of the panel's content to the caret position. If disabled, moving the caret will not change the panel's content and will only update if the user issues a manual _Update_ command.]
of a state panel, the client needs to send a `PIDE/state_auto_update` notification, with an `id` and `enabled` field.

In particular, when starting the Isabelle language server, it did not automatically initialize a state panel. The client had to send a `PIDE/state_init` notification to create a state panel. However, the client could not define the state panel's ID within this notification. Instead, the server used the Isabelle internal `Counter` module to create a unique state panel ID.

In order to keep these IDs separate between Isabelle's ML and Scala processes, this module counts forwards in ML and backwards in Scala. Since the language server is part of the Scala part of Isabelle's codebase, this meant that the state panel's IDs would start at $-1$ and count downwards with each new created state panel. This in and of itself is not a problem, the problem was that the language server did not communicate the created IDs with the language client. Thus, the language client had to know the internal Isabelle language server ID creation logic. And if that logic ever changes in the future, the client would need to be updated with it.

To eliminate this issue, we changed the `PIDE/state_init` message from a notification to a request. Now, when a `PIDE/state_init` request is sent by the client, the server send a response back that includes the state ID of the newly created state panel. That way, we were able to decouple and future proof the internal language server logic from the language client implementation.

An important thing to note is that #vscode[] does not actually support multiple state panels. The underlying language server does, but the Isabelle VSCode language client only has support for a single state panel. Therefore there is further work that needs to be done in this area.

// #TODO[
//   - originally State Init would expect the client to know what ID it is
//   - VSCode implmentation never used the ID for anything itself
//   - now is a request instead of a notification which returns the newly created ID
// ]

// == Decoration Notification Send All Decorations

// #TODO[
//   - currently only send some decorations, now send all
// ]

== State and Output Panels

A comparison of #vscode['s] previous panel output against #jedit['s] panel output can be seen in @state-comparison. There are two main issues that needed to be tackled:
1. The lack of formatting, in particular with regards to line breaks.

2. The use of an incorrect font.

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
          #show raw: set text(font: ("Noto Sans Mono", "DejaVu Sans"))
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
  caption: [Comparison of #jedit[] State display and previous #vscode[] State display],
  kind: table,
  placement: auto,
) <state-comparison>

=== Correct Formatting

Isabelle uses an internal module called `Pretty` to manage the formatting of content in state and output panels. Specifically, this module is responsible for adding line breaks and indentation to these outputs if the panels are not wide enough to display something in a single line. The language server did not use the `Pretty` module at all, meaning that it was the responsibility of the client to add correct line breaks, which #vscode[] did not do. Instead, it used its default word wrap line breaks.

==== Isabelle's Internal XML

Isabelle internally represents almost all content with untyped XML trees. An "`XML.Body`" is defined as a list of "`XML.Tree`", which can be either an "`XML.Text`" containing some text, or an "`XML.Elem`" containing some markup and a child body. Ultimately, the actual content of an `XML.Body` is determined exclusively through such `XML.Text` instances, essentially the leaves of XML trees. The markup portion of `XML.Elem` on the other hand stores all kinds of semantic information Isabelle might need about its child body. This information can include what type of highlighting the text should have (e.g. `text_skolem`), whether it is _active markup_ that should do something when the user clicks on it, or where to go when the user initiates a _Goto Definition_. These XML bodies are so fundamental to Isabelle's inner workings, that even the theory code itself is saved as XML.

Output panel content is also created as such XML bodies. An Isabelle theory consists of many _commands_, each with some _command result_ which is an XML body. When the caret is above a command, the content of its command result is displayed on the output panel. State panel content is similarly just an XML body.

The `Pretty` module acts primarily on these XML bodies. There are 2 relevant functions within the module: "`separate`" and "`formatted`". `separate` takes an XML body and adds an XML element with a separator markup between each tree in the body. `formatted` applies the aforementioned line breaks to the XML body, as such this function also requires knowledge about the width of the area the content should be displayed in, further referred to as the _margin_. To get correctly formatted panel output as seen in @state-comparison, an XML body must first go through `separate` and then through `formatted`.

Lastly, Isabelle's `XML` module includes a "`content`" function, which reduces an XML body down into a string, using the information stored within the markups where applicable (like adding the correct separation character for a separator markup).

==== Using `Pretty` for Isabelle/VSCode

The problem with adding support for correct formatting of these panels to #vscode[] is that, for `Pretty` to be able to correctly format some output, it needs to know the margin of the panel in question. In #jedit[] this is not an issue, since the #jedit[] UI and the `Pretty` module all exist within the same Scala codebase. With #vscode[], a different solution is necessary.

Once again, there are several possibilities that we considered:
1. Rebuild the `Pretty` module within the VSCode extension.

2. Give access to the `Pretty` API through LSP messages.

3. Notify the language server about the current margin of each panel.

Option 1 would've required fundamentally changing the format in which the language client receives state and output content. Previously, the language client would get HTML code that it could just display inside a WebView. While generating this HTML code, information stored within the XML body's markup was used to create highlighting as well as hyperlinks, such that the user can click on some elements and be transported to its definition (e.g. for functions). In order for the language client to correctly format this content, it would instead need access to Isabelle's underlying XML. Such a change would've also required significantly more work for every Isabelle language client implementation, and was thus not pursued.

Option 2 is promising in that it allows a language client to use the `Pretty` module the same way #jedit[] would. However, the problem of requiring Isabelle's underlying XML content remains. Whenever the content of a panel were to change, the following would need to happen:
1. The language server sends the panel's XML body to the client.

2. The client then proceeds to send a `Pretty/separate` request to call the `Pretty` module's `separate` function on the XML body. The server calls said function and sends the resulting XML body back to the client.

3. The client sends a `Pretty/formatted` request to the server, the server calls `formatted` and sends the result back.

4. The client sends a `XML/content` request to the server, the server calls `content` and sends the result back.

In step 3 the client can easily send over the current panel's margin in its request, thus solving the original problem. This solution clearly requires a lot of work from the client and introduces several roundtrips for each panel. However, it also allows for the greatest flexibility for the client and gives a clear distinction between UI and logic. The language server exists exclusively for the internal Isabelle logic, while correct displaying of the internal information is the pure responsibility of the client. Because of this, when the UI is modified, like changing the width of the output panel, only steps 4 and 5 need to be repeated. The language server does not need to be informed about the change in UI, the panel's content does not need to be newly generated and sent to the client, and the client can handle exactly _when_ reformatting of the content is necessary.

Option 3 however requires the least amount of work for the language client. For this option, the client only needs to inform the server about the current panel margin and the server can decide completely on its own whether a re-send of the panel's content is necessary. From the perspective of a language client, it is thus the simplest solution, because all the actual output logic is done by the language server.

Due to its simplicity, Option 3 is the option we chose to implement. To this end, a new "`Pretty_Text_Panel`" module was added to #vscode[], which implements the output logic, as well as two new notifications: "`PIDE/output_set_margin`" and "`PIDE/state_set_margin`". Both output and state internally save one such `Pretty_Text_Panel` and simply tell it to refresh whenever the margin or content has changed. The `Pretty_Text_Panel` can then decide for itself if the actual content has changed and only send the appropriate notification to the client if it did.

While this solution has worked well in practice, note that one has to be careful how to send these margin updates. In VSCode for example, panel width can only be polled in pixels. The Isabelle language server however requires the margin to be in symbols, i.e. how many symbols currently fit horizontally into the panel. Since Isabelle symbols are not necessarily all monospaced, this instigates a unique problem: How do we measure symbol width? In #jedit[], this is solved by using the test string "mix", measuring its width and dividing that width by 3, thus we did the same in #vscode[]. Additionally, we added a limit on how often the margin update notifications are sent. If we were to send this notification for every single change in panel width, we would send a notification for every single pixel, which is extremely wasteful. In Neovim, by its terminal based nature, neither of these problems exist, because all characters have the same width and the width of a Neovim window only exists within discrete character counts.

=== Correct Font

#jedit[] uses a variant of the _DejaVu Sans Mono_ #footnote[https://dejavu-fonts.github.io/] font called _Isabelle DejaVu Sans Mono_. This custom font face can be built using the `isabelle component_fonts` Isabelle tool. It uses the _DejaVu Sans Mono_ fonts as a base and adds special Isabelle symbols, like #isabelle("⟹") and #isabelle("Γ") @font-email. As mentioned in @isabelle-vscode, part of the reason why #vscode[] adds custom patches on top of VSCodium is to add these custom fonts into the #vscode[] binary. That way, the user can use the _Isabelle DejaVu Sans Mono_ font family within buffers without needing to install these Isabelle fonts system-wide.

Unfortunately, these patched in fonts are not available from within VSCode extensions, and the output and state panels in #vscode[] are handled by the Isabelle extension. Therefore, to support the correct fonts for the panels, we needed to additionally include the fonts into the extension.

The Isabelle VSCode extension is built with the `isabelle components_vscode_extension` tool. Aside from calling the relevant build systems to build the extension, this tool also generates some static syntax definition to support static syntax highlighting for the most common keywords in #isar[]. We extended this tool to additionally copy the _Isabelle DejaVu Sans Mono_ font family into the extension build directory and add them to the extension's manifest file so that they are included in the extension's build. With this newly augmented extension in place, we could refer to these fonts from within the appropriate panels, the result of which can be seen in @vscode1.

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

== Symbol Options <symbol-options>

As described in @isabelle-symbols, Isabelle utilizes its own #utf8isa[] encoding to deal with Isabelle Symbols. It is important to distinguish between 3 different domains:

#{
  set par(hanging-indent: 1em)

  [
    *Physical.*
      This is the contents of the file. It's essentially a list of bytes, which need to be interpreted. Certainly, a theory file contains text, meaning the bytes represent some list of symbols. However, even then the exact interpretation of the bytes can vary depending on the encoding used. For example, the two subsequent bytes `0xC2` and `0xA5` can mean different symbols depending on the encoding used. If the encoding is #box[_UTF-8_], those two bytes stand for the symbol for Japanese Yen #isabelle("¥"). If, however, the encoding is #box[_ISO-8859-1 (Western Europe)_], the bytes are interpreted as #isabelle("Â¥"). The file itself does not note the supposed encoding, meaning without knowing the encoding, the meaning of a file's contents may be lost.

    *Isabelle System.*
      This is where the language server lives. Here, an Isabelle Symbol is simply an instance of an interal struct whose layout is outlined in @symbol-data-example.

    *Editor.*
      This is where the language client lives. When opening a file in a code editor, it gets loaded into some internal structure the editor uses for its text buffers. During this loading, the editor will need to know the encoding to use, which will also affect what bytes the editor will write back to disk.
  ]
}

When using #jedit[] and loading a theory with the #utf8isa[] encoding, the bytes of the file will be interpreted as UTF-8, and additionally ASCII representations of symbols will be interpreted as their UTF-8 counterparts. When writing back to disk, this conversion is done in reverse. Thus, as long as all symbols within a theory are valid Isabelle symbols, which all have ASCII representations, a file saved with the #utf8isa[] encoding can be viewed as plain ASCII.

When we get to #vscode[], we get the additional problem that the *Isabelle System* does not have direct access to our editor's buffer. As mentioned in @isabelle-vscode, Isabelle patches VSCodium to include a new #utf8isa[] encoding, so loading the file works virtually the same as in #jedit[].
#footnote[One particular difference between #vscode['s] and #jedit['s] implementation of the #utf8isa[] encoding is that the set of Isabelle Symbols that #vscode[] understands is static. It is possible to extend this set and #jedit[] can deal with newly defined symbols while #vscode[] can not, although this is rarely a problem in practice.]
However, the language server must still obtain the contents of the file.

// #info[One particular difference between #vscode['s] and #jedit['s] implementation of the #utf8isa[] encoding is that the set of Isabelle Symbols that #vscode[] understands is static. It is possible to extend this set and #jedit[] can deal with newly defined symbols while #vscode[] can not, although this is rarely a problem in practice.]

Recall from @didchange that the LSP specification defines multiple notifications for text document synchronization, like the `textDocument/didOpen` and `textDocument/didChange` notifications, both of which contain data that informs the language server about the contents of a file. We will focus on `textDocument/didOpen` for now. This notification's `params` field contains a "`TextDocumentItem`" instance, whose interface definition is seen in @text-document-item.

#figure(
  ```typescript
  interface TextDocumentItem {
    uri: DocumentUri;
    languageId: string;
    version: integer;
    text: string;
  }
  ```,
  caption: [`TextDocumentItem` interface definition @lsp-spec.],
  kind: raw,
  // placement: auto,
) <text-document-item>

The most relevant data is the `text` field which contains the content of the entire text document that was opened. Aside from the header which is plain ASCII, the JSON data sent between client and server is interpreted as UTF-8, thus the `text` string is also interpreted as UTF-8 content. The exact content of this string depends on the text editor. In #vscode[], thanks to the custom #utf8isa[] encoding, the language server will receive the full UTF-8 encoded content of the file (i.e. #isabelle("⟹") instead of #isabelle("\<Longrightarrow>")), however this may not be the case for another editor.

Thankfully, the Isabelle system internally deals with all types of Isabelle Symbol representations equally, so the editor is free to mix and match whichever representation is most convenient for it. As for the other direction, there are many messages sent from the server to the client containing different types of content potentially containing Isabelle Symbols. `window/showMessage` notifications sent by the server to ask the client to display a particular message, text edits sent for completions, text inserts sent for code actions, content sent for output and state panels, and many more.

Previously, there was a single Isabelle option called `vscode_unicode_symbols` which was supposed to control whether these messages sent by the server should send Isabelle Symbols in their Unicode or ASCII representations, however this option only affected a few messages (like hover information and diagnostics). Things like completions were hard-coded to always use Unicode, as that is what VSCode requires.

When viewing #vscode[] in its entirety, this is not a problem. If the VSCode Isabelle client expects Unicode symbols in certain scenarios and the language server is hard-coded to do so, then it works for #vscode[]. However, once you move to a different client, this is a problematic limitation. For example, in the Neovim code editor, it is possible to programmatically change how certain symbol sequences are displayed to the user using a feature called conceal. #footnote[https://neovim.io/doc/user/options.html#'conceallevel'] Through this feature, Neovim is able to have the ASCII representation (#isabelle("\<Longrightarrow>")) within the file and buffer, and still display the Unicode representation (#isabelle("⟹")) to the user, without the need of a custom encoding. In this case, it would be desirable to have messages sent by the server also use ASCII for consistency.

Another important consideration is that, even if Neovim may want ASCII representations of symbols within the theory file, this may not necessarily be the case for output and state panels. While there is many different types of content sent by the server, it can generally be grouped into two categories: Content that is only supposed to get _displayed_ and content that is supposed to be _placed_ within the theory file.

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

== Completions

#TODO[
  - completions were reworked
  - due to lsp completions changes, client-sided abbreviation support is not needed
  - 3 whole modules could be outright removed
]
