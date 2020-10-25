
# Intro

util to make `wildignore` and similars more friendly and easier to config

if you like my work, [check here](https://github.com/ZSaberLv0?utf8=%E2%9C%93&tab=repositories&q=ZFVim) for a list of my vim plugins,
or [buy me a coffee](https://github.com/ZSaberLv0/ZSaberLv0)


# Usage

1. Install

    ```
    Plug 'ZSaberLv0/ZFVimIgnore'
    ```

1. make your plugin or configs adapt to ignore setting

    ```
    autocmd User ZFIgnoreOnUpdate let &wildignore = join(ZFIgnoreToWildignore(ZFIgnoreGet()), ',')
    autocmd User ZFIgnoreOnUpdate let g:NERDTreeIgnore = ZFIgnoreToRegexp(ZFIgnoreGet({
            \   'bin' : 0,
            \   'media' : 0,
            \ }))
    ```

1. by default:
    * some common ignore are added
    * `.gitignore` under current dir would be recognized
    * `wildignore` would be applied automatically
1. you may add or remove custom ignore at runtime

    ```
    :ZFIgnoreAdd *.obj
    :ZFIgnoreRemove build
    ```

    supported patterns:

    * see `:h wildcards`
    * supported: `?` `*` `[abc]`
    * not supported: `**` `*/`

1. or completely enable or disable by `:ZFIgnoreToggle`


# Typical config

here are some typical config for other plugins

```
" vim-easygrep
autocmd User ZFIgnoreOnUpdate let g:EasyGrepFilesToExclude = join(ZFIgnoreToWildignore(ZFIgnoreGet()), ',')

" LeaderF
function! s:ZFIgnore_LeaderF()
    let ignore = ZFIgnoreGet()
    let g:Lf_WildIgnore = {'file' : ignore['file'], 'dir' : ignore['dir']}
endfunction
autocmd User ZFIgnoreOnUpdate call s:ZFIgnore_LeaderF()

" NERDTree
let g:NERDTreeIgnore = ZFIgnoreToRegexp(ZFIgnoreGet({
        \   'bin' : 0,
        \   'media' : 0,
        \ }))
```


# For impl to extend ignore detect

```
" for impl
if !exists('g:ZFIgnoreOptionDefault')
    let g:ZFIgnoreOptionDefault = {}
endif
if !exists("g:ZFIgnoreOptionDefault['YourOwnType']")
    let g:ZFIgnoreOptionDefault['YourOwnType'] = 1
endif
autocmd User ZFIgnoreOnSetup call YourSetup()
function! YourSetup()
    " directly update to g:ZFIgnoreData
    let g:ZFIgnoreData['YourModule'] = {
            \   'common' : {
            \       'file' : {'*.obj':1, '*.bin':1},
            \       'dir' : {'build':1},
            \   },
            \   'YourOwnType' : {...},
            \ }
endfunction
```

```
" for users
" ignore can be enable/disable by module
let ignore = ZFIgnoreGet({'YourOwnType' : 1})
" or add default option
let g:ZFIgnoreOptionDefault['YourOwnType'] = 0
```


# FAQ

* Q: `E40: Can't open errorfile`

    A: typically occur on Windows only,
    if you have many ignore items,
    the final command may be very long (`grep` for example),
    which may exceeds Windows' command line limit,
    see also:
    https://support.microsoft.com/en-us/help/830473/command-prompt-cmd-exe-command-line-string-limitation

    to resolve this, try use a temp file to store exclude pattern, for example

    * use `--exclude-from` (for GNU `grep` only)

