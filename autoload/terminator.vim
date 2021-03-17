"TODO: add options for different split locations

if exists("g:terminator_autoloaded") || &cp
  finish
endif

let g:terminator_autoloaded = 1

let s:terminator_repl_command = {
  \'python' : 'ipython --no-autoindent',
  \'javascript': 'node',
  \'lua': 'lua',
  \'ruby': 'irb',
  \'haskell': 'stack ghci',
  \}

" this dictionary was extracted out of json from the vscode extension
" code-runner and modified
let s:terminator_runfile_map = {
            \ "ahk": "autohotkey",
            \ "applescript": "osascript",
            \ "autoit": "autoit3",
            \ "bat": "cmd /c",
            \ "c": "gcc $dir$fileName -o $dir$fileNameWithoutExt && $dir$fileNameWithoutExt",
            \ "clojure": "lein exec",
            \ "coffeescript": "coffee",
            \ "cpp": "cd $dir && g++ $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
            \ "crystal": "crystal",
            \ "csharp": "scriptcs",
            \ "d": "cd $dir && dmd $fileName && $dir$fileNameWithoutExt",
            \ "dart": "dart",
            \ "fortran": "cd $dir && gfortran $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
            \ "fsharp": "fsi",
            \ "go": "go run",
            \ "groovy": "groovy",
            \ "haskell": "stack ghc",
            \ "haxe": "haxe --cwd $dirWithoutTrailingSlash --run $fileNameWithoutExt",
            \ "java": "cd $dir && javac $fileName && java $fileNameWithoutExt",
            \ "javascript": "node",
            \ "julia": "julia",
            \ "kit": "kitc --run",
            \ "less": "cd $dir && lessc $fileName $fileNameWithoutExt.css",
            \ "lisp": "sbcl --script",
            \ "lua": "lua",
            \ "nim": "nim compile --verbosity:0 --hints:off --run",
            \ "objective-c": "cd $dir && gcc -framework Cocoa $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
            \ "ocaml": "ocaml",
            \ "pascal": "cd $dir && fpc $fileName && $dir$fileNameWithoutExt",
            \ "perl": "perl",
            \ "perl6": "perl6",
            \ "php": "php",
            \ "powershell": "powershell -ExecutionPolicy ByPass -File",
            \ "python": "python -u",
            \ "r": "Rscript",
            \ "racket": "racket",
            \ "ruby": "ruby",
            \ "rust": "cd $dir && rustc $fileName && $dir$fileNameWithoutExt",
            \ "sass": "sass --style expanded",
            \ "scala": "scala",
            \ "scheme": "csi -script",
            \ "scss": "scss --style expanded",
            \ "sh": "sh",
            \ "swift": "swift",
            \ "typescript": "ts-node",
            \ "v": "v run",
            \ "vbscript": "cscript //Nologo",
            \ "zsh": "zsh",
            \}

if exists("g:terminator_repl_command")
    let s:terminator_repl_command = extend(s:terminator_repl_command, g:terminator_repl_command)
endif

if exists("g:terminator_runfile_map")
    let s:terminator_runfile_map = extend(s:terminator_runfile_map, g:terminator_runfile_map)
endif

if exists("g:terminator_repl_delimiter_regex")
    let s:terminator_repl_delimiter_regex = g:terminator_repl_delimiter_regex
else
    let s:terminator_repl_delimiter_regex = 'In\[.*\]:'
endif

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

let s:terminator_terminal_buffer_name_regex = '\(^term://\|\[Terminal\]\|\[running\]\|^!/bin/\)'

function terminator#resize_window()
    if stridx(s:terminator_split_location, "vertical") == -1
        execute printf('resize %s', string(&lines * s:terminator_split_fraction))
    else
        execute printf('vertical resize %s', string(&columns * s:terminator_split_fraction))
    endif
endfunction

function terminator#open_terminal() abort
    if exists("s:terminator_terminal_buffer_number") && bufname(s:terminator_terminal_buffer_number) =~# s:terminator_terminal_buffer_name_regex
        let buf_name = bufname(s:terminator_terminal_buffer_number)
        execute printf('%s split %s', s:terminator_split_location, buf_name)
        call terminator#resize_window()
        wincmd p
    else
        if has('nvim')
            execute printf('%s split | terminal', s:terminator_split_location)
            call terminator#resize_window()
            let s:terminator_job_id = b:terminal_job_id
            set winfixheight winfixwidth
        else
            execute printf('%s terminal', s:terminator_split_location)
            call terminator#resize_window()
            set winfixheight winfixwidth
        endif
        let s:terminator_terminal_buffer_number = bufnr("%")
        wincmd p
    endif
