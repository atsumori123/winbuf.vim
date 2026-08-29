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
	" バッファ一覧を取得し、不要な文字をクレンジング
	let ls = execute('ls')->split("\n")->map({ _, v -> v->substitute('"', '', 'g')->substitute(' 行 .*$', '', '') })

	" メニューリストの作成
	let list = map(ls, { _, s -> s->split()
		\ ->{ t -> len(t) != 4 ? insert(t, '', 2) : t }()
		\ ->{ t -> printf('%4s %s %3s %s   %-16s  (%s)', t[0], stridx(t[1], 'a') >= 0 ? '*' : ' ', t[1], t[2], fnamemodify(t[3], ':t'), t[3]) }()
		\ })

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

		" カレントバッファ以外で、ファイルとして存在、または新規ファイルのバッファリストを作成
		let buflist = map(getbufinfo({'buflisted': 1}), 'v:val.bufnr')
		call filter(buflist, 'v:val != nr && (filereadable(bufname(v:val)) || empty(getbufvar(v:val, "&buftype")))')

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
