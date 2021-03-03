if exists('g:terminator_loaded') || &compatible
  finish
endif

let g:terminator_loaded = 1

command! TerminatorOpenTerminal call terminator#open_terminal()
command! TerminatorStartREPL call terminator#start_repl()
command! -nargs=+ TerminatorSendToTerminal call terminator#send_to_terminal(<q-args> . "\n")
command! TerminatorRunFileInTerminal call terminator#run_current_file("terminal")
command! TerminatorRunFileInOutputBuffer call terminator#run_current_file("output_buffer")
command! TerminatorStopRun call terminator#run_stop_job()

if exists("g:terminator_clear_default_mappings")
else
    nnoremap <leader>ot :TerminatorOpenTerminal <CR>
    nnoremap <leader>or :TerminatorStartREPL <CR>
    nnoremap <leader>rt :TerminatorRunFileInTerminal <CR>
    nnoremap <leader>rf :TerminatorRunFileInOutputBuffer <CR>
    nnoremap <leader>rs :TerminatorStopRun <CR>

    nnoremap <leader>sd :call terminator#send_to_terminal(terminator#get_in_delimiter())<CR>
    nnoremap <leader>sf :call terminator#send_to_terminal('%run ' . expand('%') . "\n")<CR>
    vnoremap <leader>ss :call terminator#send_to_terminal(terminator#get_visual_selection())<CR>
endif
