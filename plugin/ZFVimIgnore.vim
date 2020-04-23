
augroup ZFVimIgnore_augroup
    autocmd!
    autocmd User ZFIgnoreOnSetup silent
    autocmd User ZFIgnoreOnUpdate silent
    autocmd VimEnter * call ZFIgnoreUpdate()
augroup END

" {
"   'moduleA' : 'function(option) that return {file:{},dir:{}}',
"   'moduleB' : {
"     'common' : {
"       'file' : {},
"       'dir' : {},
"     },
"     'bin' : {...}, // can be disabled via ZFIgnoreGet's option
"     'media' : {...},
"     ...
"   },
" }
if !exists('g:ZFIgnoreData')
    let g:ZFIgnoreData = {}
endif
if !exists('g:ZFIgnoreOn')
    let g:ZFIgnoreOn = 1
endif

" {
"   'type' : 1/0,
" }
if !exists('g:ZFIgnoreOptionDefault')
    let g:ZFIgnoreOptionDefault = {}
endif

" {
"   'module' : 'function({file:[], dir:[]}) to add or remove final ignore settings'
" }
if !exists('g:ZFIgnoreFilter')
    let g:ZFIgnoreFilter = {}
endif

" option: {
"   'bin' : 1, // whether ignore binary
"   'media' : 1, // whether ignore media
"   ...
" }
" return: {
"   'file' : [],
"   'dir' : [],
"   'file_filtered' : [],
"   'dir_filtered' : [],
" }
function! ZFIgnoreGet(...)
    let option = get(a:, 1, {})
    let cacheKey = s:ZFIgnoreCacheKey(option)
    if exists('s:ZFIgnoreCache') && exists('s:ZFIgnoreCache[cacheKey]')
        return s:ZFIgnoreCache[cacheKey]
    endif

    doautocmd User ZFIgnoreOnSetup
    let ret = s:ZFIgnoreGet(option)
    for module in keys(g:ZFIgnoreFilter)
        let Fn = g:ZFIgnoreFilter[module]
        call Fn(ret)
    endfor

    if !exists('s:ZFIgnoreCache')
        let s:ZFIgnoreCache = {}
    endif
    let s:ZFIgnoreCache[cacheKey] = ret
    return ret
endfunction

" return: [
"   '*.xxx',
"   '*/xxx/*',
" ]
function! ZFIgnoreToWildignore(ignore)
    let ret = []
    for t in a:ignore['file']
        let t = substitute(t, ' ', '\\ ', 'g')
        call add(ret, t)
    endfor
    for t in a:ignore['dir']
        let t = substitute(t, ' ', '\\ ', 'g')
        call add(ret, t)
        if match(t, '^\*\+/\+') < 0
            call add(ret, '**/' . t)
        endif
    endfor
    return ret
endfunction

" return: [
"   '^.*\.xxx$',
" ]
function! ZFIgnoreToRegexp(ignore)
    let ret = []
    for item in extend(copy(a:ignore['file']), a:ignore['dir'])
        let item = ZFIgnorePatternToRegexp(item)
        if !empty(item)
            call add(ret, item)
        endif
    endfor
    return ret
endfunction

function! ZFIgnorePatternToRegexp(pattern)
    if match(a:pattern, '/') >= 0
        return ''
    endif
    let item = substitute(a:pattern, '\.', '\\.', 'g')
    let item = substitute(item, '\*', '.*', 'g')
    let item = substitute(item, '?', '.?', 'g')
    let item = substitute(item, '\~', '\\~', 'g')
    return '^' . item . '$'
endfunction

" manually update ignore
function! ZFIgnoreUpdate()
    if exists('s:ZFIgnoreCache')
        unlet s:ZFIgnoreCache
    endif
    doautocmd User ZFIgnoreOnUpdate
endfunction
command! -nargs=0 ZFIgnoreUpdate :call ZFIgnoreUpdate() | echo '[ZFIgnore] updated'

" module
" type: common/bin/media/...
" ignore: {
"   'file' : 'string/list/dict',
"   'dir' : 'string/list/dict',
" }
function! ZFIgnoreAdd(module, type, ignore, ...)
    let notify = get(a:, 1, 1)
    call s:ZFIgnoreAdd(a:module, a:type, a:ignore)
    if notify
        call ZFIgnoreUpdate()
    endif
endfunction
command! -nargs=+ -complete=file ZFIgnoreAdd
            \ :call ZFIgnoreAdd('ZFIgnoreByUser', 'common', {'file':<q-args>,'dir':<q-args>})
            \| echo '[ZFIgnore] added ' . <q-args>

function! ZFIgnoreRemove(module, type, ignore, ...)
    let notify = get(a:, 1, 1)
    call s:ZFIgnoreRemove(a:module, a:type, a:ignore)
    if notify
        call ZFIgnoreUpdate()
    endif
endfunction
command! -nargs=+ -complete=file ZFIgnoreRemove
            \ :call ZFIgnoreRemove('ZFIgnoreByUser', 'common', {'file':<q-args>,'dir':<q-args>})
            \| echo '[ZFIgnore] removed ' . <q-args>

function! ZFIgnoreOn()
    let g:ZFIgnoreOn = 1
    call ZFIgnoreUpdate()
endfunction
command! -nargs=0 ZFIgnoreOn :call ZFIgnoreOn() | echo '[ZFIgnore] on'
function! ZFIgnoreOff()
    let g:ZFIgnoreOn = 0
    call ZFIgnoreUpdate()
