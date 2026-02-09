vim9script

# =============================================================================
# Filename: autoload/gbr.vim
# Version: 2.0
# Author: takahiro jinno
# License: MIT License
# =============================================================================

import autoload 'gbr/git.vim'
import autoload 'gbr/branch.vim'

# ポップアップの状態
var popup_id = 0
var branch_lines: list<string> = []
var popup_mode = 'navigate'
var selected_lnum = 1

# 入力モード用
var input_text = ''
var input_label = ''
var input_info = ''
var ActionCallback: func(string)

# 確認モード用
var confirm_lines: list<string> = []
var ConfirmCallback: func()

var popup_width = 80
var scroll_offset = 0

# =============================================================================
# ブランチ一覧ポップアップ
# =============================================================================

export def Gbr()
  branch_lines = split(system('git branch'), "\n")
  if v:shell_error
    echohl ErrorMsg
    echo 'gbr: not a git repository'
    echohl None
    return
  endif
  if g:gbr_current_branch_top
    branch_lines = branch.CurrentTop(branch_lines)
  endif

  popup_mode = 'navigate'
  selected_lnum = 1
  scroll_offset = 0
  input_text = ''

  if popup_id > 0
    # 既存のポップアップを更新
    popup_settext(popup_id, BuildContent())
    win_execute(popup_id, 'cursor(' .. selected_lnum .. ', 1)')
    return
  endif

  popup_width = g:gbr_window_width

  var opts: dict<any> = {
    title: ' Git Branches ',
    border: [1, 1, 1, 1],
    padding: [0, 1, 0, 1],
    minwidth: popup_width,
    maxwidth: popup_width,
    maxheight: g:gbr_window_height + 4,
    cursorline: true,
    mapping: false,
    filter: PopupFilter,
    callback: (id, _) => {
      popup_id = 0
    },
  }
  if &ambiwidth !=# 'double'
    opts.borderchars = ['─', '│', '─', '│', '┌', '┐', '┘', '└']
  endif
  popup_id = popup_create(BuildContent(), opts)
  win_execute(popup_id, 'cursor(' .. selected_lnum .. ', 1)')
  UpdateTitle()
  ApplySyntax()
enddef

def ApplySyntax()
  win_execute(popup_id, 'syntax match Title /^\*\s.*$/')
  win_execute(popup_id, 'syntax match Comment /^[-─]\+$/')
  win_execute(popup_id, 'syntax match Comment /^\[.*$/')
  win_execute(popup_id, 'syntax match Type /\S\+:/' )
enddef

# =============================================================================
# 表示内容の構築
# =============================================================================

def MakeSeparator(): string
  var char = &ambiwidth ==# 'double' ? '-' : '─'
  return repeat(char, popup_width)
enddef

def BottomLineCount(): number
  if popup_mode == 'navigate'
    return 3
  elseif popup_mode == 'input'
    return input_info != '' ? 3 : 2
  elseif popup_mode == 'confirm'
    return len(confirm_lines) + 2
  endif
  return 0
enddef

def VisibleBranchCount(): number
  var max_h = g:gbr_window_height + 4
  var bottom = BottomLineCount()
  return max([1, max_h - bottom])
enddef

def BuildContent(): list<string>
  var visible = VisibleBranchCount()
  var total = len(branch_lines)
  var end_idx = min([scroll_offset + visible, total]) - 1
  var content = branch_lines[scroll_offset : end_idx]

  if popup_mode == 'navigate'
    content->add('')
    content->add('  Enter:checkout c:create s:switch C:pull+create')
    content->add('  m:rename d:delete D:force t:truncate')
  elseif popup_mode == 'input'
    content->add(MakeSeparator())
    if input_info != ''
      content->add(input_info)
    endif
    content->add(input_label .. input_text .. '_')
  elseif popup_mode == 'confirm'
    content->add(MakeSeparator())
    content->extend(confirm_lines)
    content->add('[y] Yes  [n] No')
  endif

  return content
enddef

def UpdateTitle()
  var total = len(branch_lines)
  var visible = VisibleBranchCount()
  if total <= visible
    popup_setoptions(popup_id, {title: ' Git Branches '})
  else
    var s = scroll_offset + 1
    var e = min([scroll_offset + visible, total])
    var t = ' Git Branches (' .. s .. '-' .. e .. '/' .. total .. ') '
    popup_setoptions(popup_id, {title: t})
  endif
enddef

def AdjustScroll()
  var visible = VisibleBranchCount()
  if selected_lnum - 1 < scroll_offset
    scroll_offset = selected_lnum - 1
  elseif selected_lnum > scroll_offset + visible
    scroll_offset = selected_lnum - visible
  endif
enddef

def RefreshPopup()
  if popup_id <= 0
    return
  endif
  popup_settext(popup_id, BuildContent())
  var cursor_line = selected_lnum - scroll_offset
  win_execute(popup_id, 'cursor(' .. cursor_line .. ', 1)')
  UpdateTitle()
  ApplySyntax()
enddef

# =============================================================================
# フィルタ（モード分岐）
# =============================================================================

def PopupFilter(id: number, key: string): bool
  if popup_mode == 'navigate'
    return FilterNavigate(id, key)
  elseif popup_mode == 'input'
    return FilterInput(id, key)
  elseif popup_mode == 'confirm'
    return FilterConfirm(id, key)
  endif
  return false
enddef

# --- navigate モード ---

