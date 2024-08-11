#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

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
