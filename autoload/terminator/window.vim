if exists("g:autoloaded_terminator_window")
    finish
endif
let g:autoloaded_terminator_window = 1

let s:has_nvim = has('nvim')
let s:terminator_terminal_buffer_name_regex = '\(^term://\|\[Terminal\]\|\[running\]\|^!/bin/\)'

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


function terminator#window#open_new_output_buffer()
    let error_format = &errorformat
    execute printf('%s split OUTPUT_BUFFER', s:terminator_split_location)
    call terminator#window#resize_window()
    setlocal filetype=output_buffer buftype=nofile noswapfile nowrap modifiable nospell nonumber norelativenumber winfixheight winfixwidth
    let &errorformat=error_format
    let buf_num = bufnr('%')
    return buf_num
endfunction

function terminator#window#get_output_buffer(cmd) abort
    let first_line = '[Running] ' . a:cmd
    let buf_num = bufnr('OUTPUT_BUFFER')
    if buf_num == -1
        let buf_num = terminator#window#open_new_output_buffer()
        call setline(1, first_line)
        call setline(2, '')
        wincmd p
    else
        if bufwinid('OUTPUT_BUFFER') == -1
            call terminator#window#open_new_output_buffer()
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
    if !(exists("s:terminator_terminal_buffer_number")) 
        echo "Your terminal is opening ... you may have to run this again if it opens too slowly"
        call terminator#window#open_terminal()
    elseif bufname(s:terminator_terminal_buffer_number) !~# s:terminator_terminal_buffer_name_regex
        echo "Your terminal is opening ... you may have to run this again if it opens too slowly"
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

function terminator#window#shrink_output_buffer()
    if !exists('g:terminator_auto_shrink_output') || (stridx(s:terminator_split_location, 'vert') != -1)
        return
    endif
    for i in range(1, winnr('$'))
        if bufname(winbufnr(i)) == 'OUTPUT_BUFFER'
            let win_num = i
        endif
    endfor
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
