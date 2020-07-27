# vim-REPL

> a minimal REPL with vim

## Features

+ Basic REPL(one line send or  block send)
+ Open or close a window with interactive program running in it automatically
+ Load current file (only support common lisp,scheme,racket)
+ Send current functions (only support lisp,scheme,racket,javascript,php)

## Install
+ Direct way

```sh
curl -fLo ~/.vim/autoload/REPL.vim --create-dirs \  
https://raw.githubusercontent.com/E-liza-bet/vim-REPL/master/autoload/REPL.vim
```

+ Or use plugin manager,"vim-plug" for example

`Plug 'E-liza-bet/vim-REPL'`

## Configure
`REPL#Gen(<interactive program>,[leader key])`

"interactive program": programs like 'irb' for ruby,'python' for python,'php -a'for php,'node' for javascript etc. 

"leader key": optional,default is key 'Alt'
###  Examples

+ Quick usage with default hotkeys

```vim 
"In ~/.vim/ftplugin/python.vim
call REPL#Gen('python') "Send one line or block
``` 

+ You can give a leader key in vimscript format

```vim 
"In ~/.vimrc
autocmd BufNewFile,BufRead *.php call REPL#Gen('php -a','<c-c>')
```

+ For lisp,load current file  

```vim 
"In ~/.vim/ftplugin/lisp.vim
let b:REPLSend=REPL#Gen('rlwrap sbcl')[0] "In this way,get the internal hooks
nnoremap <buffer> <leader>c :call b:REPLSend("lispload")<cr> "load the current file
```

+ Load current function(only support common lisp,scheme,racket,javascript,php)

```vim
nnoremap <buffer> <leader>f :call b:REPLSend("function")<cr> "send the current function(or called procedure)
```

## Detail

```vim
:help vim-REPL
```