def FilterNavigate(id: number, key: string): bool
  if key == 'j' || key == "\<Down>" || key == "\<C-n>"
    if selected_lnum < len(branch_lines)
      selected_lnum += 1
      AdjustScroll()
      RefreshPopup()
    endif
    return true
  elseif key == 'k' || key == "\<Up>" || key == "\<C-p>"
    if selected_lnum > 1
      selected_lnum -= 1
      AdjustScroll()
      RefreshPopup()
    endif
    return true
  elseif key == 'g'
    selected_lnum = 1
    scroll_offset = 0
    RefreshPopup()
    return true
  elseif key == 'G'
    selected_lnum = len(branch_lines)
    AdjustScroll()
    RefreshPopup()
    return true
  elseif key == "\<CR>" || key == "\<Space>"
    var name = branch.GetName(branch_lines[selected_lnum - 1])
    popup_close(id, -1)
    git.Checkout(name)
    return true
  elseif key == 'c'
    EnterInputMode('Create', 'c')
    return true
  elseif key == 's'
    EnterInputMode('Create + Switch', 's')
    return true
  elseif key == 'C'
    EnterInputMode('Create + Pull', 'C')
    return true
  elseif key == 'm'
    EnterRenameMode()
    return true
  elseif key == 'd'
    EnterDeleteMode('-d')
    return true
  elseif key == 'D'
    EnterDeleteMode('-D')
    return true
  elseif key == 't'
    EnterTruncateMode()
    return true
  elseif key == 'q' || key == "\<Esc>"
    popup_close(id, -1)
    return true
  endif
  return true
enddef

# --- input モード ---

def FilterInput(id: number, key: string): bool
  if key == "\<CR>"
    if input_text != ''
      var text = input_text
      var Fn = ActionCallback
      popup_mode = 'navigate'
      Fn(text)
    endif
    return true
  elseif key == "\<Esc>"
    popup_mode = 'navigate'
    RefreshPopup()
    return true
  elseif key == "\<BS>"
    if len(input_text) > 0
      input_text = input_text[: -2]
    endif
    RefreshPopup()
    return true
  else
    if len(key) == 1 && char2nr(key) >= 32
      input_text = input_text .. key
      RefreshPopup()
    endif
    return true
  endif
enddef

# --- confirm モード ---

def FilterConfirm(id: number, key: string): bool
  if key == 'y'
    var Fn = ConfirmCallback
    popup_mode = 'navigate'
    Fn()
    return true
  elseif key == 'n' || key == "\<Esc>"
    popup_mode = 'navigate'
    RefreshPopup()
    return true
  endif
  return true
enddef

# =============================================================================
# モード切替
# =============================================================================

def EnterInputMode(title: string, option: string)
  var name = branch.GetName(branch_lines[selected_lnum - 1])
  popup_mode = 'input'
  input_text = ''
  input_info = '[' .. title .. '] Base: ' .. name
  input_label = 'Name: '

  ActionCallback = (new_name) => {
    git.Create(name, new_name, option)
    ReloadBranches()
  }
  RefreshPopup()
enddef

def EnterRenameMode()
  var name = branch.GetName(branch_lines[selected_lnum - 1])
  popup_mode = 'input'
  input_text = ''
  input_info = '[Rename] From: ' .. name
  input_label = 'To: '

  ActionCallback = (new_name) => {
    git.Rename(name, new_name)
    ReloadBranches()
  }
  RefreshPopup()
enddef

def EnterDeleteMode(option: string)
  var name = branch.GetName(branch_lines[selected_lnum - 1])
  popup_mode = 'confirm'
  confirm_lines = ['Delete ' .. option .. ' ' .. name .. ' ?']

  ConfirmCallback = () => {
    git.Delete(name, option)
    ReloadBranches()
  }
  RefreshPopup()
enddef

def EnterTruncateMode()
  var blist = split(substitute(system('git branch'), '\s', '', 'g'), "\n")
  var exclusion: list<string> = g:gbr_exclusion_branch
  var targets = branch.Filter(blist, exclusion)
  if empty(targets)
    echo 'Nothing any target branch...'
    return
  endif

  popup_mode = 'confirm'
  confirm_lines = ['Delete ' .. len(targets) .. ' branch(es):']
  var line = ' '
  for t in targets
    if len(line) + len(t) + 2 > popup_width && line != ' '
      confirm_lines->add(line)
      line = '  ' .. t .. ','
    else
      line ..= ' ' .. t .. ','
    endif
  endfor
  if line != ' '
    confirm_lines->add(substitute(line, ',$', '', ''))
  endif

  ConfirmCallback = () => {
    git.Truncate(targets)
    ReloadBranches()
  }
  RefreshPopup()
enddef

export def TruncateBranch()
  if popup_id > 0
    popup_close(popup_id, -1)
  endif
  var blist = split(substitute(system('git branch'), '\s', '', 'g'), "\n")
  var exclusion: list<string> = g:gbr_exclusion_branch
  var targets = branch.Filter(blist, exclusion)
  if empty(targets)
    echo 'Nothing any target branch...'
    return
  endif
  git.Truncate(targets)
enddef

# =============================================================================
# ユーティリティ
# =============================================================================

def ReloadBranches()
  branch_lines = split(system('git branch'), "\n")
  if g:gbr_current_branch_top
    branch_lines = branch.CurrentTop(branch_lines)
  endif
  if selected_lnum > len(branch_lines)
    selected_lnum = len(branch_lines)
  endif
  if scroll_offset >= len(branch_lines)
    scroll_offset = max([0, len(branch_lines) - g:gbr_window_height])
  endif
  popup_mode = 'navigate'
  AdjustScroll()
  RefreshPopup()
enddef
