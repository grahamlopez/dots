# first H1

to demonstrate the issue:

1. collapse all folds with 'zM'. notice that only 'first H1' and 'second H1'
   are visible
2. now add a `## second sub H2` between `## first sub H2` and `# second H1` with
   any content inside of it. Upon returning to normal mode, 'second H1' can no
   longer be closed and `# third H1` is also in the wrong location. This
   persists until exiting and reopening neovim

## first sub H2

lorem ipsum

# second H1

lorem ipsum

# thrid H1

lorem ipsum
