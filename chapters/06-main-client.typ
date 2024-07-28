#import "/utils/todo.typ": TODO

= Changes to the Language Client

== Isabelle preferences as VSCode settings

Isabelle has many options that can be set to adjust different aspects of the interactive sessions. For example, the option `editor_output_state` defined whether or not state output should be printed within the output panel.

The default options are generally defined within `etc/options` files scattered throughout the codebase. The user is then expected to overwrite these options within `~/.isabelle/etc/preferences`. With Isabelle/jEdit, these options are simply listed within the jEdit settings or throughout the UI, which then in turn add the appropriate entries into the user's preferences.

#TODO[add jEdit example screenshot?]

Another way to set Isabelle preferences is through the command line. When the user invokes the `isabelle` command with their intended subcommand, e.g. `isabelle vscode`, they can add further option overwrites with `-o`, e.g. `-o editor_output_state=true`.

Additionally, many options are annotated with a tag, thus creating grouping of similar options. For example, the `content` tag includes options such as `names_long`, `names_short` and `names_unique` which affect how names are printed within output and state panels.

If a user tries to use Isabelle/VSCode, chances are they are already familiar with VSCode, but potentially not very familiar with Isabelle. The goal was to have the relevant options available in VSCode's settings as well, to allow a similar user experience to jEdit. The ideal would be, if the settings in VSCode were kept in-sync with the user's prefernces, to have the same user experience as one would with jEdit. However, this was deemed unpractical and thus we chose an overwriting system instead.

The actual settings passed to Isabelle are then as follows, in order of priority:
1. CLI Arguments
2. VSCode's settings
3. User preferences
4. Isabelle defaults
#TODO[add example setup]

=== Choosing the relevant options

Many of the options Isabelle exposes are not relevant for Isabelle/VSCode. For example, one of the option tags available is the `jedit` tag which, as the name suggests, includes options relevant specifically for jEdit.

The first options that are relevant are the options specifically designed for VSCode and the language server. These options are defined within `src/Tools/VSCode/etc/options`. To easily access these options, a new `vscode` option tag was added and assigned to these options.

The second set of relevant options are options tagged with the aforementioned `content` tag.

The third set are manually chosen options helpful for VSCode, but not included in either of the previous two tags. The currently chosen list of options is:
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
This list might get changed in the future.

=== Adding the options into VSCode

To add options available through a VSCode extension, one has to add an entry for each option into the extension's `package.json`. Since the options available in the given tags may change in the future, simply adding them manually to this file was unsatisfactory. Instead, the options are dynamically added while building the extension with `isabelle component_vscode_extension`.

To do so, the source `package.json` includes a `"ISABELLE_OPTIONS": {},` marker which is replaced with the appropriate json format of the given options by the isabelle system during build.

== Updating VSCode

#TODO[]

== Correct Font in Output and State Panel

#TODO[
  - currently used defualt "monospace" font because it is a par
  - had to add all fonts during build
  - then add the ones needed in typescript and update css
]

== Get rid of old unused code for abbreviations

#TODO[
  - due to lsp completions changes, client-sided abbreviation support is not needed
  - 3 whole modules could be outright removed
]

== New Default Settings and Word Pattern

#TODO[
  - completions don't work properly if word pattern is not set the way it is now
]

#TODO[
  - renderWhitespace to none because the space render is not monospaced in the font
  - quickSuggestions strings to on, because everything in quotes is set to be a string by the static syntax
  - wordBasedSuggestions to off
]
