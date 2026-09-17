let s:save_cpo = &cpoptions
set cpoptions&vim

" 通常バッファの番号を取得する
function! winbuf#normal_buffers() abort
	let buffers = []
	for info in getbufinfo({'buflisted': 1})
		if filereadable(info.name) || getbufvar(info.bufnr, '&buftype') ==# ''
			call add(buffers, info.bufnr)
		endif
	endfor
	return buffers
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
