" =============================================================================
" Filename: autoload/gbr.vim
" Version: 0.0
" Author: takahiro jinno
" License: MIT License
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! gbr#list()
  let s:branch_list = split(system('git branch'), "\n")
  let s:count = len(s:branch_list)
  exec 'silent noautocmd ' . s:count . 'new'
  call setline(1, s:branch_list)
  setlocal nomodifiable
  nnoremap <silent> <buffer> <CR> :<C-u>call gbr#checkout()<CR>
  nnoremap <silent> <buffer> q :<C-u>bdelete!<CR>
endfunction

function! gbr#checkout()
  let s:branch_name = substitute(getline("."), '\s', '', 'g')
  if s:branch_name =~? "*"
    echomsg "you already switched."
    return
  endif
  let s:result = system('git checkout ' . s:branch_name)
  for mes in split(s:result, "\n")
    echomsg mes
  endfor
  exec ":bd!"
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
