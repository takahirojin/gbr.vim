vim9script

# =============================================================================
# Filename: autoload/gbr/git.vim
# Author: takahiro jinno
# License: MIT License
# =============================================================================

export def Checkout(branch_name: string)
  var result = system('git checkout ' .. shellescape(branch_name))
  echomsg result
enddef

export def Create(start_point: string, new_name: string, option: string)
  var result: string
  if option ==# 'c'
    result = system('git branch ' .. shellescape(new_name) .. ' ' .. shellescape(start_point))
    if result == ''
      echomsg "Created '" .. new_name .. "' from '" .. start_point .. "'"
    else
      echomsg result
    endif
  elseif option ==# 's'
    result = system('git checkout -b ' .. shellescape(new_name) .. ' ' .. shellescape(start_point))
    if v:shell_error
      echomsg result
      return
    endif
    echomsg "Created and switched to '" .. new_name .. "' from '" .. start_point .. "'"
  elseif option ==# 'C'
    var res_checkout = system('git checkout ' .. shellescape(start_point))
    if v:shell_error
      echomsg res_checkout
      return
    endif
    var res_pull = system('git pull')
    if v:shell_error
      echomsg res_pull
      return
    endif
    result = system('git checkout -b ' .. shellescape(new_name) .. ' ' .. shellescape(start_point))
    if v:shell_error
      echomsg result
      return
    endif
    echomsg "Created '" .. new_name .. "' from '" .. start_point .. "' (after pull)"
  endif
enddef

export def Rename(oldbranch: string, new_name: string)
  var result = system('git branch -m ' .. shellescape(oldbranch) .. ' ' .. shellescape(new_name))
  if result == ''
    echomsg "Renamed '" .. oldbranch .. "' to '" .. new_name .. "'"
  else
    echomsg result
  endif
enddef

export def Delete(branch_name: string, option: string)
  var result = system('git branch ' .. option .. ' ' .. shellescape(branch_name))
  echomsg result
enddef

export def Truncate(targets: list<string>)
  var escaped = map(copy(targets), (_, v) => shellescape(v))
  var result = system('git branch -d ' .. join(escaped, ' '))
  echomsg result
enddef
