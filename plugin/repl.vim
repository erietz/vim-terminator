if exists('g:repl_loaded') || &compatible
  finish
endif

let g:repl_loaded = 1


nnoremap <leader>tp :call repl#StartREPL()<CR>
nnoremap <leader>sd :call repl#SendStuffToTerminal(g:test_job_id, repl#GetInDelimeter())<CR>
nnoremap <leader>sf :call repl#SendStuffToTerminal(g:test_job_id, '%run ' . expand('%') . "\n")<CR>
vnoremap <c-c><c-c> :call repl#SendStuffToTerminal(g:test_job_id, repl#GetVisualSelection())<CR>

command! StartREPL call repl#StartREPL()
command! -nargs=+ SendStuffToTerminal call repl#SendStuffToTerminal(<q-args>)
