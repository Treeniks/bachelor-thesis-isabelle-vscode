#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

= Introduction

There are many examples where mathematicians tried to proof a statement, thought they conceived such proof and later found that the proof was incorrect or incomplete. #TODO[maybe introduce with an example instead] Thus, there exist software tools called proof assistants which allow one to write proofs in a language not dissimilar to a programming langauge and have the computer check for the proof's correctness. One such tool is _Isabelle_, originally developed at the _University of Cambridge_ and _Technical University of Munich_.

To interact with the Isabelle system, the Isabelle distribution bundles the #jedit code editor, a modified version of the Java-based code editor _JEdit_. Through that, the user is offered a fully interactive Isabelle session, in which proofs are evaluated and checked in real-time. However, #jedit has many accessibility and extensibility issues. To tackle this problem, #vscode was built to create support for Isabelle from within the popular code editor _Visual Studio Code_ utilizing the _Language Server Protocol_ (or _LSP_ for short).

This protocol was originally developed by Microsoft specifically for VSCode. It consists of two main components: A language _server_, responsible for understanding the language on a semantic level, and a language _client_, which is typically the code editor itself. Later, the protocol became a standardized specification and is now widely used by many different programming languages and code editors to more easily support IDE functions like completions and diagnostics.

Unfortunately, #vscode was insufficient at providing an experience comparable to that of #jedit. There were both issues with usability, as well as missing features. Another problem was that the underlying language server was not powerful enough to make an Isabelle language client implementation for another code editor viable. The goal of this thesis is to tackle both of these problems, thus bringing #vscode closer to the experience of #jedit and improve and extend the language server, such that building Isabelle support for a new code editor becomes possible.

== Motivation

The original motivation was an attempt at building a language client for the terminal-based code and text editor _Neovim_. It was quickly apparent that the existing language server was not sufficient. For example, the language server used to only send the content of certain panels in an HTML format. This is great for an Electron-based editor like VSCode, which runs on the Chromium browser engine, allowing the editor to effortlessly and natively display HTML. This is not possible from within a terminal-based editor like Neovim, meaning an option to get non-HTML text was required.

As a temporary workaround, the Isabelle fork `isabelle-emacs` was used, which includes many advancements to the Isabelle language server in order to support the _Emacs_ code editor. Based on this fork, a working Neovim Isabelle environment was achievable, but there were still many missing features compared to #jedit. The `isabelle-emacs` fork was thus a strong inspiration for some of the changes done in the context of this thesis.

// == Objectives
//
// A list of additions and changes required was compiled beforehand.
//
// - fix change_document
// - add Isabelle Extension settings into VSCode (Language Server CLI flags)
// - decorations
//   - remove necessity on static highlighting (e.g. decorate theorem keyword dynamically)
//   - ability to request decorations to be sent explicitly from client
//   - dynamic decoration radius (named caret perspective)
// - state and dynamic output
//   - overhaul how state panels are created (e.g. IDs handling)
//   - handling width of state/output window
//   - option to send output/state in non-HTML (with decorations)
//   - option to merge state and output into one message/panel
// - completion
//   - dynamic symbol auto-completion (e.g. \<gamma>)
//   - keyword completion (e.g. theorem)
// - (maybe) add message to request all current dynamic symbol replacements (\<gamma> => γ)
// - active markup (w/ LSP actions?)
//   - (maybe) rename variables etc.
//
// Over the course of the work, some of these features were discovered to already exist or not require changing and new problems came up that were added.
