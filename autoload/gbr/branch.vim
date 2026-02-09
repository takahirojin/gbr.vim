vim9script

# =============================================================================
# Filename: autoload/gbr/branch.vim
# Author: takahiro jinno
# License: MIT License
# =============================================================================

export def GetName(line: string): string
  return substitute(line, '\(^\*\|\s\)', '', 'g')
enddef

export def CurrentTop(branch_list: list<string>): list<string>
  var result: list<string> = []
  var current = ''
  for b in branch_list
    if b =~# '\*'
      current = b
    else
      add(result, b)
    endif
  endfor
  insert(result, current, 0)
  return result
enddef

export def Filter(targets: list<string>, exclusion: list<string>): list<string>
  var branches = copy(targets)
  filter(branches, (_, val) => val !~# '\*')
  if !empty(exclusion)
    filter(branches, (_, val) => index(exclusion, val) == -1)
  endif
  return branches
enddef
