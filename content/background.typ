#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

#import "@preview/cetz:0.2.2"

= Background

== Isabelle

Isabelle's core implementation languages are _ML_ and _Scala_. Generally speaking, the ML code is responsible for Isabelle's backend, i.e. the core logic, while Scala is responsible for Isabelle's frontend, i.e. everything to do with the UI and IO. Many modules within the Isabelle code base exist identically in both Scala and ML. That way, there exists an almost seamless transition between the two.

Scala, being a JVM based programming language, also effortlessly integrates into JEdit's Java code base. When using #jedit, Isabelle is able to offer an interactive session with no clear cut between what is UI and what is the underlying Isabelle logic. The entire Isabelle system has direct access to any data JEdit may hold, and the same is true the other way around. For example, #jedit has a feature to automatically indent parts of or an entire Isabelle theory. Internally, this automatic indentation uses both access to the Isabelle backend and the JEdit buffer at the same time.

Additionally, Isabelle, being a proof assistant, does not follow conventional programming language wisdom. For the sake of keeping correctness, the actual Isabelle core is kept small (albeit with performance related additions). Much of Isabelle's systems are built within Isabelle itself, including a majority of its syntax. Keywords such as `theorem` do not exist statically, but are instead defined in `Pure.thy`, and it is thus also possible to extend this syntax if needed. When editing a theory in #jedit, the actual syntax highlighting is done mostly dynamically.

=== Isabelle Output and State Panels

#figure(
    image("/figures/jedit1.png", width: 80%),
    caption: [JEdit with both _Output_ and _State_ panels open. _Output_ on the bottom, _State_ on the right.],
    // placement: auto,
)

Isabelle has a few different types of panels which give crucial information to the user. The two most important of such panels are the _Output_ panel and _State_ panels. The point of the _Output_ panel is to show messages that correspond to a given command, which can include general information, warnings or errors. This also means, that the content of the _Output_ panel is directly tied to a specific command in the theory. The command is typically determined by the current position of the caret.

_State_ panels on the other hand display the current internal proof state within a proof. While there can only be one _Output_ panel, it is possible to have multiple _State_ panels open, which may show states at different positions within the document. Whether or not moving the caret updates the currently displayed _Output_ or _State_ depends on the _Auto update_ setting of the respective panel.

=== Isabelle's Symbols

Isabelle uses a lot of custom symbols to allow logical terms to be written in a syntax much closer to that of mathematics. The concept of what an _Isabelle symbol_ is exactly is rather broad, so for simplicity we will focus primarily on a certain group of symbols typically used in mathematical formulas.

Each Isabelle symbol roughly consists of the following data:
- an ASCII representation of the symbol
- a name
- an optional unicode codepoint
- a list of abbreviations for this symbol

These 4 points are not the whole story, however for the sake of this thesis, we will ignore some details.

As an example, let's say you write the implication $A ==> B$ in Isabelle. Within JEdit, you will see it written out as "#isabelle[A ⟹ B]", however internally the "#isabelle[⟹]" is an Isabelle symbol with the following data:
- ASCII representation: "`\<Longrightarrow>`"
- name: "`Longrightarrow`"
- unicode codepoint: `0x27F9`
- abbreviations: "`.>`", "`==>`"

To deal with these symbols, #jedit uses a custom encoding called /* to prevent hyphenation */ #box(emph["UTF-8-Isabelle"]). This encoding ensures that the user sees "#isabelle[A ⟹ B]" while the actual content of the underlying file is "`A \<Longrightarrow> B`". However, because Isabelle internally uses its own abstracted representation of symbols, it has no trouble dealing with cases where the actual
"#isabelle[⟹]" unicode symbol is used within a file.

=== Isabelle/VSCode

#figure(
    image("/figures/vscode1.png", width: 80%),
    caption: [VSCode with both _Output_ and _State_ panels open. _Output_ on the bottom, _State_ on the right.],
    // placement: auto,
)

