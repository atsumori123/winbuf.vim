let s:save_cpo = &cpoptions
set cpoptions&vim

let s:preview_line = ""
let s:normal_buflist = []

"---------------------------------------------------------------
" close_preview
"---------------------------------------------------------------
function! s:close_preview() abort
	" jump to preview window
	silent! wincmd P

	" if it is not preview window ?
	if &previewwindow == 0 | return | endif

	" get buffer number of preview
	let bnr = bufnr('%')

	" back to quickfix window
	wincmd p

	" close preview window
	silent! pclose

	" if there is no preview buffer in normal buffer, then delete buffer
	if match(s:normal_buflist, bnr) < 0
		silent! execute 'bdelete! '.bnr
	endif
endfunction

"---------------------------------------------------------------
" プレビューの表示/非表示
"---------------------------------------------------------------
function! quickfix#toggle_preview() abort
	" if it is not quickfix window, then return
	if &buftype != 'quickfix' | return | endif

	" 一旦プレビューをクローズ
	call s:close_preview()

	" get current line number of quickfix window
	let line = getline('.')

	" 前回と同じ項目のプレビューの場合は空白を設定し、プレビューを表示させない
	let s:preview_line = line == s:preview_line ? "" : line
	if empty(s:preview_line) | return | endif

	" プレビューを開く前の全ての通常バッファを記憶
	let s:normal_buflist= map(getbufinfo({'buflisted': 1}), 'v:val.bufnr')
	call filter(s:normal_buflist, 'filereadable(bufname(v:val)) || empty(getbufvar(v:val, "&buftype"))')

	" ファイル履歴に残さずにプレビューウィンドウを水平分割の上側に開く
	if exists('g:lock_oldfiles') | let g:lock_oldfiles = 1 | endif
	let w = split(line, '|')
	execute "leftabove pedit +" . w[1] . ' ' . w[0]
	if exists('g:lock_oldfiles') | let g:lock_oldfiles = 0 | endif
endfunction

"---------------------------------------------------------------
" Quickfixの表皮/非表示
"---------------------------------------------------------------
function! quickfix#toggle_quickfix() abort
	if g:winbuf_switch_all_window
		let nr = winnr("$")
		copen

		if nr == winnr("$")
			wincmd p
			cclose
			call s:close_preview()
		else
			set modifiable
		endif

	else
		if get(getwininfo(win_getid())[0], 'quickfix', 0)
			cclose
			return
		else
			copen
			set modifiable
		endif
	endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
