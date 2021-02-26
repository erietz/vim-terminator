# About

This plugin can do a few thing.

1. Run your current file in neovim terminal using automatic file type detection 
2. Start a REPL using automatic file type detection
3. Send selected text and text between commented delimiters to a REPL (or terminal)
  - Currently only optimized for python

# Extensibility

- Out of the box, this plugin comes with several functions and default mappings.
- Eventually the default mappings will be optional and can be setup by the user
individually
- Both the commands used to run the current file and start a REPL for the current
file are modifiable by a global dictionary defined in the `init.vim` or `vimrc`.

The REPL command dictionary is defined like this.

```vim
let g:REPL_command = {
  \'python' : ['ipython', '--no-autoindent'],
  \'javascript': ['node'],
  \}
````

The file running dictionary is defined like this.

```vim
let g:terminator_runfile_map = {
            \ "javascript": "node",
            \ "java": "cd $dir && javac $fileName && java $fileNameWithoutExt",
            \ "c": "cd $dir && gcc $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
            \ }
```
allowing use of the variables defined below

| variable name            | description                                                                |
| ---                      | ---                                                                        |
| $fileName                | what you would get from running  `basename` on the file                    |
| $fileNameWithoutExt      | same as $fileName with everything after and including the last `.` removed |
| $dir                     | the full path of the parent directory of the filename                      |
| $dirWithoutTrailingSlash | same as $dir with the trailing slash removed                               |

# Installation

Using `vim-plug`

```vim
plug 'erietz/vim-terminator'
```
