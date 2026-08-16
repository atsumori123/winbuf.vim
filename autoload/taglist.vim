"===============================================================
" Original Work:
" Copylight (c) Yegappan Lakshmanan (yegappan AT yahoo DOT com)
" Source: https://github.com/vim-scripts/taglist.vim
"===============================================================
if exists('g:winbuf_taglist_enable') && g:winbuf_taglist_enable
let s:cpo_save = &cpo
set cpo&vim

" if !exists('loaded_taglist')
"	  if !exists('*system')
"		  echomsg 'Taglist: Vim system() built-in function is not available. ' .
"					  \ 'Plugin is not loaded.'
"		  let loaded_taglist = 'no'
"		  let &cpo = s:cpo_save
"		  finish
"	  endif

"	  " When the taglist buffer is created when loading a Vim session file,
"	  " the taglist buffer needs to be initialized. The BufFilePost event
"	  " is used to handle this case.
"	  autocmd BufFilePost __Tag_List__ call s:Tlist_Vim_Session_Load()
" endif

let s:current_filename = ""
let s:TagList = []

"-------------------------------------------------------
" get_file_hash
"-------------------------------------------------------
function! s:get_file_hash(filename)
	return "_".sha256(a:filename)
endfunction

"-------------------------------------------------------
" is_registered
"-------------------------------------------------------
function! s:is_registered(file_hash)
	return index(s:TagList, a:file_hash) != -1 ? 1 : 0
endfunction

"-------------------------------------------------------
" register_taglist
"-------------------------------------------------------
function! s:register_taglist(file_hash)
	call add(s:TagList, a:file_hash)
endfunction

"-------------------------------------------------------
" unregister_taglist
"-------------------------------------------------------
function! s:unregister_taglist(file_hash)
	let i = index(s:TagList, a:file_hash)
	if i == -1 | return | endif
	call remove(s:TagList, i)
	unlet s:{a:file_hash}
endfunction

"-------------------------------------------------------
" unregister_all_taglist
"-------------------------------------------------------
function! s:unregister_all_taglist()
	for v in s:TagList
		call s:unregister_taglist(v)
	endfor
endfunction

"-------------------------------------------------------
" dump_taglist
"-------------------------------------------------------
function! s:dump_taglist()
	let vars = execute('echo s:')
	let vars = substitute(vars, '[{}\n]', "", 'g')
	echom vars
endfunction

"-------------------------------------------------------
" warning_msg
"-------------------------------------------------------
function! s:warning_msg(msg)
	echohl WarningMsg | echomsg a:msg | echohl None
endfunction

"-------------------------------------------------------
" exe_cmd_no_acmds
"-------------------------------------------------------
function! s:exe_cmd_no_acmds(cmd)
	let old_eventignore = &eventignore
	set eventignore=all
	exe a:cmd
	let &eventignore = old_eventignore
endfunction

"-------------------------------------------------------
" is_skip_file
"-------------------------------------------------------
function! s:is_skip_file(filename, ftype)
	" 以下に該当するファイルはスキップ対象
	" - ファイル名なし
	" - ファイルタイプなし
	" - ReadOnly
	return (a:filename == '' || a:ftype == '' || !filereadable(a:filename)) ? 1 : 0
endfunction

"-------------------------------------------------------
" run_background_job
"-------------------------------------------------------
function! s:run_background_job(cmd) abort
	let exit = []
	let lines = []
	let jopts = {
		\ 'out_cb': { j, str -> add(lines, str) },
		\ 'err_cb': { j, str -> add(lines, str) },
		\ 'exit_cb': { j, code -> add(exit, code) }}
	let job = job_start(a:cmd, jopts)
	call ch_close_in(job)
	while ch_status(job) !~# '^closed$\|^fail$' || job_status(job) ==# 'run'
		sleep 1m
	endwhile

	return [lines, exit[0]]
endfunction

