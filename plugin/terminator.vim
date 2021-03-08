if exists('g:terminator_loaded') || &compatible
  finish
endif

let g:terminator_loaded = 1

command! TerminatorOpenTerminal call terminator#open_terminal()
command! TerminatorStartREPL call terminator#start_repl()
command! -nargs=+ TerminatorSendToTerminal call terminator#send_to_terminal(<q-args> . "\n")
command! TerminatorRunFileInTerminal call terminator#run_file("terminal", expand("%"))
command! TerminatorRunFileInOutputBuffer call terminator#run_file("output_buffer", expand("%"))
command! TerminatorStopRun call terminator#stop_running_job()

if exists("g:terminator_clear_default_mappings")
else
    nnoremap <silent> <leader>ot :TerminatorOpenTerminal <CR>
    nnoremap <silent> <leader>or :TerminatorStartREPL <CR>
    nnoremap <silent> <leader>rt :TerminatorRunFileInTerminal <CR>
    nnoremap <silent> <leader>rf :TerminatorRunFileInOutputBuffer <CR>
    nnoremap <silent> <leader>rs :TerminatorStopRun <CR>

    nnoremap <silent> <leader>sd :call terminator#send_delimiter_to_terminal()<CR>
    vnoremap <silent> <leader>ss :<C-U> call terminator#send_to_terminal(terminator#get_visual_selection())<CR>

    vnoremap <silent> <leader>rf :<C-U> call terminator#run_part_of_file("output_buffer", terminator#get_visual_selection())<CR>
    vnoremap <silent> <leader>rt :<C-U> call terminator#run_part_of_file("terminal", terminator#get_visual_selection())<CR>
endif
