let s:save_cpo = &cpoptions
set cpoptions&vim

"-------------------------------------------------------
" warning
"-------------------------------------------------------
function! s:warning(msg) abort
	echohl WarningMsg | echomsg a:msg | echohl None
endfunction

"---------------------------------------------------------------
" switch_buffer#switch_buffer
"---------------------------------------------------------------
function! switch_buffer#switch_buffer(direction) abort
	if &buftype == 'quickfix'
		let qfnum = getqflist({'nr':'$'}).nr
		let qfid = getqflist({'nr':0}).nr

		if a:direction == 1
			if qfid >= qfnum
				call s:warning('qflist: top of stack')
			else
				silent cnewer
				echo "\r"
				setlocal modifiable
			endif
		else
			if qfid <= 1
				call s:warning('qflist: bottom of stack')
			else
				silent colder
				echo "\r"
				setlocal modifiable
			endif
		endif

	else
		" 通常バッファ以外は操作対象外
		if !buflisted(bufnr('%')) | return | endif

		if exists('g:stline_buffers')
			let buflist = g:stline_buffers
		else
			" カレントバッファ以外で、ファイルとして存在、または新規ファイルのバッファリストを作成
			let buflist = map(getbufinfo({'buflisted': 1}), 'v:val.bufnr')
			call filter(buflist, 'filereadable(bufname(v:val)) || empty(getbufvar(v:val, "&buftype"))')
		endif
			
		" 通常バッファが1個の場合はスイッチできるバッファがないため終了する
		if len(buflist) <= 1 | return | endif

		" 次(前)のバッファ番号のインデックスを取得
		let ofs = index(buflist, bufnr("%")) + a:direction
		let ofs = (ofs < 0) ? len(buflist) - 1 : ofs % len(buflist)

		" バッファスイッチ
		execute 'buffer ' . buflist[ofs]
	endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
