vim9script
# Save and reset 'compatible' options to ensure consistent behaviour.
const cpo_save = &cpo
set cpo&vim

# App_colourscheme_switchsafe {{
# Switch colorscheme while preserving highlight-group links that Vim
# sometimes clears during the switch (e.g. "String links to Constant").
export def App_colourscheme_switchsafe(colour: string) # {{
    AccurateColorscheme(colour)
enddef # }}
# Cache of highlight links discovered before a colorscheme switch.
var known_links: dict<string> = {}
def Find_links() # {{
    # Find and remember links between highlighting groups.
    known_links = {}
    var listing: string
    redir => listing
    try
        silent highlight
    finally
        redir END
    endtry
    # We're looking for lines like "String xxx links to Constant" in the
    # output of the :highlight command.
    split(listing, "\n")
        ->mapnew((_, line) => split(line))
        ->filter((_, t) => len(t) == 5 && t[1] == 'xxx'
            && t[2] == 'links' && t[3] == 'to')
        ->foreach((_, t) => {
            known_links[t[0]] = t[4]
        })
enddef # }}
def Restore_links() # {{
    # Restore broken links between highlighting groups.
    var listing: string
    redir => listing
    try
        silent highlight
    finally
        redir END
    endtry
    # We're looking for lines like "String xxx cleared" in the
    # output of the :highlight command.
    split(listing, "\n")
        ->mapnew((_, line) => split(line))
        ->filter((_, t) => len(t) == 3 && t[1] == 'xxx' && t[2] == 'cleared'
            && !empty(get(known_links, t[0], '')))
        ->foreach((_, t) => {
            execute 'hi link' t[0] known_links[t[0]]
        })
enddef # }}
def AccurateColorscheme(colo_name: string) # {{
    Find_links()
    execute 'colorscheme' fnameescape(colo_name)
    Restore_links()
enddef # }}
# }}
# App_colourssw_switchcolours {{
# Cycle through every [colorscheme, background] combination.
# dir is '+' for next or '-' for previous, wrapping around at the ends.
export def App_colourssw_switchcolours(dir: string) # {{
    # Build the combination list once and cache it globally.
    if !exists('g:colourssw_combi')
        g:colourssw_combi = getcompletion('', 'color')
            ->mapnew((_, c) => [[c, 'dark'], [c, 'light']])
            ->flattennew(1)
    endif
    if !exists('g:colourssw_default')
        g:colourssw_default = [g:colors_name, &g:background]
    endif
    g:colourssw_current = [g:colors_name, &g:background]
    g:colourssw_current_ind = index(g:colourssw_combi, g:colourssw_current)
    # Reset to start if current scheme was changed externally.
    if g:colourssw_current_ind == -1
        g:colourssw_current_ind = 0
    endif
    # Advance or retreat with wrap-around.
    g:colourssw_current_ind = dir ==# '+' ?
        g:colourssw_current_ind == (len(g:colourssw_combi) - 1) ?
        0 : g:colourssw_current_ind + 1 :
        g:colourssw_current_ind == 0 ?
        len(g:colourssw_combi) - 1 : g:colourssw_current_ind - 1
    g:colourssw_current = g:colourssw_combi[g:colourssw_current_ind]
    App_colourscheme_switchsafe(g:colourssw_current[0])
    &background = g:colourssw_current[1]
    redraw | echo g:colourssw_current
enddef # }}
# }}
# App_conceal_automode {{
# Reveal concealed text while in insert mode and restore on leave.
# switch: 1 = enable, 0 or 2 = disable (2 is treated as off).
export def App_conceal_automode(switch: number) # {{
    var switch_val = switch == 2 ? 0 : switch
    if switch_val == 0
        return
    endif
    if &l:conceallevel != 0
        var conceallevel_init = &l:conceallevel
        augroup insertmode_conceal
            autocmd!
            autocmd InsertEnter * let &l:conceallevel = 0
            execute 'autocmd InsertLeave * let &l:conceallevel = '
                .. conceallevel_init
        augroup END
    endif