"---------------------------------------------------------------
" skip_cursor
"---------------------------------------------------------------
function! s:skip_cursor(direction) abort
	let n = line(".") + a:direction
	let len = line('$')
	for i in range(1, len)
		if n > len | let n = 1 | endif
		if n < 1 | let n = len | endif
		if getline(n) =~ '^[0-9a-zA-Z]'
			call cursor([n, 1, 0, 1])
			break
		endif
		let n += a:direction
	endfor
endfunction

"---------------------------------------------------------------
" bg_cmd
"---------------------------------------------------------------
function! s:bg_cmd(command)
	let result = s:run_background_job(a:command)
	return result[1] == 0 ? result[0]: []
endfunction

"-------------------------------------------------------
" get_ftype_option
"-------------------------------------------------------
function! s:get_ftype_option(ftype)
	let opt = ""

	" assembly	(d:define, l:label, m:macro, t:type)
	if	   a:ftype == 'asm'		| let opt = '--asm-types=dlmt'

	" C"		(d:macro, g:enum, s:struct, u:union, t:typedef, v:variable, f:function)
	elseif a:ftype == 'c'		| let opt = '--c-types=dgsutvf'

	" c++		(n:namespace, v:variable, d:macro, t:typedef, c:class, g:enum, s:struct, u:union, f:function)
	elseif a:ftype == 'cpp'		| let opt = '--c++-types=nvdtcgsuf'

	" c#		(d:macro, t:typedef, n:namespace, c:class, E:event, g:enum, s:struct, i:interface, p:propert, m:method
	elseif a:ftype == 'cs'		| let opt = '--c#-types=dtfcEgsipm'

	" HTML		(a:anchor, f:javascript function)
	elseif a:ftype == 'html'	| let opt = '--html-types=af'

	" java		(p:package, c:class, i:interface, f:field, m:method)
	elseif a:ftype == 'java'	| let opt = '--java-types=pcifm'

	" javascript (f:function)
	elseif a:ftype == 'javascript' | let opt = '--javascript-types=f'

	" lua		(f:function)
	elseif a:ftype == 'lua'		| let opt = '--lua-types=f'

	" makefiles	(m:macro)
	elseif a:ftype == 'make'	| let opt = '--make-types=m'

	" pasca		(f:function, p:procedure)
	elseif a:ftype == 'pascal'	| let opt = '--pascal-types=fp'

	" perl		(c:constant, l:label, p:package, s:subroutine)
	elseif a:ftype == 'perl'	| let opt = '--perl-types=clps'

	" php		(c:class, d:constant, v:variable, f:function)
	elseif a:ftype == 'php'		| let opt = '--php-types=cdvf'

	" python	(c:class, m:member, f:function)
	elseif a:ftype == 'python'	| let opt = '--python-types=cmf'

	" ruby		(c:class, f:method, F:function, m:singleton method)
	elseif a:ftype == 'ruby'	| let opt = '--ruby-types=cfFm:'

	" shell		(f:function)
	elseif a:ftype == 'sh'		| let opt = '--sh-types=f'

	" C shell	(f:function)
	elseif a:ftype == 'csh'		| let opt = '--sh-types=f'

	" sml		(e:exception, c:functor, s:signature, r:structure, t:type, v:value, f:function)
	elseif a:ftype == 'sml'		| let opt = '--sml-types=ecsrtvf'

	" sql		(c:cursor, F:field, P:package, r:record, s:subtype, t:table, T:trigger, v:variable, f:function, p:procedure)
	elseif a:ftype == 'sql'		| let opt = '--sql-types=cFPrstTvfp'

	" vim		(a:autocmds, v:variable, f:function)
	elseif a:ftype == 'vim'		| let opt = '--vim-types=avf'

	endif

	return opt
endfunction

"-------------------------------------------------------
" extract_tagtype
"-------------------------------------------------------
function! s:extract_tagtype(tag_line)
	let start	= strridx(a:tag_line, '/;"' . "\t") + 4
	let end		= strridx(a:tag_line, 'line:') - 1
	return strpart(a:tag_line, start, end - start)
endfunction

"-------------------------------------------------------
" extract_linenumber
"-------------------------------------------------------
function! s:extract_linenumber(tag_line)
	let start = strridx(a:tag_line, "\t" . "line:") + 6
	return start == -1 ? -1 : matchstr(a:tag_line, '^.\{' . start . '\}\zs\d\+')
