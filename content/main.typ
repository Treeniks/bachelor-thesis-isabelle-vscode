#import "/utils/todo.typ": TODO

= Main

== Desync on file changes

#TODO[oof, explanation of the `textDocument/didChange` notification and desync problem]

The cause of this issue was related to how the changes coming in from the language client were interpreted withing the language server. The specific issue was that the language server first sorted the changes:
```scala
@tailrec def norm(chs: List[LSP.TextDocumentChange]): Unit = {
  if (chs.nonEmpty) {
    val (full_texts, rest1) = chs.span(_.range.isEmpty)
    val (edits, rest2) = rest1.span(_.range.nonEmpty)
    norm_changes ++= full_texts
    norm_changes ++= edits.sortBy(_.range.get.start)(Line.Position.Ordering).reverse
    norm(rest2)
  }
}
```

This normalization was not intended according to the LSP specficiation:
#quote[
    The actual content changes. The content changes describe single state changes to the document. So if there are two content changes c1 (at array index 0) and c2 (at array index 1) for a document in state S then c1 moves the document from S to S' and c2 from S' to S''. So c1 is computed on the state S and c2 is computed on the state S'.

    To mirror the content of a document using change events use the following approach:
    - start with the same initial content
    - apply the `textDocument/didChange` notifications in the order you receive them.
    - apply the `TextDocumentContentChangeEvent`s in a single notification in the order you receive them.
]

Thus, all that needed to be done to fix the common desyncs was to remove said normalization and instead apply the changes in the order they are received.

== Isabelle preferences as VSCode settings

#TODO[explain preferences, including tags]

If a user tries to use Isabelle/VSCode, chances are they are already familiar with VSCode, but potentially not very familiar with Isabelle. Isabelle uses its own system for options that alter the Isabelle system. The default options are generally defined within `etc/options` files scattered throughout the codebase. The user is then expected to overwrite these options within `~/.isabelle/etc/preferences`.
With Isabelle/JEdit, these options are simply listed within the JEdit settings, which then in turn add the appropriate entries into the user's preferences.

Another way to set Isabelle preferences is through the command line. When the user invokes the `isabelle` command with their intended subcommand, e.g. `isabelle vscode`, they can add further option overwrites with `-o`, e.g. `-o editor_output_state=true`.

The goal was to have the relevant options available in VSCode's settings as well, to allow a similar user experience to JEdit. The ideal would be, if the settings in VSCode were kept in-sync with the user's prefernces, to have the same user experience as one would with JEdit. However, this was deemed unpractical and thus we chose an overwriting system instead.
The actual settings passed to Isabelle are then as follows, in order of priority:
1. CLI Arguments
2. VSCode's settings
3. User preferences
4. Isabelle defaults
#TODO[add example setup]

=== Choosing the relevant options
Many of the options Isabelle exposes are not relevant for Isabelle/VSCode. For example, one of the option tags available is the `jedit` tag which, as the name suggests, includes options relevant specifically for JEdit. The first options that are relevant are the options specifically designed for VSCode and the language server. These options are defined within `src/Tools/VSCode/etc/options`. To easily access these options, a new `vscode` option tag was added and assigned to these options.

The second set of relevant options are options tagged with the `content` tag. These include options like `names_short` which forces names in output to be the base name only at the cost of ambiguity.

The third set are manually chosen options helpful also in VSCode, but not included in either of the previous two tags. The currently chosen list of options is:
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
This list might get extended in the future.

=== Adding the options into VSCode
To add options available through a VSCode extension, one has to add an entry for each option into the extension's `package.json`. Since the options available in the given tags may change in the future, simply adding them manually to this file was unsatisfactory. Instead the options are dynamically added while building the extension with `isabelle component_vscode_extension`.

To do so, the source `package.json` includes a `"ISABELLE_OPTIONS": {},` marker which is replaced with the appropriate json format of the given options by the isabelle system during build.