enddef # }}
# }}
# App_fontsize {{
# Adjust GUI font size by +1 or -1, or restore to default.
# adjust: '+', '-', or 'default'.
export def App_fontsize(adjust: string) # {{
    # Snapshot the original fonts on first call so 'default' can restore them.
    if !exists('g:rjvim9#defaultguifont') && &g:guifont != ''
        g:rjvim9#defaultguifont = &g:guifont
    endif
    if !exists('g:rjvim9#defaultguifontwide') && &g:guifontwide != ''
        g:rjvim9#defaultguifontwide = &g:guifontwide
    endif

    if adjust ==# 'default'
        App_fontsizerestore()
    else
        App_fontsizechange(adjust)
    endif
enddef # }}
def App_fontsizerestore() # {{
    if exists('g:rjvim9#defaultguifont')
        &g:guifont = g:rjvim9#defaultguifont
    endif
    if exists('g:rjvim9#defaultguifontwide')
        &g:guifontwide = g:rjvim9#defaultguifontwide
    endif
enddef # }}
def App_fontsizechange(adjust: string) # {{
    # Modify the :h<N> size field in the font name string.
    # \zs positions the match start after ":h" so only the digit is replaced.
    # The expression replacement evaluates e.g. str2nr("12") + 1 = 13.
    if adjust !=# '+' && adjust !=# '-'
        return
    endif
    var newsize = ''
    var newsizewide = ''

    if &g:guifont != ''
        newsize = substitute(&g:guifont,
            ':h\zs\d\+',
            '\=string(str2nr(submatch(0)) ' .. adjust .. ' 1)', 'g')
        &g:guifont = newsize
    endif
    if &g:guifontwide != ''
        newsizewide = substitute(&g:guifontwide,
            ':h\zs\d\+',
            '\=string(str2nr(submatch(0)) ' .. adjust .. ' 1)', 'g')
        &g:guifontwide = newsizewide
        echom newsize .. ',' .. newsizewide
    endif
enddef # }}
# }}
# App_guitablabel {{
# Generate a tab label: [tabnr:bufnr] filename +
# Intended for use with 'guitablabel' (&gtl).
export def App_guitablabel(): string
    var bufnrlist = tabpagebuflist(v:lnum)
    # Add '+' if one of the buffers in the tab page is modified
    var label = empty(copy(bufnrlist)
        ->filter((_, b) => getbufvar(b, '&modified'))) ? '' : '+'
    # Append the buffer name
    var bnr = bufnr(bufnrlist[tabpagewinnr(v:lnum) - 1])
    var name = bufname(bufnrlist[tabpagewinnr(v:lnum) - 1])
    # give a name to no-name documents
    name = name ==? '' ?
        (&buftype ==? 'quickfix' ?
        '[Quickfix List]' :
        '[No Name]') :
        fnamemodify(name, ':t')
    label = '[' .. v:lnum .. ':' .. bnr .. '] ' .. name .. ' ' .. label
    return label
enddef # }}

# Fmt_autoformattoggle {{
# Toggle the 'a' flag in 'formatoptions' (automatic paragraph reformatting).
export def Fmt_autoformattoggle() # {{
    var formatoptionsoperator = stridx(&l:formatoptions, "a") >= 0 ?
        '-' : '+'
    execute ":setlocal formatoptions" .. formatoptionsoperator .. "=a"
    echom "autoformat" .. formatoptionsoperator
enddef # }}
# }}
# Fmt_breakonperiod {{
# Join the paragraph into one long line, then split on sentence boundaries.
export def Fmt_breakonperiod() # {{
    Fmt_formattext_long()
    var save_pos = getcurpos()
    silent! execute ':.s/\. /.\r/ge'
    setpos('.', save_pos)
    # Strip only the split paragraph. A bare :DTWS spans the whole buffer,
    # which hangs under 'foldmethod=expr' (pandoc) on large files.
    silent! execute ":'{,'}DTWS"
enddef # }}
# }}
# Fmt_fixfileformat {{
# Remove stray carriage returns (\r) from a file that has mixed line endings.
# Re-reads the file as dos to let Vim normalise it, then restores the
# original 'fileformat'.  The buffer must be saved first.
export def Fmt_fixfileformat() # {{
    if &l:modified
        echom 'Save the file first.'
        return
    endif
    if search('\r', 'nw') > 0
        var fforig = &l:fileformat
        if &l:fileformat ==# 'dos'
            setlocal fileformat=unix
            write
        endif
        edit ++fileformat=dos
        &l:fileformat = fforig
        # The file on disk still has the old line endings until it is written.
        setlocal modified
    endif
