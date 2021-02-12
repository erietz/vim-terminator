if exists('g:repl_autoloaded') || &cp
  finish
endif
let g:repl_autoloaded = 1

"TODO: check if terminal is already opening and toggle it if it is
"TODO: make functions with # in them for internal use
"TODO: add things to the plugin folder which call these functions
"TODO: add options for different split locations
"TODO: add safety featur to sendstufftoterminal so it only send if its the
"right terminal and the repl is open

function repl#OpenTerminal()
    belowright split | terminal
    exec 'resize ' . string(&lines - &lines / 1.618)
    let g:test_job_id = b:terminal_job_id
    wincmd k
endfunction

function repl#SendStuffToTerminal(job_id, contents)
    call chansend(a:job_id, a:contents)
endfunction

function repl#StartREPL()
    call repl#OpenTerminal()
    call repl#SendStuffToTerminal(g:test_job_id, ['ipython --no-autoindent', ' '])
endfunction

function repl#GetInDelimeter()
    " TODO: pass in the delimeter as an argument so different delimeters can
    " be used

    " save original cursor position cuz search command moves cursor
    let save_pos = getpos(".")
    " get line number of delimeter before cursor
    let last_delim = search('# In\[.*\]:', 'b')
    " return cursor to original position
    call setpos('.', save_pos)
    " get line number of delimeter after cursor (or end of file)
    let next_delim = search('\(# In\[.*\]:\|\%$\)')
    " return cursor to original position
    call setpos('.', save_pos)
    " cell is a list of all the lines between the delimeters
    "let cell = nvim_buf_get_lines(0, last_delim + 1, next_delim - 1, v:false)
    if next_delim == line('$')
        let cell = getbufline(bufnr('%'), last_delim + 1, next_delim)
    endif
    let cell = getbufline(bufnr('%'), last_delim + 1, next_delim - 1)
    " remove all of the blank lines to not clog up the repl feed as much
    let cell = filter(cell, '!empty(v:val)')
    " if last line is indented, add a new line so the repl enters text
    " correctly 
    if cell[-1][0] == " "
    " TODO: this breaks when cursor is on last line of buffer
        let cell = cell + [" "]
    endif


    return cell + ["\n"]


    " returns a string separated by new line characters
    "return join(cell, "\n") . "\n"
endfunction

function! repl#GetVisualSelection() range
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