endfunction

"---------------------------------------------------------------
" exe_ctags
"---------------------------------------------------------------
function! s:exe_ctags(filename, ftype, file_hash)
	" ファイルタイプ毎のctagsオプションを取得
	let ctags_args = s:get_ftype_option(a:ftype)

	" 未サポートのファイルタイプの場合は終了
	if ctags_args == ""
		return 0
	endif

	let cmd = ['ctags', '-f', '-', '--excmd=pattern', '--fields=nKs', '--sort=no']

	" ファイルタイプを指定
	call add(cmd, '--language-force=' . a:ftype)

	" ファイルタイプ固有の引数を指定
	call add(cmd, ctags_args)

	" 対象ファイルを指定
	call add(cmd, a:filename)

	" ctags
	let cmd_output = s:bg_cmd(cmd)

	let tags = "s:" . a:file_hash
	let {tags} = {}
	for tag in cmd_output
		let ttype = s:extract_tagtype(tag)
		let lnum  = s:extract_linenumber(tag)
		let name  = strpart(tag, 0, stridx(tag, "\t"))
		if !has_key({tags}, ttype)
			let {tags}[ttype] = ["[" . lnum . "] " . name]
		else
			call add({tags}[ttype], "[" . lnum . "] " . name)
		endif
	endfor

	" 登録
	call s:register_taglist(a:file_hash)

	return 1
endfunction

"-------------------------------------------------------
" close_cleanup
"-------------------------------------------------------
function! s:close_cleanup(close)
	" Remove the taglist autocommands
	silent! autocmd! TagListAutoCmds

	" Clear all the highlights
	match none
	silent! syntax clear TagListTitle
	silent! syntax clear TagListComment
	silent! syntax clear TagListTagScope

	call s:unregister_all_taglist()

	if a:close
		exe 'close'
	endif
endfunction

"-------------------------------------------------------
" remove_buffer
"-------------------------------------------------------
function! s:remove_buffer(filename)
	if a:filename == ''
		return
	endif

	" 登録解除
	call s:unregister_taglist(s:get_file_hash(a:filename))
endfunction

"-------------------------------------------------------
" init_window
"-------------------------------------------------------
function! s:init_window()
	setlocal noreadonly
	setlocal filetype=taglist

	" ハイライト設定
	syntax match TagListLnum '\[.*\]'
	syntax match TagListTitle '^[^\ \->].*'
	syntax match TagListTagScope  '\s\[.\{-\}\]$'

	" ハイライトの設定
	highlight default link TagListTagName Search
	highlight default link TagListLnum Comment
	highlight default link TagListTitle String
	highlight default link TagListTagScope Identifier

	silent! setlocal buftype=nofile
	silent! setlocal bufhidden=delete
	silent! setlocal noswapfile
	silent! setlocal nobuflisted
	silent! setlocal nowrap
	silent! setlocal nonumber
	silent! setlocal winfixheight winfixwidth

	" Create buffer local mappings for jumping to the tags and sorting the list
	nnoremap <buffer> <silent> <CR> :call <SID>jump_to_tag()<CR>
	nnoremap <buffer> <silent> <2-LeftMouse> :call <SID>jump_to_tag()<CR>
	nnoremap <buffer> <silent> q :call <SID>close_cleanup(1)<CR>
	nnoremap <buffer> <silent> <c-k> :call <SID>skip_cursor(-1)<CR>
	nnoremap <buffer> <silent> <c-j> :call <SID>skip_cursor(1)<CR>
	nnoremap <buffer> <silent> d :call <SID>dump_taglist()<CR>

	" Define the taglist autocommands
	augroup TagListAutoCmds
		autocmd!
		" 無操作状態が続いたときに発火-->カレントタグをハイライト
		autocmd CursorHold * silent call s:highlight_tag(fnamemodify(bufname('%'), ':p'), line('.'), 0, 1)

		" taglistウィンドウをアンロードしたときに発火-->taglistのクリーンアップ
		autocmd BufUnload __Tag_List__ call s:close_cleanup(0)

		" バッファに入ったときに発火-->taglistウィンドウをリフレッシュ
		autocmd BufEnter * call timer_start(0, {-> execute('call s:refresh_bufenter(0)')})

		" バッファを削除したときに発火-->キャッシュを削除
		autocmd BufDelete * call s:remove_buffer(expand('<afile>:p'))

		autocmd BufWritePost * call s:refresh_bufenter(1)
	augroup end
