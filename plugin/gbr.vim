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

let g:gbr_no_default_key_mappings = get(g:, 'g:gbr_no_default_key_mappings', 0)
let g:gbr_buf_max_height          = get(g:, 'gbr_buf_max_height', 15)
let g:gbr_current_branch_top      = get(g:, 'gbr_current_branch_top', 0)

command! Gbr call gbr#gbr()
" command! GbrSwitch call gbr#checkout()
" command! GbrDelete call gbr#delete()

nnoremap <silent> <Plug>(gbr_gbr) :<C-u>Gbr<CR>
" nnoremap <silent> <Plug>(gbr_checkout) :<C-u>GbrSwitch<CR>
" nnoremap <silent> <Plug>(gbr_delete) :<C-u>GbrDelete<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
