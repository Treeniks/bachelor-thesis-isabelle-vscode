#import "/utils/todo.typ": TODO

= Introduction
// #TODO[
//   Introduce the topic of your thesis, e.g. with a little historical overview.
// ]

There are many examples where mathematicians tried to proof a statement, thought they found a proof and later found that the proof was incorrect or incomplete. Thus, there are systems like #emph[Isabelle] which allow one to write proofs in a language not dissimilar to programming langauges and then let the computer check if the proof is correct. These systems are colloqially known as #emph[Proof Assistants], or #emph[PA]s for short. To interact with the underlying prover logic, Isabelle offers an altered version of the #emph[JEdit] code editor called #emph[Isabelle/JEdit]. This editor gives access to a fully interactive Isabelle session, in which proofs are evaluated and checked in real-time.

However, Isabelle/JEdit, while the primary interaction method for Isabelle, has many accessibility and extensibility issues. Thus, #emph[Isbelle/VSCode] was built to have support for the Isabelle PA from within the popular code editor #emph[Visual Studio Code] utilizing the #emph[Language Server Protocol].

Before the introduction of the Language Server Protocol (or #emph[LSP] for short), it was customary for code editors to either only support syntax highlighting for its supported languages with very basic auto-completion and semantic understanding, or implement a full fletched IDE environment for the language. This system had a few problems:
- Smaller languages would either not be able to offer a full-IDE experience at all, or would ship with an IDE of its own.
- The configuration for one IDE is rarely compatible with the configuration of another. As such, developers using multiple languages would need to get used to multiple different IDE systems, or live without IDE-features.
- The idea of a truly polymorphic IDE, that could be used for any language, was virtually impossible.

The Language Server Protocol was meant to solve these problem by introducing one API describing how the semantics of a language are supposed to be communicated with a code editor.

The LSP consists of two main components: A language server and a language client. The language server is responsible for understanding the semantics of the language. It may be connected to a compiler, or it may have the language's logic built from the ground up, but either way, it is supposed to understand the types of values, when and why code does not compile, which functions are available in the current scope, and more. The language client on the other hand exists on the side of the code editor. It receives messages from the language server about the aforementioned list and converts these messages into GUI elements of the given code editor. The end goal is a system in which a new programming language only needs to implement a single language server, while a new code editor only needs to implement a single language client. In the best case scenario, any language server and language client can be used together (although in practice this is still not always the case). If we wanted to support $N$ programming languages for $M$ code editors, without the LSP we would need $N dot M$ implementations of language semantics and GUI translation layers. With the LSP, this number is reduced drastically to only $N$ implementations of language semantics and $M$ GUI translation layers.

Unfortunately, Isabelle/VSCode it was insufficient at providing an experience comparable to that of Isabelle/JEdit. There were many issues with usability, as well as many missing features that are available in Isabelle/JEdit but were missing from Isabelle/VSCode. The goal of this thesis is to bring Isabelle/VSCode closer to the experience of Isabelle/JEdit, i.e. to introduce some of those missing features and tackle the usability problems.

Another problem with Isabelle/VSCode was that the underlying language server did not offer a full enough feature set for it to be usable from within other editors outside of VSCode. The nature of Isabelle's interactive sessions is fundamentally too complex to fit into the LSP's default protocols, making it impossible to create a plug-in language server implementation that works out of the box. There was always going to be work needed on the client side. Even still, the offered extra APIs by Isabelle/VSCode were not enough to reliably implement a working language client.

== Problem
#TODO[
  Describe the problem that you like to address in your thesis to show the importance of your work. Focus on the negative symptoms of the currently available solution.
]

== Motivation

The original motivation behind extending Isabelle/VSCode was that I tried to implement a language client for the terminal-based code and text editor #emph[Neovim]. However, I quickly discovered that the existing language server was not sufficient. For example, originally, the language server would only send the content of Dynamic and State Outputs in an HTML format. This is great for an Electron-based editor like VSCode, which runs on an underlying V8 Javascript and HTML engine, allowing the editor to effortlessly and natively display HTML. This is obviously not possible from within a terminal-based editor like Neovim, meaning an option to get pure non-HTML text was required, which creates new problems such as how to achieve color highlighting within these panels.

As a temporary workaraound, the Isabelle fork `isabelle-emacs` was used, which includes many advancements to the Isabelle language server in order to support eh #emph[Emacs] code editor. With this fork, a fully working Neovim Isabelle implementation was achievable, however it still had many usability issues that needed to be addressed.

== Objectives

Before starting work on the language server, a list of additions and changes required was compiled beforehand:

- fix change_document
- add Isabelle Extension settings into VSCode (Language Server CLI flags)
- decorations
    - remove necessity on static highlighting (e.g. decorate theorem keyword dynamically)
    - ability to request decorations to be sent explicitly from client
    - dynamic decoration radius (named caret perspective)
- state and dynamic output
    - overhaul how state panels are created (e.g. IDs handling)
    - handling width of state/output window
    - option to send output/state in non-HTML (with decorations)
    - option to merge state and output into one message/panel
- completion
    - dynamic symbol auto-completion (e.g. \<gamma>)
    - keyword completion (e.g. theorem)
- (maybe) add message to request all current dynamic symbol replacements (\<gamma> => γ)
- active markup (w/ LSP actions?)
    - (maybe) rename variables etc.

Over the course of the work, some of these features were discovered to already exist or not require changing and new problems came up that were added.

// == Outline
// #TODO[
//   Describe the outline of your thesis
// ]
