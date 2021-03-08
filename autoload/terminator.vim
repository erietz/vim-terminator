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
            \ "haskell": "runhaskell",
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
    let s:terminator_split_location = 'belowright'
endif

if exists("g:terminator_split_fraction")
    let s:terminator_split_fraction = g:terminator_split_fraction
else
    let s:terminator_split_fraction = 0.381953
endif

function terminator#resize_window()
    execute printf('resize %s', string(&lines * s:terminator_split_fraction))
    "execute printf('resize %s', string(&columns * s:terminator_split_fraction))
endfunction

function terminator#open_terminal() abort
    if exists("s:terminator_terminal_buffer_number") && bufname(s:terminator_terminal_buffer_number) =~#  '\(^term://\|\[Terminal\]\|\[running\]\|^!/bin/\)'
        let buf_name = bufname(s:terminator_terminal_buffer_number)
        if has('nvim')
            execute printf('%s split %s', s:terminator_split_location, buf_name)
            call terminator#resize_window()
        else
            execute printf('%s split %s', s:terminator_split_location, buf_name)
            call terminator#resize_window()
        endif
        wincmd p
    else
        if has('nvim')
            execute printf('%s split | terminal', s:terminator_split_location)
            call terminator#resize_window()
            let s:terminator_job_id = b:terminal_job_id
        else
            execute printf('%s terminal', s:terminator_split_location)
            call terminator#resize_window()
        endif
        let s:terminator_terminal_buffer_number = bufnr("%")
        wincmd p
    endif
endfunction

function terminator#send_to_terminal(contents) abort
    if !(exists("s:terminator_terminal_buffer_number")) 
        echo "Your terminal is opening ... you may have to run this again if it opens too slowly"
        call terminator#open_terminal()
    elseif bufname(s:terminator_terminal_buffer_number) !~# '\(^term://\|\[Terminal\]\|\[running\]\|^!/bin/\)'
        echo "Your terminal is opening ... you may have to run this again if it opens too slowly"
        echomsg bufname(s:terminator_terminal_buffer_number)
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
    let save_pos = getpos(".")
    "let last_delim = search('\(' . delimiter . '\|\%^\)', 'bW')
    let last_delim = search(delimiter, 'b', line("w0"))
    call setpos('.', save_pos)
    "let next_delim = search('\(' . delimiter . '\|\%$\)', 'W')
    let next_delim = search(delimiter, '', line("w$"))
    call setpos('.', save_pos)
    if (next_delim == 0) || (last_delim == 0)
        echo "delimiter not found"
        return ""
    endif
    if next_delim == line('$')
        let cell = getbufline(bufnr('%'), last_delim + 1, next_delim)
    endif
    let cell = getbufline(bufnr('%'), last_delim + 1, next_delim - 1)
    let cell = filter(cell, '!empty(v:val)')
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
    execute printf('%s split _OUTPUT_BUFFER_', s:terminator_split_location)
    exec 'resize ' . string(&lines - &lines / 1.618)
    setlocal filetype=output_buffer buftype=nofile noswapfile nowrap modifiable nospell
    let &errorformat=error_format
    let buf_num = bufnr('%')
    return buf_num
endfunction

function terminator#get_output_buffer(cmd) abort
    let first_line = '[Running] ' . a:cmd
    let buf_num = bufnr('_OUTPUT_BUFFER_')
    if buf_num == -1
        let buf_num = terminator#open_new_output_buffer()
        call setline(1, first_line)
        call setline(2, '')
        wincmd p
    else
        if bufwinid('_OUTPUT_BUFFER_') == -1
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

" The data that is outputted from the async command looks like this

"['hello world 1', '']
"['hello world 2', '']
"['hello world 3']
"['', '']
"['hello world 4', '']
"['hello world']
"[' 5', '']
"['hello world 6', '']

" If the last item in the list is not an empty string, then the first item in
" the next message needs to be joined with the last item from the previous
" list

function terminator#glue_lists_together(list1, list2)
    let list1 = copy(a:list1)
    let list2 = copy(a:list2)
    if len(list1) > 1
        let resin = remove(list1, -1)
    else
        let resin = remove(list1, 0)
    endif
    let hardener = remove(list2, 0)
    let new_list = list1 + [resin . hardener] + list2
    if new_list[-1] == ''
        call remove(new_list, -1)
    endif
    return new_list
endfunction

function terminator#nvim_on_event(job_id, data, event) dict
    if a:event == 'stdout'
        if !empty(a:data[-1])
            call extend(self.stdout_buffer, a:data)
        elseif !empty(self.stdout_buffer)
            let l:chunks = terminator#glue_lists_together(self.stdout_buffer, a:data)
            let self.stdout_buffer = []
        else
            let l:chunks = a:data
            if empty(l:chunks[-1])
                call remove(l:chunks, -1)
            endif
        endif
        if exists("l:chunks")
            let l:str = l:chunks
        endif
    elseif a:event == 'stderr'
        if join(a:data) == '' | return | endif
        let l:str = 'stderr: check the quickfix window for errors'
        if !empty(a:data[-1])
            call extend(self.stderr_buffer, a:data)
        elseif !empty(self.stderr_buffer)
            let l:chunks = terminator#glue_lists_together(self.stderr_buffer, a:data)
            let self.stderr_buffer = []
        else
            let l:chunks = a:data
            if empty(l:chunks[-1])
                call remove(l:chunks, -1)
            endif
        endif
        if exists("l:chunks")
            caddexpr l:chunks
        endif
    else
        let run_time = split(reltimestr(reltime(s:start_time)))[0]
        call appendbufline(s:output_buf_num, '$', '')
        let l:str = '[Done] exited with code=' . string(a:data) . ' in '  . run_time . ' seconds'
        cwindow
    endif
    if exists("l:str")
        call appendbufline(s:output_buf_num, '$', l:str)
    endif
endfunction

function terminator#vim_on_exit(channel, data)
    let run_time = split(reltimestr(reltime(s:start_time)))[0]
    call appendbufline(s:output_buf_num, '$', '')
    let l:str = '[Done] exited with code=' . string(a:data) . ' in '  . run_time . ' seconds'
    call appendbufline(s:output_buf_num, '$', l:str)
    cwindow
endfunction

function terminator#vim_on_error(channel, data)
    if a:data == '' | return | endif
    let l:str = 'stderr: check the quickfix window for errors'
    call appendbufline(s:output_buf_num, '$', l:str)
    caddexpr a:data
endfunction

function! terminator#run_file_in_output_buffer(cmd) abort
    cexpr ''
    cwindow
    let s:output_buf_num = terminator#get_output_buffer(a:cmd)
    let s:start_time = reltime()
    let cmd =  ['/bin/sh', '-c', a:cmd]
    if has("nvim")
        let g:terminator_running_job = jobstart(cmd, {
                    \ 'stdout_buffer': [],
                    \ 'stderr_buffer': [],
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
