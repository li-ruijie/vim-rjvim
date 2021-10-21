if exists('g:loaded_DeleteTrailingWhitespace')
    finish
endif
let g:loaded_DeleteTrailingWhitespace = 1
" configuration
if ! exists('g:DeleteTrailingWhitespace')
    let g:DeleteTrailingWhitespace = 'highlighted'
endif
if ! exists('g:DeleteTrailingWhitespace_Action')
    let g:DeleteTrailingWhitespace_Action = 'abort'
endif
if ! exists('g:DeleteTrailingWhitespace_ChoiceAffectsHighlighting')
    let g:DeleteTrailingWhitespace_ChoiceAffectsHighlighting = 1
endif
" autocmds
augroup DeleteTrailingWhitespace
    autocmd!
    autocmd BufWritePre * try | call DeleteTrailingWhitespace#InterceptWrite() | catch /^DeleteTrailingWhitespace:/ | echoerr substitute(v:exception, '^\CDeleteTrailingWhitespace:\s*', '', '') | endtry
augroup END
" commands
function! s:Before()
    let s:isModified = &l:modified
endfunction
    function! s:After()
    if ! s:isModified
        setlocal nomodified
    endif
    unlet s:isModified
    endfunction
command! -bar -range=% DeleteTrailingWhitespace call <SID>Before()<Bar>call setline(<line1>, getline(<line1>))<Bar>call <SID>After()<Bar>call DeleteTrailingWhitespace#Delete(<line1>, <line2>)
