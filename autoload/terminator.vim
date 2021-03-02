"TODO: add options for different split locations
"TODO: add safety featur to send_to_terminal so it only send if its the
"right terminal and the terminator is open

if exists("g:terminator_autoloaded") || &cp
  finish
endif

let g:terminator_autoloaded = 1

let s:terminator_repl_command = {
  \'python' : ['ipython', '--no-autoindent'],
  \'javascript': ['node'],
  \}

" this dictionary was extracted out of json from the vscode extension
" code-runner and modified 
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

if exists("g:terminator_repl_command")
    let s:terminator_repl_command = extend(s:terminator_repl_command, g:terminator_repl_command)
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
    let cmd = get(s:terminator_repl_command, &ft, 'language_not_found')
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
    let save_pos = getpos(".")
    let last_delim = search('# In\[.*\]:', 'b')
    call setpos('.', save_pos)
    let next_delim = search('\(# In\[.*\]:\|\%$\)')
    call setpos('.', save_pos)
    if next_delim == line('$')
        let cell = getbufline(bufnr('%'), last_delim + 1, next_delim)
    endif
    let cell = getbufline(bufnr('%'), last_delim + 1, next_delim - 1)
    let cell = terminator#remove_empty_strings(cell)
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

function terminator#run_current_file(output_location)
    let dir = expand("%:p:h") . "/"
    let fileName = expand("%:t")
    let fileNameWithoutExt = expand("%:t:r")
    let dirWithoutTrailingSlash = expand("%:h")

    let cmd = get(s:terminator_runfile_map, &ft, 'language_not_found')
    if cmd == 'language_not_found' | echo 'language not in run dictionary' | return | endif
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

"-------------------------------------------------------------------------------
" Run plugin merge
"-------------------------------------------------------------------------------
"
function terminator#remove_empty_strings(list)
    return filter(a:list, '!empty(v:val)')
endfunction

function terminator#splice_lists_together(list1, list2)
    let l:tmp1 = copy(a:list1)
    let l:tmp2 = copy(a:list2)
    let l:tmp1[-1] = trim(l:tmp1[-1], ' ')
    let l:tmp2[0] = trim(l:tmp2[0], ' ')
    let l:dummy = extend(l:tmp1, l:tmp2)
    let l:dummy = [join(l:dummy)]
    return l:dummy
endfunction

function terminator#on_event(job_id, data, event) dict
    "let output_string = join(a:data)
    if a:event == 'stdout'

        if !empty(a:data[-1])
            call add(self.str_buffer, join(a:data))
        elseif !empty(self.str_buffer)"
            let tmp = deepcopy(a:data)
            let l:chunks = terminator#splice_lists_together(self.str_buffer, tmp)
            let self.str_buffer = []
        else
            let l:chunks = a:data
        endif

        " TODO: data arrives in inconsistant order and results in
        " string new line issues
        " see Note 2 of :h job-control
        "
        "let s:chunks = ['']
        "let s:chunks[-1] .= a:data[0]
        "call extend(s:chunks, a:data[1:])

        "if s:chunks[0] == ''
        "    call remove(s:chunks, 0)
        "elseif s:chunks[-1] == ''
        "    call remove(s:chunks, -1)
        "endif

        if exists("l:chunks")
            call terminator#remove_empty_strings(l:chunks)
            let l:str = deepcopy(l:chunks)
        endif
    elseif a:event == 'stderr'
        let the_data = join(a:data)
        caddexpr a:data
        cwindow
        if the_data == '' | return | endif
        call appendbufline(self.win_num, '$', '')
        let l:str = 'stderr: check the quickfix window for errors'
    else
        "let str = 'exited ' . a:data
        "let finished_time = reltime()
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
        "execute("belowright split " . buffer_name)
        "exec 'resize ' . string(&lines - &lines / 1.618)
        silent call deletebufline(buffer_name, 1, '$')
        "call appendbufline(buffer_name, 1, first_line)
        call setbufline(buffer_name, 1, first_line)
        "wincmd p
    endif

    return buf_num
endfunction

function! terminator#run_file_in_output_buffer(cmd)
    cexpr ''
    cwindow
    "let cmd = get(s:terminator_runfile_map, &ft, '')
    "let full_cmd = a:cmd . ' ' . expand("%:p")
    let full_cmd = a:cmd
    let win_num = terminator#get_output_buffer(full_cmd)
    let start_time = reltime()
    let g:run_running_job = jobstart(full_cmd, extend({'win_num': win_num, 'start_time': start_time, 'str_buffer': []}, s:callbacks))
endfunction

function terminator#run_stop_job()
    call jobstop(g:run_running_job)
endfunction

