#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

== Isabelle

From proving the prime number theorem @prime-number-theorem, over a verified microkernel @verified-microkernel, to a formalization of a sequential Java-like programming language @jinja; Isabelle has been used for various and numerous formalizations and proofs since its initial release in 1986. Additionally, the Archive of Formal Proofs #footnote[https://www.isa-afp.org/] hosts a journal-style collection of many more of such proofs constructed in Isabelle.

// #quote(attribution: <paulson-next-700>, block: true)[Isabelle was not designed; it evolved. Not everyone likes this idea.]

=== #isar

When one wants to write an Isabelle theory, i.e. a document containing a number of theorems, lemmas, function definitions and more, Isabelle offers its own proof language called #emph(isar), allowing its users to write human-readable structured proofs @manual-isar-ref. An example theory and #isar proof can be seen in @list:example-theory.

The #isar syntax consists of three main syntactic concepts: _Commands_, _methods_ and _attributes_. Particularly relevant for us are the commands, which include keywords like `theorem` to state a proposition followed by a proof, or `apply` to apply a proof method.

#figure(

  align(left, rect(
    fill: luma(235),
    radius: 5%,
  )[
    #let blue = rgb(42, 100, 149)
    #let green = rgb(67, 151, 106) // used for imports, begin, where etc.
    #let green2 = rgb(58, 126, 38) // used for f, A, a, x etc.
    #let lightblue = rgb(67, 151, 247)
    #let purple = rgb(145, 51, 221) // used for 'a
    #let lightpurple = rgb(146, 104, 247) // used for add
    #let orange = rgb(196, 111, 51)

    #show raw: set text(font: "Isabelle DejaVu Sans Mono")
    #show "from": set text(blue, weight: "semibold")
    #show "then": set text(blue, weight: "semibold")
    #show "have": set text(blue, weight: "semibold")
    #show "by": set text(blue, weight: "semibold")
    #show "theory": set text(blue, weight: "semibold")
    #show "proof": set text(blue, weight: "semibold")
    #show "qed": set text(blue, weight: "semibold")
    #show "theorem": set text(blue, weight: "semibold")

    #show "imports": set text(green, weight: "semibold")
    #show "begin": set text(green, weight: "semibold")
    #show "end": set text(green, weight: "semibold")
    #show "where": set text(green, weight: "semibold")

    #show "obtain": set text(lightblue, weight: "semibold")
    #show "assume": set text(lightblue, weight: "semibold")
    #show "show": set text(lightblue, weight: "semibold")

    #show "'a": set text(purple)
    #show "add": set text(lightpurple)

    `theory Example
  imports Main
begin

theorem "∄`#text(green2)[`f`]` :: 'a ⇒ 'a set. surj(`#text(green2)[`f`]`)"
proof
  assume "∃`#text(green2)[`f`]` :: 'a ⇒ 'a set. surj(`#text(green2)[`f`]`)"
  then obtain `#text(orange)[`f`]` :: "'a ⇒ 'a set" where a: "surj(`#text(orange)[`f`]`)" by blast
  from a have b: "∀`#text(green2)[`A`]`. ∃`#text(green2)[`a`]`. `#text(green2)[`A`]` = `#text(orange)[`f`]` `#text(green2)[`a`]`" by (simp add: surj_def)
  from b have c: "∃`#text(green2)[`a`]`. {(`#text(green2)[`x`]` :: 'a). `#text(green2)[`x`]` ∉ `#text(orange)[`f`]` `#text(green2)[`x`]`} = `#text(orange)[`f`]` `#text(green2)[`a`]`" by blast
  from c show False by blast
qed

end`
  ]),
  caption: [Example Isabelle theory with #isar proof.],
  kind: raw,
  placement: auto,
) <list:example-theory>

=== Implementation Design

Isabelle's core implementation languages are _ML_ and _Scala_. Generally, the ML code is responsible for Isabelle's purely functional and mathematical domain, e.g. its LCF-style kernel~@paulson-next-700@lcf-to-isabelle, while Scala is responsible for Isabelle's physical domain, e.g. everything to do with the UI and IO~@manual-system[Chapter~5]. Many modules within the Isabelle code base exist in both Scala and ML, thus creating an almost seamless transition between the two.

Isabelle employs a monolithic architecture. While logic is split between modules, there is no limitation on how they can be accessed within the Isabelle system. Moreover, Scala, being a JVM based programming language, effortlessly integrates into jEdit's Java code base. Due to these two facts, when using #jedit, Isabelle is able to offer an interactive session where the entire Isabelle system has direct access to any data jEdit may hold, and the same is true the other way around. For example, #jedit has a feature to automatically indent an Isabelle theory. Internally, this automatic indentation uses both access to the Isabelle system and the jEdit buffer at the same time.

Isabelle, being a proof assistant, also does not follow conventional programming language design practices. For the sake of keeping correctness, the actual Isabelle kernel is kept small (albeit with performance related additions). Many of Isabelle's systems are built within Isabelle itself, including a majority of the #isar syntax.

#quote(block: true, attribution: <markarius-isabelle-vscode-2017>)[Note that static grammar and language definitions are not ideal: Isabelle syntax depends on theory imports: new commands may be defined in user libraries.]

Even quite fundamental keywords such as `theorem` do not exist statically, but are instead defined in user space. When editing a theory in #jedit, the syntax highlighting is mostly done dynamically.

=== Output and State Panels <background:output-and-state-panels>

#figure(
  box(stroke: 1pt, image("/resources/jedit1.png", width: 80%)),
  caption: [JEdit with both output and state panels open. Output on the bottom, state on the right.],
  kind: image,
  placement: auto,
) <jedit1>

Isabelle has a few different types of panels which give crucial information to the user. The two most relevant to us are the _output_ panel and _state_ panels as seen in @jedit1. The point of the output panel is to show messages that correspond to a given command, which can include general information, warnings or errors. This also means, that the content of the output panel is directly tied to a specific command in the theory. The command is typically determined by the current position of the caret.

State panels on the other hand display the current internal proof state within a proof. It is possible to have multiple state panels open, which may show states at different positions within the document. Whether moving the caret updates the currently displayed output or state depends on the _Auto update_ setting of the respective panel.

=== Symbols <background:isabelle-symbols>

Isabelle uses a lot of custom symbols to allow logical terms to be written in a syntax close to that of mathematics. The concept of what an _Isabelle symbol_ is exactly is rather broad, so for simplicity we will focus primarily on a certain group of symbols typically used in mathematical formulas.

#figure(
  table(
    columns: 2,
    stroke: (x, y) => (
      left: if x > 0 { .5pt } else { 0pt },
      right: 0pt,
      top: 0pt,
      bottom: 0pt,
    ),
    align: left,

    [*ASCII Representation*], [`\<Longrightarrow>`],
    [*Name*], [`Longrightarrow`],
    [*UTF-16 Codepoint*], [`0x27F9`],
    [*Abbreviations*], [#isabelle(`.>`), #isabelle(`==>`)],
  ),
  caption: [Symbol data of #isabelle(`⟹`).],
  kind: table,
  placement: auto,
) <symbol-data-example>

Each Isabelle symbol roughly consists of four components: An ASCII representation of the symbol, a name, an optional #box[UTF-16] code point and a list of abbreviations for this symbol. These four are not the whole story, however for the sake of simplicity, we will skip some details.

As an example, let's say you write the implication $A ==> B$ in Isabelle. Within jEdit, you will see it written out as #isabelle(`A ⟹ B`), however internally the #isabelle(`⟹`) is an Isabelle symbol. Its corresponding data is outlined in @symbol-data-example.

To deal with these symbols, #jedit uses a custom encoding called #emph(utf8isa). This encoding ensures that the user sees #isabelle(`A ⟹ B`) while the actual content of the underlying file is "`A \<Longrightarrow> B`". However, Isabelle has no trouble dealing with cases where the actual #isabelle(`⟹`) Unicode symbol is used within a file.

There are a few reasons why this special system exists instead of just encoding the files in UTF-16 or UTF-8. Unicode is somewhat inconsistent when it comes to #sub[subscript] and #super[superscript] support (e.g. while the capital letters A to W exist in superscript, X Y and Z currently do not). Isabelle instead adds #isabelle(`\<^sub>`) and #isabelle(`\<^sup>`) prefixes to letters and numbers, which can also be nested. Additionally, by encoding theories with simple ASCII characters, they can be viewed with almost any font, and don't require more advanced Unicode support.

// #TODO[
//   Add explanation why this custom encoding is used instead of just unicode:
//   - sub/sup not consistent in Unicode, can even be nested in Isabelle
//   - not dependent on font Unicode support, file can be viewed with virtually any font if needed
// ]

=== #vscode <background:isabelle-vscode>

#figure(
  box(stroke: 1pt, image("/resources/vscode1-light.png", width: 80%)),
  caption: [VSCode with both output and state panels open. Output on the bottom, state on the right.],
  kind: image,
  placement: auto,
) <vscode1>

Isabelle consists of multiple different components. #jedit is one such component. When we refer to #vscode, we are actually referring to three different Isabelle components: The Isabelle _language server_ which is a part of #scala, Isabelle's own patched _VSCodium_ #footnote[https://vscodium.com/], and the VSCode _extension_ written in TypeScript. #footnote[https://www.typescriptlang.org/] Note in particular that when running #vscode, Isabelle does not actually use a standard distribution of VSCode. Instead, it is a custom VSCodium package. VSCodium is a fully open-source distribution of Microsoft's VSCode with some patches to disable telemetry as well as replacing the VSCode branding with that of VSCodium.

Isabelle adds its own patches on top of VSCodium, in order to add a custom encoding mimicking the functionality of #jedit described in @background:isabelle-symbols, as well as integrating custom Isabelle-specific fonts. Since neither adding custom encodings nor including custom fonts is possible from within a VSCode extension, these patches exist instead.

The concept of output and state panels exist equivalently within #vscode as seen in @vscode1, although it is currently not possible to create multiple state panels for reasons outlined in @state-init.

Generally speaking, the goal of #vscode is to mimic the functionality of #jedit as closely as possible. As such, many issues described and solved within this work stem from a discrepancy between the two, and #jedit will often serve as the reference implementation.