endfunction

"-------------------------------------------------------
" load_taglist
"-------------------------------------------------------
function! s:load_taglist(filename, ftype)
	" ファイルパスをハッシュ値に変換
	let file_hash = s:get_file_hash(a:filename)

	" キャッシュの有無をチェック
	if !s:is_registered(file_hash)
		" キャッシュが無い場合はctagsを実行
		if s:exe_ctags(a:filename, a:ftype, file_hash) == 0
			return
		endif
	endif

	" 表示形式に変換
	let output = []
	for key in keys(s:{file_hash})
		let output += [key] + map(copy(s:{file_hash}[key]), '"  " . v:val') + [""]
	endfor

	" バッファの内容を消去してから表示
	setlocal modifiable
	silent! %delete _
	call setline(1, output)
	setlocal nomodifiable

	" taglistのカレントファイルを更新
	let s:current_filename = a:filename
endfunction

"-------------------------------------------------------
" refresh_bufenter
"-------------------------------------------------------
function! s:refresh_bufenter(reload)
	" ファイル名、ファイルタイプの取得
	let filename	= fnamemodify(bufname('%'), ':p')
	let ftype		= getbufvar('%', '&filetype')
	let tlist_win	= bufwinnr("__Tag_List__")
	let cur_lnum	= line('.')

	" 以下に該当する場合はスキップ
	" 特殊バッファの場合
	" リスト対象外のファイルの場合
	" TagListウィンドウが未オープンの場合
	if &buftype != '' || s:is_skip_file(filename, ftype) || tlist_win == -1
		return
	endif

	if a:reload
		call s:unregister_taglist(s:get_file_hash(filename))
	else
		if s:current_filename == filename
			return
		endif
	endif

	" Update the taglist window
	" Disable screen updates
	let old_lazyredraw = &lazyredraw
	set nolazyredraw

	" Save the current window number
	let save_winnr = winnr()

	" TagListウィンドウにジャンプ
	let winnum = bufwinnr("__Tag_List__")
	if winnum != -1 && winnr() != winnum
		call s:exe_cmd_no_acmds(winnum . 'wincmd w')
	endif

	" Update the taglist window
	call s:load_taglist(filename, ftype)

	" カレントタグをハイライトする
	call s:highlight_tag(filename, cur_lnum, 0, 0)

	" Jump back to the original window
	if save_winnr != winnr()
		call s:exe_cmd_no_acmds(save_winnr . 'wincmd w')
	endif

	" Restore screen updates
	let &lazyredraw = old_lazyredraw
endfunction

"-------------------------------------------------------
" highlight_current_line_tag
"-------------------------------------------------------
function! s:highlight_current_line_tag()
	" Clear previously selected name
	match none

	" Highlight the current line
	let pat = '/\%' . line('.') . 'l\s\+\zs.*/'

	exe 'match TagListTagName ' . pat
endfunction

