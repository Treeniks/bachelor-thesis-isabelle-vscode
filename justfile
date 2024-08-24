all: thesis presentation

thesis:
    typst compile thesis.typ --font-path ./fonts

watch:
    typst watch thesis.typ --font-path ./fonts

presentation:
    typst compile presentation.typ --font-path ./fonts

watch-presentation:
    typst watch presentation.typ --font-path ./fonts

clean:
    rm -rf thesis.pdf
