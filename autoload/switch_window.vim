let s:save_cpo = &cpoptions
set cpoptions&vim

"-------------------------------------------------------
" Tabキーでウィンドウを切り替える関数
"-------------------------------------------------------
function! switch_window#switch_window(direction) abort
	" 特殊バッファも全てのウィンドウが移動対象の場合
	if g:switch_all_window == 0
		if a:direction > 0 | wincmd w | else | wincmd W | endif
		return
	endif

	" ウィンドウが1つしかない場合は何もしない
	if winnr('$') == 1 | return | endif

	let start_win = winnr()
	let current_win = start_win
	let total_win = winnr('$')

	while 1
		if a:direction > 0
			" 正順: 1 -> 2 -> 3 -> 1
			let current_win = (current_win % winnr('$')) + 1
		else
			" 逆順: 1 -> 3 -> 2 -> 1
			let current_win = current_win == 1 ? total_win : current_win - 1
		endif

		" 特殊バッファかどうかを判定（buftypeが空＝通常バッファ）
		" もし移動先が通常バッファ、あるいは一周回って戻ってきたらループ終了
		if getbufvar(winbufnr(current_win), '&buftype') ==# '' || current_win == start_win
			execute current_win . 'wincmd w'
			break
		endif
	endwhile
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
