" echo license && curl http://www.gnu.org/licenses/gpl-3.0.txt 
function! s:findByLinesUp(str,from)
	let row = a:from
	let pos = -1
	while row>0 && match(getline(row),a:str) == -1
		let row = row -1
	endwhile
	if row>0
		let pos=match(getline(row),a:str)
	endif
	return [row,pos]
endfunc
function! s:findByLinesDown(str,from)
	let row = a:from
	let pos = -1
	while getline(row)!="" && match(getline(row),a:str) == -1
		let row = row + 1
	endwhile
	if getline(row)!=""
		let pos=match(getline(row),a:str)
	endif
	return [row,pos]
endfunc
function! s:countPairs(row,pos,leftSymbol,rightSymbol,oneLine)
	let cleft=0
	let cright = 0
	let row = a:row
	let line = str2list(getline(a:row))[a:pos:]
	let text=''
	while line != []
		for ch in line
			let text .= nr2char(ch)
			if ch == char2nr(a:leftSymbol)
				let cleft += 1
			elseif ch == char2nr(a:rightSymbol)
				let cright += 1
				if cleft == cright
					return text
				endif
			endif
		endfor
		if !a:oneLine
			let text .= "\r"
		endif
		let row += 1
		let line = str2list(getline(row))
	endwhile
	return '' "not match
endfunc
function! s:selectFromTo(row,pos,row2,pos2)
	let lines= getline(a:row,a:row2)
	let lines[0] = (lines[0])[a:pos:]
	let lines[-1] = (lines[-1])[:a:pos2-1]
	let text = ''
	for line in lines
		let text .= line
	endfor
	return text
endfunc
function! REPL#Gen(sh,...)
	if a:0 < 1
		let leader = ''
	else
		let leader = a:1
	endif
	let sh=copy(a:sh)
	let name = expand('%').".term"
	let winid = 0
	let options={'term_name':name,'term_rows':float2nr(&lines*0.3)}
	function! REPL_(mode) closure
		let status = term_getstatus(name)
		if status == ''
			belowright call term_start(sh,options)
			let winid = win_getid()
			wincmd p
		endif
		if a:mode == 'line'
			let text=substitute(getline('.'),"\t","    ","g")
			if status == 'normal'
				call term_sendkeys(name,'Ga')
			endif
			call term_sendkeys(name,text."\<cr>")
			call cursor(line('.')+1,col('.'))
		elseif a:mode == 'cr'
			call term_sendkeys(name,"\<cr>")
		elseif a:mode == 'loadfile'
			if sh == 'ipython'
				call term_sendkeys(name,'%load "'.expand('%').'"'.""."\<cr>")
			elseif sh == 'ghci'
				call term_sendkeys(name,':l '.expand('%')."\<cr>")
			elseif sh == 'irb'
				call term_sendkeys(name,'load "'.expand('%').'"'.""."\<cr>")
			else
				call term_sendkeys(name,'(load "'.expand('%').'")'."\<cr>")
			endif
		elseif a:mode == 'function'
			function! s:replfunc(searchEngin,start,end,funcIdentifer,oneLine) closure
				let [row,pos] = s:findByLinesUp(a:funcIdentifer,line('.'))
				if row>0
					let [row2,pos2] = a:searchEngin(a:start,row)
					if row<=row2 && pos<pos2
						let text = s:selectFromTo(row,pos,row2,pos2)[:-2]
					else
						let text = ''
					endif
					if pos>-1
						let text .= s:countPairs(row2,pos2,a:start,a:end,a:oneLine)
						if text != ''
							let text=substitute(text,"\t"," ","g")
							call term_sendkeys(name,text."\<cr>")
						else
							echo "not match"
						endif
					endif
				endif
			endfunc
			if &ft == "racket" || &ft == "scheme"
				if sh=="petite" || sh == 'scheme'
					call s:replfunc(funcref("s:findByLinesUp"),'(',')',"define",1)
				else
					call s:replfunc(funcref("s:findByLinesUp"),'(',')',"define",0)
				endif
			elseif &ft == "lisp"
				call s:replfunc(funcref("s:findByLinesUp"),'(',')',"defun",0)
			elseif &ft == "javascript" || &ft == "php" || &ft == "typescript"
				call s:replfunc(funcref("s:findByLinesDown"),'{','}',"function",0)
			endif
		elseif a:mode == 'visual'
			let text=substitute(getreg('"'),"\t","    ","g")
			if sh == 'petite' || sh == 'scheme' "fix
				let text=substitute(text,"\n","","g")
			endif
			call term_sendkeys(name,text)
		endif
	endfunc
	function! REPLeave_(mode) closure
		if term_getstatus(name) != ''
			call term_sendkeys(name,"\<cr>\<c-d>")
			let w=win_id2win(winid)
			call term_wait(name,100)
			exec w."wincmd q"
			if a:mode == 'quit'
				wincmd q
			endif
		endif
	endfunc
	function! REPLChange_(name) closure
		let sh=a:name
	endfunc
	let b:REPL=funcref('REPL_')
	let b:REPLeave=funcref('REPLeave_')
	let b:REPLChange=funcref('REPLChange_')
	exec 'nnoremap <buffer> '.leader.'e :call b:REPL("line")<cr>'
	exec 'nnoremap <buffer> '.leader.'b :call b:REPL("cr")<cr>'
	exec 'nnoremap <buffer> '.leader.'q :call b:REPLeave("")<cr>'
	exec 'vnoremap <buffer> '.leader.'e y:call b:REPL("visual")<cr>'
	autocmd  BufUnload <buffer> call b:REPLeave('quit')
	command! -nargs=1 REPLChange :call b:REPLChange(<args>)
	return [b:REPL,b:REPLeave,b:REPLChange]
endfunc
