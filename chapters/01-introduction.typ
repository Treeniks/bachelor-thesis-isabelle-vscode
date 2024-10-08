#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

= Introduction

In 1911, #cite(<korselt1911>, form: "prose") showed that Ernst Schröder's proof of the Cantor-Bernstein-Schröder theorem, initially published in 1898 @schroder1898, contained an error. While the theorem was correct, and other proofs of this theorem existed even back then @dedekind1887, this is not the only instance where mathematicians tried to prove a statement, thought they conceived such proof, and later found that the proof was incorrect or incomplete. Proof assistants were developed to alleviate this issue by allowing one to formalize mathematical proofs and have the computer check for the proof's correctness. One such tool is _Isabelle_ #footnote[https://isabelle.in.tum.de/], originally developed at the _University of Cambridge_ and _Technical University of Munich_.

To interact with the Isabelle system, the Isabelle distribution bundles the #emph(jedit) code editor @manual-jedit, a modified version of the Java-based code editor _jEdit_ #footnote[https://www.jedit.org/]. Through that, the user is offered a fully interactive Isabelle session, in which proofs are written and checked in real time. However, #jedit has many accessibility shortcomings, like missing a dark theme. To tackle this problem, #emph(vscode) was built to create support for Isabelle from within the popular code editor _Visual Studio Code_ utilizing the _Language Server Protocol_ #footnote[https://microsoft.github.io/language-server-protocol/] (_LSP_) @markarius-isabelle-vscode-2017 @accessibility-vscode.

This protocol was originally developed by Microsoft specifically for VSCode. It consists of two main components: A language _server_, responsible for understanding the language on a semantic level, and a language _client_, which is typically the code editor itself. Later, the protocol became a standardized specification and is now widely used by many different programming languages and code editors to more easily support IDE functions like completions and diagnostics.

Unfortunately, the current state of #vscode is not on par with the experience of #jedit. There are issues with usability and missing features. Additionally, the underlying language server lacks the necessary capabilities to support the development of an Isabelle language client for another code editor.

To combat these deficiencies, we will identify the various aspects of the current #vscode that need improvement and evaluate potential solutions to enhance its functionality. Given that Isabelle's design is often fundamentally incompatible with the LSP specification, the primary question throughout this endeavor is whether the existing LSP spec can be utilized to fit Isabelle's unique requirements, whether a completely custom solution needs to be built for each language client, or whether there is a middle ground in which the language server can take over much of the work, but custom handlers for the client are still necessary.

We will consider two primary metrics for these solutions: How closely they resemble #jedit and how universally applicable it is to other language clients. The former ensures consistency within the broader Isabelle system, while the latter facilitates integration with new language clients.

The primary contribution of this thesis is the implementation of several such solutions to create a more flexible language server, reducing Isabelle's reliance on jEdit and VSCode. Moreover, we extended and modified the VSCode extension to accommodate these new changes, bringing its user experience closer to that of #jedit, and we built two usable prototype client integrations for the _Neovim_ #footnote[https://neovim.io/] and _Sublime Text_ #footnote[https://www.sublimetext.com/] code editors to assess the new flexibility.

== Motivation <intro:motivation>

Prior to this work, we attempted to build an Isabelle language client for the terminal-based code and text editor Neovim. However, it quickly became apparent that the existing language server was insufficient. For example, it only sent the content of certain panels in an HTML format. This makes it easy for an Electron-based editor like VSCode, which runs on the Chromium browser engine, allowing the editor to effortlessly and natively display HTML. However, displaying HTML content from within a terminal-based editor like Neovim is not reasonably possible, meaning an option to get non-HTML output was required.

Because of this, it was virtually impossible to build such a language client with the official Isabelle language server. Instead, we used the unofficial Isabelle fork `isabelle-emacs` #footnote[https://github.com/m-fleury/isabelle-emacs], which includes many advancements to the Isabelle language server and fixes some of its issues to support the _Emacs_ #footnote[https://www.gnu.org/software/emacs/] code editor. While this fork enabled a usable Neovim Isabelle environment #footnote[https://github.com/Treeniks/isabelle-lsp.nvim/tree/0b718d85fd4589d27638877f8955bedb93f56738], e.g., by offering the aforementioned non-HTML output option, there were still many missing features compared to #jedit. Still, the `isabelle-emacs` fork was a strong inspiration for some of the changes made in the context of this thesis.

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
