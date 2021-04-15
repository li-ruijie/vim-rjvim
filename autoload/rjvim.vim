let s:cpo_save = &cpo
set cpo&vim

function! rjvim#app_colourscheme_switchsafe(colour) "{{
    if !exists('s:known_links') "{{
        let s:known_links = {}
    endif "}}
    function! s:Find_links() "{{
        " Find and remember links between highlighting groups.
        redir => listing
        try
            silent highlight
        finally
            redir END
        endtry
        for line in split(listing, "\n")
            let tokens = split(line)
            " We're looking for lines like "String xxx links to Constant" in the
            " output of the :highlight command.
            if len(tokens) ==# 5 && tokens[1] ==# 'xxx' && tokens[2] ==# 'links' && tokens[3] ==# 'to'
                let fromgroup = tokens[0]
                let togroup = tokens[4]
                let s:known_links[fromgroup] = togroup
            endif
        endfor
    endfunction "}}
    function! s:Restore_links() "{{
        " Restore broken links between highlighting groups.
        redir => listing
        try
            silent highlight
        finally
            redir END
        endtry
        let num_restored = 0
        for line in split(listing, "\n")
            let tokens = split(line)
            " We're looking for lines like "String xxx cleared" in the
            " output of the :highlight command.
            if len(tokens) ==# 3 && tokens[1] ==# 'xxx' && tokens[2] ==# 'cleared'
                let fromgroup = tokens[0]
                let togroup = get(s:known_links, fromgroup, '')
                if !empty(togroup)
                    execute 'hi link' fromgroup togroup
                    let num_restored += 1
                endif
            endif
        endfor
    endfunction "}}
    function! s:AccurateColorscheme(colo_name) "{{
        call <SID>Find_links()
        exec "colorscheme " a:colo_name
        call <SID>Restore_links()
    endfunction "}}
    call <SID>AccurateColorscheme(a:colour)
endfunction "}}
function! rjvim#app_colourssw_switchcolours(dir) "{{
    if !exists('g:colourssw_combi')
        for i in getcompletion('', 'color')
            for j in ['dark', 'light']
                let g:colourssw_combi += [[i, j]]
            endfor
        endfor
    endif
    if !exists('g:colourssw_default')
        let g:colourssw_default = [g:colors_name, &g:background]
    endif
    let g:colourssw_current       = [g:colors_name, &g:background]
    let g:colourssw_current_ind   = index(g:colourssw_combi, g:colourssw_current)
    let g:colourssw_current_ind = a:dir ==# '+' ?
        \ g:colourssw_current_ind ==# (len(g:colourssw_combi) - 1) ?
        \ 0 : g:colourssw_current_ind + 1 :
        \ g:colourssw_current_ind ==# 0 ?
        \ len(g:colourssw_combi) - 1 : g:colourssw_current_ind - 1
    let g:colourssw_current = g:colourssw_combi[g:colourssw_current_ind]
    call rjvim#app_colourscheme_switchsafe(g:colourssw_current[0])
    let &background = g:colourssw_current[1]
    redraw | echo g:colourssw_current
endfunction "}}

function! rjvim#app_fontsize(adjust) "{{
    if !exists('g:rjvim#defaultguifont')
        let g:rjvim#defaultguifont     = has('nvim') ? g:GuiFont : &g:guifont
    endif
    if !exists('g:rjvim#defaultguifontwide')
        let g:rjvim#defaultguifontwide = &g:guifontwide
    endif
    if a:adjust ==# 'default'
        let &g:guifont     = g:rjvim#defaultguifont
        let &g:guifontwide = g:rjvim#defaultguifontwide
    else
        function! s:fontsizevim(adjust) "{{
            let l:newsize = substitute(&g:guifont,
                \ ':h\zs\d\+',
                \ '\=eval(submatch(0)' . a:adjust . '1)', 'g')
            :execute 'let &g:guifont = "' . l:newsize . '"'
            let l:newsizewide = substitute(&g:guifontwide,
                \ ':h\zs\d\+',
                \ '\=eval(submatch(0)' . a:adjust . '1)', 'g')
            :execute 'let &g:guifontwide = "' . l:newsizewide . '"' |
                \ echom l:newsize . ',' l:newsizewide
        endfunction "}}
        function! s:fontsizenvim(adjust) "{{
            let l:newsize = substitute(g:GuiFont,
                \ ':h\zs\d\+',
                \ '\=eval(submatch(0)' . a:adjust . '1)', 'g')
            :execute 'GuiFont! ' . l:newsize
                \ echom l:newsize
        endfunction "}}
        if has('nvim') "{{
            :call s:fontsizenvim(a:adjust)
        else
            :call s:fontsizevim(a:adjust)
        endif "}}
    endif
