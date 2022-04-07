if exists("g:autoloaded_terminator_util")
    finish
endif
let g:autoloaded_terminator_util = 1

if exists("g:terminator_repl_delimiter_regex")
    let s:terminator_repl_delimiter_regex = g:terminator_repl_delimiter_regex
else
    let s:terminator_repl_delimiter_regex = 'In\[.*\]:'
endif

" Stolen from tpopes commentary plugin
function terminator#util#get_filetype_comment() abort
  return split(get(b:, 'commentary_format', substitute(substitute(substitute(
        \ &commentstring, '^$', '%s', ''), '\S\zs%s',' %s', '') ,'%s\ze\S', '%s ', '')), '%s', 1)
endfunction

function terminator#util#get_in_delimiter()
    let [l, r] = terminator#util#get_filetype_comment()
    " l and r may contains characters, such as '*' that need escaped when
    " interpretted as a regex. For example, a comment like: /* foo bar */.
    " Here we 'escape' l and r my using \M to make interpret them as nomagic
    " and return the rest of the string to magic using \m
    let delimiter = '\M' . l . '\m' . s:terminator_repl_delimiter_regex . '\M' . r
    let save_pos = getpos(".")

    " Find delimiters: always start from search_pos := end of current line.
    " Last delimiter: search backwards (accept match at starting cursor pos).
    let search_pos = [save_pos[0], save_pos[1], col('$'), save_pos[3]]
    call setpos('.', search_pos)
    let last_delim = search(delimiter, 'ncWb', line("0"))
    if last_delim == 0
        let ladjust = 0
    else
        let ladjust = 1
    endif

    " Next delimiter: search forwards (dont accept match at starting cursor pos).
    let next_delim = search(delimiter, 'nW', line("$"))
    if next_delim == 0
        let next_delim = line('$')
        let nadjust = 0
    else
        let nadjust = 1
    endif

    call setpos('.', save_pos)

    let cell = getline(last_delim + ladjust, next_delim - nadjust)
    let cell = filter(cell, '!empty(v:val)')
    if len(cell) > 0
        if cell[-1][0] == " "
            call add(cell, " ")
        endif
    endif
    let cell = join(cell, "\n") . "\n"
    return cell
endfunction

function! terminator#util#get_visual_selection() range
    let reg_save = getreg('"')
    let regtype_save = getregtype('"')
    let cb_save = &clipboard
    set clipboard&
    normal! ""gvy
    let selection = getreg('"')
    call setreg('"', reg_save, regtype_save)
    let &clipboard = cb_save
    return selection
endfunction 

function terminator#util#send_delimiter_to_terminal()
    let l:contents = terminator#util#get_in_delimiter()
    if exists("l:contents")
        call terminator#window#send_to_terminal(l:contents)
    endif
endfunction

