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
    nnoremap <silent> <leader>ot :TerminatorOpenTerminal <CR>
    nnoremap <silent> <leader>or :TerminatorStartREPL <CR>
    nnoremap <silent> <leader>rt :TerminatorRunFileInTerminal <CR>
    nnoremap <silent> <leader>rf :TerminatorRunFileInOutputBuffer <CR>
    nnoremap <silent> <leader>rs :TerminatorStopRun <CR>

    nnoremap <silent> <leader>sd :call terminator#send_to_terminal(terminator#get_in_delimiter())<CR>
    nnoremap <silent> <leader>sf :call terminator#send_to_terminal('%run ' . expand('%') . "\n")<CR>
    vnoremap <silent> <leader>ss :call terminator#send_to_terminal(terminator#get_visual_selection())<CR>
endif
