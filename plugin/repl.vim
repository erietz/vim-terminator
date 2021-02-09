if exists('g:repl_loaded') || &compatible
  finish
endif

let g:repl_loaded = 1


nnoremap <leader>tp :call repl#StartREPL()<CR>
nnoremap <c-c><c-d> :call repl#SendStuffToTerminal(g:test_job_id, repl#GetInDelimeter())<CR>
vnoremap <c-c><c-c> :call repl#SendStuffToTerminal(g:test_job_id, repl#GetVisualSelection())<CR>

command! StartREPL call repl#StartREPL()
command! -nargs=+ SendStuffToTerminal call repl#SendStuffToTerminal(<q-args>)
