#import "/utils/todo.typ": TODO

= Background
#TODO[Background]

== Language Server Protocol (LSP)

Before the introduction of the Language Server Protocol, it was customary for code editors to either only support syntax highlighting for its supported languages with very basic auto-completion and semantic understanding, or implement a full fletched IDE environment for the language. This system had a few problems:
- Smaller languages would either not be able to offer a full-IDE experience at all, or would ship with an IDE of its own.
- The configuration for one IDE is rarely compatible with the configuration of another. As such, developers using multiple languages would need to get used to multiple different IDE systems, or live without IDE-features.
- The idea of a truly polymorphic IDE, that could be used for any language, was virtually impossible.

The Language Server Protocol was meant to solve these problem by introducing one API describing how the semantics of a language are supposed to be communicated with a code editor.

The LSP consists of two main components: A language server and a language client. The language server is responsible for understanding the semantics of the language. It may be connected to a compiler, or it may have the language's logic built from the ground up, but either way, it is supposed to understand the types of values, when and why code does not compile, which functions are available in the current scope, and more. The language client on the other hand exists on the side of the code editor. It receives messages from the language server about the aforementioned list and converts these messages into GUI elements of the given code editor. The end goal is a system in which a new programming language only needs to implement a single language server, while a new code editor only needs to implement a single language client. In the best case scenario, any language server and language client can be used together (although in practice this is still not always the case). If we wanted to support $N$ programming languages for $M$ code editors, without the LSP we would need $N dot M$ implementations of language semantics and GUI translation layers. With the LSP, this number is reduced drastically to only $N$ implementations of language semantics and $M$ GUI translation layers.

#TODO[insert graphic (server <-> client)]

== Isabelle

Isabelle is a Proof Assistant

#TODO []

// = Background
// #TODO[
//   Describe each proven technology / concept shortly that is important to understand your thesis. Point out why it is interesting for your thesis. Make sure to incorporate references to important literature here.
// ]

// == e.g. User Feedback
// #TODO[
//   This section would summarize the concept User Feedback using definitions, historical overviews and pointing out the most important aspects of User Feedback.
// ]

// == e.g. Representational State Transfer
// #TODO[
//   This section would summarize the architectural style Representational State Transfer (REST) using definitions, historical overviews and pointing out the most important aspects of the architecture.
// ]

// == e.g. Scrum
// #TODO[
//   This section would summarize the agile method Scrum using definitions, historical overviews and pointing out the most important aspects of Scrum.
// ]
