#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

== State Panel IDs <state-init>

As mentioned in @background:output-and-state-panels, it is possible to open multiple state panels in #jedit. While users typically want to see the proof state at the position of their caret, there may be cases where one wants to permanently see the proof state at a different position.

The language server already supported multiple state panels (although not multiple output panels). Internally, the language server stores a `Map` from IDs to state panels. Additionally, all state-related messages must include the ID of the panel that they are referring to. For example, to disable the _Auto update_ property
#footnote[The _Auto update_ property enables automatic updating of the panel's content to the caret position. If disabled, moving the caret will not change the panel's content and will only update if the user issues a manual _Update_ command.]
of a state panel, the client needs to send a `PIDE/state_auto_update` notification with an `id` and `enabled` field.

When starting the Isabelle language server, it does not automatically initialize a state panel. The client has to send a `PIDE/state_init` notification to create a state panel. However, the client can not define the state panel's ID within this notification. Instead, the server used the Isabelle internal `Counter` module to create a unique state panel ID.

In order to keep these IDs separate between #ml and #scala, this module counts in ascending order in ML and descending order in Scala. Since the language server is part of #scala, the state panel's IDs start at $-1$ and count downward with each newly created state panel. This in and of itself is not a problem; the problem was that the language server did not communicate the created IDs with the language client. Thus, the language client had to know the internal Isabelle language server ID creation logic. Furthermore, if that logic ever changes in the future, the client would need to be updated with it.

To eliminate this issue, we changed the `PIDE/state_init` message from a notification to a request. Now, when the client sends a `PIDE/state_init` request, the server sends a response back that includes the state ID of the newly created state panel. That way, we were able to decouple and future-proof the internal language server logic from the language client implementation.

An important thing to note is that #vscode does not support multiple state panels. While the underlying language server supports them, the Isabelle VSCode language client only supports a single state panel, therefore necessitating further work in this area.

// #TODO[
//   - originally State Init would expect the client to know what ID it is
//   - VSCode implmentation never used the ID for anything itself
//   - now is a request instead of a notification which returns the newly created ID
// ]