Isabelle nowadays consists of many different components. #jedit is one such component. When we refer to #vscode, we are actually referring to three different Isabelle components: The Isabelle _language server_, Isabelle's own patched _VSCodium_ and the VSCode _extension_ binding the two together. Note in particular that when running #vscode, Isabelle does not actually use a standard distribution of VSCode. Instead, it is a custom VSCodium package. VSCodium is a fully open-source version distribution of Microsoft's VSCode with some patches to disable certain types of internal telemetry as well as replacing the VSCode branding with that of VSCodium.

Isabelle adds its own patches on top of VSCodium, in order to to add a custom encoding mimicking the functionality of #jedit. As such, when loading a theory file in #vscode, the user again will see "#isabelle[A ⟹ B]", while the file itself is loaded and saved as "`A \<Longrightarrow> B`".

The concept of _Output_ and _State_ panels exist equivalently within #vscode, although it is not possible to create multiple _State_ panels for reasons outlined in @state-init.

== Language Server Protocol (LSP)

Before the introduction of the Language Server Protocol, it was customary for code editors to either only support syntax highlighting for its supported languages with very basic auto-completion and semantic understanding, or implement a full fletched IDE environment for the language. The idea of a truly polyglot IDE was virtually impossible.

Now, the responsibility of semantic understanding of the language has moved entirely to the language server, while the language client is responsible only for handling user interaction.

The goal is a system in which a new programming language only needs to implement a single language server, while a new code editor only needs to implement a single language client. In the best case scenario, any language server and language client can be used together (although in practice this is still not always the case). If we wanted to support $N$ programming languages for $M$ code editors, without the LSP we would need $N dot M$ implementations of language semantics. With the LSP, this number is reduced drastically to only $N$ implementations of language semantics.

// #figure(
//     cetz.canvas({
//         import cetz.draw: *
//
//         rect((0, 0), (2.5, 1), name: "client", radius: 10pt)
//         content("client", align(center)[Client\ (e.g. Editor)])
//
//         rect((7, 0), (9.5, 1), name: "server", radius: 10pt)
//         content("server", [Server])
//
//         line("client.east", "server.west", name: "connection", mark: (symbol: "stealth"))
//         content("connection.mid", align(center)[jsonrpc 2.0\ connection], frame: "rect", stroke: none, fill: white, padding: .1)
//
//         line((rel: (0, -1), to: "client.east"), (rel: (0, -1), to: "server.west"), name: "connection2", mark: (end: (symbol: "stealth")))
//         content((rel: (0, .2), to: "connection2.mid"), [`initialize` request])
//
//         line((rel: (0, -2), to: "client.east"), (rel: (0, -2), to: "server.west"), name: "connection3", mark: (start: (symbol: "stealth")))
//         content((rel: (0, .2), to: "connection3.mid"), [`initialize` response])
//
//         line((rel: (0, -3), to: "client.east"), (rel: (0, -3), to: "server.west"), name: "connection4", mark: (end: (symbol: "stealth")))
//         content((rel: (0, .2), to: "connection4.mid"), [`initialized` notification])
//     }),
// )

The general setup is quite simple: The client and server communicate via `jsonrpc 2.0` messages. These messages are mostly either of 3 types:
- _Notification Messages_
- _Request Messages_
- _Response Messages_

_Notification Messages_ are messages that, as the name suggest, only exist to notify the other party. They must not send a response back. _Request Messages_ are requests sent to the other party and require a _Response Message_ to be sent back once the request has been processed. The structure of these message types is also defined within the LSP Specification:
#align(center,
    // box to prevent pagebreak in the middle of the table
    box(table(
        columns: 3,
        // fill: (x, y) => if y == 0 { gray },
        stroke: (x, y) => (
            left: if x > 0 { .5pt } else { 0pt },
            right: 0pt,
            top: if y == 1 { .5pt } else { 0pt },
            bottom: 0pt,
        ),
        align: left,
        table.header([*Notification*], [*Request*], [*Response*]),
        [ jsonrpc: string ],
        [ jsonrpc: string ],
        [ jsonrpc: string ],
        [],
        [ id: integer | string; ],
        [ id: integer | string | null; ],
        [ method: string; ],
        [ method: string; ],
        [ result?: Any; ],
        [ params?: array | object; ],
        [ params?: array | object; ],
        [ error?: ResponseError; ],
    ))
)

