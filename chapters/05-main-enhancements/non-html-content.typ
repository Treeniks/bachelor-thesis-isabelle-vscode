#import "/utils/todo.typ": TODO
#import "/utils/isabelle.typ": *

== Non-HTML Content for Panels <enhance:non-html>

The output and state panels in #vscode were previously always sent as HTML content by the language server. The server sends #box[`PIDE/dynamic_output`] and #box[`PIDE/state_output`] notifications with output and state content respectively. We will focus on content for the output panel in this section, however everything is almost equivalently done for state panel content.

The #box[`PIDE/dynamic_output`] notification only contained a single `content` value, which was a string containing the panel's content. As mentioned, this content used to be HTML content that was displayed by #vscode in a WebView. However, not every code editor has the ability to natively display HTML content, and there used to be no way for a language client to get pure text content instead.

We added a new Isabelle system option called #box[`vscode_html_output`]. If disabled, the language server skips the conversion to HTML and sends text content instead. However, this poses a new problem: The conversion to HTML added highlighting to the panel content. It takes the source XML body, extracts the relevant decoration markup and uses it to generate equivalent HTML markup. Skipping this conversion and sending pure text instead also meant the language client got no highlighting within these panels. The Neovim language client prototype mentioned in @intro:motivation had this problem, as seen in @fig:neovim-no-decs.

#{
  show figure.caption: it => box(width: 71%, it)

  columns(2)[
    #figure(
      box(stroke: 1pt, image("/resources/neovim-no-decs-light.png", width: 100%)),
      kind: image,
      caption: [Neovim Isabelle client without decorations in output panel.],
      // placement: bottom,
    ) <fig:neovim-no-decs>
    #colbreak()
    #figure(
      box(stroke: 1pt, image("/resources/neovim-with-decs-light.png", width: 100%)),
      kind: image,
      caption: [Neovim Isabelle client with decorations in output panel.],
      // placement: bottom,
    ) <fig:neovim-with-decs>
  ]
}

Decorations within state and output panels are quite important, as they provide more than just superficial visuals. There are many cases when writing Isabelle proofs where a single name is used for two or more individual variables. Isabelle also often generates its own names within proofs, and that generation may introduce further overlaps of identifiers. This may create goals like #isabelle[#text(blue)[`x`]` = `#text(green)[`x`]] that are not provable because the left #isabelle[#text(blue)[`x`]] is a different variable than the right #isabelle[#text(green)[`x`]]. The only way to differentiate these variables in these cases is by their color. If the colors are missing, the goal will look like #isabelle(`x = x`).

To fix this, we added an optional `decorations` value to #box[`PIDE/dynamic_output`] and #box[`PIDE/state_output`] notifications, one that is only given when HTML output is disabled. The form of this value is the same as the `entries` value of the #box[`PIDE/decoration`] notifications described in @enhance:decorations. That way, even when the server sends non-HTML panel content, the client can apply the given decorations to the respective panel. The result of adding this functionality into Neovim's language client prototype can be seen in @fig:neovim-with-decs.

// To extract the decoration markup from the output and state XML bodies, we used Isabelle's internal `Markup_Tree` module.

// #TODO[
//   - currently server sends output always in HTML format
//   - VSCode can display HTML, but not all clients can
//   - now can disable HTML output and send pure text instead with option
//   - added decorations to the message if HTML is disabled (biggest usability win in neovim)
// ]