enddef # }}
# }}
# Fmt_formattext_short {{
# Reformat the current paragraph using g:textwidth.
export def Fmt_formattext_short() # {{
    var origtextwidth = &l:textwidth
    # An operator in a closed fold takes the whole fold, so disable folding
    # while it runs.  Joined lines get one space after a sentence end.
    var foldenable = &l:foldenable
    var joinspaces = &joinspaces
    &l:textwidth = exists('g:textwidth') ? g:textwidth : 80
    &l:foldenable = false
    &joinspaces = false
    # An insert-mode cursor past the end of the line comes back from gw on
    # the last character, so step it over that character again.
    var pastend = col('.') > strlen(getline('.'))
    try
        execute 'normal! gwap'
    finally
        &l:textwidth = origtextwidth
        &l:foldenable = foldenable
        &joinspaces = joinspaces
    endtry
    if pastend
        setcursorcharpos(line('.'), charcol('.') + 1)
    endif
enddef # }}
# }}
# Fmt_formattext_long {{
# Join the current paragraph into a single long line, collapse multiple
# spaces, and fix double-space after sentence-ending periods.
export def Fmt_formattext_long() # {{
    var save_pos = getcurpos()
    var origtextwidth = &l:textwidth
    &l:textwidth = 800000000
    silent! execute "normal! gwap"
    silent! execute 's/\s\s\+/ /e'
    silent! execute 's/\(\.\)\( \u\l\)/\1 \2/e'
    # Restrict to the current line. A bare :DTWS spans the whole buffer,
    # which forces a full-buffer fold recompute under 'foldmethod=expr'
    # (as pandoc sets), making this extremely slow on large files.
    silent! execute ':.DTWS'
    &l:textwidth = origtextwidth
    setpos('.', save_pos)
enddef # }}
# }}
# Fmt_formattext_isolated {{
# Wrap the current paragraph in blank lines, reformat it, then remove them.
# Prevents reformatting from merging with adjacent paragraphs.
export def Fmt_formattext_isolated() # {{
    if getline('.') =~# '^\s*$'
        return
    endif
    FormatIsolated(line('.'), line('.'))
enddef # }}
# Format lines top..bottom, which hold the cursor, as one paragraph.  Blank
# lines added around them keep gwap from reaching past them, and are removed
# again afterwards.
def FormatIsolated(top: number, bottom: number) # {{
    append(bottom, '')
    append(top - 1, '')
    Fmt_formattext_short()
    # gw leaves the cursor in the block, so the first blank line below it is
    # the one added under the block.
    deletebufline(bufnr(), search('^\s*$', 'nW'))
    deletebufline(bufnr(), top)
enddef # }}
# }}
# Fmt_formattext_tex {{
# Reformat the LaTeX block under the cursor using g:textwidth.  A bare gwap
# takes the whole blank-line paragraph, joining \begin, \end, and \item lines
# into the text.  Find the block the way vimtex's formatter does, isolate it
# with blank lines, and format it with gw, which keeps the cursor in place.
export def Fmt_formattext_tex() # {{
    var lnum = line('.')
    if getline(lnum) =~# tex_alone
        return
    endif
    var up = range(lnum, 2, -1)
        ->indexof((_, l) => !TexJoins(getline(l - 1), getline(l)))
    var down = range(lnum, line('$') - 1)
        ->indexof((_, l) => !TexJoins(getline(l), getline(l + 1)))
    var top = up < 0 ? 1 : lnum - up
    var bottom = down < 0 ? line('$') : lnum + down
    FormatIsolated(top, bottom)
enddef # }}
# Pattern for a line that opens a block, which is vimtex's
# g:vimtex_format_border_begin plus \caption and the run-in \paragraph heading.
const tex_opens = '\v^\s*%(\\%(item|begin|end|caption|paragraph)|%(\\\[|\$\$)\s*$)'
# Pattern for a line that closes its block, taken from vimtex's
# g:vimtex_format_border_end.
const tex_closes = '\v\\%(\\\*?|clear%(double)?page|linebreak|new%(line|page)|pagebreak'
    .. '|%(begin|end)\{[^}]*\})\s*$|^\s*%(\\\]|\$\$)\s*$'
