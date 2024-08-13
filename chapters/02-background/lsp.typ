#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

#import "@preview/cetz:0.2.2"

== Language Server Protocol (LSP)

Before the introduction of the Language Server Protocol, it was common for code editors to either only support syntax highlighting for its supported languages with very basic auto-completion and semantic understanding, or implement a full-fledged IDE for the language.

Now, the responsibility of semantic understanding of the language has moved entirely to the language server, while the language client is responsible for handling user interaction.

The goal is a system in which a new programming language only needs to implement a single language server, while a new code editor only needs to implement a single language client. In the best case scenario, any language server and language client can be used together (although in practice this is still not always the case). If we wanted to support $N$ programming languages for $M$ code editors, without the LSP we would need $N dot M$ implementations of language semantics. With the LSP, this number is reduced drastically to only $N$ language server and $M$ language client implementations.

#cite(form: "prose", <lsp-spec>) describes the general setup: The client and server communicate via #box[`jsonrpc 2.0`] messages. The three primary message types are:
- _Notification Messages_
- _Request Messages_
- _Response Messages_

As the name suggests, notification messages are messages that only exist to notify the other party. They must not send a response back. Requests are sent to the other party and require a response message to be sent back once the request has been processed. The structure of these message types is also defined within the LSP specification and can be seen in @lsp-message-structure.

#figure(
  {
    set raw(lang: "ts")
    table(
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
      [ `jsonrpc: string` ], [ `jsonrpc: string` ], [ `jsonrpc: string` ],
      [], [ `id: integer | string` ], [ `id: integer | string | null` ],
      [ `method: string` ], [ `method: string` ], [ `result?: Any` ],
      [ `params?: array | object` ], [ `params?: array | object` ], [ `error?: ResponseError` ],
    )
  },
  caption: [General LSP message structure.],
  kind: table,
  // placement: auto,
) <lsp-message-structure>

At the time of writing, The `jsonrpc` entry of every message is always set to "`2.0`". The `id` of the request is sent in order to identify the associated response, thus the `id` in a response message must also be set appropriately. The `method` entry is an identifier for the _kind_ of message at hand and dictates the shape of the `params`, `result` and `error` entries, which in turn contain the primary data of the message.

There are many different _methods_. For example, messages dealing with text documents are sent under the #box["`textDocument/`"] method prefix, like the #box["`textDocument/hover`"] request which requests for hover information, or the #box["`textDocument/didChange`"] notification, sent by the client to keep the server informed about changes made to the document's text.

=== Initialization <back:lsp-initialization>

Because of the LSP's server/client system, it is technically possible to use an externally running language server. Even so, in practice the server is typically started by an IDE.

The first message exchanged between client and server is an #box["`initialize`"] request sent by the client. The client has to wait for the server to respond to this request before sending any other messages, and finally sends an #box["`initialized`"] notification to mark the initialization complete. This handshake is illustrated in @lsp-init.

#figure(
  cetz.canvas({
    import cetz.draw: *
    let r = 7
    let m = (symbol: "stealth")

    line((0, 0), (0, -3), name: "client")
    content((rel: (0, .2), to: "client.start"), align(center)[Client\ (e.g. Editor)], anchor: "south")

    line((r, 0), (r, -3), name: "server")
    content((rel: (0, .2), to: "server.start"), align(center)[Server], anchor: "south")

    line((0, -.5), (r, -.5), name: "connection2", mark: (end: m))
    content((rel: (0, .2), to: "connection2.mid"), [`initialize` request])

    line((0, -1.5), (r, -1.5), name: "connection3", mark: (start: m))
    content((rel: (0, .2), to: "connection3.mid"), [`initialize` response])

    line((0, -2.5), (r, -2.5), name: "connection4", mark: (end: m))
    content((rel: (0, .2), to: "connection4.mid"), [`initialized` notification])
  }),
  caption: [Visualization of the LSP initialization handshake.],
  kind: image,
  // placement: auto,
) <lsp-init>

Similarly to exchanging cipher suites in a TLS handshake, within the `initialize` request and response, the client and server send each other their capabilities. These capabilities describe which features of the LSP the client or server actually supports. For example, not every server supports completions, and even if it does, there is further information needed, like which characters should automatically request completions. By exchanging the capabilities this early on, the client and server can exclude certain parts of messages or even skip sending some entirely, preventing expensive JSON Serialization and Deserialization for messages that the other party cannot handle anyway.

=== Isabelle Language Server

While the LSP defines most methods required for typical language server use cases, specific language servers may also extend the basic protocol by their own methods. In such cases, the corresponding client will need to define extra handlers for these new methods.

Since the standard Language Server Protocol is designed for normal programming languages in mind, it defines little for other types of languages, particularly theorem provers @lsp-spec-extension, and is thus insufficient for Isabelle's needs. For example, in order to keep the output and state panels updated, the server needs to know the current location of the caret at all times. This is not a typical need for language servers of normal programming languages and is thus not built into the protocol by default.

Isabelle therefore extends the LSP with its own methods under the #box["`PIDE/`"] prefix, which have to be enabled with the #box["`vscode_pide_extensions`"] Isabelle option. For example, here are 3 such methods:
1. "`PIDE/caret_update`": A bidirectional notification for telling the other party that the caret has been moved. Mostly sent from the client to the server.

2. "`PIDE/dynamic_output`": A notification sent from the server to the client containing the current content of the output panel.

3. "`PIDE/decoration`": A notification sent from the server to the client containing information on the dynamic syntax highlighting within the current theory.

There are several more of these methods. As a result, unlike most language servers, the Isabelle language server cannot be started from within an existing language client with the expectation that it will function correctly. There is significant additional work that needs to be done on the client side before an IDE can utilize the Isabelle language server.
