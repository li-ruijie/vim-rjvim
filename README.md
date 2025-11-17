# vim-rjvim

Personal Vim9 script plugin with utility functions for GUI font management, colorscheme switching, text formatting, file templates, backup management, and trailing whitespace handling.

Neovim port: https://github.com/li-ruijie/vim-rjnvim

## Requirements

- Vim 9.0+ with Vim9 script support

## Installation

Using a plugin manager (e.g., vim-plug):

```vim
Plug 'li-ruijie/vim-rjvim'
```

Or clone to your pack directory:

```
git clone https://github.com/li-ruijie/vim-rjvim ~/.vim/pack/plugins/start/vim-rjvim
```

## Features

### Font Size (GUI)

```vim
nmap <C-=> <Plug>(rjvim-fontsize-increase)
nmap <C--> <Plug>(rjvim-fontsize-decrease)
nmap <C-0> <Plug>(rjvim-fontsize-default)
```

### Colorscheme Switching

```vim
nmap <F3> <Plug>(rjvim-colorscheme-prev)
nmap <F4> <Plug>(rjvim-colorscheme-next)
```

### Spell Checking

```vim
nmap z= <Plug>(rjvim-spell-accept-first)
```

### DTWS (Delete Trailing White Space)

Automatically handles trailing whitespace on save.

```vim
let g:rjvim9#DTWS = 1           " Enable (0 to disable)
let g:rjvim9#DTWS_action = 'delete'  " 'delete' or 'abort'
```

Manual command: `:DTWS` (works with range)

### Other Functions

| Function | Description |
|----------|-------------|
| `rjvim9#Sys_info()` | Set `g:os`, `g:root`, `g:dirsep` |
| `rjvim9#Sys_backupenable()` | Enable timestamped backups in `.vbak/` |
| `rjvim9#Ft_templates()` | Load file templates on new files |
| `rjvim9#Fmt_formattext_short()` | Format paragraph to `g:textwidth` |
| `rjvim9#Fmt_autoformattoggle()` | Toggle `formatoptions+=a` |
| `rjvim9#App_guitablabel()` | Custom tab label format |

## License

GPL-3.0
