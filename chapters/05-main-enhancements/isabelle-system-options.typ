#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

#import "@preview/fletcher:0.5.1" as fletcher: diagram, node, edge

== Isabelle System Options as VSCode Settings

Isabelle has many options that can be set to adjust different aspects of the interactive sessions. For example, the option `editor_output_state` defines whether the current state should additionally be printed within the output panel.

The options, including their default values, are generally defined within `etc/options` files scattered throughout the codebase. The user can overwrite these options by adding respective entries into a `$ISABELLE_HOME_USER/etc/preferences` file. When using #jedit[], the user will also find many of these options within #jedit['s] settings, as seen in @jedit-settings. These settings and the content of the `preferences` file are kept in sync @manual-jedit.

#figure(
  image("/resources/jedit-settings.png", width: 80%),
  kind: image,
  caption: [Isabelle options inside of #jedit[].],
  // placement: auto,
) <jedit-settings>

The Isabelle language server offers one additional way of overwriting Isabelle system options: Via CLI arguments. When starting the Isabelle language server with `isabelle vscode_server`, one may add additional option overwrites with `-o NAME=VAL` arguments. The order of priority for Isabelle options for the language server is then as follows:
1. CLI arguments.
2. User preferences defined in the `preferences` file.
3. Isabelle defaults.

The same is true for #vscode[]. When starting #vscode[] with `isabelle vscode`, the user can add option overwrites as CLI arguments. However, previously there was no method to set Isabelle options through #vscode['s] UI. We wanted to alleviate this discrepancy between #vscode[] and #jedit[] by adding options that are relevant to #vscode[] to its settings.

Ideally, the settings in #vscode[] would be kept in-sync with the user's `preferences` file, like #jedit[] does. However, to do so, we would need be able to parse and understand the `preferences` file from within the VSCode extension, yet this file is supposed to be managed by #scala[] exclusively. Therefore, we instead chose to use the #vscode[] settings as pure overwrites.

=== Passing Options from VSCode to the Language Server

#vscode[] itself has no use for Isabelle system options. These options are used by Isabelle internally, not by the code editor. That means that only the language server needs to know the options set by the user.

When using #vscode[], the user does not manually start the language server. Instead, they start `isabelle vscode`, which starts an instance of Isabelle's patched VSCodium with an Isabelle extension installed, which then starts the language server once the user opens an Isabelle theory.

The `isabelle vscode` command optionally takes option overwrites as CLI arguments and converts these into an environment variable called "`ISABELLE_VSCODIUM_ARGS`", such that the extension can read this environment variable later. On top of that, the extension used to add a few hard-coded options that are needed for #vscode[] to function properly. This set of options is finally given to the language server as CLI arguments. @vscode-options-flow-previous shows this process.

#figure(
  diagram(
    edge-stroke: 1pt,

    edge((-1, -1.5), (-1, -0.7), "-}>", [CLI arguments], label-side: left),
    node((-1, -0.7), [Isabelle System], height: 40pt, stroke: 1pt),

    edge((-1, -0.7), (-1, 0)),
    node((-1, 0), [`ISABELLE_VSCODIUM_ARGS`]),
    edge((-1, 0), (0, 0), "-}>"),

    node((0, 0), [VSCodium\ Extension], height: 40pt, stroke: 1pt),
    edge((0, 0), (2, 0), "-}>", align(center, [CLI\ arguments]), label-anchor: "center", label-sep: 0pt),
    node((2, 0), [Language Server], height: 40pt, stroke: 1pt),
  ),
  kind: image,
  caption: [Previous passing of option overwrites.],
) <vscode-options-flow-previous>

The language server gets its option values by first taking the Isabelle default, overwriting those with whatever the user specified in their `preferences` file, and overwriting those again with whatever was given as CLI arguments.

In order to additionally consider VSCode settings, we must add them from within the extension, as we do not have access to the VSCode settings from within the language server nor the original Isabelle process that starts VSCodium. Therefore, the only part we can actually affect with VSCode settings is the CLI arguments sent to the server by the extension. Here, we must decide whether the user's CLI arguments or VSCode settings have priority. This limits the possible order of priority to two different possibilities, seen in @priority-order-options.

#figure(
  table(
    columns: 2,
    align: left,
    stroke: (x, y) => (
      left: if x > 0 { .5pt } else { 0pt },
      right: 0pt,
      top: if y > 0 { .5pt } else { 0pt },
      bottom: 0pt,
    ),
    table.header([*Option 1*], [*Option 2*]),
    enum(indent: 0pt, [CLI], [VSCode Settings], [Preferences], [Defaults]),
    enum(indent: 0pt, [VSCode Settings], [CLI], [Preferences], [Defaults]),
  ),
  caption: [Different possibilities for Isabelle system option priority order.],
  kind: table,
) <priority-order-options>

Of these, we chose to proceed with option 1, as CLI option overwrites are more explicit than the user's VSCode settings and should be prioritized.