endfunction

function terminator#send_to_terminal(contents) abort
    if !(exists("s:terminator_terminal_buffer_number")) 
        echo "Your terminal is opening ... you may have to run this again if it opens too slowly"
        call terminator#open_terminal()
    elseif bufname(s:terminator_terminal_buffer_number) !~# s:terminator_terminal_buffer_name_regex
        echo "Your terminal is opening ... you may have to run this again if it opens too slowly"
        call terminator#open_terminal()
    else
        if has('nvim')
            call chansend(s:terminator_job_id, a:contents)
        else
            call term_sendkeys(s:terminator_terminal_buffer_number, a:contents)
        endif
    endif
endfunction

function terminator#start_repl() abort
    let cmd = get(s:terminator_repl_command, &ft, 'language_not_found')
    if cmd == 'language_not_found' | echo 'language not in repl dictionary' | return | endif
    call terminator#open_terminal()
    let cmd = terminator#substitute_command_variables(cmd, expand("%"))
    call terminator#send_to_terminal(cmd . "\n")
endfunction

" Stolen from tpopes commentary plugin
function terminator#get_filetype_comment() abort
  return split(get(b:, 'commentary_format', substitute(substitute(substitute(
        \ &commentstring, '^$', '%s', ''), '\S\zs%s',' %s', '') ,'%s\ze\S', '%s ', '')), '%s', 1)
endfunction

function terminator#get_in_delimiter()
    let [l, r] = terminator#get_filetype_comment()
    let delimiter = l . s:terminator_repl_delimiter_regex . r

    " get line numbers of delimiters (0 if not found)
    let save_pos = getpos(".")
    let last_delim = search(delimiter, 'b', line("w0"))
    call setpos('.', save_pos)
    let next_delim = search(delimiter, '', line("w$"))
    call setpos('.', save_pos)

    if (last_delim == 0) && (next_delim != 0)
        let cell = getline(1, next_delim - 1)
    elseif (last_delim != 0) && (next_delim == 0)
        let cell = getline(last_delim + 1, line('$'))
    elseif (last_delim != 0) && (next_delim != 0)
        let cell = getline(last_delim + 1, next_delim - 1)
    else
        echo "delimiter not found"
        return ""
    endif

    " remove empty lines
    let cell = filter(cell, '!empty(v:val)')
    " add extra line if last line is indented
    if len(cell) > 0
        if cell[-1][0] == " "
            call add(cell, " ")
        endif
    endif

    let cell = join(cell, "\n") . "\n"
    return cell
endfunction

function terminator#send_delimiter_to_terminal()
    let l:contents = terminator#get_in_delimiter()
    if exists("l:contents")
        call terminator#send_to_terminal(l:contents)
    endif
endfunction

function! terminator#get_visual_selection() range
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

function terminator#substitute_command_variables(command, filename)
    let cmd = a:command
    let dir = fnamemodify(a:filename, ":p:h") . "/"
    let fileName = fnamemodify(a:filename, ":t")
    let fileNameWithoutExt = fnamemodify(a:filename, ":t:r")
    let dirWithoutTrailingSlash = fnamemodify(a:filename, ":h")
    let cmd = substitute(cmd, "\$dir", dir, "g")
    let cmd = substitute(cmd, "\$fileName ", fileName . " ", "g")
    let cmd = substitute(cmd, "\$fileNameWithoutExt", fileNameWithoutExt, "g")
    let cmd = substitute(cmd, "\$dirWithoutTrailingSlash", dirWithoutTrailingSlash, "g")
    return cmd
endfunction

function terminator#open_new_output_buffer()
    let error_format = &errorformat
    execute printf('%s split OUTPUT_BUFFER', s:terminator_split_location)
    call terminator#resize_window()
    setlocal filetype=output_buffer buftype=nofile noswapfile nowrap modifiable nospell nonumber norelativenumber winfixheight winfixwidth
    let &errorformat=error_format
    let buf_num = bufnr('%')
    return buf_num
endfunction

