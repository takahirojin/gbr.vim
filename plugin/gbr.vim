" =============================================================================
" Filename: plugin/gbr.vim
" Version: 0.0
" Author: takahiro jinno
" License: MIT License
" =============================================================================

if exists('g:gbr_vim')
  finish
endif
let g:loaded_gbr_vim = 1

let s:save_cpo = &cpo
set cpo&vim

let g:gbr_no_default_key_mappings = get(g:, 'gbr_no_default_key_mappings', 0)
let g:gbr_window_height           = get(g:, 'gbr_window_height', 15)
let g:gbr_current_branch_top      = get(g:, 'gbr_current_branch_top', 0)
let g:gbr_exclusion_branch        = get(g:, 'gbr_exclusion_branch', [])

command! Gbr call gbr#gbr()
command! GbrTruncateBranch call gbr#truncate_branch()

nnoremap <silent> <Plug>(gbr_gbr) :<C-u>Gbr<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
