if exists("g:autoloaded_terminator_jobs")
    finish
endif
let g:autoloaded_terminator_jobs = 1

let s:has_windows = has('win32') || has('win64')
let s:has_nvim = has('nvim')

function! terminator#jobs#run_file_in_output_buffer(cmd) abort
    cexpr ''
    botright cwindow
    let s:output_buf_num = terminator#window#output_buffer_prepare(a:cmd)
    let s:start_time = reltime()
    if s:has_windows
        let cmd =  a:cmd
    else
        let cmd =  ['/bin/sh', '-c', a:cmd]
    endif
    if s:has_nvim
        let g:terminator_running_job = jobstart(cmd, {
                    \ 'stdout_queue': [''],
                    \ 'stderr_queue': [''],
                    \ 'on_stdout': function('terminator#jobs#nvim_on_event'),
                    \ 'on_stderr': function('terminator#jobs#nvim_on_event'),
                    \ 'on_exit': function('terminator#jobs#nvim_on_event'),
                    \ })
    else
        let g:terminator_running_job = job_start(cmd, {
                    \ 'out_io': "buffer",
                    \ 'out_buf': s:output_buf_num,
                    \ 'err_cb': function('terminator#jobs#vim_on_error'),
                    \ 'exit_cb': function('terminator#jobs#vim_on_exit'),
                    \ })
    endif
endfunction

function terminator#jobs#nvim_on_event(job_id, data, event) dict
    " see :help channel-bytes for details on this
    if a:event == 'stdout'
        let self.stdout_queue[-1] .= a:data[0]
        call extend(self.stdout_queue, a:data[1:])
        let l:str = self.stdout_queue[:-2]
        let self.stdout_queue = [self.stdout_queue[-1]]

    elseif a:event == 'stderr'
        " [''] is returned if there are no errors
        if join(a:data) == '' | return | endif

        let self.stderr_queue[-1] .= a:data[0]
        call extend(self.stderr_queue, a:data[1:])
        caddexpr self.stderr_queue[:-2]
        let self.stderr_queue = [self.stderr_queue[-1]]
        return

    else
        let run_time = split(reltimestr(reltime(s:start_time)))[0]
        let end_of_queue = self.stdout_queue[-1]
        if end_of_queue != ''
            call appendbufline(s:output_buf_num, '$', end_of_queue)
        endif
        call appendbufline(s:output_buf_num, '$', '')
        if a:data == 0
            let l:str = '[Done] in '  . run_time . ' seconds'
        else
            call terminator#window#output_buffer_close()
            let l:str = '[Done] in '  . run_time . ' seconds with code=' . string(a:data)
        endif
        botright cwindow
        " call terminator#window#output_buffer_shrink()
        if a:data != 0
            copen
        endif
    endif

    call appendbufline(s:output_buf_num, '$', l:str)
endfunction

function terminator#jobs#vim_on_exit(channel, data)
    let run_time = split(reltimestr(reltime(s:start_time)))[0]
    call appendbufline(s:output_buf_num, '$', '')
    if a:data == 0
        let l:str = '[Done] in '  . run_time . ' seconds'
    else
        let l:str = '[Done] in '  . run_time . ' seconds with code=' . string(a:data)
    endif
    call appendbufline(s:output_buf_num, '$', l:str)
    botright cwindow
    call terminator#window#output_buffer_shrink()
endfunction

function terminator#jobs#vim_on_error(channel, data)
    if a:data == '' | return | endif
    caddexpr a:data
endfunction


function terminator#jobs#stop_running_job()
    if s:has_nvim
        call jobstop(g:terminator_running_job)
    else
        call job_stop(g:terminator_running_job)
    endif
endfunction

