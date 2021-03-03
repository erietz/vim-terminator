"TODO: add options for different split locations

if exists("g:terminator_autoloaded") || &cp
  finish
endif

let g:terminator_autoloaded = 1

let s:terminator_repl_command = {
  \'python' : 'ipython --no-autoindent',
  \'javascript': 'node',
  \}

" this dictionary was extracted out of json from the vscode extension
" code-runner and modified
let s:terminator_runfile_map = {
            \ "javascript": "node",
            \ "java": "cd $dir && javac $fileName && java $fileNameWithoutExt",
            \ "c": "gcc $dir$fileName -o $dir$fileNameWithoutExt && $dir$fileNameWithoutExt",
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

if exists("g:terminator_repl_command")
    let s:terminator_repl_command = extend(s:terminator_repl_command, g:terminator_repl_command)
endif

if exists("g:terminator_runfile_map")
    let s:terminator_runfile_map = extend(s:terminator_runfile_map, g:terminator_runfile_map)
endif

function terminator#open_terminal()
    if exists("g:terminator_buffer_number") && bufname(g:terminator_buffer_number) =~# '^term://'
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
        echo "Your terminal is opening ... you may have to run this again if it opens too slowly"
        call terminator#open_terminal()
    elseif bufname(g:terminator_buffer_number) !~# '^term://'
        echo "Your terminal is opening ... you may have to run this again if it opens too slowly"
        call terminator#open_terminal()
    else
        call chansend(g:terminator_job_id, a:contents)
    endif
endfunction

function terminator#start_repl()
    let cmd = get(s:terminator_repl_command, &ft, 'language_not_found')
    if cmd == 'language_not_found' | echo 'language not in repl dictionary' | return | endif
    call terminator#open_terminal()
    let cmd = terminator#substitute_command_variables(cmd)
    call terminator#send_to_terminal(cmd . "\n")
endfunction

function terminator#get_in_delimiter()
    " TODO: pass in the delimeter as an argument so different delimeters can
    " be used
    let save_pos = getpos(".")
    let last_delim = search('# In\[.*\]:', 'b')
    call setpos('.', save_pos)
    let next_delim = search('\(# In\[.*\]:\|\%$\)')
    call setpos('.', save_pos)
    if next_delim == line('$')
        let cell = getbufline(bufnr('%'), last_delim + 1, next_delim)
    endif
    let cell = getbufline(bufnr('%'), last_delim + 1, next_delim - 1)
    let cell = filter(cell, '!empty(v:val)')
    if cell[-1][0] == " "
    " TODO: this breaks when cursor is on last line of buffer
        let cell = cell + [" "]
    endif
    return cell + ["\n"]
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

function terminator#substitute_command_variables(command)
    let cmd = a:command
    let dir = expand("%:p:h") . "/"
    let fileName = expand("%:t")
    let fileNameWithoutExt = expand("%:t:r")
    let dirWithoutTrailingSlash = expand("%:h")
    let cmd = substitute(cmd, "\$dir", dir, "g")
    let cmd = substitute(cmd, "\$fileName ", fileName . " ", "g")
    let cmd = substitute(cmd, "\$fileNameWithoutExt", fileNameWithoutExt, "g")
    let cmd = substitute(cmd, "\$dirWithoutTrailingSlash", dirWithoutTrailingSlash, "g")
    return cmd
endfunction

function terminator#get_output_buffer(cmd)
    let first_line = '[Running] ' . a:cmd
    let error_format = &errorformat
    let buf_num = bufnr('_OUTPUT_BUFFER_')
    if buf_num == -1
        keepalt belowright split _OUTPUT_BUFFER_
        exec 'resize ' . string(&lines - &lines / 1.618)
        setlocal filetype=output_buffer buftype=nofile noswapfile nowrap cursorline modifiable nospell
        let &errorformat=error_format
        let buf_num = bufnr('%')
        call setline(1, first_line)
        wincmd p
    else
        let buffer_name = bufname(buf_num)
        silent call deletebufline(buffer_name, 1, '$')
        call setbufline(buffer_name, 1, first_line)
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

function terminator#on_event(job_id, data, event) dict
    if a:event == 'stdout'
        "echomsg a:data
        "TODO: on slow computers (such as raspberry pi) multiple lines may
        "print on one line
        if !empty(a:data[-1])
            call extend(self.str_buffer, a:data)
        elseif !empty(self.str_buffer)
            let l:chunks = terminator#glue_lists_together(self.str_buffer, a:data)
            let self.str_buffer = []
        else
            let l:chunks = a:data
            if empty(l:chunks[-1])
                call remove(l:chunks, -1)
            endif
        endif
        if exists("l:chunks")
            let l:str = copy(l:chunks)
        endif
    elseif a:event == 'stderr'
        "TODO: test if stderr needs buffered like stdout
        let the_data = join(a:data)
        caddexpr a:data
        cwindow
        if the_data == '' | return | endif
        call appendbufline(self.win_num, '$', '')
        let l:str = 'stderr: check the quickfix window for errors'
    else
        let run_time = split(reltimestr(reltime(self.start_time)))[0]
        let l:str = '[Done] exited with code=' . string(a:data) . ' in '  . run_time . ' seconds'
        cwindow
    endif
    if exists("l:str")
        call appendbufline(self.win_num, '$', l:str)
    endif
endfunction

let s:callbacks = {
\ 'on_stdout': function('terminator#on_event'),
\ 'on_stderr': function('terminator#on_event'),
\ 'on_exit': function('terminator#on_event')
\ }

function! terminator#run_file_in_output_buffer(cmd)
    cexpr ''
    cwindow
    let full_cmd = a:cmd
    let win_num = terminator#get_output_buffer(full_cmd)
    let start_time = reltime()
    let g:terminator_running_job = jobstart(full_cmd, extend({'win_num': win_num, 'start_time': start_time, 'str_buffer': []}, s:callbacks))
endfunction

function terminator#run_current_file(output_location)
    let cmd = get(s:terminator_runfile_map, &ft, 'language_not_found')
    if cmd == 'language_not_found' | echo 'language not in run dictionary' | return | endif
    let cmd = terminator#substitute_command_variables(cmd)
    if stridx(cmd, "fileName") == -1
        let needs_filename_at_end = 1
    endif
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

function terminator#run_stop_job()
    call jobstop(g:terminator_running_job)
endfunction
