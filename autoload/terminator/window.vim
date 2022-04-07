if exists("g:autoloaded_terminator_window")
    finish
endif
let g:autoloaded_terminator_window = 1

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

function terminator#window#resize_window()
    if stridx(s:terminator_split_location, "vertical") == -1
        execute printf('resize %s', string(&lines * s:terminator_split_fraction))
    else
        execute printf('vertical resize %s', string(&columns * s:terminator_split_fraction))
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
