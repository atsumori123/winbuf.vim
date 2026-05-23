let s:save_cpo = &cpoptions
set cpoptions&vim

if exists('g:loaded_switch')
	finish
endif
let g:loaded_switch = 1

if !exists('g:switch_all_window')
	let g:switch_all_window = 0
endif

nnoremap <silent> <Plug>(wb-next-buffer)		:<C-U>call switch_buffer#switch_buffer(1)
nnoremap <silent> <Plug>(wb-prev-buffer)		:<C-U>call switch_buffer#switch_buffer(-1)
nnoremap <silent> <Plug>(wb-next-window)		:<C-U>call switch_window#switch_window(1)
nnoremap <silent> <Plug>(wb-prev-window)		:<C-U>call switch_window#switch_window(-1)
nnoremap <silent> <Plug>(wb-toggle-terminal)	:<C-U>call terminal#toggle_terminal()
tnoremap <silent> <Plug>(wb-toggle-terminal)	:<C-U> <C-\><C-n>:call terminal#toggle_terminal()
tnoremap <silent> <Plug>(wb-rotate-terminal)	:<C-U> <C-\><C-n>:call terminal#rotate_terminal()
nnoremap <silent> <Plug>(wb-toggle_preview)	:<C-U>call quickfix#toggle_preview()
nnoremap <silent> <Plug>(wb-toggle-quickfix)	:<C-U>call quickfix#toggle_quickfix()
nnoremap <silent> <Plug>(wb-buffer-close)		:<C-U>call buffer#close()
nnoremap <silent> <Plug>(wb-buffer-list)		:<C-U>call buffer#list()

let &cpoptions = s:save_cpo
unlet s:save_cpo
