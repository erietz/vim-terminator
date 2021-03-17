syn region first_line oneline matchgroup=running start="^\[Running\]" matchgroup=command end=/.*/
syn region last_line1 oneline matchgroup=last_line_all start=/^\[Done\]/ end=/seconds/ contains=last_line2,last_line3
syn match last_line2 /code=\d*/ contained
syn region last_line3 matchgroup=last_line_time start=/in/ end=/seconds/ contained
syn region error oneline matchgroup=stderr start=/^stderr\:/ matchgroup=errmsg end=/ check the quickfix window/

hi def link running Identifier
hi def link command String
hi def link last_line1 String
hi def link last_line_all Identifier
hi def link last_line2 Function
hi def link last_line3 Number
hi def link last_line_time String
hi def link stderr Error
hi def link errmsg Underlined
