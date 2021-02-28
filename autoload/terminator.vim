"TODO: add options for different split locations
"TODO: add safety featur to send_to_terminal so it only send if its the
"right terminal and the terminator is open

if exists("g:terminator_autoloaded") || &cp
  finish
endif

let g:terminator_autoloaded = 1

let s:REPL_command = {
  \'python' : ['ipython', '--no-autoindent'],
  \'javascript': ['node'],
  \}

let s:terminator_runfile_map = {
            \ "javascript": "node",
            \ "java": "cd $dir && javac $fileName && java $fileNameWithoutExt",
            \ "c": "cd $dir && gcc $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
            \ "cpp": "cd $dir && g++ $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
            \ "objective-c": "cd $dir && gcc -framework Cocoa $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
            \ "php": "php",
            \ "python": "python -u",
            \ "perl": "perl",
            \ "perl6": "perl6",
            \ "ruby": "ruby",
            \ "go": "go run",
            \ "lua": "lua",
            \ "groovy": "groovy",
            \ "powershell": "powershell -ExecutionPolicy ByPass -File",
            \ "bat": "cmd /c",
            \ "shellscript": "bash",
            \ "fsharp": "fsi",
            \ "csharp": "scriptcs",
            \ "vbscript": "cscript //Nologo",
            \ "typescript": "ts-node",
            \ "coffeescript": "coffee",
            \ "scala": "scala",
            \ "swift": "swift",
            \ "julia": "julia",
            \ "crystal": "crystal",
            \ "ocaml": "ocaml",
            \ "r": "Rscript",
            \ "applescript": "osascript",
            \ "clojure": "lein exec",
            \ "haxe": "haxe --cwd $dirWithoutTrailingSlash --run $fileNameWithoutExt",
            \ "rust": "cd $dir && rustc $fileName && $dir$fileNameWithoutExt",
            \ "racket": "racket",
            \ "scheme": "csi -script",
            \ "ahk": "autohotkey",
            \ "autoit": "autoit3",
            \ "dart": "dart",
            \ "pascal": "cd $dir && fpc $fileName && $dir$fileNameWithoutExt",
            \ "d": "cd $dir && dmd $fileName && $dir$fileNameWithoutExt",
            \ "haskell": "runhaskell",
            \ "nim": "nim compile --verbosity:0 --hints:off --run",
            \ "lisp": "sbcl --script",
            \ "kit": "kitc --run",
            \ "v": "v run",
            \ "sass": "sass --style expanded",
            \ "scss": "scss --style expanded",
            \ "less": "cd $dir && lessc $fileName $fileNameWithoutExt.css",
            \ "FortranFreeForm": "cd $dir && gfortran $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
            \ "fortran-modern": "cd $dir && gfortran $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
            \ "fortran_fixed-form": "cd $dir && gfortran $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
            \ "fortran": "cd $dir && gfortran $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt"
            \}

if exists("g:REPL_command")
    let s:REPL_command = extend(s:REPL_command, g:REPL_command)
endif

if exists("g:terminator_runfile_map")
    let s:terminator_runfile_map = extend(s:terminator_runfile_map, g:terminator_runfile_map)
endif

function terminator#open_terminal()
    if exists("g:terminator_buffer_number")
        let buffer_name = bufname(g:terminator_buffer_number)
        execute("belowright split " . buffer_name )
        exec 'resize ' . string(&lines - &lines / 1.618)
        wincmd p
    else
        belowright split | terminal
        exec 'resize ' . string(&lines - &lines / 1.618)
        let g:terminator_job_id = b:terminal_job_id
        let g:terminator_buffer_number = bufnr("%")
        wincmd p
    endif
endfunction

function terminator#send_to_terminal(contents)
    if !(exists("g:terminator_job_id")) 
        echo "Please open a terminal before running this command"
    else
        call chansend(g:terminator_job_id, a:contents)
    endif
endfunction

function terminator#get_command()
    let cmd = get(s:REPL_command, &ft, '')
    return cmd
endfunction

function terminator#start_repl()
    call terminator#open_terminal()
    let cmd = terminator#get_command()
    call terminator#send_to_terminal(join(cmd, ' ') . "\n")
endfunction

