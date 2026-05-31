"===============================================================
" Reference plugins
"
" https://zenn.dev/taro0079/articles/6094881dcadf4d
" https://qiita.com/gorilla0513/items/f59e54606f6f4d7e3514
"
" iaalm/terminal-drawer.vim
" https://github.com/iaalm/terminal-drawer.vim
"
"===============================================================
let s:save_cpo = &cpoptions
set cpoptions&vim

let s:pop_term_win = 0
let s:pop_term_buf = 0

"---------------------------------------------------------------
" nvim用（フローティングウィンドウ）
"---------------------------------------------------------------
function! s:toggle_terminal_floating() abort
	" すでにウィンドウが開いている場合は閉じる（バッファは維持）
	if s:pop_term_win != 0 && nvim_win_is_valid(s:pop_term_win)
		call nvim_win_close(s:pop_term_win, 1)
		let s:pop_term_win = 0
		return
	endif

	" フローティングウィンドウの配置計算（中央表示）
	let width = &columns - 20
	let height = &lines - 10
	let opts = {
		\ 'relative': 'editor',
		\ 'width': width,
		\ 'height': height,
		\ 'col': (&columns - width) / 2,
		\ 'row': (&lines - height) / 2,
		\ 'style': 'minimal',
		\ 'border': 'rounded'
		\ }

	" 過去の有効なバッファがあるか確認
	if s:pop_term_buf != 0 && bufexists(s:pop_term_buf)
		let s:pop_term_win = nvim_open_win(s:pop_term_buf, v:true, opts)
	else
		" 新しいバッファを作成してターミナルを起動
		let s:pop_term_buf = nvim_create_buf(v:false, v:true)
        let s:pop_term_win = nvim_open_win(s:pop_term_buf, v:true, opts)

		" ウィンドウが開いた状態（アクティブ）でターミナルを起動
		call termopen(&shell)
	endif

	highlight link NormalFloat Normal
	highlight link FloatBorder Normal

"	call feedkeys("i", "n")
	call feedkeys("i\<BS>\<BS>\<BS>", "n")
endfunction

"---------------------------------------------------------------
" vim用（ポップアップウィンドウ）
"---------------------------------------------------------------
function! s:toggle_terminal_popup() abort
	" すでにポップアップウィンドウが開いている場合は閉じる（プロセスは維持）
	if s:pop_term_win != 0 && popup_getoptions(s:pop_term_win) != {}
		call popup_close(s:pop_term_win)
		let s:pop_term_win = 0
		return
	endif

	" 過去に作ったバッファが存在し、かつ有効な場合はそれを再利用する（前回の続き）
	let continue = 0
	if s:pop_term_buf != 0 && bufexists(s:pop_term_buf)
		let buf = s:pop_term_buf
		let continue = 1
	else
		" 初回起動、またはプロセスが終了していた場合は新しくターミナルを作る
		" &shell を使うことで、現在環境の標準シェル（bash, " zsh等）を自動起動する
		let buf = term_start([&shell], {'hidden': 1, 'term_finish': 'close', 'term_kill': 'kill'})
		let s:pop_term_buf = buf
	endif

	" ポップアップウィンドウを作成してターミナルバッファを表示
	let s:pop_term_win = popup_create(buf, {
		\ 'minwidth': &columns - 20,
		\ 'minheight': &lines - 10,
		\ 'maxwidth': &columns - 20,
		\ 'maxheight': &lines - 10,
		\ 'border': [],
		\ 'borderhighlight': ['Comment'],
		\ 'filter': 'TogglePopupTerminalFilter',
		\ })

	if continue
    	call feedkeys("i", "n")
	endif
endfunction

"---------------------------------------------------------------
" terminal#ToggleTerminal
"---------------------------------------------------------------
function! terminal#toggle_terminal() abort
	if has('nvim')
		call s:toggle_terminal_floating()
	else
		call s:toggle_terminal_popup()
	endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo

