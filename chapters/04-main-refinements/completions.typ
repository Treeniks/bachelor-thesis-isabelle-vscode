#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

== Completions

The LSP specification defines how completions are supposed to be handled. For this, it defines a `textDocument/completion` request sent by the client @lsp-spec. In particular, this means that the choice of _when_ completions are triggered is up to the client. They typically trigger them automatically for certain trigger characters that were typed, although most of them also offer a keybind to manually request completions. The client may choose which characters count as such trigger characters, and many also offer the user to overwrite this set in their preferences. The language server can additionally send a list of trigger characters within its capabilities during the initialization stage described in @back:lsp-initialization.

Completions were already implemented in the Isabelle language server. The generation of the completions used the same internal system that #jedit uses, meaning the completions sent by the language server are identical to those offerd by #jedit.

=== Completions Items Not Showing

Isabelle completions concern primarily Isabelle symbols, although completions for other things such as keywords are also offered. We will differentiate Isabelle completions by three different categories:
1. Symbol completions for abbreviations.
2. Symbol completions for ASCII representations.
3. Any other types of completions.

Curiously, in #vscode, only categories 2 and 3 worked, category 1 did not. In Neovim, categories 1 and 3 worked, and 2 did not. Since completions are part of the standard LSP spec, handling of these completions is not done within the Isabelle extensions, but instead the standard language client implementations. Although in Neovim, the standard language client does not offer completions out of the box, so an additional plugin is required, for which we used `nvim-cmp` #footnote[https://github.com/hrsh7th/nvim-cmp].

The core problem is that completions in the LSP are meant to work in an additive fashion. That is, if the user writes `con` in JavaScript, it should be possible to complete to `console`. Note that the text the user wrote originally is a prefix of the completed text. This is not necessarily the case for Isabelle: In #jedit, the user can complete #isabelle(`\Longright`) to #isabelle(`\<Longrightarrow>`) which in turn gets displayed as #isabelle(`⟹`). An abbreviation like #isabelle(`<=`) should get replaced by #isabelle(`\<le>`) which gets displayed as #isabelle(`≤`). For the language server, it may even be that the completion should insert #isabelle(`⟹`) or #isabelle(`≤`) directly, depending on the options described in @symbol-options. These types of non-prefix completions are called _flex_ completions, which the LSP does not intend to handle.

However, the Isabelle language server sends these flex completions anyway, it's up to the client whether it wants to display them or not. Clients are supposed to implement a filter for these completions, and this filter is intentionally not defined in the LSP specification in order to allow consistency across languages within the editor. Therefore, different clients may use vastly different approaches for these filters, causing the aforementioned inconsistency issues.

There are discussions for supporting flex completions within the LSP #footnote[https://github.com/microsoft/language-server-protocol/issues/651]. For our use, we made use of the `filterText` string that is optionally provided with completions. This text is supposed to be used when filtering. By setting this text to be equivalent to what the user wrote so far (#isabelle(`\Longright`) in our previous example), this should force all filters to show the completion no matter what.

This fixed the original issue, but introduced a new problem specifically in #vscode: Now, while writing out #isabelle(`\Longright`), the completion overlay would fade in and out at every second keystroke. This meant that, while #isabelle(`\Longright`) could be completed, #isabelle(`\Longrigh`) could not. This only manifested within #vscode and was no problem in Neovim. To solve this, we modified some tangential values in #vscode's settings and its Isabelle grammar, although we could not figure out the actual source of the problem. #vscode is based on VSCode version `1.70.1`, which released on the 11th of August, 2022. It may be that by upgrading this, the problem disappears as well. We could unfortunately not verify this hypothesis due to time constraints.

We also found certain other language clients reacting rather strangely to provided `filterText`s. In Sublime Text for example, the `filterText` is not just used during filtering, but also displayed to the user as the completion item itself. This means that the user is shown the choice of completing #isabelle(`\Long`) with the three options #isabelle(`\Long`), #isabelle(`\Long`) or #isabelle(`\Long`), even though the completions are supposed to show #isabelle(`\<Longleftarrow>`) (#isabelle(`⟸`)), #isabelle(`\<Longrightarrow>`) (#isabelle(`⟹`)) and #isabelle(`\<Longleftrightarrow>`) (#isabelle(`⟺`)).

=== Immediate Completions and Commit Characters

Isabelle marks certain completions as _immediate_. If a completion is the only one available and the completion is marked as immediate, #jedit inserts the completion without further user intervention. That way, a user can write #isabelle(`==>`) and have it instantly replaced by #isabelle(`\<Longrightarrow>`) (#isabelle(`⟹`)).

To replicate this functionality in #vscode, me made use of the LSP's `commitCharacters` list that can be optionally added to a completion item. #cite(form: "prose", <lsp-spec>) describes this list as: #quote[An optional set of characters that when pressed while this completion is active will accept it first and then type that character.]

In the language server, we now check if the completion item is unique (i.e. there are no other completions) and immediate. If so, we set `commitCharacters` to a list containing _most_ writeable characters (the ASCII range `0x20`: Space to `0x7E`: \~ to be exact). That way, while the immediate insertion of the completion that #jedit does is not replicated, once the user types virtually any additional character, the completion is inserted.

Note that, while this feature is supported by VSCode, that does not seem to be the case for all language clients. Both Neovim and Sublime Text ignored this list in our testing.

// === Previous Abbreviation Modules in #vscode
//
// Before the introduction of completions into the Isabelle language server, abbreviations were handled entirely from within the Isabelle VSCode extension.
//
// #TODO[
//   - completions were reworked
//   - due to lsp completions changes, client-sided abbreviation support is not needed
//   - 3 whole modules could be outright removed
// ]