"-------------------------------------------------------
" highlight_tag
"-------------------------------------------------------
function! s:highlight_tag(filename, cur_lnum, center, autocmd)
	" taglistのウィンドウ番号を取得
	let winnum = bufwinnr("__Tag_List__")
	if winnum == -1
		call s:warning_msg('Error: Taglist window is not open')
		return
	endif

	" 現在のウィンドウ番号を退避
	let org_winnr = winnr()

	" フォーカスがtaglistウィンドウにある場合はスキップ
	if a:autocmd && (winnum == org_winnr)
		return
	endif

	" taglistのウィンドウにスイッチ
	if org_winnr != winnum
		exe winnum . 'wincmd w'
	endif

	" {タグの行番号:バッファ内でのタグの位置}の辞書を作成
	let lnum_dic = {}
	for i in range(1, line('$'))
		let line = getline(i)

		" [nnn] tag name 形式の行以外はスキップ
		if line !~ '^\v\s+\[.*' | continue | endif
		
		" [ ] の中にある数字だけを抽出する
		let lnum = matchstr(line, '\[\zs\d\+\ze\]')

		" 辞書に追加
		let lnum_dic[lnum] = i
	endfor

	" キー(行番号)を取り出して昇順にソートする
	let sorted_keys = sort(keys(lnum_dic), 'N')

	" 現在のハイライトをクリア
	match none

	" カーソル位置と一番近いタグを探す
	let lnum = -1
	if a:cur_lnum < sorted_keys[0]
		return
	elseif a:cur_lnum > sorted_keys[-1]
		let lnum = lnum_dic[sorted_keys[-1]]
	else
		let old_v = 1
		for v in sorted_keys
			let diff = a:cur_lnum - v
			if diff <= 0
				let lnum = lnum_dic[!diff ? v : old_v]
				break
			endif
			let old_v = v
		endfor
	endif

	exe lnum

	if a:center
		normal! z.
	endif

	" Highlight the tag name
	call s:highlight_current_line_tag()

	" Go back to the original window
	if org_winnr != winnum
		exe org_winnr . 'wincmd w'
	endif
endfunction

"-------------------------------------------------------
" jump_to_tag
"-------------------------------------------------------
function! s:jump_to_tag()
	let line = getline('.')

	" 空白行の場合は終了
	if line =~ '^\s*$'
		return
	endif

	" [ ] の中にある数字だけを抽出する
	let lnum = matchstr(line, '\[\zs\d\+\ze\]')

	" 選択したタグをハイライト
	call s:highlight_current_line_tag()

	" ターゲットファイルを表示しているウィンドウ番号を取得
	let winnum = bufwinnr(s:current_filename)
	if winnum != -1
		" ウィンドウにスイッチ
		exe winnum . 'wincmd w'
		call cursor(lnum, 1)
		normal! z.

	elseif buflisted(s:current_filename)
		" バッファがhidden状態の場合は通常バッファを表示しているウィンドウ探す
		let normal_wins = -1
		for w in range(1, winnr('$'))
			if getwinvar(w, '&buftype') ==# ''
				" 通常バッファを表示しているウィンドウにスイッチ
				exe w . 'wincmd w'
				exe "buffer" . bufnr(s:current_filename) 
				call cursor(lnum, 1)
				normal! z.
				break
			endif
		endfor
	endif
endfunction

" Tlist_Vim_Session_Load
" Initialize the taglist window/buffer, which is created when loading
" a Vim session file.
function! s:Tlist_Vim_Session_Load()
	" Initialize the taglist window
	call s:init_window()

	" Refresh the taglist window
	setlocal modifiable
	silent! %delete _
	setlocal nomodifiable
endfunction

"-------------------------------------------------------
" Tlist_Window_Open
"-------------------------------------------------------
function! taglist#open()
	" ファイル名、ファイルタイプ、行番号の取得
	let filename	= fnamemodify(bufname('%'), ':p')
	let ftype		= getbufvar('%', '&filetype')
	let lnum		= line('.')

	" taglistのウィンドウ番号を取得
	let winnum = bufwinnr("__Tag_List__")
	if winnum != -1
		" 既にウィンドウがある場合はそのウィンドウにスイッチ
		if winnr() != winnum
			exe winnum . 'wincmd w'
		endif
	else
		" ウィンドウが無い場合は作成
		exe 'silent! botright vertical 30 split __Tag_List__'
		exe 'silent vertical resize 30'
		call s:init_window()
	endif

	" 対象外のファイルの場合はスキップ
	if s:is_skip_file(filename, ftype)
		return
	endif

	" タグの表示
	call s:load_taglist(filename, ftype)

	" カレントタグをハイライトする
	call s:highlight_tag(filename, lnum, 1, 0)
endfunction

" restore 'cpo'
let &cpo = s:cpo_save
unlet s:cpo_save
endif

