"===============================================================
" Original Work:
" Copylight (c) Kim Silkebækken, haya14busa
" Source: https://github.com/easymotion/vim-easymotion
"===============================================================
if exists('g:winbuf_easymotion_enable') && g:winbuf_easymotion_enable

let s:save_cpo = &cpo
set cpo&vim

let s:loaded = 0
"-------------------------------------------------------
" 初期化処理
"-------------------------------------------------------
function! s:init()
	if s:loaded | return | endif
	let s:loaded = 1

	highlight default link EasyMotionShade Comment
  	highlight EasyMotionTarget ctermfg=150 guifg=cyan
	highlight EasyMotionTarget2First ctermfg=216 guifg=#e2a478
endfunction

"-------------------------------------------------------
" ハイライト追加
"-------------------------------------------------------
function! s:add_highlight(group, re, priority) abort
	call matchadd(a:group, a:re, a:priority)
endfunction

function! s:add_highlight_pos(group, lnum, cnum, priority) abort
	call matchaddpos(a:group, [[a:lnum, a:cnum]], a:priority)
endfunction

"-------------------------------------------------------
" ハイライト消去
"-------------------------------------------------------
function! s:delete_highlight(...) abort
	if a:0 == 1
		call map(filter(getmatches(), {_, val -> index(a:1, val.group) >= 0}), {_, val -> matchdelete(val.id)})
	else
		call map(filter(getmatches(), {_, val -> stridx(val.group, "EasyMotion") != -1 }), {_, val -> matchdelete(val.id)})
	endif
endfunction

"-------------------------------------------------------
" 1文字入力
"-------------------------------------------------------
function! s:get_char() abort
	try
		let char = call('getchar', a:000)
	catch /^Vim:Interrupt$/
		let char = 3 " <C-c>
	endtry

	if char == 27 || char == 3
		" ESC or <C-c> key pressed
		redraw
		echo 'EasyMotion: Cancelled'
		return ''
	endif

	return type(char) == v:t_number ? nr2char(char) : char
endfunction

"-------------------------------------------------------
" bufvar設定
"-------------------------------------------------------
function! s:set_bufvar()
	let vartbl = {
				\ '&modified'		: 0,
				\ '&modifiable'		: 1,
				\ '&readonly'		: 0,
				\ '&spell'			: 0,
				\ }

    if ! exists('s:var_reset')
        let s:var_reset = {}
    endif

	for [var, v] in items(vartbl)
		" Store original value
		let s:var_reset[var] = getbufvar("", var)
		" Set new var value
		call setbufvar('%', var, v)
	endfor
endfunction

"-------------------------------------------------------
" bufvar復元
"-------------------------------------------------------
function! s:restore_bufvar()
    if ! exists('s:var_reset')
		return
    endif

	for [var, v] in items(s:var_reset)
		"echom var.".".v
		call setbufvar('%', var, v)
	endfor

	unlet s:var_reset
endfunction

"-------------------------------------------------------
" Set lines
"-------------------------------------------------------
function! s:set_lines(lines, key)
	for [lnum, line] in a:lines
		keepjumps call setline(lnum, line[a:key])
	endfor
endfunction

"-------------------------------------------------------
" grouping_algorithm
"-------------------------------------------------------
function! s:grouping_algorithm(targets, keys)
	let keys_len	= len(a:keys)
	let targets_len = len(a:targets)
	let groups		= {}

	" キー数分割り付ける
	let cnt = 0
	while cnt < targets_len && cnt < keys_len
		let groups[a:keys[cnt]] = a:targets[cnt] 
		let cnt += 1
	endwhile

	" ターゲットが使えるキー数以上ある場合は、子ノードで登録する
	let keys = a:keys
	while cnt < targets_len
		let key  = keys[-1:]
		let keys = keys[:-2]
		let j	 = 1
		let inner_dict = {a:keys[0] : groups[key[0]]}
		while cnt < targets_len && j < len(a:keys)
			let inner_dict[a:keys[j]] = a:targets[cnt]
			let j += 1
			let cnt += 1
		endwhile
		let groups[key[0]] = inner_dict
	endwhile
	return groups
endfunction

"-------------------------------------------------------
" マーカーの座標と辞書を作成
"-------------------------------------------------------
function! s:create_coord_key_dict(groups)
	let sort_list = []
	let coord_keys = {}

	for [key, item] in items(a:groups)
		if type(item) == v:t_list
			" Destination coords
			let dict_key = printf('%05d,%05d', item[0], item[1])
			let coord_keys[dict_key] = key
			call add(sort_list, dict_key)
		else
			" Item is a dict (has children)
			for [child_key, child_item] in items(item)
				let dict_key = printf('%05d,%05d', child_item[0], child_item[1])
				let coord_keys[dict_key] = key . child_key
				call add(sort_list, dict_key)
			endfor
		endif
	endfor

	return [sort_list, coord_keys]
endfunction

