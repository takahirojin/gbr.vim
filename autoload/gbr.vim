vim9script

# =============================================================================
# Filename: autoload/gbr.vim
# Version: 2.0
# Author: takahiro jinno
# License: MIT License
# =============================================================================

const buf_name = '[gbr]'

export def Gbr()
  var height = g:gbr_window_height
  var branch_list = split(system('git branch'), "\n")
  if v:shell_error
    echohl ErrorMsg
    echo 'gbr: not a git repository'
    echohl None
    return
  endif
  if g:gbr_current_branch_top
    branch_list = CurrentBranchTop(branch_list)
  endif

  var count = len(branch_list)
  if count < height
    height = count
  endif
  execute 'silent noautocmd :' .. height .. 'new ' .. buf_name
  setline(1, branch_list)
  setlocal buftype=nofile bufhidden=hide noswapfile
  setlocal nomodified
  setlocal nomodifiable
  syntax match Title /^\*\s.*$/
  SetDefaultKeyMappings()
enddef

export def Checkout()
  var branch_name = GetTargetBranch()
  var result = system('git checkout ' .. shellescape(branch_name))
  execute 'bd!'
  echo result
enddef

export def Delete(option: string)
  var branch_name = GetTargetBranch()
  if input('Are you sure, delete ' .. option .. ' ' .. branch_name .. ' [y/n] : ') != 'y'
    return
  endif
  redraw
  var result = system('git branch ' .. option .. ' ' .. shellescape(branch_name))
  execute 'bd!'
  echo result
  Gbr()
enddef

def CurrentBranchTop(branch_list: list<string>): list<string>
  var result: list<string> = []
  var current = ''
  for branch in branch_list
    if branch =~# '\*'
      current = branch
    else
      add(result, branch)
    endif
  endfor
  insert(result, current, 0)
  return result
enddef

def GetTargetBranch(): string
  return substitute(getline('.'), '\(^\*\|\s\)', '', 'g')
enddef

export def Create(option: string)
  var new_branch_name = input('Input new-branch-name : ')
  if new_branch_name == ''
    return
  endif

  redraw
  var start_point = GetTargetBranch()
  var result: string
  if option ==# 'c'
    result = system('git branch ' .. shellescape(new_branch_name) .. ' ' .. shellescape(start_point))
    if result == ''
      echo "Created new branch '" .. new_branch_name .. "' from '" .. start_point .. "'"
    endif
  elseif option ==# 'cc'
    result = system('git checkout -b ' .. shellescape(new_branch_name) .. ' ' .. shellescape(start_point))
    echo result
    echo "Created new branch '" .. new_branch_name .. "' from '" .. start_point .. "'"
  elseif option ==# 'C'
    var res_checkout = system('git checkout ' .. shellescape(start_point))
    if v:shell_error
      echo res_checkout
      return
    endif
    var res_pull = system('git pull')
    if v:shell_error
      echo res_pull
      return
    endif
    result = system('git checkout -b ' .. shellescape(new_branch_name) .. ' ' .. shellescape(start_point))
    echo result
    echo "Created new branch '" .. new_branch_name .. "' from '" .. start_point .. "'\nbefore 'git checkout " .. start_point .. " && git pull'"
  endif
  execute 'bd!'
  Gbr()
enddef

export def Rename()
  var oldbranch = GetTargetBranch()
  var new_branch_name = input("Rename from '" .. oldbranch .. "'\nInput new-branch-name : ")
  if new_branch_name == ''
    return
  endif

  redraw
  var result = system('git branch -m ' .. shellescape(oldbranch) .. ' ' .. shellescape(new_branch_name))
  if result == ''
    echo "Rename '" .. new_branch_name .. "' from '" .. oldbranch .. "'"
  endif
  execute 'bd!'
  Gbr()
enddef

def SetDefaultKeyMappings()
  if g:gbr_no_default_key_mappings
    return
  endif
  nnoremap <silent> <buffer> <CR> <ScriptCmd>Checkout()<CR>
  nnoremap <silent> <buffer> c <ScriptCmd>Create('c')<CR>
  nnoremap <silent> <buffer> cc <ScriptCmd>Create('cc')<CR>
  nnoremap <silent> <buffer> C <ScriptCmd>Create('C')<CR>
  nnoremap <silent> <buffer> m <ScriptCmd>Rename()<CR>
  nnoremap <silent> <buffer> d <ScriptCmd>Delete('-d')<CR>
  nnoremap <silent> <buffer> D <ScriptCmd>Delete('-D')<CR>
  nnoremap <silent> <buffer> q <Cmd>bdelete!<CR>
enddef

export def TruncateBranch()
  var branch_list = split(substitute(system('git branch'), '\s', '', 'g'), "\n")
  var exclusion_branch: list<string> = g:gbr_exclusion_branch
  var truncate_branch_list = FilterBranch(branch_list, exclusion_branch)
  if !empty(truncate_branch_list)
    var escaped = map(copy(truncate_branch_list), (_, v) => shellescape(v))
    var result = system('git branch -d ' .. join(escaped, ' '))
    if bufname('[gbr]') == '[gbr]'
      redraw
      execute 'bd!'
      echo result
      Gbr()
    else
      echo result
    endif
  else
    echo 'Nothing any target branch...'
  endif
enddef

def FilterBranch(truncate_branch: list<string>, exclusion_branch: list<string>): list<string>
  var branches = copy(truncate_branch)
  filter(branches, (_, val) => val !~# '\*')
  if !empty(exclusion_branch)
    filter(branches, (_, val) => index(exclusion_branch, val) == -1)
  endif
  return branches
enddef
