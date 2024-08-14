#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

= Enhancements and New Features

This chapter focuses on significant redesigns or additions to #vscode. Users of #vscode frequently reported syntax highlighting breaking, particularly when switching files. To address this, we implemented a feature that allows manual requests for decorations.

Additionally, we added the ability to disable HTML output for state and output panels, a feature primarily motivated by the requirements of the Neovim language client prototype mentioned in @intro:motivation. We also provided more granular control for the language client regarding the handling of Isabelle symbols, which enhances the server's flexibility.

Lastly, we identified two features of #jedit where #vscode had no equivalent: Active markup and the ability to set Isabelle preferences through a UI settings menu. While these features required certain compromises, the implementations in #vscode prioritize simplicity and compatibility, even if they deviate from the exact functionality found in #jedit.

#include "/chapters/05-main-enhancements/decorations-file-switch.typ"
#include "/chapters/05-main-enhancements/non-html-content.typ"
#include "/chapters/05-main-enhancements/symbol-handling.typ"
#include "/chapters/05-main-enhancements/code-actions-active-markup.typ"
#include "/chapters/05-main-enhancements/isabelle-system-options.typ"

// == New Default Settings and Word Pattern

// #TODO[
//   - completions don't work properly if word pattern is not set the way it is now
// ]

// #TODO[
//   - renderWhitespace to none because the space render is not monospaced in the font
//   - quickSuggestions strings to on, because everything in quotes is set to be a string by the static syntax
//   - wordBasedSuggestions to off
// ]
