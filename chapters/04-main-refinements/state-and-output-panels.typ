#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

== State and Output Panels

A comparison of #vscode's previous panel output against #jedit's panel output can be seen in @state-comparison. Two main issues needed to be tackled:
1. The lack of formatting, particularly regarding line breaks.

2. The use of an incorrect font.

#figure(
  {
    show raw: set text(size: 8pt)

    let blue = rgb(0, 0, 245) // used for s
    let green = rgb(55, 126, 34)

    show "Γ": set text(green)
    show "τ": set text(green)
    show "a1": set text(green)
    show "a2": set text(green)

    set par(justify: false)

    box(
      fill: luma(245),
      stroke: 2pt + luma(230),
      radius: 5%,
      table(
        columns: (1fr, 1fr),
        align: left,
        stroke: (x, y) => (
          left: if x > 0 { .5pt } else { 0pt },
          right: 0pt,
          top: if y > 0 { .5pt } else { 0pt },
          bottom: 0pt,
        ),
        inset: 4.6pt, // otherwise the jedit side has a bad linebreak
        table.header([*jEdit State Panel*], [*VSCode State Panel*]),
        [
          #show raw: set text(font: "Isabelle DejaVu Sans Mono")

          #let blue2 = rgb(42, 100, 149) // used for goal

`proof (state)
`#text(blue2)[`goal`]` (4 subgoals):
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

          #let blue2 = rgb(160, 32, 211) // used for goal

`proof (state)
`#text(blue2)[`goal`]` (4 subgoals):
 1. ⋀Γ `#text(green)[`i`]`. Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval (Ic `#text(green)[`i`]`) `#text(blue)[`s`]`)
 2. ⋀Γ `#text(green)[`r`]`. Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval (Rc `#text(green)[`r`]`) `#text(blue)[`s`]`)
 3. ⋀Γ `#text(green)[`x`]`. Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval (V `#text(green)[`x`]`) `#text(blue)[`s`]`)
 4. ⋀Γ a1 τ a2. Γ ⊢ a1 : τ ⟹ (Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval a1 `#text(blue)[`s`]`)) ⟹ Γ ⊢ a2 : τ ⟹ (Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval a2 `#text(blue)[`s`]`)) ⟹ Γ ⊢ `#text(blue)[`s`]` ⟹ Ex (taval (Plus a1 a2) `#text(blue)[`s`]`)`
        ]
      )
    )
  },
  caption: [Comparison of #jedit State display and previous #vscode State display.],
  kind: table,
  placement: auto,
) <state-comparison>

=== Correct Formatting <correct-formatting>

Isabelle uses an internal module called `Pretty` to manage the formatting of content in state and output panels. Specifically, this module is responsible for adding line breaks and indentation to these outputs if the panels are not wide enough to display something in a single line. The language server did not use the `Pretty` module, meaning it was the client's responsibility to add correct line breaks, which #vscode did not do. Instead, it used its default word wrap line breaks.

==== Isabelle's Internal XML

Isabelle internally represents almost all content with untyped XML trees. An `XML.Body` is a list of `XML.Tree`, which can be an `XML.Text` containing some text or an `XML.Elem` containing some markup and a child body. Ultimately, the text of an `XML.Body` is determined exclusively through such `XML.Text` instances, essentially the leaves of XML trees. On the other hand, the markup portion of `XML.Elem` stores all kinds of semantic information Isabelle might need about its child body. This information can include what type of highlighting the text should have (e.g. `text_skolem` for Skolem variables), whether it is _active markup_ that should do something when the user clicks on it, or where to go when the user initiates a _Goto Definition_. These XML bodies are so fundamental to Isabelle's inner workings that even the theory code itself is XML internally.

Output panel content is also created as such an XML body. An Isabelle theory consists of many _commands_, each with some _command result_, which is an XML body. When the caret is above a command, the content of its command result is displayed on the output panel. State panel content is similarly just an XML body.

The `Pretty` module acts primarily on these XML bodies. There are two relevant functions within the module: `separate` and `formatted`. `separate` takes an XML body and adds an XML element with a separator markup between each tree in the body. `formatted` applies the aforementioned line breaks to the XML body, as such this function also requires knowledge about the width of the area the content should be displayed in, further referred to as the _margin_. To get correctly formatted panel output, as seen in @state-comparison, an XML body must first go through `separate` and then through `formatted`.

Lastly, Isabelle's `XML` module includes a `content` function, which reduces an XML body down into a string by stripping all tags.

==== Using `Pretty` for Isabelle/VSCode

The problem with supporting correct formatting of these panels to #vscode is that, for `Pretty` to correctly format some output, it needs to know the margin of the panel in question. In #jedit, this is not an issue since the #jedit UI and the `Pretty` module all exist within the same Scala codebase. With #vscode, a different solution is necessary.

Once again, there are several possibilities that we considered:
1. Rebuild the `Pretty` module within the VSCode extension.

2. Give access to the `Pretty` API through LSP messages.

3. Notify the language server about the current margin of each panel.

Option 1 would have required fundamentally changing the format in which the language client receives state and output content. Previously, the language client got HTML source that it could just display inside a WebView. While generating this HTML source, information stored within the XML body's markup was used to create highlighting and hyperlinks, allowing the user to click on some elements and be transported to their definition (e.g. for functions). For the language client to correctly format this content, it would need access to Isabelle's underlying XML instead. Such a change would have also required significantly more work for every Isabelle language client implementation and was thus not pursued.

Option 2 is promising because it allows a language client to use the `Pretty` module the same way #jedit would. However, the problem of requiring Isabelle's underlying XML content remains. Whenever the content of a panel were to change, the following would need to happen:
1. The language server sends the panel's XML body to the client.

2. The client then sends a #box[`Pretty/separate`] request to call the `Pretty` module's `separate` function on the XML body. The server calls said function and returns the resulting XML body to the client.

3. The client sends a #box[`Pretty/formatted`] request to the server, the server calls `formatted` and sends the result back.

4. The client sends an #box[`XML/content`] request to the server, and the server calls `content` and sends the result back.

In step 3, the client can easily send over the current panel's margin in its request, thus solving the original problem. This solution requires much work from the client and introduces several roundtrips for each panel. However, it also allows for the greatest flexibility for the client and gives a clear distinction between UI and logic. The language server exists exclusively for the internal Isabelle logic, while correctly displaying the internal information is the client's sole responsibility. Because of this, when the UI is modified, like changing the width of the output panel, only steps 4 and 5 need to be repeated. The language server does not need to be informed about the change in the UI, the panel's content does not need to be newly generated and sent to the client, and the client can handle exactly _when_ reformatting of the content is necessary.

Option 3 requires the least amount of work for the language client. For this option, the client only needs to inform the server about the current panel margin, and the server can decide entirely on its own whether a re-send of the panel's content is necessary. From the perspective of a language client, it is thus the simplest solution because the language server does all the actual output logic. Additionally, a client that does not notify the server about the correct margins may not have correct formatting but can still easily display the content, keeping the barrier of entry for a new Isabelle client prototype low.

Due to its simplicity, Option 3 is the option we chose to implement. To this end, a new #box[`Pretty_Text_Panel`] module was added to #vscode, which implements the output logic, as well as two new notifications: #box[`PIDE/output_set_margin`] and #box[`PIDE/state_set_margin`]. Both output and state internally save one such #box[`Pretty_Text_Panel`] and simply tell it to refresh whenever the margin or content has changed. The #box[`Pretty_Text_Panel`] can then decide for itself if the actual content has changed and only send the appropriate notification to the client if it did.

While this solution has worked well in practice, note that one has to be careful how to send these margin updates. In VSCode, for example, panel width can only be polled in pixels. The Isabelle language server, however, requires the margin to be in symbols, i.e., how many symbols currently fit horizontally into the panel. Since Isabelle symbols are not necessarily all monospaced, this instigates a unique problem: How do we measure symbol width? In #jedit, this is solved by using the test string "mix", measuring its width, and dividing that width by 3. Thus, we did the same in #vscode.

Additionally, we added a limit on how often the margin update notifications are sent. If we were to send this notification for every change in panel width, we would send a notification for every pixel, which is extremely wasteful. In Neovim, by its terminal-based nature, neither of these problems exist because all characters have the same width and the width of a Neovim window only exists within discrete character counts.

=== Correct Font

#jedit uses a variant of the _DejaVu Sans Mono_ #footnote[https://dejavu-fonts.github.io/] font called _Isabelle DejaVu Sans Mono_. This custom font can be built using the #box[`isabelle component_fonts`] Isabelle tool. It uses the _DejaVu Sans Mono_ fonts as a base and adds special Isabelle symbols, like #isabelle(`⟹`) and #isabelle(`Γ`) @font-email. As mentioned in @background:isabelle-vscode, part of the reason why #vscode adds custom patches on top of VSCodium is to add these fonts into the #vscode binary. That way, the user can use the _Isabelle DejaVu Sans Mono_ font family within buffers without needing to install these Isabelle fonts system-wide.

Unfortunately, these patched-in fonts are not available from within VSCode extensions, and the output and state panels in #vscode are handled by the Isabelle extension. Therefore, to support the correct fonts for the panels, we needed to additionally include the fonts into the extension.

The Isabelle VSCode extension is built with the #box[`isabelle components_vscode_extension`] tool. Aside from calling the relevant build systems to build the extension, this tool also generates static syntax definitions to support static syntax highlighting for the most common keywords in #isar. We extended this tool to additionally copy the _Isabelle DejaVu Sans Mono_ font family into the extension build directory and add them to the extension's manifest file to include them in the extension's build. With this newly augmented extension in place, we could refer to these fonts from within the appropriate panels, the result of which can be seen in @vscode1.

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
