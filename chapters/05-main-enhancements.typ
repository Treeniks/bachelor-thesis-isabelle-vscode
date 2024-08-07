#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

= Enhancements and New Features

== Decorations on File Switch

Previously, when switching theories within #vscode[], the dynamic syntax highlighting would not persist. It was possible to get the highlighting to work again by changing the buffer's content; however, until this was done, it never recovered by itself. This was a problem when working on multiple theory files.

#figure(
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
  ```,
  caption: [Example `PIDE/decoration` notification sent by the language server.],
  kind: raw,
  placement: auto,
) <pide-decoration-json>

To understand how #vscode[] does dynamic syntax highlighting, we will first take a look at the structure of the `PIDE/decoration` notifications. Recall that the primary data of notifications is sent within a `params` field. In this case, this field contains two components: A `uri` field with the relevant theory file's URI, and a list of decorations called `entries`. Each of these entries then consists of a `type` and a list of ranges called `content`. The `type` is a string identifier for an Isabelle decoration type. This includes things like `text_skolem` for Skolem variables and `dotted_warning` for things that should have a dotted underline. Each entry in the `content` list is another list of 4 integers describing the line start, line end, column start, and column end of the range the specified decoration type should be applied to. @pide-decoration-json shows an example of what a `PIDE/decoration` message may look like.

Since this is not part of the standard LSP specification, a language client must implement a special handler for such decoration notifications. Additionally, it was not possible to explicitly request these decorations from the language server. Instead, the language server would send new decorations whenever it deemed necessary, e.g., because the caret moved into areas of the text that haven't been decorated yet or because the document's content has changed.

On the VSCode side, these decorations were applied via the `TextEditor.setDecoration` API function #footnote[https://code.visualstudio.com/api/references/vscode-api#TextEditor.setDecorations], which does not inherently cache these decorations on file switch. Thus, when switching theories, VSCode did not cache the previously set decorations, nor did the language server send them again, causing the highlighting to disappear.

There were two primary ways to fix this issue:
1. Implement caching of decorations manually in the VSCode extension.

2. Add the ability to request new decorations from the server and do so on file switch.

The main advantage of option 1 is performance. If the client handles caching of decorations, then the server won't have to calculate the decorations anew (which is a rather expensive operation), nor will another round of JSON Serialization and Deserialization have to happen. However, the trade-off is that more work needs to be done on the client side, making new client implementations for other editors potentially harder.

Because of this, we instead introduced a new `PIDE/decoration_request` notification, sent by the client to explicitly signal to the server that it should send a `PIDE/decoration` notification back.

Note that this system is atypical for the LSP. The `PIDE/decoration_request` notification is, semantically speaking, a request and intends a response from the server, yet from the perspective of the LSP, it is a unidirectional notification, while its response is also a unidirectional `PIDE/decoration` notification. We chose this approach for two reasons:
1. There was already precedent for such behavior in the Isabelle language server, specifically with `PIDE/preview_request`.

2. `PIDE/preview_response` notifications, and, the `PIDE/decoration` notification is not only sent after a request. The original automatic sending behavior that existed before is still present and was not altered. If we were to implement `PIDE/decoration_request`s as an LSP request instead, this would only result in extra implementation work on the client side because a client would need to implement the same decoration application logic for both the `PIDE/decoration` notification and the `PIDE/decoration_request` response. By defining `PIDE/decoration_request`s as notifications, the client only needs to implement a singular handler for `PIDE/decoration` notifications and automatically covers both scenarios simultaneously.

Later we found that client-side caching was already implemented for the Isabelle VSCode extension; however, incorrectly so. The caching was done via a JavaScript `Map` #footnote[https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map], with files as keys and the content list from the decoration messages as values. For the keys, the specific value used was of type `URI` #footnote[https://code.visualstudio.com/api/references/vscode-api#Uri], which does not explicitly implement an equality function, thus resulting in an inconsistent equality check where two URIs pointing to the same file may not have been the same URI in TypeScript-land. Switching the key to using string representations of the URIs fixed the issue. However, we decided to keep the `PIDE/decoration_request` notification. While it may not be in use by #vscode[] directly, other Isabelle language client implementations may make use of this functionality.

// #TODO[
//   - currently breaks when switching files/tabs
//   - originally solved by implementing decoration request and requesting them every time we switch file/tab
//   - later found that client-side caching was implemented, but used URI as key instead of URI strings which didn't work
//   - decoration request kept in, in case a different client needs it (Foreshadowing to Sublime Text implementation which used it)
// ]

== Disable HTML Output for Panels <html-panel-output>

#TODO[
  - currently server sends output always in HTML format
  - VSCode can display HTML, but not all clients can
  - now can disable HTML output and send pure text instead with option
  - added decorations to the message if HTML is disabled (biggest usability win in neovim)
]


== Symbols Request and Conversions

#TODO[
  - currently client was expected to just know what symbols are available, but this is dynamic
  - now client can request a list of all symbols from server
    - gives the same list used by VSCode during compilation, meaning dynamic symbol additions still don't work (Future Work)
]

#TODO[
  - flush_edits used to automatically convert symbols based on `vscode_unicode_symbols`
  - but now the code for it was just unused, so it was removed
  - now symbol conversion is a request
    - client can easily convert whole document to unicode with that
]

== Code Actions for Active Markup

One feature of #jedit[] that was missing entirely in #vscode[] is Isabelle's _active markup_. Active markup, generally speaking, describes parts of the theory, state or output content that is clickable. The action taken when the user clicks on an active markup can vary, as there is many different kinds of active markup. One type of active markup the user will probably come across frequently is the so called _sendback_ markup. This type of markup appears primarily in the output panel and clicking on it inserts its text into the source theory. It appears, for example, when issuing a `sledgehammer` command.
#footnote[The `sledgehammer` command is an Isabelle command that calls different external automatic theorem provers in hopes of one of them finding a proof. Isabelle then translates the found proof back into an Isabelle proof.]
When this command finds a proof, it is displayed in the output panel with a gray background. The user can then click on it and Isabelle inserts the proof into the document. This example can be seen in @active-markup-sledgehammer-jedit. As mentioned, there are other types of active markup as well, but we will focus exclusively on these sendback markups.

#figure(
  table(
    columns: 2,
    stroke: none,
    table.header([*Before*], [*After*]),
    box(stroke: 1pt, image("/resources/jedit-active-sledgehammer-before.png")),
    box(stroke: 1pt, image("/resources/jedit-active-sledgehammer-after.png")),
  ),
  kind: image,
  caption: [Active markup in #jedit[] when using sledgehammer.\ Before and after clicking on sendback markup.],
) <active-markup-sledgehammer-jedit>

Unlike other features discussed in this work, active markups are a concept that has no comparable feature within typical code editors. Clicking on parts of code may exist in the form of _Goto Definition_ actions or clicking on hyperlinks, but inserting things from some output panel into the code unique. Hence, there is also no existing precedent on how to handle this type of interaction within the LSP specification. Because of this, the first question that needed to be answered is how we want to tackle this problem on a user experience level. That is, do we intend for #vscode['s] implementation to work the same way as it does in #jedit[] (i.e. by clicking with the mouse), or should the interaction work completely differently.

There exist two major problems when trying to replicate the user experience of #jedit[]:
1. For the sake of accessibility, it is usually possible to control VSCode completely with the Keyboard. To keep this up, we decided it should also be possible to interact with active markup entirely with the keyboard.

2. It would need a completely custom solution for both the language server and language client, increasing complexity and reducing the barrier of entry for new potential Isabelle IDEs. We would potentially need to reimagine the way that output panel content is sent to the client, and if so, it would be very difficult expanding the functionality to other types of active markup that live within the theory.

Instead, we decided to explore completely new interaction methods, utilizing existing LSP features where possible. And luckily, the LSP spec defines a concept called _code actions_ which we could utilize for active markup.

The intended use case of code actions is to support more complicated IDE features acting on specific ranges of code that may result in beautifications or refactors of said code. For example, when using the `rust-analyzer` language server #footnote[https://rust-analyzer.github.io/] which serves as a server for the Rust programming language #footnote[https://www.rust-lang.org/], it is possible to use a code action to fill out match arms of a match expression, an example of which can be seen in @rust-match-action.

#figure(
  table(
    columns: 2,
    stroke: none,
    table.header([*Before*], [*After*]),
    box(stroke: 1pt, image("/resources/sublime-action-rust-light-before.png")),
    box(stroke: 1pt, image("/resources/sublime-action-rust-light-after.png")),
  ),
  kind: image,
  caption: [`rust-analyzer`'s "Fill match arms" code action in Sublime Text.],
) <rust-match-action>

The big advantage to using code actions, is that code actions are a part of the normal LSP specification, meaning most language clients support them out of the box. If the Isabelle language server supports interaction with active markup through code actions, there is no extra work necessary for the client.

To initiate a code action, the language client sends a `textDocument/codeAction` request to the server whose content can be seen in @action-request-interface. The request's response then contains a list of possible code actions. Each code action may be either an _edit_, a _command_ or both. For our use case of supporting _sendback_ active markup, which only inserts text, the _edit_ type suffices, although to support other types of active markup, the _command_ type may become necessary.

The `range` data sent in the code action request is the text range from which the client wants to get code actions from. Code actions are quite dependent on caret position. Different parts of the document may exhibit different code actions. Most of the time, the `range` just includes the current position of the caret, however most clients will also allow the user to do a selection or even create multiple carets and request code actions for the selected range.

#figure(
  ```typescript
  interface CodeActionParams {
    textDocument: TextDocumentIdentifier;
    range: Range;
    context: CodeActionContext;
  }
  ```,
  caption: [`CodeActionParams` interface definition @lsp-spec.],
  kind: raw,
) <action-request-interface>

=== Implementation for the Isabelle Language Server

When the Isabelle language server receives a code action request, the generation of the code actions list for its response is roughly done in these four steps:
1. Find all #isar[] commands within the given `range`.

2. Get the command results of all these commands.

3. Extract all sendback markup out of these command results.

4. Create LSP text edit JSON objects, inserting the sendback markup's content at the respective command's position.

#figure(
  table(
    columns: 2,
    stroke: none,
    table.header([*Before*], [*After*]),
    box(stroke: 1pt, image("/resources/vscode-action-active-sledgehammer-light-before.png")),
    box(stroke: 1pt, image("/resources/vscode-action-active-sledgehammer-light-after.png")),
  ),
  kind: image,
  caption: [Active markup in #vscode[] when using sledgehammer.\ Code action initiated with "`Ctrl+.`". Before and after accepting code action.],
  placement: auto,
) <active-markup-sledgehammer-vscode>

Once the list of these code actions is sent to the language client, the server's work is done. The LSP text edit objects exist in a format standardized in the LSP, so the actual execution of the text edit can be done entirely in the client.

We also considered how to deal with correct indentation for the inserted text. In #jedit[], when a sendback markup gets inserted, the general indentation function that exists in #jedit[] is called right after to correctly indent the newly inserted text. Since this internal indentation function uses direct access to the underlying jEdit buffer, we could not easily use this function from the language server. However, simply ignoring the indentation completely results in a subpar user experience. A proper solution would reimplement #jedit['s] indentation logic for the language server, however this would require additional work. For our contribution, the language server instead just copies the source command's indentation to the inserted text. This will potentially give slightly different indentations compared to #jedit[], however the result is acceptable in practice.

An example of the resulting implementation for #vscode[] can be seen in @active-markup-sledgehammer-vscode.

// #TODO[
//   - explanation of active markup
//   - adding support for clicking is somewhat difficult and goes way beyond the LSP Spec
//   - code actions are a way for the server to send different options to client, and the client to then be able to select one
//     - can include just text edits, client commands or even server commands
//     - thus very flexible
//     - most clients already implement logic for it, so no need for manual implementation on client
//   - now works for sendbacks (insertions)
//     - example with sledgehammer/try0
//     - indentation is copied from current line
//       - indentation on jEdit is handled via global indent function
//       - uses internal jEdit buffers, thus not easily translatable to server
//   - TODO look into git history for more difficulties
// ]

== Isabelle Preferences as VSCode Settings

Isabelle has many options that can be set to adjust different aspects of the interactive sessions. For example, the option `editor_output_state` defines whether the current state should additionally be printed within the output panel.

The options including their default value are generally defined within `etc/options` files scattered throughout the codebase. There are three ways to change the value of an option:
1. Manually within a `~/.isabelle/etc/preferences` file.

2. Within #jedit['s] settings and throughout its UI, as seen in @jedit-settings. When an option is changed in #jedit[], the appropriate entry in the `preferences` file is added or modified.

3. Via command line arguments. When the user invokes the `isabelle` command with their intended subcommand, e.g. `isabelle vscode`, they can add further option overwrites with `-o`, e.g. `-o editor_output_state=true`.

#figure(
  image("/resources/jedit1.png"),
  kind: image,
  caption: [#TODO[replace image for correct one]]
) <jedit-settings>

Additionally, many options are annotated with a tag, thus creating grouping of similar options. For example, the `content` tag includes options such as `names_long`, `names_short` and `names_unique` which affect how names (like function names) are printed within output and state panels.

For users of #vscode[], only the first and third method of setting preferences was possible. There was no method to do so through #vscode['s] UI. We wanted to alleviate this discrepancy between #vscode[] and #jedit[] by adding options that are relevant to #vscode[] to its settings.

Ideally, the settings in #vscode[] would be kept in-sync with the user's `preferences` file, like #jedit[] does. However, to do so, we would need be able to parse and understand the `preferences` file from within the VSCode extension, which we deemed to be too much work. Instead, we chose to use the #vscode[] settings as pure overwrites.

Therefore, the order of priority for the value of an option when starting #vscode[] is supposed to be as follows:
1. CLI arguments.
2. VSCode's settings.
3. User preferences.
4. Isabelle defaults.

=== Extending #vscode['s] Settings

// To allow this level of granularity to the user, the VSCode options mostly allow for three 

// For example, the default for the aforementioned `editor_output_state` option is `false`. To change this to true, the user may add an appropriate entry into their `preferences` file. 

It is possible to add custom settings to VSCode with a VSCode extension. To do so, one can add a `contributes.configuration` entry into the extensions `package.json` file @extension-api.

These settings' values are also given a type, like `string` or `boolean`. Isabelle options also have a type, which can be `string`, `int`, `real` or `bool`. It might tempting to use the same type for the VSCode extension's settings. However, since we ultimately want the user to be able to _overwrite_ these options, this is not optimal. Taking the `editor_output_state` as an example, which is of type `bool`, the respective VSCode setting would be of type `boolean`, giving it two states. However, we actually need three states: don't overwrite, off and on. If the type of the VSCode setting was `boolean` with a default value of `off`, there would be no difference between the user not wanting VSCode to overwrite their `preferences` file and wanting to overwrite it with `off`.

Additionally, these settings will ultimately be passed to the language server via CLI arguments, because the language server does not have access to the VSCode settings directly. In fact, the language server's and really any Isabelle tool's option priority is similar to the one we want for #vscode[]:
1. CLI arguments.
2. User preferences.
3. Isabelle defaults.

With other words, the correct handling of defaults and user preferences is already given by the language server and does not need to be considered from the VSCode extension. When the user starts `isabelle vscode`, the extension gets both the VSCode settings and the given CLI arguments, then combines the two prioritizing the CLI arguments, and then sends this combination as CLI arguments to the language server.

This also means that even `int` and `real` Isabelle options are better off as being options of type `string` in VSCode, as it needs to be converted into strings to be sent as CLI arguments down the line.

The ultimate format of the VSCode settings we then chose is: All VSCode settings are of type `string`. For Isabelle options of type `bool`, the respective VSCode setting will have possible values `""`, `"off"` and `"on"`, meaning dont-override, overwrite with off and overwrite with on respectively. For Isabelle options of any other type, the empty string `""` means don't overwrite and any other value is the value the option should be overwritten with.

#TODO[add example setup]

=== Choosing the relevant options

Many of the options Isabelle exposes are not relevant for #vscode[]. For example, one of the option tags available is the `jedit` tag which, as the name suggests, includes options relevant specifically for #jedit[].

The first options that are relevant are the options specifically designed for VSCode and the language server. These options are defined within `src/Tools/VSCode/etc/options`. To easily access these options, we added and assigned a new `vscode` option tag to these options.

The second set of relevant options are options tagged with the aforementioned `content` tag.

The third set are manually chosen options helpful for #vscode[], but not included in either of the previous two tags. The list of options we chose is:
- `editor_output_state`
- `auto_time_start`
- `auto_time_limit`
- `auto_nitpick`
- `auto_sledgehammer`
- `auto_methods`
- `auto_quickcheck`
- `auto_solve_direct`
- `sledgehammer_provers`
- `sledgehammer_timeout`

Since the options available in the given tags may change in the future, simply adding them manually to the `package.json` file was unsatisfactory. Instead, the options are dynamically added while building the extension with `isabelle component_vscode_extension`. To do so, the `package.json` file includes a `"ISABELLE_OPTIONS": {},` marker which is replaced with the appropriate JSON format of the given options by the Isabelle system during build.

// == New Default Settings and Word Pattern

// #TODO[
//   - completions don't work properly if word pattern is not set the way it is now
// ]

// #TODO[
//   - renderWhitespace to none because the space render is not monospaced in the font
//   - quickSuggestions strings to on, because everything in quotes is set to be a string by the static syntax
//   - wordBasedSuggestions to off
// ]