# Pattern for a line that joins neither neighbour, namely a blank line, a
# comment (text joined after it would be commented out), a heading or \label,
# or a bare command such as \noindent.
const tex_alone = '\v^\s*$|%(^|[^\\])\%|^\s*\\%(%(sub){,2}section|chapter|part|label)>'
    .. '|^\s*\\\a+\*?\s*$'
# Return whether LaTeX line a can be joined with line b below it.
def TexJoins(a: string, b: string): bool # {{
    return a !~# tex_closes && b !~# tex_opens && a !~# tex_alone && b !~# tex_alone
enddef # }}
# }}
# Fmt_insert_blank {{
# Insert blank lines above ('up'), below ('down'), or both ('updown').
export def Fmt_insert_blank(mode: string) # {{
    var lnum = line('.')
    # Insert below first, since inserting above moves the line down.
    if mode ==# 'down' || mode ==# 'updown'
        append(lnum, '')
    endif
    if mode ==# 'up' || mode ==# 'updown'
        append(lnum - 1, '')
    endif
enddef # }}
# }}

# Ft_sh_init {{
# Register a FileType autocmd that configures shell scripts for bash
# with syntax folding enabled.
export def Ft_sh_init() # {{
    augroup ftshinit
        autocmd!
        autocmd FileType sh Run_ftshinit()
    augroup END
enddef # }}
# Runs inside the FileType autocmd, so the options are buffer-local and
# the filetype is already sh.
def Run_ftshinit() # {{
    setlocal foldenable
    setlocal foldmethod=syntax
    g:is_bash = 1
    g:sh_fold_enabled = 7
    g:sh_no_error = 0
enddef # }}
# }}
# Ft_templates {{
# Load a file template based on the buffer's extension.  Templates are
# read from g:templates_path / g:templates_prefix.<ext>.
export def Ft_templates() # {{
    # Skip for special buffers (preview, help, quickfix, etc.)
    if &l:buftype != ''
        return
    endif
    var template = GetTemplateFN('%:e')
    if !filereadable(template)
        return
    endif
    var insert = readfile(template)
    appendbufline(bufnr(), 0, insert)
    &l:fileformat = GetFF(template)
enddef # }}
# Detect whether a file uses dos (CRLF) or unix (LF) line endings by
# reading the raw bytes and checking for 0D before the first 0A.
def GetFF(file: string): string # {{
    # Read the first 1024 bytes as a blob, convert to a hex string, then
    # split into two-character hex pairs (e.g. ['76', '69', '0D', '0A', ...]).
    var file_bytes = expand(file)
        ->fnameescape()
        ->readblob(0, 1024)
        ->string()
        ->split('.\{2}\zs')
    var filelen = len(file_bytes)
    var filelenbrk = filelen > 80 ? filelen / 2 : filelen
    var fileindex = index(slice(file_bytes, 0, filelenbrk), '0A')
    if fileindex == -1
        fileindex = filelenbrk
    endif
    var fileformat = fileindex > 0 && file_bytes[fileindex - 1] == '0D'
        ? 'dos' : 'unix'
    return fileformat
enddef # }}
# Build the full path to a template file for the given extension.
def GetTemplateFN(ext: string): string # {{
    var dirsep = IsWin() ? '\' : '/'
    return expand(g:templates_path)
        .. dirsep
        .. g:templates_prefix
        .. '.'
        .. expand(ext)
enddef # }}
# }}

# Sys_backupenable {{
# Enable persistent undo and timestamped backups under .vbak/<filename>/.
export def Sys_backupenable() # {{
    setlocal undofile
    setlocal backup
    augroup enablebackupsprewrite
        autocmd!
        autocmd BufWritePre * Setupbackup()
    augroup END
enddef # }}
# Create the backup directory and set the backup extension to the file's
# last-modified timestamp (YYYYMMDDHHmmSS) for unique versioned backups.
def Setupbackup() # {{
    var filename = expand('%')
    var backupdir = '.vbak/' .. filename
    if empty(glob(backupdir))
        mkdir(backupdir, "p")
    endif
    &l:backupdir = backupdir
    var fileftime = getftime(filename)
    var tformat = '%Y%m%d%H%M%S'
    &l:backupext = '.' .. (fileftime == -1 ?
        strftime("%Y%m%d%H%M%S") :
        strftime(tformat, getftime(filename)))
