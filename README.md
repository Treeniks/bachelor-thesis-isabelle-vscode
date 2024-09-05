# Improving Isabelle/VSCode: Towards Better Prover IDE Integration via Language Server

Bachelor's Thesis in *Informatics: Games Engineering* at [TUM](https://www.tum.de/). The thesis and colloquium presentation slides are written with [Typst](https://typst.app/). The thesis template is my own, and may be released separately in the future. Build using [just](https://just.systems/).

- **Author:** Thomas Lindae
- **Supervisor:** Prof. Dr. Stephan Krusche
- **Advisors:** Prof. Dr. Tobias Nipkow, M.Sc. Fabian Huch
- **Start Date:** 15.04.2024
- **Submission Date:** 15.08.2024

**German Title:** Isabelle/VSCode Verbesserungen: Fortschritte in der Prover IDE Integration mittels Language Server

## Acknowledgements

There are several people I would like to thank:

**Prof. Dr. Tobias Nipkow** for giving me the opportunity to work on a tool as big and prominent as Isabelle.

**My advisor Fabian Huch** for meeting with me weekly, helping me understand the inner workings of Isabelle, discussing design and implementation details and lending me his time for other silly questions.

**My father Andreas Lindae** for doing his best rubber duck impression and letting me waste his time by explaining the contents of this thesis to him to sort out my thoughts.

**My friends Adrian Stein and Alexander Treml** for their valuable feedback on various sections of this thesis and helping me with its overall structure.

**Many more of my fellow student friends** for joining me in my visits to the cafeteria and providing mental and emotional respite during lunch.

## Abstract

> The primary interface for interacting with the Isabelle proof assistant is the Isabelle/jEdit prover IDE. Isabelle/VSCode was developed as an alternative, implementing a language server for the Language Server Protocol and a language client for Visual Studio Code. However, Isabelle/VSCode did not provide a user experience comparable to Isabelle/jEdit. This thesis explores and implements several improvements to address these shortcomings by refining existing functionality and augmenting Isabelle/VSCode with new features. Key enhancements include improved completions, persistent decorations on file switch, code actions for interacting with active markup, and better formatting for state and output panels. Additionally, we implemented more granular control over symbol handling and an Isabelle system option to turn off HTML output, increasing compatibility with potential new language clients. We developed prototype language clients for the Neovim and Sublime Text code editors to evaluate the improved language server's versatility. While an Isabelle language client for these editors was previously infeasible, our enhancements made them viable. Our work not only brings Isabelle/VSCode closer to feature parity with Isabelle/jEdit, but also paves the way for future integrations with a broader range of development environments.

## Fonts & Logo

The thesis uses the following fonts:
- Isabelle's modified DejaVu Sans Mono
- [DejaVu Sans](https://dejavu-fonts.github.io/)
- [JetBrains Mono](https://www.jetbrains.com/lp/mono/)
- [Noto Sans Mono](https://fonts.google.com/noto/specimen/Noto+Sans+Mono)
- [STIX Two](https://www.stixfonts.org/)

For ease of building, these are all included in the `fonts` directory.

It also requires a TUM's logo in svg format, included as `resources/tum-logo.svg` and grabbed from [MyTUM-Portal](https://portal.mytum.de/corporatedesign/index_html).
