if exists('g:loaded_winbuf')
	finish
endif
let g:loaded_winbuf = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

if !exists('g:winbuf_switch_all_window')
	let g:winbuf_switch_all_window = 0
endif
if !exists('g:winbuf_shell_type')
	let g:winbuf_shell_type = &shell
endif

let &cpoptions = s:save_cpo
unlet s:save_cpo