enddef # }}
# }}
# Sys_info {{
# Detect OS, root/admin status, and directory separator.
# Sets g:os ('windows', 'linux', 'unknown'), g:root (0 or 1), g:dirsep.
export def Sys_info() # {{
    g:os = IsWin() ? 'windows' :
        has('linux') ? 'linux' :
        'unknown'
    g:root = g:os ==# 'windows' ?
        filewritable('C:\Windows\System32') :
        $USER ==# 'root' ? 1 : 0
    g:dirsep = g:os ==# 'windows' ?
        '\' : '/'
enddef # }}
# Return 1 if any of the win16/win32/win64 features are present.
def IsWin(): number # {{
    return ['win16', 'win32', 'win64']->mapnew((_, v) => has(v))->max()
enddef # }}
# }}
# Sys_insertmute_off {{
# Re-enable InsertEnter/InsertLeave events after a muted motion.
export def Sys_insertmute_off(): string # {{
    set eventignore-=InsertLeave,InsertEnter
    return "\<Ignore>"
enddef # }}
# }}
# Sys_insertmute_on {{
# Suppress InsertEnter/InsertLeave events and return a <C-o> motion
# sequence.  Useful for insert-mode mappings that should not trigger
# autocmds (e.g. conceallevel toggling).
export def Sys_insertmute_on(motion: string): string # {{
    set eventignore+=InsertLeave,InsertEnter
    return "\<C-o>" .. motion
enddef # }}
# }}
# Sys_insertmute_move {{
# Perform a motion in insert mode without firing InsertEnter/InsertLeave.
export def Sys_insertmute_move(motion: string): string # {{
    return Sys_insertmute_on(motion) .. Sys_insertmute_off()
enddef # }}
# }}

