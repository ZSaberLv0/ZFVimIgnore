
if !get(g:, 'ZFVimIgnore_apply_wildignore', 1)
    finish
endif

augroup ZFVimIgnore_apply_wildignore_augroup
    autocmd!
    autocmd User ZFIgnoreOnUpdate let &wildignore = join(ZFIgnoreToWildignore(ZFIgnoreGet()), ',')
augroup END

