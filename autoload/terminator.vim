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

function terminator#run_file_in_terminal()
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

    call terminator#send_to_terminal(cmd . "\n")
endfunction