#figure(
  diagram(
    edge-stroke: 1pt,

    edge((-1, -1.65), (-1, -0.85), "-}>", [CLI arguments], label-side: left),
    node((-1, -0.85), [Isabelle System], height: 40pt, stroke: 1pt),

    edge((-1, -0.85), (-1, -0.15)),
    node((-1, -0.15), [`ISABELLE_VSCODIUM_ARGS`]),
    edge((-1, -0.15), (0, -0.15), "-}>"),

    node((-1, 0.15), [VSCode settings]),
    edge((-1, 0.15), "r", "-}>"),

    node((0, 0), [VSCodium\ Extension], height: 40pt, stroke: 1pt),
    edge((0, 0), (2, 0), "-}>", align(center, [CLI\ arguments]), label-anchor: "center", label-sep: 0pt),
    node((2, 0), [Language Server], height: 40pt, stroke: 1pt),
  ),
  kind: image,
  caption: [Passing of option overwrites with VSCode settings.],
) <vscode-options-flow-after>

@vscode-options-flow-after shows the new flow of Isabelle options when starting #vscode[]. The VSCode Isabelle extension has access to both the CLI arguments given to the `isabelle vscode` command, and whatever settings are set in VSCode.

These two get merged, prioritizing the options within the `ISABELLE_VSCODIUM_ARGS` variable, and this merged set of option overwrites gets passed to the language server.

=== Option Types

Isabelle system options all have a type, which can be `string`, `int`, `real` or `bool`. It might be tempting to use the same type for the VSCode extension's settings. However, since we ultimately want the user to be able to _overwrite_ these options, this is not optimal. Taking the `editor_output_state` as an example, which is of type `bool`, the respective VSCode setting would be of type `boolean`. In the UI, this would make it a checkbox, giving it two states. However, we actually need three states: Don't overwrite, `off` and `on`. If the type of the VSCode setting were `boolean` with a default value of `off`, there would be no difference between the user not wanting VSCode to overwrite their user preferences and wanting to overwrite it with `off`.

Instead, we made all #vscode[] settings of type `string`. For Isabelle options of type `bool`, the respective VSCode setting will have possible values `""`, `"off"` and `"on"`, meaning dont-override, overwrite with `off` and overwrite with `on` respectively. For Isabelle options of any other type, the empty string `""` means don't overwrite and any other value is the value the option should be overwritten with.

This system has another advantage for numerical options: The types of VSCode settings are just JavaScript types. Isabelle makes a difference between `real` and `int` options, but JavaScript only has a singular `numeric` type. If the VSCode option were to take such `numeric` values, the extension would need to convert this value to a string to pass it to the language server as a CLI argument. By keeping it a string from the start, we skip potential conversion errors that may occur otherwise.

=== Extending #vscode['s] Settings

Many Isabelle options are annotated with a tag, thus creating grouping of similar options. For example, the `content` tag includes options such as `names_long`, `names_short` and `names_unique` which affect how names (like function names) are printed within output and state panels.

Many of the options Isabelle exposes are not relevant for #vscode[]. For example, one of the option tags available is the `jedit` tag which, as the name suggests, includes options relevant specifically for #jedit[].

The first options that we deemed relevant are the options specifically designed for VSCode and the language server. These options are defined within `src/Tools/VSCode/etc/options`. To easily access these options, we added and assigned a new `vscode` option tag to these options.

The second set of relevant options are options tagged with the aforementioned `content` tag.

The third set are manually chosen options helpful for #vscode[], but not included in either of the previous two tags. The list of options we chose is:
#columns(2)[
  - `editor_output_state`
  - `auto_time_start`
  - `auto_time_limit`
  - `auto_nitpick`
  - `auto_sledgehammer`
  #colbreak()
  - `auto_methods`
  - `auto_quickcheck`
  - `auto_solve_direct`
  - `sledgehammer_provers`
  - `sledgehammer_timeout`
]

To add custom settings to VSCode with a VSCode extension, one can add a `contributes.configuration` entry into the extensions `package.json` file @extension-api. Since the options available in the given tags may change in the future, simply adding them manually to the `package.json` file was unsatisfactory. Instead, the options are dynamically added while building the extension with `isabelle component_vscode_extension`. To do so, the `package.json` file includes a `"ISABELLE_OPTIONS": {},` marker which is replaced with the appropriate JSON format of the given options by the Isabelle system during build.

Additionally, we gave the options that were previously hard-coded into the extension a respective default value during this build process instead. That way, the user is able to change these settings if they want to, which was not possible before.

// == New Default Settings and Word Pattern

// #TODO[
//   - completions don't work properly if word pattern is not set the way it is now
// ]

// #TODO[
//   - renderWhitespace to none because the space render is not monospaced in the font
//   - quickSuggestions strings to on, because everything in quotes is set to be a string by the static syntax
//   - wordBasedSuggestions to off
// ]
