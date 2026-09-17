let s:save_cpo = &cpoptions
set cpoptions&vim

"-------------------------------------------------------
" warning
"-------------------------------------------------------
function! s:warning(msg) abort
	echohl WarningMsg | echomsg a:msg | echohl None
endfunction

"-------------------------------------------------------
" 選択
"-------------------------------------------------------
function! s:on_select(pos) abort
	let bnr = split(getline(a:pos))
	silent! close
	let winnum = bufwinnr(bnr[0] + 0)
	if winnum != -1
		execute winnum.'wincmd w'
	else
		execute 'wincmd p'
		execute 'buffer '.bnr[0]
	endif
endfunction

"-------------------------------------------------------
" 削除
"-------------------------------------------------------
function! s:on_delete(pos) abort
	if line('$') <= 1
		call s:warning("Cannot delete because number of buffers is 1")
		return
	endif

	let bnr1 = split(getline(a:pos))[0]
	let bnr2 = split(getline(a:pos == 1 ? a:pos + 1 : a:pos - 1))[0]

	setlocal modifiable
	normal! dd
	normal! 0
	setlocal nomodifiable

	if !getbufinfo(str2nr(bnr1, 10))[0].hidden
		wincmd p
		execute "b".bnr2
		wincmd p
	endif
	execute 'bdelete! '.bnr1
endfunction

"-------------------------------------------------------
" バッファーリスト
"-------------------------------------------------------
function! buffer#list() abort
	" バッファ情報を構造化データから取得してメニューリストを作成
	let current_bufnr = bufnr('%')
	let alternate_bufnr = bufnr('#')
	let list = []
	for info in getbufinfo({'buflisted': 1})
		let filename = empty(info.name) ? '[No Name]' : info.name
		let is_active = !empty(get(info, 'windows', []))
		let flags = info.bufnr == current_bufnr ? '%a' : info.bufnr == alternate_bufnr ? '#'.(is_active ? 'a' : 'h') : is_active ? 'a' : 'h'
		call add(list, printf('%4d %s %3s    %s  (%s)', info.bufnr, is_active ? '*' : ' ', flags, fnamemodify(filename, ':t'), filename))
	endfor

	" 既にバッファリストを開いている場合はフォーカスだけ移動させて終了
	let winnum = bufwinnr("-buffers-")
	if winnum != -1
		exe winnum.'wincmd w'
		return
	endif

	" Open a new window at the bottom
	exe 'silent! botright 8 split '."-buffers-"

	setlocal buftype=nofile
	setlocal bufhidden=delete
	setlocal noswapfile
	setlocal nobuflisted
	setlocal nowrap
	setlocal nonumber
	setlocal foldcolumn=0
	setlocal filetype=buffer
	setlocal winfixheight winfixwidth

	" draw buffer
	silent! 0put = list
	silent! $delete _
	normal! gg
	setlocal nomodifiable

	" カーソル位置を先頭に移動
	call setpos(".", [0, 1, 1, 0])

	" set hightlight
	syn match bufferKey '^  .[A-Z|[0-9] '
	syn match bufferText '\*.*$'
	hi! def link bufferKey Function
	hi! def link bufferText Label

	" set keymap
	nnoremap <buffer> <silent> <CR> :call <SID>on_select(line('.'))<CR>
	nnoremap <buffer> <silent> dd :call <SID>on_delete(line('.'))<CR>
	nnoremap <buffer> <silent> q :close<CR>
endfunction

"---------------------------------------------------
" close
"---------------------------------------------------
function! buffer#close(arg) abort
	let bt = &buftype
	let nr = bufnr('%')

	if bt ==# '' && a:arg == 0
		return

	elseif bt ==# 'quickfix'
		" カレントバッファがQuickfixの場合
		cclose
		return

	elseif (bt ==# 'nofile' || bt !=# '') && !buflisted(nr)
		" 特別なバッファタイプ(バッファ名はあるがファイルとして存在しない)の場合
		bdelete
		return

	else
		if &modified
			call s:warning('Discard the changes ? [y/n] ')
			let key = nr2char(getchar())
			redraw
			echo ""
			if key !=# 'y'
				return
			endif
		endif

		" カレントバッファ以外の通常バッファを取得
		let buflist = winbuf#normal_buffers()
		call filter(buflist, 'v:val != nr')

		" バッファ削除前に他のバッファに移動しておく。移動できるバッファが無い場合は空バッファを作成する
		if len(buflist)
			execute 'buffer' . buflist[0]
		else
			new
		endif

		execute 'bdelete! ' . nr
	endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
