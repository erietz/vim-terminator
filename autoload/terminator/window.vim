if exists("g:autoloaded_terminator_window")
    finish
endif
let g:autoloaded_terminator_window = 1

let s:has_nvim = has('nvim')
let s:terminator_terminal_buffer_name_regex = '\(^term://\|\[Terminal\]\|'.'!'.&shell.'\|^!/bin/\)'

if exists("g:terminator_split_location")
    let s:terminator_split_location = g:terminator_split_location
else
    let s:terminator_split_location = 'botright'
endif

if exists("g:terminator_split_fraction")
    let s:terminator_split_fraction = g:terminator_split_fraction
else
    let s:terminator_split_fraction = 0.3819660113000001
endif


function terminator#window#output_buffer_new()
    let error_format = &errorformat
    execute printf('%s split OUTPUT_BUFFER', s:terminator_split_location)
    call terminator#window#resize_window()
    setlocal filetype=output_buffer nobuflisted buftype=nofile noswapfile nowrap modifiable nospell nonumber norelativenumber winfixheight winfixwidth
    let &errorformat=error_format
    let buf_num = bufnr('%')
    return buf_num
endfunction

function terminator#window#output_buffer_prepare(cmd) abort
    let first_line = '[Running] ' . a:cmd
    let buf_num = bufnr('OUTPUT_BUFFER')
    if buf_num == -1
        let buf_num = terminator#window#output_buffer_new()
        call setline(1, first_line)
        call setline(2, '')
        wincmd p
    else
        if bufwinid('OUTPUT_BUFFER') == -1
            call terminator#window#output_buffer_new()
            wincmd p
        endif
        let buf_name = bufname(buf_num)
        silent call deletebufline(buf_name, 1, '$')
        call setbufline(buf_name, 1, first_line)
        call setbufline(buf_name, 2, '')
    endif
    return buf_num
endfunction

function terminator#window#resize_window()
    if stridx(s:terminator_split_location, "vertical") == -1
        execute printf('resize %s', string(&lines * s:terminator_split_fraction))
    else
        execute printf('vertical resize %s', string(&columns * s:terminator_split_fraction))
    endif
endfunction

function terminator#window#send_to_terminal(contents) abort
    let warning_message = 'Your terminal is opening ... you may have to run this again if it opens too slowly'
    if !(exists("s:terminator_terminal_buffer_number")) 
        echo warning_message
        call terminator#window#open_terminal()
    elseif bufname(s:terminator_terminal_buffer_number) !~# s:terminator_terminal_buffer_name_regex
        echo warning_message
        call terminator#window#open_terminal()
    else
        if s:has_nvim
            call chansend(s:terminator_job_id, a:contents)
        else
            call term_sendkeys(s:terminator_terminal_buffer_number, a:contents)
        endif
    endif
endfunction

function terminator#window#open_terminal() abort
    if exists("s:terminator_terminal_buffer_number") && bufname(s:terminator_terminal_buffer_number) =~# s:terminator_terminal_buffer_name_regex
        let buf_name = bufname(s:terminator_terminal_buffer_number)
        execute printf('%s split %s', s:terminator_split_location, buf_name)
        call terminator#window#resize_window()
        wincmd p
    else
        if s:has_nvim
            execute printf('%s split | terminal', s:terminator_split_location)
            call terminator#window#resize_window()
            let s:terminator_job_id = b:terminal_job_id
            set winfixheight winfixwidth
        else
            execute printf('%s terminal', s:terminator_split_location)
            call terminator#window#resize_window()
            set winfixheight winfixwidth
        endif
        let s:terminator_terminal_buffer_number = bufnr("%")
        wincmd p
    endif
endfunction

function terminator#window#output_buffer_get_winnum()
    for i in range(1, winnr('$'))
        if bufname(winbufnr(i)) == 'OUTPUT_BUFFER'
            return i
        endif
    endfor
    return -1
endfunction

function terminator#window#output_buffer_close()
    execute printf('%s close', terminator#window#output_buffer_get_winnum())
endfunction

function terminator#window#output_buffer_toggle()
    let buf_num = bufnr("OUTPUT_BUFFER")
    if buf_num == -1 | return | endif
    let win_num = terminator#window#output_buffer_get_winnum()

    if win_num > -1
        call terminator#window#output_buffer_close()
    else
        execute s:terminator_split_location . ' sbuffer ' . buf_num
        call terminator#window#resize_window()
    endif
endfunction

function terminator#window#output_buffer_shrink()
    if !exists('g:terminator_auto_shrink_output') || (stridx(s:terminator_split_location, 'vert') != -1)
        return
    endif
    let win_num = terminator#window#output_buffer_get_winnum()
    execute win_num . 'wincmd w'
    let size1 = &lines * s:terminator_split_fraction
    let size2 = line('$') + 1
    if size2 > size1
        let new_size = size1
    else
        let new_size = size2
    endif
    execute 'resize ' . string(new_size)
    wincmd p
endfunction