"-------------------------------------------------------
" ターゲットの入力
"-------------------------------------------------------
function! s:prompt_user(groups)
	" ジャンプ先候補が1個だけの場合は、そこにダイレクトジャンプさせる
	let group_values = values(a:groups)
	if len(group_values) == 1
		redraw
		return group_values[0]
	endif

	" マーカーの座標と辞書を作成
	let [marker_coord, marker_dict] = s:create_coord_key_dict(a:groups)

	" ジャンプ先候補数分
	let lines = {}
	for dict_key in sort(marker_coord)
		" ジャンプ先の行番号とカラム
		let [lnum, cnum] = split(dict_key, ',')
		let lnum = str2nr(lnum)
		let cnum = str2nr(cnum)

		" オリジナルデータの退避
		if !has_key(lines, lnum)
			let current_line = getline(lnum)
			let lines[lnum] = {'orig':   current_line, 'marker': current_line}
		endif

		" マーカーの文字とその長さ
		let marker_chars = marker_dict[dict_key]
		let marker_chars_len = strlen(marker_chars)

		" Replace {target} with {marker} & Highlight
		let col_add = 0 " Column add byte length
		for i in range(marker_chars_len)
			let marker_char = marker_chars[i]

			" 行末尾を2文字のマーカーに置き換える場合、1文字分拡張しておく、
			if strlen(lines[lnum]['marker']) < cnum + col_add
				let lines[lnum]['marker'] .= ' '
			endif

			" 指定した列番号にある1文字の正規表現
			let target_col_regexp = '\%' . (cnum + col_add) . 'c.'
			" 正規表現で指定した位置の文字を取得
			let target_char = matchstr(lines[lnum]['marker'], target_col_regexp)
			" マーカー文字の表示幅が元の文字と揃うように調整する
			" 'abcあいう'の'c'をマーカーの'fj'に置き換えるとき、後続の'いう’の表示がずれないようにするため
			let space_len = strdisplaywidth(target_char) - strdisplaywidth(marker_char)
			let replace_pattern = marker_char . repeat(' ', space_len)

			" マーカーに置換
			let lines[lnum]['marker'] = substitute(lines[lnum]['marker'], target_col_regexp, replace_pattern, '')

			" ハイライト
			let hl_group = (marker_chars_len == 1) ? "EasyMotionTarget" : "EasyMotionTarget2First"
			call s:add_highlight_pos(hl_group, lnum, cnum + col_add, 100)

			" Shift column
			let col_add += strlen(marker_char)
		endfor
	endfor

	let lines_items = items(lines)
	try
		" マーカー付きのバッファテキストに変更
		call s:set_lines(lines_items, 'marker')
		redraw

		" ターゲット文字の入力
		echohl Question | echo 'Target key: ' | echohl None
		let char = s:get_char()

	finally
		" バッファテキストを復元
		call s:set_lines(lines_items, 'orig')

		" マーカーのハイライト消去
		call s:delete_highlight(["EasyMotionTarget", "EasyMotionTarget2First"])
		redraw
	endtry

	" 入力文字チェック
	if empty(char)					" 入力なし
		throw 'EasyMotion: Cancelled'
	elseif !has_key(a:groups, char)	" 無効なキー入力
		throw 'EasyMotion: Invalid target'
	endif

	" 子ノードがある場合は2文字目を入力して、ターゲットを確定して復帰する
	let target = a:groups[char]
	return type(target) == v:t_list ? target : s:prompt_user(target)
endfunction

"-------------------------------------------------------
" EasyMotion
"-------------------------------------------------------
function! s:EasyMotion(char)
	let cursor_position = [line('.'), col('.')]		" current cursor position
	let win_first_lnum	= line('w0')				" visible first line num
	let win_last_lnum	= line('w$')				" visible last line num

	try
		" 現在のバッファコンフィグを退避して、EasyMotion用に設定
		call s:set_bufvar()

		" 下方向に検索
		let targetsF = []
		let pos = searchpos(a:char, '', win_last_lnum)
		while pos != [0, 0] 
			call add(targetsF, pos)
			let pos = searchpos(a:char, '', win_last_lnum)
		endwhile

		" カーソルを元の位置に戻す
		keepjumps call cursor(cursor_position)

		" 上方向に検索
		let targetsB = []
		let pos = searchpos(a:char, 'b', win_first_lnum)
		while pos != [0, 0] 
			call add(targetsB, pos)
			let pos = searchpos(a:char, 'b', win_first_lnum)
		endwhile

		" カーソル位置を中心に検索結果をマージする
		let targets = []
		while len(targetsF) || len(targetsB)
			if len(targetsF)
				call add(targets, remove(targetsF, 0))
			endif
			if len(targetsB)
				call add(targets, remove(targetsB, 0))
			endif
		endwhile

		if empty(targets)
			" ジャンプ先候補が無い場合は終了
			throw 'EasyMotion: No matches'
		elseif len(targets) != 1
			" ジャンプ先候補が複数ある場合はテキスト部全体をグレーでハイライト(priority=0)
			call s:add_highlight("EasyMotionShade", '\_.*', 0)
		endif

		" Attach specific key as marker to gathered matched coordinates
		let easymotion_keys = 'hklyuiopnm,qwertzxcvbasdgjf'
		let groups = s:grouping_algorithm(targets, split(easymotion_keys, '\zs'))

		" カーソルを元の位置に戻す
		keepjumps call cursor(cursor_position)

		" Prompt user for target group/character
		let coords = s:prompt_user(groups)

		" Jump to destination
		keepjumps call cursor(coords[0], coords[1])
		echo 'EasyMotion: Jumping to [' . coords[0] . ', ' . coords[1] . ']'

	catch /^EasyMotion:.*/
		redraw
		" 直近に補足された例外メッセージを表示
		echo v:exception

	catch
		" 直近に補足されてまだ終了していな例外メッセージを表示
		echo 'EasyMotion: v:exception : ' . v:throwpoint

	finally
		" バッファコンフィグの復元
		call s:set_bufvar()

		" 全ハイライトを無効化
		call s:delete_highlight()
	endtry
endfunction

"-------------------------------------------------------
" start
"-------------------------------------------------------
function! easymotion#start()
	call s:init()

	" ターゲットの入力
	echohl Question | echo 'Search for 1 character: ' | echohl None
	let char = s:get_char()

	" 検索文字が無しまたは空白の場合は終了
	if empty(char) || char ==# ' ' | return | endif

	" 大文字が指定された場合は、大文字と小文字を区別して検索する
	let re = (match(char, '\u') == -1 ? '\c' : '\C') . char
	call s:EasyMotion(re)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
endif
