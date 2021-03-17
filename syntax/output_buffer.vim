syn region first_line oneline matchgroup=running start="^\[Running\]" matchgroup=command end=/.*/

syn region last_line oneline matchgroup=done start=/^\[Done\]/ matchgroup=sentence end=/$/ contains=exit_code,run_time
syn match exit_code /code=\d*/ contained
syn region run_time matchgroup=sentence start=/in/ end=/seconds/ contained

hi def link running Identifier
hi def link command String

hi def link last_line String
hi def link done Identifier
hi def link exit_code Error
hi def link run_time Number
hi def link sentence String
