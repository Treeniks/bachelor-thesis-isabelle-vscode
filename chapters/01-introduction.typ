#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

= Introduction

In 1911, Alwin Korselt @intro-korselt1911 showed that Ernst Schröder's proof of the Cantor-Bernstein-Schröder theorem, originally published in 1898 @intro-schroder1898, contained an error. While the theorem was correct, and other proofs of this theorem existed even back then, this isn't the only instance where mathematicians tried to proof a statement, thought they conceived such proof and later found that the proof was incorrect or incomplete. Thus, there exist software tools called proof assistants which allow one to formalize mathematical proofs and have the computer check for the proof's correctness. One such tool is _Isabelle_ #footnote[https://isabelle.in.tum.de/], originally developed at the _University of Cambridge_ and _Technical University of Munich_ @paulson-natural-deduction.

To interact with the Isabelle system, the Isabelle distribution bundles the #jedit code editor @manual-jedit, a modified version of the Java-based code editor _jEdit_ #footnote[https://www.jedit.org/]. Through that, the user is offered a fully interactive Isabelle session, in which proofs are written and checked in real-time. However, #jedit has many accessibility shortcomings. To tackle this problem, #vscode was built to create support for Isabelle from within the popular code editor _Visual Studio Code_ utilizing the _Language Server Protocol_ #footnote[https://microsoft.github.io/language-server-protocol/] (or _LSP_ for short) @markarius-isabelle-vscode.

This protocol was originally developed by Microsoft specifically for VSCode. It consists of two main components: A language _server_, responsible for understanding the language on a semantic level, and a language _client_, which is typically the code editor itself. Later, the protocol became a standardized specification and is now widely used by many different programming languages and code editors to more easily support IDE functions like completions and diagnostics.

Unfortunately, the current state of #vscode is not on par with the experience of #jedit. There are issues with usability, missing features, and the underlying language server lacks the necessary capabilities to support the development of an Isabelle language client for another code editor. The goal of this thesis is to tackle these problems, thus bringing #vscode closer to the experience of #jedit and improve and extend the language server.

#TODO[
  Roter Faden: Can a general language server even be built, or must it always be a specific implementation? What are the challenges, what are its solutions?

  Potentially introduce Fabian's system:
  - Problem
  - Solutions
  - Contributions
]

== Motivation

Prior to this work, I attempted to build a language client for the terminal-based code and text editor _Neovim_ #footnote[https://neovim.io/]. However, it quickly became apparent that the existing language server was not sufficient. For example, the language server used to only send the content of certain panels in an HTML format. This makes it easy for an Electron-based editor like VSCode, which runs on the Chromium browser engine, allowing the editor to effortlessly and natively display HTML. It is, however, not reasonably possible to display HTML content from within a terminal-based editor like Neovim, meaning an option to get non-HTML output was required.

Because of this, it was virtually impossible to build such a language client with the official Isabelle language server. Instead, I used the unofficial Isabelle fork `isabelle-emacs` #footnote[https://github.com/m-fleury/isabelle-emacs], which includes many advancements to the Isabelle language server and fixes some of its issues in order to support the _Emacs_ #footnote[https://www.gnu.org/software/emacs/] code editor. This fork enabled a usable Neovim Isabelle environment #footnote[https://github.com/Treeniks/isabelle-lsp.nvim/tree/0b718d85fd4589d27638877f8955bedb93f56738], e.g. by offering the aforementioned non-HTML output option, but there were still many missing features compared to #jedit. Still, the `isabelle-emacs` fork was a strong inspiration for some of the changes done in the context of this thesis.

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
