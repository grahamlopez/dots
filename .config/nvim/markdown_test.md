# first H1

to demonstrate the issue:

1. collapse all folds with 'zM'. notice that only the H1's are visible
   are visible.
2. now add a `### second H3` between `## first sub H2` and `# second H2` with
   any content inside of it. Upon returning to normal mode, 'second H1' can no
   longer be closed and `# third H1` is also in the wrong location. Sometimes
   the details here change around, but folds no longer work right. This persists
   until exiting and reopening neovim

maybe these problems all have to do with having multiple H1 headings, and
following the Google Markdown style guide by only having a single H1 fixes most
of this? https://google.github.io/styleguide/docguide/style.html#document-layout

with nvim-ufo, it is kinda/mostly fixed. it still happens without nvim-ufo, but
a little differently

## first sub H2

lorem ipsum

### first H3

lorem ipsum

## second H2

lorem ipsum
