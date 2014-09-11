" =============================================================================
" Filename: autoload/gbr.vim
" Version: 0.0
" Author: takahiro jinno
" License: MIT License
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let g:buf_name = '[gbr]'

function! gbr#gbr()
  let s:height = g:gbr_window_height
  let s:branch_list = split(system('git branch'), "\n")
  if g:gbr_current_branch_top
    let s:branch_list = gbr#current_branch_top(s:branch_list)
  endif

  let s:count = len(s:branch_list)
  if s:count < s:height
    let s:height = s:count
  endif
  exec 'silent noautocmd ' . s:height . 'new' . ' ' . g:buf_name
  call setline(1, s:branch_list)
  setlocal buftype=nofile bufhidden=hide noswapfile
  setlocal nomodified
  setlocal nomodifiable
  syntax match Title /^\*\s.*$/
  call s:gbr_default_key_mappings()
endfunction

function! gbr#checkout()
  let s:branch_name = gbr#get_target_branch()
  let s:result = system('git checkout ' . s:branch_name)
  exec ":bd!"
  call gbr#echomsg(s:result)
endfunction

function! gbr#delete(option) abort
  let s:branch_name = gbr#get_target_branch()
  if input("are you sure, delete " . a:option . ' ' . s:branch_name . " [y/n] : ") != 'y'
    return
  endif
  redraw
  let s:result = gbr#cmd_branch(a:option, s:branch_name)
  exec ":bd!"
  call gbr#echomsg(s:result)
  call gbr#gbr()
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

function! gbr#echomsg(result)
  for mes in split(a:result, "\n")
    echomsg mes
  endfor
endfunction

function! gbr#cmd_branch(option, branch_name)
  let s:result = system('git branch ' . a:option . ' ' . a:branch_name)
  return s:result
endfunction

function! gbr#get_target_branch()
  return substitute(getline("."), '\(^\*\|\s\)', '', 'g')
endfunction

function! gbr#create()
endfunction

function! s:gbr_default_key_mappings()
  if g:gbr_no_default_key_mappings
    return
  endif
  augroup gbr
    nnoremap <silent> <buffer> <CR> :<C-u>call gbr#checkout()<CR>
    nnoremap <silent> <buffer> d :<C-u>call gbr#delete("-d")<CR>
    nnoremap <silent> <buffer> D :<C-u>call gbr#delete("-D")<CR>
    nnoremap <silent> <buffer> c :<C-u>call gbr#create()<CR>
    nnoremap <silent> <buffer> q :<C-u>bdelete!<CR>
  augroup END
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
