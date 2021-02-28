if exists('g:terminator_loaded') || &compatible
  finish
endif

let g:terminator_loaded = 1

nnoremap <leader>sd :call terminator#send_to_terminal(terminator#get_in_delimiter())<CR>
nnoremap <leader>sf :call terminator#send_to_terminal('%run ' . expand('%') . "\n")<CR>
vnoremap <c-c><c-c> :call terminator#send_to_terminal(terminator#get_visual_selection())<CR>

command! OpenTerminal call terminator#open_terminal()
command! StartREPL call terminator#StartREPL()
command! -nargs=+ SendStuffToTerminal call terminator#send_to_terminal(<q-args> . "\n")
command! RunFileInTerminal call terminator#run_current_file("terminal")
command! RunFileInOutputBuffer call terminator#run_current_file("output_buffer")

nnoremap <leader>ot :OpenTerminal <CR>
nnoremap <leader>or :StartREPL <CR>
nnoremap <leader>rf :RunFileInTerminal <CR>
nnoremap <leader>rr :RunFileInOutputBuffer <CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Run plugin merge
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

command! RunStop call terminator#run_stop_job()
