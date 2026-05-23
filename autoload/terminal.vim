"===============================================================
" Reference plugins
"
" https://zenn.dev/taro0079/articles/6094881dcadf4d
"
" iaalm/terminal-drawer.vim
" https://github.com/iaalm/terminal-drawer.vim
"
"===============================================================
let s:save_cpo = &cpoptions
set cpoptions&vim

let s:terminal_vsplit = 0
let s:terminal_winsize = -1

"---------------------------------------------------------------
" s:get_terminal_win_size
"---------------------------------------------------------------
function! s:get_terminal_win_size() abort
	let dic = getwininfo(win_getid())
	let s:terminal_winsize = s:terminal_vsplit ? dic[0].width : dic[0].height
endfunction

"---------------------------------------------------------------
" s:set_terminal_win_size
"---------------------------------------------------------------
function! s:set_terminal_win_size() abort
	if s:terminal_winsize > 0
		let vertical = s:terminal_vsplit ? "vertical " : ""
		execute vertical."resize ".s:terminal_winsize
	endif
endfunction

"---------------------------------------------------------------
" terminal#ToggleTerminal
"---------------------------------------------------------------
function! terminal#ToggleTerminal() abort
	let termNums = filter(map(getbufinfo(), 'v:val.bufnr'), 'getbufvar(v:val, "&buftype") is# "terminal"')
	let termWins = filter(getwininfo(), 'v:val.terminal')

	if &buftype == 'terminal'
		" If the current buffer is a terminal, close terminal window
		execute "buffer #"
		call s:get_terminal_win_size()
		execute "close"

	elseif len(termWins) > 0
		" Terminal buffer exists but is not current
		execute 'tabn'.termWins[0].tabnr
		execute termWins[0].winnr.'wincmd w'
		"
	elseif len(termNums) > 0
		" If the terminal buffer exists but is not visible, show terminal buffer
		let vertical = s:terminal_vsplit ? "vertical " : ""
		execute vertical.'split'
		execute "buffer " . termNums[0]
		execute "normal i"
		call s:set_terminal_win_size()

	else
		" If no terminal buffer exists, create a new one and save its buffer number
		execute 'lcd '.expand("%:h")
		terminal
		call s:set_terminal_win_size()
	endif
endfunction

"---------------------------------------------------------------
" terminal#ToggleRotate
"---------------------------------------------------------------
function! terminal#ToggRotate() abort
	let termNums = filter(map(getbufinfo(), 'v:val.bufnr'), 'getbufvar(v:val, "&buftype") is# "terminal"')

	if &buftype == 'terminal' && len(termNums) > 0
		" close terminal window
		execute "buffer #"
"		call s:get_terminal_win_size()
		execute "close"

		" reset terminal window size
		let s:terminal_winsize = 0

		" Toggle rotate
		let s:terminal_vsplit = xor(s:terminal_vsplit, 0x01)

		" show terminal window
		let vertical = s:terminal_vsplit ? "vertical " : ""
		execute vertical.'split'
		execute "buffer " . termNums[0]
		execute "normal i"
	endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo

