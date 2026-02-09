vim9script

# =============================================================================
# Filename: plugin/gbr.vim
# Version: 2.0
# Author: takahiro jinno
# License: MIT License
# =============================================================================

if exists('g:loaded_gbr_vim')
  finish
endif
g:loaded_gbr_vim = 1

import autoload 'gbr.vim' as gbr

g:gbr_window_height           = get(g:, 'gbr_window_height', 15)
g:gbr_window_width            = get(g:, 'gbr_window_width', 80)
g:gbr_current_branch_top      = get(g:, 'gbr_current_branch_top', 0)
g:gbr_exclusion_branch        = get(g:, 'gbr_exclusion_branch', [])

command! Gbr gbr.Gbr()
command! GbrTruncateBranch gbr.TruncateBranch()

nnoremap <silent> <Plug>(gbr_gbr) <ScriptCmd>gbr.Gbr()<CR>
