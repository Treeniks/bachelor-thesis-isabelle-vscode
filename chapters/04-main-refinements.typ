#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

= Refinements to Existing Functionality

The work presented in this thesis on #vscode can be roughly categorized into two areas: The refinement of existing features and the introduction of new ones. This chapter focuses on the former. In both categories, #jedit serves as the primary reference implementation. Whether addressing a problem or filling a gap in functionality, the aim has been to replicate the behavior of #jedit closely. While it could be argued that certain features in #jedit also warrant improvements, this thesis does not engage with those considerations.

#include "/chapters/04-main-refinements/desyncs.typ"
#include "/chapters/04-main-refinements/state-ids.typ"
#include "/chapters/04-main-refinements/state-and-output-panels.typ"
#include "/chapters/04-main-refinements/completions.typ"
