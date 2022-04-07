if exists("g:autoloaded_terminator") || &cp
    finish
endif
let g:autoloaded_terminator = 1

if exists("g:terminator_repl_command")
    let s:terminator_repl_command = extend(terminator#language_maps#repl_command, g:terminator_repl_command)
endif

if exists("g:terminator_runfile_map")
    let s:terminator_runfile_map = extend(terminator#language_maps#runfile_map, g:terminator_runfile_map)
endif

" used in plugin/terminator.vim
function terminator#get_run_cmd(filename)
    let cmd = get(s:terminator_runfile_map, &ft, 'language_not_found')
    if cmd == 'language_not_found' | echo 'language not in run dictionary' | return | endif
    if stridx(cmd, "fileName") == -1
        let needs_filename_at_end = 1
    endif
    let cmd = terminator#substitute_command_variables(cmd, a:filename)
    if exists("needs_filename_at_end")
        let cmd = cmd . ' ' . fnamemodify(a:filename, ":p")
    endif
    return cmd
endfunction

function terminator#start_repl() abort
    let cmd = get(s:terminator_repl_command, &ft, 'language_not_found')
    if cmd == 'language_not_found' | echo 'language not in repl dictionary' | return | endif
    call terminator#window#open_terminal()
    let filename = fnameescape(expand("%"))
    let cmd = terminator#substitute_command_variables(cmd, filename)
    call terminator#window#send_to_terminal(cmd . "\n")
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

