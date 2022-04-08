if exists("g:autoloaded_terminator") || &cp
    finish
endif
let g:autoloaded_terminator = 1

if exists("g:terminator_repl_command")
    let s:terminator_repl_command = extend(terminator#language_maps#repl_command, g:terminator_repl_command)
else
    let s:terminator_repl_command = terminator#language_maps#repl_command
endif

if exists("g:terminator_runfile_map")
    let s:terminator_runfile_map = extend(terminator#language_maps#runfile_map, g:terminator_runfile_map)
else
    let s:terminator_runfile_map = terminator#language_maps#runfile_map
endif

" used in plugin/terminator.vim
function terminator#get_run_cmd(filename)
    let cmd = get(s:terminator_runfile_map, &ft, 'language_not_found')
    if cmd == 'language_not_found' | echo 'language not in run dictionary' | return | endif
    if stridx(cmd, "fileName") == -1
        let needs_filename_at_end = 1
    endif
    let cmd = terminator#util#substitute_command_variables(cmd, a:filename)
    if exists("needs_filename_at_end")
        let cmd = cmd . ' ' . fnamemodify(a:filename, ":p")
    endif
    return cmd
endfunction

function terminator#run_file(output_location, filename) abort
    update
    let cmd = terminator#get_run_cmd(a:filename)
    if a:output_location == "terminal"
        call terminator#window#send_to_terminal(cmd . "\n")
    elseif a:output_location == "output_buffer"
        call terminator#jobs#run_file_in_output_buffer(cmd)
    else
        echo "invalid option for this function"
    end
endfunction

function terminator#run_part_of_file(output_location, register) abort
    let filename = fnamemodify(fnameescape(expand("%")), ":e")
    let l:tmpfile = tempname() . "." . filename
    call writefile(split(a:register, '\n'), fnameescape(l:tmpfile))
    call terminator#run_file(a:output_location, fnameescape(l:tmpfile))
endfunction


function terminator#start_repl() abort
    let cmd = get(s:terminator_repl_command, &ft, 'language_not_found')
    if cmd == 'language_not_found' | echo 'language not in repl dictionary' | return | endif
    call terminator#window#open_terminal()
    let filename = fnameescape(expand("%"))
    let cmd = terminator#util#substitute_command_variables(cmd, filename)
    call terminator#window#send_to_terminal(cmd . "\n")
endfunction

