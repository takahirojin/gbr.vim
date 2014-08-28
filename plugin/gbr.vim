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

command! Gbr call gbr#list()

let &cpo = s:save_cpo
unlet s:save_cpo
