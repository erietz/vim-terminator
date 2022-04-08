if exists('g:terminator_loaded') || &compatible
  finish
endif

let g:terminator_loaded = 1

command! TerminatorOpenTerminal call terminator#window#open_terminal()
command! TerminatorStartREPL call terminator#start_repl()
command! -nargs=+ TerminatorSendToTerminal call terminator#window#send_to_terminal(<q-args> . "\n")
command! TerminatorRunFileInTerminal call terminator#run_file("terminal", expand("%"))
command! TerminatorRunFileInOutputBuffer call terminator#run_file("output_buffer", expand("%"))
command! TerminatorStopRun call terminator#jobs#stop_running_job()
command! -nargs=+ TerminatorRunAltCmd call terminator#jobs#run_file_in_output_buffer(<q-args>)
command! TerminatorToggleOutputBuffer call terminator#window#output_buffer_toggle()

command! -range TerminatorSendSelectionToTerminal call terminator#window#send_to_terminal(terminator#util#get_visual_selection())
command! TerminatorSendDelimiterToTerminal call terminator#util#send_delimiter_to_terminal()
command! -range TerminatorRunPartOfFileInTerminal call terminator#run_part_of_file("terminal", terminator#util#get_visual_selection())
command! -range TerminatorRunPartOfFileInOutputBuffer call terminator#run_part_of_file("output_buffer", terminator#util#get_visual_selection())

if !exists("g:terminator_clear_default_mappings")
    nnoremap <silent> <leader>ot :TerminatorOpenTerminal <CR>
    nnoremap <silent> <leader>or :TerminatorStartREPL <CR>
    nnoremap <silent> <leader>rt :TerminatorRunFileInTerminal <CR>
    nnoremap <silent> <leader>rf :TerminatorRunFileInOutputBuffer <CR>
    nnoremap <silent> <leader>rs :TerminatorStopRun <CR>
    nnoremap <leader>rm :TerminatorRunAltCmd <C-R>=terminator#get_run_cmd(fnameescape(expand("%")))<CR>

    nnoremap <silent> <leader>sd :TerminatorSendDelimiterToTerminal<CR>
    vnoremap <silent> <leader>ss :TerminatorSendSelectionToTerminal<CR>

    vnoremap <silent> <leader>rf :TerminatorRunPartOfFileInOutputBuffer<CR>
    vnoremap <silent> <leader>rt :TerminatorRunPartOfFileInTerminal<CR>
endif
