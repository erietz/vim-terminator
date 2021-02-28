syn region first_line oneline matchgroup=running start="^\[Running\]" matchgroup=command end=/.*/
"syn region last_line1 oneline matchgroup=done start="^\[Done\]" matchgroup=exit_status end=/code=\d*/
"syn region last_line2 oneline matchgroup=NONE start="^\[Done.*code=\d*\]" matchgroup=time end=/in \d* seconds/
syn region last_line1 oneline matchgroup=test1 start=/^\[Done\]/ end=/seconds/ contains=last_line2,last_line3
syn match last_line2 /code=\d*/ contained
syn region last_line3 matchgroup=time start=/in/ end=/seconds/ contained
"syn region last_line2 matchgroup=test2 start=/code=\d*/ end=/\d* seconds/ contained

hi def link running Number
hi def link command String
hi def link last_line1 String
hi def link test1 Number
hi def link test2 Operator
hi def link last_line2 Type
hi def link last_line3 PreProc
hi def link time String
"hi def link last_line1 Operator
"hi def link done Number
"hi def link exit_status Type
