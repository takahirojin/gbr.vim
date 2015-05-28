" =============================================================================
" Filename: autoload/gbr.vim
" Version: 1.0
" Author: takahiro jinno
" License: MIT License
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let g:buf_name = '[gbr]'

function! gbr#gbr() abort
  let s:height = g:gbr_window_height
  let s:branch_list = split(system('git branch'), "\n")
  if g:gbr_current_branch_top
    let s:branch_list = s:current_branch_top(s:branch_list)
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

function! gbr#checkout() abort
  let s:branch_name = s:get_target_branch()
  let s:result = system('git checkout ' . s:branch_name)
  exec ":bd!"
  echo s:result
endfunction

function! gbr#delete(option) abort
  let s:branch_name = s:get_target_branch()
  if input("Are you sure, delete " . a:option . ' ' . s:branch_name . " [y/n] : ") != 'y'
    return
  endif
  redraw
  let s:result = system('git branch ' . a:option . ' ' . s:branch_name)
  exec ":bd!"
  echo s:result
  call gbr#gbr()
endfunction

function! s:current_branch_top(branch_list) abort
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

function! s:get_target_branch()
  return substitute(getline("."), '\(^\*\|\s\)', '', 'g')
endfunction

function! gbr#create(option) abort
  let s:new_branch_name = input("Input new-branch-name : ")
  if s:new_branch_name == ""
    return
  endif

  redraw
  let s:start_point = s:get_target_branch()
  if a:option ==# "c"
    let s:result = system('git branch ' . s:new_branch_name . ' ' . s:start_point)
    if s:result == ""
      echo "Created new branch '" . s:new_branch_name . "' from '" . s:start_point . "'"
    endif
  elseif a:option ==# "cc"
    let s:result = system('git checkout -b ' . s:new_branch_name . ' ' . s:start_point)
    echo s:result
    echo "Created new branch '" . s:new_branch_name . "' from '" . s:start_point . "'"
  elseif a:option ==# "C"
    let s:resCheckout = system('git checkout ' . s:start_point)
    if v:shell_error
      echo s:resCheckout
      return
    endif
    let s:resPull = system('git pull')
    if v:shell_error
      echo s:resPull
      return
    endif
    let s:result = system('git checkout -b ' . s:new_branch_name . ' ' . s:start_point)
    echo s:result
    echo "Created new branch '" . s:new_branch_name . "' from '" . s:start_point . "'\nbefore 'git checkout " . s:start_point . " && git pull'"
  endif
  exec ":bd!"
  call gbr#gbr()
endfunction

function! s:gbr_default_key_mappings()
  if g:gbr_no_default_key_mappings
    return
  endif
  nnoremap <silent> <buffer> <CR> :<C-u>call gbr#checkout()<CR>
  nnoremap <silent> <buffer> c :<C-u>call gbr#create("c")<CR>
  nnoremap <silent> <buffer> cc :<C-u>call gbr#create("cc")<CR>
  nnoremap <silent> <buffer> C :<C-u>call gbr#create("C")<CR>
  nnoremap <silent> <buffer> d :<C-u>call gbr#delete("-d")<CR>
  nnoremap <silent> <buffer> D :<C-u>call gbr#delete("-D")<CR>
  nnoremap <silent> <buffer> q :<C-u>bdelete!<CR>
endfunction

function! gbr#truncate_branch() abort
  let s:branch_list = []
  for branch in split(system('git branch'), "\n")
    let s:branch = substitute(branch, " ", "", "g")
    call add(s:branch_list, s:branch)
  endfor
  let s:exclusion_branch = g:gbr_exclusion_branch
  let s:truncate_branch_list = s:filter_branch(s:branch_list, s:exclusion_branch)
  if !empty(s:truncate_branch_list)
    let s:result = system('git branch -d ' . join(s:truncate_branch_list, " "))
    if bufname("[gbr]") == "[gbr]"
      redraw
      exec ":bd!"
      echo s:result
      call gbr#gbr()
    else
      echo s:result
    endif
  else
    echo "Nothing any target branch..."
  endif
endfunction

function! s:filter_branch(truncate_branch, exclusion_branch) abort
  call filter(a:truncate_branch, 'v:val !~# "*"')
  if !empty(a:exclusion_branch)
    call filter(a:truncate_branch, 'index(a:exclusion_branch, v:val) == -1')
  endif
  return a:truncate_branch
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
