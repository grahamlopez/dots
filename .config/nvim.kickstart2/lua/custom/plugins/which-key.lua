return { -- Useful plugin to show you pending keybinds.
  'folke/which-key.nvim',
  event = 'VimEnter', -- Sets the loading event to 'VimEnter'
  config = function() -- This is the function that runs, AFTER loading
    require('which-key').setup {
      key_labels = {
        ['<space>'] = 'SPC',
        ['<cr>'] = 'RET',
        ['<tab>'] = 'TAB',
      },
      window = {
        border = 'rounded',
        position = 'bottom',
        margin = { 1, 3, 1, 3 },
        padding = { 1, 3, 1, 3 },
        winblend = 10,
      },
    }

    -- Document existing key chains
    require('which-key').register {
      ['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
      ['<leader>d'] = { name = '[D]ocument', _ = 'which_key_ignore' },
      ['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
      ['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
      ['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
      ['<leader>t'] = { name = '[T]oggle', _ = 'which_key_ignore' },
      ['<leader>h'] = { name = 'Git [H]unk', _ = 'which_key_ignore' },
    }

    -- TODO: integrate this straight copy/paste from old config
    local nvs_mode_mappings = {
      u = {
        -- wrap, textwidth, conceal, spelling, diagnostics
        name = ' [u]i',
        C = { '<cmd>Togglecolorcolumn<cr>', '[c]olorcolumn toggle at textwidth' },
        -- TODO: it would be nice to know which are light vs. dark themes
        c = { "<cmd>lua require'telescope.builtin'.colorscheme( { enable_preview = true } )<cr>", '[c]olorscheme' },
        h = { '<cmd>Togglecursorline<cr>', '[h]ighlight cursorline' },
        t = { '<cmd>TransparentToggle<cr>', '[t]oggle transparent background' },
      },
    }
    local nvs_mode_opts = {
      mode = { 'n', 'v', 's' },
      prefix = '<leader>',
    }
    require('which-key').register(nvs_mode_mappings, nvs_mode_opts)

    -- visual mode
    require('which-key').register({
      ['<leader>h'] = { 'Git [H]unk' },
    }, { mode = 'v' })
  end,
}

--[[

A catalogue of kickstart keybindings

K   LSP: hover documentation
>   indent right
<   indent left

s   [s]urround
  a   [a]dd surround 
  d   [d]elete surround
  F   [f]ind left surround
  f   [f]ind right surround
  h   [h]ighlight surround
  n   update 'Mini.surround.config.n_lines'
  r   [r]eplace surround


<leader><leader>  find existing buffers  
<leader>/   fuzzy search current buffer   
<leader>D   LSP: type [d]efinition
<leader>e   show diagnostic error messages
<leader>f   format buffer
<leader>q   open diagnostic quickfix list
<leader>x   execute the current line
<leader><leader>x  execute the current file

<leader>c   [c]ode
          a   LSP: code [a]ction

<leader>d   [d]ocument
          s   LSP: document [s]ymbols

<leader>h   git [h]unk

<leader>r   [r]ename
          n   LSP: re[n]ame

<leader>s   [s]earch
          .   search recent files
          /   search [/] in open files
          d   search [d]iagnostics
          f   search [f]iles
          g   search by [g]rep
          h   search [h]elp
          k   search [k]eymaps
          n   search [n]eovim filenames
          r   search [r]esume
          s   search [s]elect telescope
          w   search current [w]ord

<leader>t   [t]oggle
          h   LSP: toggle inlay [h]ints

<leader>w   [w]orkspace
          s   LSP: workspace [s]ymbols

---------------
A catalogue of keybindings from my old configs. (t) == to implement

'gd' goto definition (built-in)
<c-g> find word under cursor (telescope grep)
<c-k> vim help for word under cursor (telescope) - should these k/K be combined/adapted based on filetype and/or path?
<c-K> man page for word under cursor (telescope)
<c-h> lsp hover
<c-b> buffer list (telescope) - watch out for collisions with other utilities e.g. telescope or whatever
<c-n/p> forward/back in buffer list (ensure it doesn't conflict with other things e.g. telescope)

<leader>a   [a]pps
          a   [a]erial toggle

<leader>b   [b]uffer
          b   switch [b]uffer
          d   [d]elete buffer
          f   [f]ind buffers
          n   b[n]ext
          p   b[p]revious

<leader>f   [f]ind stuff
          C   neovim [C]onfig
          b   find [b]uffers
          e   [e]xplorer
          F   find [F]iles
          f   [f]uzzy find
          g   [g]rep
          h   [h]elp tags

<leader>h   [h]elp
          h   [h]elp
       (t)f   [f]uzzy search help
          k   help under cursor
          m   show key [m]apping
          v   [v]ertical help

<leader>l   [l]anguage server
          d   goto [d]efinition
          f   [f]ormat
          k   hover

<leader>s   [s]elect (telescope)
          s   [s]tart selection
          i   [i]ncrement
          c   s[c]ope incremental
          d   [d]ecrement

<leader>u   [u]i
          C   toggle [C]olorcolumn
          c   choose [c]olorscheme
          t   toggle [t]ransparent background

--]]
