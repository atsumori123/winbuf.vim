let s:save_cpo = &cpoptions
set cpoptions&vim

"-------------------------------------------------------
" ウィンドウのリサイズ
"-------------------------------------------------------
function! resize_window#resize_window() abort
	" リサイズウィンドウ位置の幾何情報を取得
	let info = getwininfo(win_getid())[0]
	let is_left_edge = (info.wincol == 1)
	let is_top_edge  = (info.winrow == 1)

	" 隣接するウィンドウの有無をチェック (移動先が自分と同じなら「端」)
	let has_left_win  = (winnr() != winnr('h'))
	let has_right_win = (winnr() != winnr('l'))
	let has_up_win	  = (winnr() != winnr('k'))
	let has_down_win  = (winnr() != winnr('j'))

	" 隣接するウィンドウがwinfixwidthまたはwinfixheightか取得
	let is_right_win_fixed	= has_left_win ? getwinvar(winnr('l'), '&winfixwidth') : 0
	let is_down_win_fixed	= has_down_win ? getwinvar(winnr('j'), '&winfixheight') : 0

	" 現在のウィンドウがwinfixwidthまたはwinfixheightか取得
	let is_width_fixed		= getwinvar(0, '&winfixwidth')
	let is_height_fixed		= getwinvar(0, '&winfixheight')

	echohl String | echo "Window resizing... (Expand with H/J/K/L, Exit with <ESC>)" | echohl None

	let exit_flag = 0
	while !exit_flag
		try
			let char_raw = getchar()
			let char = (type(char_raw) == type(0)) ? nr2char(char_raw) : char_raw
		catch /^Vim:Interrupt$/
			let char = "\<ESC>"
		endtry

		" H キー：左側に縮小
		if char ==# 'h'
			if has_right_win
				" 右側にウィンドウがある場合、現在のウィンドウを縮小する
				execute printf("vertical resize %s", is_right_win_fixed ? "+2" : "-2")
			elseif has_left_win
				" 左側にウィンドウがある場合、左側のウィンドウを縮小する
				if is_width_fixed 
					execute "vertical resize +2"
				else
					execute "wincmd h"
					execute "vertical resize -2"
					execute "wincmd p"
				endif
			endif

		" L キー：右側に拡張
		elseif char ==# 'l'
			if has_right_win
				" 右側にウィンドウがある場合、現在のウィンドウを拡張する
				execute printf("vertical resize %s", is_right_win_fixed ? "-2" : "+2")
			elseif has_left_win
				" 左側にウィンドウがある場合、左側のウィンドウを拡張する
				if is_width_fixed 
					execute "vertical resize -2"
				else
					execute "wincmd h"
					execute "vertical resize +2"
					execute "wincmd p"
				endif
			endif

		" K キー: 上側に縮小
		elseif char ==# 'k'
			if has_down_win
				" 下側にウィンドウがある場合、現在のウィンドウを縮小する
				execute printf("resize %s", is_down_win_fixed ? "+2" : "-2")
			elseif has_up_win
				" 上側にウィンドウがある場合、上側のウィンドウを縮小する
				if is_height_fixed 
					execute "resize +2"
				else
					execute "wincmd k"
					execute "resize -2"
					execute "wincmd p"
				endif
			endif

		" J キー: 下側に拡張
		elseif char ==# 'j'
			if has_down_win
				" 下側にウィンドウがある場合、現在のウィンドウを拡張する
				execute printf("resize %s", is_down_win_fixed ? "-2" : "+2")
			elseif has_up_win
				" 上側にウィンドウがある場合、上側のウィンドウを拡張する
				if is_height_fixed 
					execute "resize -2"
				else
					execute "wincmd k"
					execute "resize +2"
					execute "wincmd p"
				endif
			endif

		" --- ESC キー: 終了 ---
		elseif char == "\<ESC>"
			let exit_flag = 1

		endif
		redraw

	endwhile
	echo ""
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
