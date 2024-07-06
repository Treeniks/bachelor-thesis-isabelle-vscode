#import "/utils/todo.typ": TODO

= Introduction
// #TODO[
//   Introduce the topic of your thesis, e.g. with a little historical overview.
// ]

Isabelle/VSCode exists primarily as an Accessibility Component for interacting with the Isabelle Proof Assistant. However, it was insufficient at providing an experience comparable to that of Isabelle/JEdit. There were many issues with usability, as well as many missing features, that are available in Isabelle/JEdit but were missing from Isabelle/VSCode. The goal of this thesis is to bring Isabelle/VSCode closer to the experience of Isabelle/JEdit, i.e. to introduce some of those missing features and tackle the usability problems.

Another problem with Isabelle/VSCode was that the underlying language server did not offer a full enough feature set for it to be in other editors outside of VSCode. The nature of Isabelle interactive sessions makes it impossible to create a plug-in language server implementation, there was always going to be work needed on the client side.

== Problem
#TODO[
  Describe the problem that you like to address in your thesis to show the importance of your work. Focus on the negative symptoms of the currently available solution.
]

== Motivation
#TODO[
  Motivate scientifically why solving this problem is necessary. What kind of benefits do we have by solving the problem?
]

== Objectives
// #TODO[
//   Describe the research goals and/or research questions and how you address them by summarizing what you want to achieve in your thesis, e.g. developing a system and then evaluating it.
// ]

Before starting work on the language server, a list of additions and changes required was compiled beforehand:

- fix change_document
- add Isabelle Extension settings into VSCode (Language Server CLI flags)
- decorations
    - remove necessity on static highlighting (e.g. decorate theorem keyword dynamically)
    - ability to request decorations to be sent explicitly from client
    - dynamic decoration radius (named caret perspective)
- state and dynamic output
    - overhaul how state panels are created (e.g. IDs handling)
    - handling width of state/output window
    - option to send output/state in non-HTML (with decorations)
    - option to merge state and output into one message/panel
- completion
    - dynamic symbol auto-completion (e.g. \<gamma>)
    - keyword completion (e.g. theorem)
- (maybe) add message to request all current dynamic symbol replacements (\<gamma> => γ)
- active markup (w/ LSP actions?)
    - (maybe) rename variables etc.

Over the course of the work, some of these features were discovered to already exist or not require changing and new problems came up that were added.

// == Outline
// #TODO[
//   Describe the outline of your thesis
// ]