The _jsonrpc_ entry of every message is, at the time of writing, always set to "_2.0_". The _id_ of the Request is sent in order to identify the associated response, thus the _id_ in a Response Message must also be set appropriately. The _params_, _result_ and _error_ entries' shape all depend on the type of Notification/Request/Response sent. This type is specified within the _method_ entry, which is the most important for now.

There are many different #emph[method]s. For example, messages dealing with text documents are sent under the #box["`textDocument/`"] method prefix, like the #box["`textDocument/hover`"] request which requests for hover information, or the #box["`textDocument/didChange`"] notification, sent by the client to keep the server informed about changes made to the document's text.

=== Initialization

Because of the LSP's server/client system, it is technically possible to use an externally running language server. Even so, in practice the server is typically started by the IDE in question.

The first message exchanged between client and server is an #box["`initialize`"] request sent by the client. The client has to wait for the server to respond to this request before sending any other messages, and finally sends an #box["`initialized`"] notification to mark the initialization complete once the server's response has arrived.

#figure(
    cetz.canvas({
        import cetz.draw: *
        let r = 7
        let m = (symbol: "stealth")

        line((0, 0), (0, -3), name: "client")
        content((rel: (0, .2), to: "client.start"), align(center)[Client\ (e.g. Editor)], anchor: "south")

        line((r, 0), (r, -3), name: "server")
        content((rel: (0, .2), to: "server.start"), align(center)[Server], anchor: "south")

        // content((r / 2, .2), align(center)[jsonrpc 2.0\ connection], anchor: "south")

        // line((1.5, .2), (r - 1.5, .2), name: "connection", mark: (symbol: "stealth"))
        // content("connection.mid", align(center)[jsonrpc 2.0\ connection], frame: "rect", stroke: none, fill: white, padding: .1)

        line((0, -.5), (r, -.5), name: "connection2", mark: (end: m))
        content((rel: (0, .2), to: "connection2.mid"), [`initialize` request])

        line((0, -1.5), (r, -1.5), name: "connection3", mark: (start: m))
        content((rel: (0, .2), to: "connection3.mid"), [`initialize` response])

        line((0, -2.5), (r, -2.5), name: "connection4", mark: (end: m))
        content((rel: (0, .2), to: "connection4.mid"), [`initialized` notification])
    }),
    caption: [LSP Initialization],
    // placement: auto,
) <lsp-init>

What's important for us is that during this back and forth, within the `initialize` request and response, the client and server send each other client and server capabilities respectively. These capabilities describe which features of the LSP the client or server actually supports. For example, not every server supports completions, and even if it does, there is further information needed, like which characters should automatically request completions. By exchanging the capabilities this early on, the client and server can exclude certain parts of messages or even skip sending some entirely, preventing expensive JSON Serialization and Deserialization for messages that the other party cannot deal with anyway.

=== Isabelle's Language Server

While the LSP defines most methods required for typical language server usecases, specific language servers may also extend the basic protocol by their own methods. In such cases, the corresponding client will need to define extra handlers for these new methods.

Through Isabelle's interactive nature, the standard Language Server Protocol is not strong enough to represent everything Isabelle needs. For example, in order to keep the _Output_ and _State_ panels updated, the server needs to know the current location of the caret at all times. This is not a typical need for language servers of normal programming languages and is thus not build into the protocol by default.

Isabelle thus extends the LSP with its own methods under the #box["`PIDE/`"] prefix, which have to be enabled with the #box["`vscode_pide_extensions`"] Isabelle option. For example, here are 3 such methods:
1. "`PIDE/caret_update`": A bidirectional notification for telling the other party that the caret has been moved. Mostly sent from the client to the server.
2. "`PIDE/dynamic_output`": A notification sent from the server to the client containing the current content of the _Output_ panel.
3. "`PIDE/decoration`": A notification sent from the server to the client containing information on the dynamic syntax highlighting within the current theory.

There are many more of the sort. As a result, unlike most language servers, one cannot simply start the Isabelle language server from within an existing language client and expect everything to work. There is an unusual amount of extra work that needs to be done on the client side before an IDE can utilize the Isabelle language server.

