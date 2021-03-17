syn region first_line oneline matchgroup=running start="^\[Running\]" matchgroup=command end=/.*/
hi def link running Identifier
hi def link command String

syn region last_line oneline matchgroup=done start=/^\[Done\]/ matchgroup=sentence end=/$/ contains=exit_code,run_time
syn match exit_code /code=\d*/ contained
syn region run_time matchgroup=sentence start=/in/ end=/seconds/ contained
"syn region error oneline matchgroup=stderr start=/^stderr\:/ matchgroup=errmsg end=/ check the quickfix window/

hi def link last_line String
hi def link done Identifier
hi def link exit_code Error
hi def link run_time Number
hi def link sentence String

"hi def link last_line2 Function
"hi def link run_time Number
"hi def link last_line_time String
"hi def link stderr Error
"hi def link errmsg Underlined