endfunction "}}
function! rjvim#app_guitablabel() "{{
    " set up tab labels with tab number, buffer name, number of windows
    let l:label = ''
    let l:bufnrlist = tabpagebuflist(v:lnum)
    " Add '+' if one of the buffers in the tab page is modified
    for l:bufnr in l:bufnrlist
        if getbufvar(l:bufnr, '&modified')
            let l:label = '+'
            break
        endif
    endfor
    " Append the buffer name
    let l:bnr = bufnr(l:bufnrlist[tabpagewinnr(v:lnum) - 1])
    let l:name = bufname(l:bufnrlist[tabpagewinnr(v:lnum) - 1])
    " give a name to no-name documents
    let l:name = l:name ==? '' ?
        \(&buftype ==? 'quickfix' ?
        \'[Quickfix List]' :
        \'[No Name]') :
        \ fnamemodify(l:name,':t')
    let l:label = '['.v:lnum.':'.l:bnr.'] '.l:name.' '.l:label
    return l:label
endfunction "}}
" mods "{{{
if !(!has('gui_running') || (!has('win32') && !has('win64')))
    let g:mod_dll_path =
        \ expand('<sfile>:p:h:h') . '/dll/' . (has('win64') ?
        \ 'mod64.dll' : 'mod32.dll')
    function! rjvim#app_modsetalphadll(alpha) "{{{
        call libcallnr(g:mod_dll_path, "SetAlpha", 0+a:alpha)
    endfunction "}}}
    function! rjvim#app_modenablemaxdll() "{{{
        call libcallnr(g:mod_dll_path, "EnableMaximize", 1)
    endfunction "}}}
    function! rjvim#app_moddisablemaxdll() "{{{
        call libcallnr(g:mod_dll_path, "EnableMaximize", 0)
    endfunction "}}}
    function! rjvim#app_modenablealwaystopdll() "{{{
        call libcallnr(g:mod_dll_path, "EnableTopMost" , 1)
    endfunction "}}}
    function! rjvim#app_moddisablealwaystopdll() "{{{
        call libcallnr(g:mod_dll_path, "EnableTopMost" , 0)
    endfunction "}}}
endif "}}}

function! rjvim#fmt_autoformattoggle() "{{
    let l:formatoptionsoperator = strridx(&l:formatoptions, "a") > 0 ?
        \ '-' : '+'
    :execute ':setlocal formatoptions' . l:formatoptionsoperator . '=a' |
        \ echom 'autoformat'.l:formatoptionsoperator
endfunction "}}
function! rjvim#fmt_breakonperiod() "{{
    call rjvim#fmt_formattext_long()
    silent! execute "normal! mT:.s/\\. /.\\r/e\<CR>`T:delmarks T\<CR>^:DeleteTrailingWhitespace\<CR>"
endfunction "}}
function! rjvim#fmt_formattext_short() "{{
    let s:origtextwidth = &l:textwidth
    let &l:textwidth = g:textwidth
    execute 'normal! gwap\<CR>'
    let &l:textwidth = s:origtextwidth
endfunction "}}
function! rjvim#fmt_formattext_long() "{{
    let s:origtextwidth = &l:textwidth
    let &l:textwidth = 800000000
    silent! execute "normal! mTgwap\<CR>`T"
    silent! execute 's/\s\s\+/ /e'
    silent! execute "normal! ^:DeleteTrailingWhitespace\<CR>`T:delmarks T\<CR>"
    let &l:textwidth = s:origtextwidth
endfunction "}}

function! rjvim#sys_backupenable() "{{
    setlocal undofile
    setlocal backup
    function! s:setupbackup()
        let l:backupdir = fnameescape('.file-backup/' . expand('%'))
        call rjvim#sys_backupmkdir(l:backupdir)
        let &l:backupdir = l:backupdir
        let &l:backupext = '.' . strftime("%Y%m%d%H%M%S")
    endfunction
    augroup enablebackupsprewrite "{{
        autocmd!
        autocmd BufWritePre * call s:setupbackup()
    augroup END "}}
endfunction "}}
function! rjvim#sys_backupmkdir(targetdir) "{{
    if empty(glob(a:targetdir))
        call mkdir(a:targetdir, "p")
    endif
endfunction "}}
function! rjvim#sys_insertmute_on(motion) "{{
    set eventignore+=InsertLeave,InsertEnter
    return "\<C-o>" . a:motion
endfunction "}}
function! rjvim#sys_insertmute_off() "{{
    set eventignore-=InsertLeave,InsertEnter
    return "\<Ignore>"
endfunction "}}
function! rjvim#sys_performanceswitch(mode) "{{
    let g:performance_mode =
        \ a:mode ==# 0 ? 0 :
        \ a:mode ==# 1 ? 1 :
        \ a:mode ==# 2 ? g:performance_mode ? 0 : 1 :
        \ g:performance_mode
    if g:performance_mode
        set nocursorline
        if !has('nvim')
            set renderoptions=
        endif
        set noshowmatch
        redraw | echo "FAST"
    else
        set cursorline
        if !has('nvim')
            set renderoptions=type:directx
        endif
        set showmatch
        redraw | echo "SLOW"
    endif
endfunction "}}

function! rjvim#ut_add_ln(pad, width) "{{
    let s:width =
        \ a:width ==# 0 ?
        \ strlen(line("$")) : a:width
    let s:pad =
        \ a:pad ==# '' || a:pad ==# '0' ?
        \ a:pad : '0'
    silent! execute '%s/^/\=printf(''%' . s:pad . s:width . 'd '', line(''.''))'
endfunction "}}
function! rjvim#ut_gensep(comment, head, body, tail, level) "{{
    let l:textwidth   = exists('g:textwidth') ? g:textwidth : 80
    let l:length      = l:textwidth - (a:level * 10)
    let l:comment     = a:comment ==# ['auto'] ? split(&l:commentstring, '%s') : a:comment
    let l:comment_len = len(l:comment)
    if !(l:comment_len == 0 || l:comment_len > 2)
        let l:head = l:comment[0] . a:head
        let l:tail = len(l:comment) == 2 ?  a:tail . l:comment[1] : a:tail
    else
        return 'ERROR'
    endif
    let l:line      = getline('.')
    let l:sep       =
        \ l:head
        \ . repeat(a:body,
        \ reduce(map([ l:head, a:body, l:tail ],
        \ 'strlen(v:val)'), { acc, val -> acc - val},
        \ l:length + 1))
        \ . l:tail
    call setline('.',
        \ strpart(l:line, 0, col('.') - 1)
        \ . l:sep
        \ . strpart(l:line, col('.') - 1))
endfunction "}}
function! rjvim#ut_initvar(var, val) "{{
    execute 'let ' . a:var . ' = exists(''' . a:var . ''') ? ' . a:var . ': ' . a:val
endfunction "}}
function! rjvim#ut_multifunc(funcs, init) "{{
    return reduce(a:funcs, { acc, val -> eval(val . '(' . string(acc) . ')') }, a:init)
endfunction "}}
function! rjvim#ut_spellacceptfirst() "{{
    execute 'normal! mT1z=`T:delmarks T\<CR>'
endfunction "}}

let &cpo = s:cpo_save
unlet s:cpo_save
