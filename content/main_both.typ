#import "/utils/todo.typ": TODO

= Changes for both Language Server and Client

== Decorations on file switch

#TODO[
    - currently breaks when switching files/tabs
    - originally solved by implementing decoration request and requesting them everytime we switch file/tab
    - later found that client-side caching was implemented, but used URI as key instead of URI strings which didn't work
    - decoration request kept in, in case a different client needs it (Foreshadowing to Sublime Text implementation which used it)
]

== Panel Margin Handling

=== Server

#TODO[
    - new introduction of Pretty Panel module
    - manages the formatting of output, including extracting the decorations if HTML is disabled
    - now client can send margins for both state and output panels
        - pretty panel manages if new message needs to be sent or not (i.e. if output has actually changed)
]

=== Client

#TODO[
    - "mix" as test string for symbol sizes, same as in JEdit
    - send with a timeout, otherwise there is a message for every pixel
    - add headroom
]

== Symbol Options

#TODO[
    - difference between ASCII representation of Symbols and Unicode representation of Symbols
        - not always the case
        - Isabelle internally makes no difference
        - add Encoding graphic and explanation here
    - before: `vscode_unicode_symbols`
        - inconsistently used throughout the server codebase
        - badly defined which symbols this affects
    - now: two settings `vscode_unicode_symbols_output` and `vscode_unicode_symbols_edits`
        - output for all output (e.g. panels, messages)
        - edits for all edits (TextEdit objects, e.g. for autocompletion/code actions)
]
