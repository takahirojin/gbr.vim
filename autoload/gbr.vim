" =============================================================================
" Filename: autoload/gbr.vim
" Version: 0.0
" Author: takahiro jinno
" License: MIT License
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! gbr#gbr()
  let s:height = g:gbr_buf_max_height
  let s:branch_list = split(system('git branch'), "\n")
  if g:gbr_current_branch_top
    let s:branch_list = gbr#current_branch_top(s:branch_list)
  endif

  let s:count = len(s:branch_list)
  if s:count < s:height
    let s:height = s:count
  endif
  exec 'silent noautocmd ' . s:height . 'new'
  call setline(1, s:branch_list)
  setlocal nomodifiable
  syntax match Title /^\*\s.*$/
  call s:gbr_default_key_mappings()
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

function! gbr#delete()
  let s:branch_name = substitute(getline("."), '\s', '', 'g')
  if s:branch_name =~? "*"
    echomsg "switch another branch, before delete the branch."
    return
  endif
  if input("are you sure, delete " . s:branch_name . " [y/n] : ") != 'y'
    return
  endif
  redraw
  let s:result = system('git branch -d ' . s:branch_name)
  for mes in split(s:result, "\n")
    echomsg mes
  endfor
  exec ":bd!"
endfunction

function! gbr#current_branch_top(branch_list)
  let s:list = []
  for branch in a:branch_list
    if branch =~# "*"
      let s:current = branch
    else
      call add(s:list, branch)
    endif
  endfor
  call insert(s:list, s:current, 0)
  return s:list
endfunction

function! s:gbr_default_key_mappings()
  if g:gbr_no_default_key_mappings
    return
  endif
  augroup gbr
    nmap <silent> <buffer> <CR> <Plug>(gbr_checkout)
    nmap <silent> <buffer> d <Plug>(gbr_delete)
    nnoremap <silent> <buffer> q :<C-u>bdelete!<CR>
  augroup END
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