function terminator#get_output_buffer(cmd) abort
    let first_line = '[Running] ' . a:cmd
    let buf_num = bufnr('OUTPUT_BUFFER')
    if buf_num == -1
        let buf_num = terminator#open_new_output_buffer()
        call setline(1, first_line)
        call setline(2, '')
        wincmd p
    else
        if bufwinid('OUTPUT_BUFFER') == -1
            call terminator#open_new_output_buffer()
            wincmd p
        endif
        let buf_name = bufname(buf_num)
        silent call deletebufline(buf_name, 1, '$')
        call setbufline(buf_name, 1, first_line)
        call setbufline(buf_name, 2, '')
    endif
    return buf_num
endfunction

function terminator#nvim_on_event(job_id, data, event) dict
    " see :help channel-bytes for details on this
    if a:event == 'stdout'
        let self.stdout_queue[-1] .= a:data[0]
        call extend(self.stdout_queue, a:data[1:])
        let l:str = self.stdout_queue[:-2]
        let self.stdout_queue = [self.stdout_queue[-1]]

    elseif a:event == 'stderr'
        " [''] is returned if there are no errors
        if join(a:data) == '' | return | endif
        let l:str = 'stderr: check the quickfix window'

        let self.stderr_queue[-1] .= a:data[0]
        call extend(self.stderr_queue, a:data[1:])
        caddexpr self.stderr_queue[:-2]
        let self.stderr_queue = [self.stderr_queue[-1]]

    else
        let run_time = split(reltimestr(reltime(s:start_time)))[0]
        call appendbufline(s:output_buf_num, '$', '')
        let l:str = '[Done] exited with code=' . string(a:data) . ' in '  . run_time . ' seconds'
        botright cwindow
        call terminator#shrink_output_buffer()
    endif

    call appendbufline(s:output_buf_num, '$', l:str)
endfunction

function terminator#vim_on_exit(channel, data)
    let run_time = split(reltimestr(reltime(s:start_time)))[0]
    call appendbufline(s:output_buf_num, '$', '')
    let l:str = '[Done] exited with code=' . string(a:data) . ' in '  . run_time . ' seconds'
    call appendbufline(s:output_buf_num, '$', l:str)
    botright cwindow
    call terminator#shrink_output_buffer()
endfunction

function terminator#vim_on_error(channel, data)
    if a:data == '' | return | endif
    let l:str = 'stderr: check the quickfix window'
    call appendbufline(s:output_buf_num, '$', l:str)
    caddexpr a:data
endfunction

function! terminator#run_file_in_output_buffer(cmd) abort
    cexpr ''
    botright cwindow
    let s:output_buf_num = terminator#get_output_buffer(a:cmd)
    let s:start_time = reltime()
    let cmd =  ['/bin/sh', '-c', a:cmd]
    if has("nvim")
        let g:terminator_running_job = jobstart(cmd, {
                    \ 'stdout_queue': [''],
                    \ 'stderr_queue': [''],
                    \ 'on_stdout': function('terminator#nvim_on_event'),
                    \ 'on_stderr': function('terminator#nvim_on_event'),
                    \ 'on_exit': function('terminator#nvim_on_event'),
                    \ })
    else
        let g:terminator_running_job = job_start(cmd, {
                    \ 'out_io': "buffer",
                    \ 'out_buf': s:output_buf_num,
                    \ 'err_cb': function('terminator#vim_on_error'),
                    \ 'exit_cb': function('terminator#vim_on_exit'),
                    \ })
    endif
endfunction

function terminator#run_file(output_location, filename) abort
    let cmd = get(s:terminator_runfile_map, &ft, 'language_not_found')
    if cmd == 'language_not_found' | echo 'language not in run dictionary' | return | endif
    if stridx(cmd, "fileName") == -1
        let needs_filename_at_end = 1
    endif
    let cmd = terminator#substitute_command_variables(cmd, a:filename)
    if exists("needs_filename_at_end")
        let cmd = cmd . ' ' . fnamemodify(a:filename, ":p")
    endif
    if a:output_location == "terminal"
        call terminator#send_to_terminal(cmd . "\n")
    elseif a:output_location == "output_buffer"
        call terminator#run_file_in_output_buffer(cmd)
    else
        echo "invalid option for this function"
    end
endfunction

function terminator#stop_running_job()
    if has('nvim')
        call jobstop(g:terminator_running_job)
    else
        call job_stop(g:terminator_running_job)
    endif
endfunction

function terminator#run_part_of_file(output_location, register) abort
    let l:tmpfile = tempname() . "." . expand("%:e")
    call writefile(split(a:register, '\n'), fnameescape(l:tmpfile))
    call terminator#run_file(a:output_location, fnameescape(l:tmpfile))
endfunction

function terminator#shrink_output_buffer()
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
