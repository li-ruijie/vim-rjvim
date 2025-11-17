vim9script
const cpo_save = &cpo
set cpo&vim

# Plug mappings for rjvim9 {{
## Font size adjustments {{
nnoremap <silent> <Plug>(rjvim-fontsize-decrease) <ScriptCmd>rjvim9#App_fontsize('-')<CR>
nnoremap <silent> <Plug>(rjvim-fontsize-increase) <ScriptCmd>rjvim9#App_fontsize('+')<CR>
nnoremap <silent> <Plug>(rjvim-fontsize-default)  <ScriptCmd>rjvim9#App_fontsize('default')<CR>
# }}
## Color scheme switching {{
nnoremap <silent> <Plug>(rjvim-colorscheme-next) <ScriptCmd>rjvim9#App_colourssw_switchcolours('+')<CR>
nnoremap <silent> <Plug>(rjvim-colorscheme-prev) <ScriptCmd>rjvim9#App_colourssw_switchcolours('-')<CR>
# }}
## Spell checking {{
nnoremap <silent> <Plug>(rjvim-spell-accept-first) <ScriptCmd>rjvim9#Ut_spellacceptfirst()<CR>
inoremap <silent> <Plug>(rjvim-spell-accept-first) <ScriptCmd>rjvim9#Ut_spellacceptfirst()<CR>
# }}
# }}
# DTWS {{
# load once only {{
if exists('g:rjvim9#DTWS_loaded') # {{
    finish
endif # }}
g:rjvim9#DTWS_loaded = 1
# }}
# configuration {{
if !exists('g:rjvim9#DTWS') # {{
    g:rjvim9#DTWS = 0
endif # }}
if !exists('g:rjvim9#DTWS_action') # {{
    g:rjvim9#DTWS_action = 'abort'
endif # }}
# }}
# autocmds {{
augroup DTWS # {{
    autocmd!
    autocmd BufWritePre *
        \ try
        \ | call rjvim9#Ut_DTWS_interceptwrite()
        \ | catch /^DTWS:/
        \ | echoerr substitute(v:exception, '^\CDTWS:\s*', '', '')
        \ | endtry
augroup END # }}
# }}
# command: DTWS {{
def DTWSCommand(line1: number, line2: number)
    var isModified = &l:modified
    setline(line1, getline(line1))
    rjvim9#Ut_DTWS_delete(line1, line2)
    if !isModified
        setlocal nomodified
    endif
enddef

command! -bar -range=% DTWS DTWSCommand(<line1>, <line2>)
# }}
# }}

&cpo = cpo_save