# Ut_add_ln {{
# Prepend line numbers to every line in the buffer.
# pad: '0' for zero-padded, '' for space-padded.
# width: digit width (0 = auto-detect from last line number).
export def Ut_add_ln(pad: string, width: number) # {{
    var width_val = width == 0 ?
        strlen(line("$")) : width
    var pad_val = pad ==# '' || pad ==# '0' ?
        pad : '0'
    var format_str = '%' .. pad_val .. string(width_val) .. 'd '
    execute ':%s/^/\=printf(''' .. format_str .. ''', line(''.''))/'
enddef # }}
# }}
# Ut_gensep {{
# Generate a separator line (e.g. "# ========...========") at the cursor.
# comment: comment markers list, or ['auto'] to derive from 'commentstring'.
# head/body/tail: separator characters.
# level: indentation tier (each level reduces width by 10).
export def Ut_gensep(
    comment: any,
    head: string,
    body: string,
    tail: string,
    level: number
): string # {{
    var textwidth = exists('g:textwidth') ? g:textwidth : 80
    var length = textwidth - (level * 10)
    var comment_val = (type(comment) == v:t_list && comment == ['auto']) ?
        split(&l:commentstring, '%s') : comment
    var comment_len = len(comment_val)
    var head_val: string
    var tail_val: string
    if !(comment_len == 0 || comment_len > 2)
        head_val = comment_val[0] .. head
        tail_val = len(comment_val) == 2 ?
            tail .. comment_val[1] : tail
    else
        return 'ERROR'
    endif
    var line = getline('.')
    var sep = head_val
        .. repeat(body,
        reduce(mapnew([head_val, body, tail_val],
        (_, v) => strlen(v)), (acc, val) => acc - val,
        length + 1))
        .. tail_val
    setline('.',
        strpart(line, 0, col('.') - 1)
        .. sep
        .. strpart(line, col('.') - 1))
    return ''
enddef # }}
# }}
# Ut_initvar {{
# Set a variable by name only if it does not already exist.
export def Ut_initvar(var: string, val: string) # {{
    if !exists(var)
        execute var .. ' = ' .. val
    endif
enddef # }}
# }}
# Ut_multifunc {{
# Compose a list of function names into a pipeline, threading init through
# each in order: f3(f2(f1(init))).
export def Ut_multifunc(funcs: list<any>, init: any): any # {{
    return reduce(funcs,
        (acc, val) => eval(val .. '(' .. string(acc) .. ')'),
        init)
enddef # }}
# }}
# Ut_spellacceptfirst {{
# Accept the first spelling suggestion for the word under the cursor.
export def Ut_spellacceptfirst() # {{
    var save_pos = getcurpos()
    execute 'normal! 1z='
    setpos('.', save_pos)
enddef # }}
# }}

# Ut_DTWS_delete {{
# Remove trailing whitespace from lines startLnum..endLnum.
export def Ut_DTWS_delete(startLnum: number, endLnum: number) # {{
    var save_cursor = getpos('.')
    # Only rewrite lines that actually have trailing whitespace. Rewriting
    # every line (even unchanged) makes a whole-buffer :DTWS or the on-write
    # hook rebuild every fold under 'foldmethod=expr' (pandoc), which hangs.
    var pattern = Ut_DTWS_pattern()
    range(startLnum, endLnum)
        ->filter((_, lnum) => getline(lnum) =~# pattern)
        ->foreach((_, lnum) => setline(lnum, substitute(getline(lnum), pattern, '', '')))
    setpos('.', save_cursor)
enddef # }}
# }}
# Ut_DTWS_get {{
# Return the DTWS setting, preferring a buffer-local override.
export def Ut_DTWS_get(): any # {{
    return (exists('b:rjvim9#DTWS') ? b:rjvim9#DTWS : g:rjvim9#DTWS)
enddef # }}
# }}
# Ut_DTWS_getaction {{
# Return the DTWS action ('delete' or 'abort'), preferring buffer-local.
export def Ut_DTWS_getaction(): any # {{
    return (exists('b:rjvim9#DTWS_action') ?
                \ b:rjvim9#DTWS_action : g:rjvim9#DTWS_action)
enddef # }}
# }}
# Ut_DTWS_hastrailingwhitespace {{
# Return the line number of the first trailing-whitespace match, or 0.
export def Ut_DTWS_hastrailingwhitespace(): number # {{
    # Note: In contrast to matchadd(), search() does consider the 'magic',
    # ignorecase' and 'smartcase' settings. However, I don't think this is
    # relevant for the whitespace pattern, and local exception regular
    # expressions can / should force this via \c / \C.
    return search(Ut_DTWS_pattern(), 'cnw')
enddef # }}
# }}
# Ut_DTWS_interceptwrite {{
# BufWritePre hook: delete or abort on trailing whitespace depending
# on the configured action.
export def Ut_DTWS_interceptwrite() # {{
    if !Ut_DTWS_isset()
        return
    endif
    if !&l:modifiable && Ut_DTWS_getaction() ==# 'delete'
        echomsg
            \ 'Cannot automatically delete trailing whitespace, buffer is'
            \ .. ' not modifiable'
        sleep 1 # Need a delay as the message is overwritten by :write.
        return
    endif
    if Ut_DTWS_isaction()
        Ut_DTWS_delete(1, line('$'))
    endif
enddef # }}
# }}
# Ut_DTWS_isaction {{
# Execute the configured DTWS action and return true, or throw to abort.
export def Ut_DTWS_isaction(): bool # {{
    var action = Ut_DTWS_getaction()
    if action ==# 'delete'
        return true
    elseif action ==# 'abort'
        if !v:cmdbang && Ut_DTWS_hastrailingwhitespace()
            # Note: Defining a no-op BufWriteCmd only comes into effect on the
            # next write, but does not affect the current one. Since we don't
            # want to install such an autocmd across the board, the best we can
            # do is throwing an exception to abort the write.
            throw
                \ 'DTWS: Trailing whitespace found, aborting write ' ..
                \ '(add ! to override, or :DTWS to eradicate)'
        endif
        return true
    else
        throw 'ASSERT: Invalid value for DTWS_action: ' .. string(action)
    endif
enddef # }}
# }}
# Ut_DTWS_isset {{
# Return true if DTWS is enabled (value is '1' or 'always').
export def Ut_DTWS_isset(): bool # {{
    return index(['1', 'always'], string(Ut_DTWS_get())) >= 0
enddef # }}
# }}
# Ut_DTWS_pattern {{
# Return the regex pattern that matches trailing whitespace.
export def Ut_DTWS_pattern(): string # {{
    return '\s\+$'
enddef # }}
# }}

# Restore original 'compatible' options.
&cpo = cpo_save
