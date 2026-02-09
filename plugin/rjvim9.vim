vim9script
# Save and reset 'compatible' options to ensure consistent behaviour.
const cpo_save = &cpo
set cpo&vim

# Plug mappings for rjvim9 {{
## Font size adjustments {{
nnoremap <silent> <Plug>(rjvim-fontsize-decrease) <Cmd>call rjvim9#App_fontsize('-')<CR>
nnoremap <silent> <Plug>(rjvim-fontsize-increase) <Cmd>call rjvim9#App_fontsize('+')<CR>
nnoremap <silent> <Plug>(rjvim-fontsize-default)  <Cmd>call rjvim9#App_fontsize('default')<CR>
# }}
## Color scheme switching {{
nnoremap <silent> <Plug>(rjvim-colorscheme-next) <Cmd>call rjvim9#App_colourssw_switchcolours('+')<CR>
nnoremap <silent> <Plug>(rjvim-colorscheme-prev) <Cmd>call rjvim9#App_colourssw_switchcolours('-')<CR>
# }}
## Spell checking {{
nnoremap <silent> <Plug>(rjvim-spell-accept-first) <Cmd>call rjvim9#Ut_spellacceptfirst()<CR>
inoremap <silent> <Plug>(rjvim-spell-accept-first) <Cmd>call rjvim9#Ut_spellacceptfirst()<CR>
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
# Intercept every write to enforce trailing-whitespace policy.
# Exceptions prefixed "DTWS:" are caught and displayed as errors,
# which aborts the :write without leaving an unhandled exception.
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
# Strip trailing whitespace in the given range without marking an
# unmodified buffer as modified.  The no-op setline() ensures the
# buffer is touched so Ut_DTWS_delete can operate on it.
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

# Restore original 'compatible' options.
&cpo = cpo_save
