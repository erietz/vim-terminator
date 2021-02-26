if exists('g:terminator_loaded') || &compatible
  finish
endif

let g:terminator_loaded = 1

nnoremap <leader>sd :call terminator#SendStuffToTerminal(terminator#GetInDelimeter())<CR>
nnoremap <leader>sf :call terminator#SendStuffToTerminal('%run ' . expand('%') . "\n")<CR>
vnoremap <c-c><c-c> :call terminator#SendStuffToTerminal(terminator#GetVisualSelection())<CR>

command! OpenTerminal call terminator#OpenTerminal()
command! StartREPL call terminator#StartREPL()
command! -nargs=+ SendStuffToTerminal call terminator#SendStuffToTerminal(<q-args> . "\n")
command! RunFileInTerminal call terminator#RunFileInTerminal()

nnoremap <leader>ot :OpenTerminal <CR>
nnoremap <leader>or :StartREPL <CR>
nnoremap <leader>rf :RunFileInTerminal <CR>