function terminator#get_in_delimiter()
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
    " remove all of the blank lines to not clog up the terminator feed as much
    let cell = filter(cell, '!empty(v:val)')
    " if last line is indented, add a new line so the terminator enters text
    " correctly 
    if cell[-1][0] == " "
    " TODO: this breaks when cursor is on last line of buffer
        let cell = cell + [" "]
    endif

    return cell + ["\n"]
    " returns a string separated by new line characters
    "return join(cell, "\n") . "\n"
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

function terminator#run_current_file(output_location)
    let dir = expand("%:p:h") . "/"
    let fileName = expand("%:t")
    let fileNameWithoutExt = expand("%:t:r")
    let dirWithoutTrailingSlash = expand("%:h")

    let cmd = get(s:terminator_runfile_map, &ft, '')
    if stridx(cmd, "fileName") == -1
        let needs_filename_at_end = 1
    endif
    let cmd = substitute(cmd, "\$dir", dir, "g")
    let cmd = substitute(cmd, "\$fileName ", fileName . " ", "g")
    let cmd = substitute(cmd, "\$fileNameWithoutExt", fileNameWithoutExt, "g")
    let cmd = substitute(cmd, "\$dirWithoutTrailingSlash", dirWithoutTrailingSlash, "g")

    if exists("needs_filename_at_end")
        let cmd = cmd . ' ' . expand("%:p")
    endif

    if a:output_location == "terminal"
        call terminator#send_to_terminal(cmd . "\n")
    elseif a:output_location == "output_buffer"
        call terminator#run_file_in_output_buffer(cmd)
    else
        echo "invalid option for this function"
    end
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Run plugin merge
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function terminator#on_event(job_id, data, event) dict
    "let output_string = join(a:data)
    if a:event == 'stdout'
        " TODO: data arrives in inconsistant order and results in
        " string new line issues
        " see Note 2 of :h job-control
        let s:chunks = ['']
        let s:chunks[-1] .= a:data[0]
        call extend(s:chunks, a:data[1:])
        "if s:chunks[0] == ''
        "    call remove(s:chunks, 0)
        "elseif s:chunks[-1] == ''
        "    call remove(s:chunks, -1)
        "endif
        call filter(s:chunks, '!empty(v:val)')
        let the_data = s:chunks
        "let the_data = join(a:data)
        let str = the_data
        "echomsg str
    elseif a:event == 'stderr'
        let the_data = join(a:data)
        caddexpr a:data
        cwindow
        if the_data == '' | return | endif
        call appendbufline(self.win_num, '$', '')
        let str = 'stderr: check the quickfix window for errors'
    else
        "let str = 'exited ' . a:data
        let finished_time = localtime()
        let run_time = finished_time - self.start_time
        let str = '[Done] exited with code=' . string(a:data) . ' in '  . run_time . ' seconds'
        cwindow
    endif
    call appendbufline(self.win_num, '$', str)
endfunction

let s:callbacks = {
\ 'on_stdout': function('terminator#on_event'),
\ 'on_stderr': function('terminator#on_event'),
\ 'on_exit': function('terminator#on_event')
\ }

function terminator#get_output_buffer(cmd)
    let first_line = '[Running] ' . a:cmd
    let error_format = &errorformat

    let buf_num = bufnr('_OUTPUT_BUFFER_')
    if buf_num == -1
        keepalt belowright split _OUTPUT_BUFFER_
        exec 'resize ' . string(&lines - &lines / 1.618)
        setlocal filetype=run_output buftype=nofile noswapfile nowrap cursorline modifiable nospell
        let &errorformat=error_format
        let buf_num = bufnr('%')
        call setline(1, first_line)
        wincmd p
    else
        let buffer_name = bufname(buf_num)
        "execute("belowright split " . buffer_name)
        "exec 'resize ' . string(&lines - &lines / 1.618)
        call deletebufline(buffer_name, 1, '$')
        "call appendbufline(buffer_name, 1, first_line)
        call setbufline(buffer_name, 1, first_line)
        "wincmd p
    endif

    return buf_num
endfunction

function! terminator#run_file_in_output_buffer(cmd)
    cexpr ''
    "let cmd = get(s:terminator_runfile_map, &ft, '')
    "let full_cmd = a:cmd . ' ' . expand("%:p")
    let full_cmd = a:cmd
    let win_num = terminator#get_output_buffer(full_cmd)
    let start_time = localtime()
    let g:run_running_job = jobstart(full_cmd, extend({'win_num': win_num, 'start_time': start_time}, s:callbacks))
endfunction

function terminator#run_stop_job()
    call jobstop(g:run_running_job)
endfunction

