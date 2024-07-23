#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

= Changes for both Language Server and Client

As mentioned in @isabelle-vscode, #vscode describes multiple Isabelle components working in cohort to support Isabelle within VSCode. As such, the work done on #vscode can be categorized on whether it deals with the language server, the language client (i.e. the VSCode extension), or both, the latter of which we will look at first.

== Decorations on File Switch

Previously, when switching theory within #vscode and then switching back, the dynamic syntax highlighting would not persist. It was possible to get the highlighting to work again by changing the buffer's content; however, until this was done, it never recovered by itself. This was a problem when working on multiple theory files.

To understand how #vscode does dynamic syntax highlighting, we will first take a look at the structure of the `PIDE/decoration` notifications: The `params` field of this method's Notifications has two components: A `uri` field with the relevant theory file's URI, and a list of decorations called `entries`. Each of these entries then consists of a `type` and a list of ranges called `content`. The `type` is a string identifier for an Isabelle decoration type. It includes things like `text_skolem` for Skolem variables and `dotted_warning` for things that have warnings associated and thus have a dotted underline. Each entry in the `content` list is another list of 4 integers describing the line start, line end, column start, and column end of the range the specified decoration type should be applied to.

Thus, an example `PIDE/decoration` message may look something like this:
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

Since this is not part of the standard LSP specification, a language client must implement a special handler for such decoration notifications. It was also not possible to explicitly request these decorations from the language server. Instead, the language server would send new decorations whenever it deemed necessary, e.g., because the caret moved into areas of the text that haven't been decorated yet or because the document's content has changed.

On the VSCode side, these decorations were applied via the `TextEditor.setDecoration` API function, which does not inherently cache these decorations on file switch. Thus, there were two ways to fix the above issue:
1. implement caching of decorations manually on the client side
2. add the ability to request new decorations from the server and do so on file switch

The main advantage of option 1 is performance. If the client handles caching of decorations, then the server won't have to calculate the decorations anew (which is a rather expensive operation within Isabelle), nor will another round of JSON Serialization and Deserialization have to happen. However, the trade-off is that more work needs to be done on the client side, making new client implementations for other editors potentially harder.

Because of this, we introduced a new `PIDE/decoration_request` notification, sent by the client to explicitly signal to the server that it should send a `PIDE/decoration` notification back no matter what. Note that this system is atypical for the LSP. The `PIDE/decoration_request` notification is semantically a request and intends a response from the server, yet from the perspective of the LSP, it is a unidirectional notification, while its response is also a unidirectional `PIDE/decoration` notification.

The reason for this is twofold: There was already precedent for such behavior in the Isabelle language server, specifically with `PIDE/preview_request` and `PIDE/preview_response` notifications. Secondly, the `PIDE/decoration` notification is not only sent after a request. The original automatic sending behavior that existed before is still present and was not altered. If we were to implement `PIDE/decoration_request`s as an LSP request instead, this would only result in extra implementation work on the client side because a client would need to implement the same decoration application logic for both the `PIDE/decoration` notification and the `PIDE/decoration_request` response. By defining `PIDE/decoration_request`s as notifications, the client only needs to implement a singular handler for `PIDE/decoration` notifications and covers both scenarios simultaneously.

Later on, we found that client-side caching was already implemented for the Isabelle VSCode extension; however, incorrectly so. The caching was done via a Typescript `Map`, with files as keys and the content list from the decoration messages as values. For the keys, the specific value used was of type `URI`, which does not explicitly implement an equality function, thus resulting in an inconsistent equality check where two URIs pointing to the same file may not have been the same URI in Typescript-land. Switching the key to using String representations of the URIs fixed the issue. However, we decided to keep the `PIDE/decoration_request` notification. While it may not be in use by #vscode directly, other Isabelle language client implementations may make use of this functionality.

// #TODO[
//   - currently breaks when switching files/tabs
//   - originally solved by implementing decoration request and requesting them every time we switch file/tab
//   - later found that client-side caching was implemented, but used URI as key instead of URI strings which didn't work
//   - decoration request kept in, in case a different client needs it (Foreshadowing to Sublime Text implementation which used it)
// ]

== Panel Margin Handling

=== Server

#TODO[
  - new introduction of Pretty Panel module
  - manages the formatting of output, including extracting the decorations if HTML is disabled
  - now client can send margins for both state and output panels
    - pretty panel manages if new message needs to be sent or not (i.e. if output has actually changed)
]

=== Client

#TODO[
  - "mix" as test string for symbol sizes, same as in jEdit
  - send with a timeout, otherwise there is a message for every pixel
  - add headroom
]

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