endfunction
command! -nargs=0 ZFIgnoreOff :call ZFIgnoreOff() | echo '[ZFIgnore] off'
function! ZFIgnoreToggle()
    let g:ZFIgnoreOn = 1 - g:ZFIgnoreOn
    call ZFIgnoreUpdate()
endfunction
command! -nargs=0 ZFIgnoreToggle :call ZFIgnoreToggle() | echo '[ZFIgnore] ' . (g:ZFIgnoreOn ? 'on' : 'off')

" ============================================================
function! s:ZFIgnoreGet(option)
    if !g:ZFIgnoreOn
        return {
                    \   'file' : [],
                    \   'dir' : [],
                    \   'file_filtered' : [],
                    \   'dir_filtered' : [],
                    \ }
    endif

    let option = extend(copy(g:ZFIgnoreOptionDefault), a:option)
    let file = {}
    let dir = {}

    for key in keys(g:ZFIgnoreData)
        " E706 for some old vim
        if exists('Module')
            unlet Module
        endif

        let Module = g:ZFIgnoreData[key]
        if type(Module) == type(function('function'))
            let t = Module(option)
            call extend(file, get(t, 'file', {}))
            call extend(dir, get(t, 'dir', {}))
        else
            for type in keys(Module)
                if !get(option, type, 1)
                    continue
                endif
                call extend(file, get(Module[type], 'file', {}))
                call extend(dir, get(Module[type], 'dir', {}))
            endfor
        endif
    endfor

    let fileRet = []
    let dirRet = []
    for key in keys(file)
        if file[key]
            call add(fileRet, key)
        endif
    endfor
    for key in keys(dir)
        if dir[key]
            call add(dirRet, key)
        endif
    endfor

    return {
                \   'file' : fileRet,
                \   'dir' : dirRet,
                \   'file_filtered' : [],
                \   'dir_filtered' : [],
                \ }
endfunction

function! s:ZFIgnoreAdd_item(old, add, key)
    if !empty(get(a:add, a:key, ''))
        let t = a:add[a:key]
        if type(t) == type('')
            let a:old[a:key][t] = 1
        elseif type(t) == type([])
            for item in t
                let a:old[a:key][item] = 1
            endfor
        elseif type(t) == type({})
            for item in keys(t)
                let a:old[a:key][item] = 1
            endfor
        endif
    endif
endfunction
function! s:ZFIgnoreAdd(module, type, ignore)
    if empty(a:module) || empty(a:type) || empty(a:ignore)
        return
    endif
    let g:ZFIgnoreData[a:module] = get(g:ZFIgnoreData, a:module, {})
    let g:ZFIgnoreData[a:module][a:type] = get(g:ZFIgnoreData[a:module], a:type, {
                \   'file' : {},
                \   'dir' : {},
                \ })
    call s:ZFIgnoreAdd_item(g:ZFIgnoreData[a:module][a:type], a:ignore, 'file')
    call s:ZFIgnoreAdd_item(g:ZFIgnoreData[a:module][a:type], a:ignore, 'dir')
    if empty(g:ZFIgnoreData[a:module][a:type]['file'])
                \ && empty(g:ZFIgnoreData[a:module][a:type]['dir'])
        unlet g:ZFIgnoreData[a:module][a:type]
        if empty(g:ZFIgnoreData[a:module])
            unlet g:ZFIgnoreData[a:module]
        endif
    endif
endfunction

function! s:ZFIgnoreRemove_item(old, add, key)
    if !empty(get(a:add, a:key, ''))
        let t = a:add[a:key]
        if type(t) == type('')
            if exists('a:old[a:key][t]')
                unlet a:old[a:key][t]
            endif
        elseif type(t) == type([])
            for item in t
                if exists('a:old[a:key][item]')
                    unlet a:old[a:key][item]
                endif
            endfor
        elseif type(t) == type({})
            for item in keys(t)
                if exists('a:old[a:key][item]')
                    unlet a:old[a:key][item]
                endif
            endfor
        endif
    endif
endfunction
function! s:ZFIgnoreRemove(module, type, ignore)
    if empty(a:module) || !exists('g:ZFIgnoreData[a:module]')
        return
    endif
    if empty(a:type)
        unlet g:ZFIgnoreData[a:module]
        return
    endif
    if !exists('g:ZFIgnoreData[a:module][a:type]')
        return
    endif
    if empty(a:ignore)
        unlet g:ZFIgnoreData[a:module][a:type]
        if empty(g:ZFIgnoreData[a:module])
            unlet g:ZFIgnoreData[a:module]
        endif
        return
    endif

    call s:ZFIgnoreRemove_item(g:ZFIgnoreData[a:module][a:type], a:ignore, 'file')
    call s:ZFIgnoreRemove_item(g:ZFIgnoreData[a:module][a:type], a:ignore, 'dir')
    if empty(g:ZFIgnoreData[a:module][a:type]['file'])
                \ && empty(g:ZFIgnoreData[a:module][a:type]['dir'])
        unlet g:ZFIgnoreData[a:module][a:type]
        if empty(g:ZFIgnoreData[a:module])
            unlet g:ZFIgnoreData[a:module]
        endif
    endif
endfunction

function! s:ZFIgnoreCacheKey(option)
    " some old vim does not support empty key (E713)
    let cacheKey = ':'
    for key in keys(a:option)
        let cacheKey .= key . ':' . a:option[key] . ';'
    endfor
    return cacheKey
endfunction
