
if !get(g:, 'ZFIgnore_ignore_gitignore', 1)
    finish
endif

if !exists('g:ZFIgnoreOptionDefault')
    let g:ZFIgnoreOptionDefault = {}
endif
if !exists("g:ZFIgnoreOptionDefault['gitignore']")
    let g:ZFIgnoreOptionDefault['gitignore'] = 1
endif

augroup ZFIgnore_ignore_gitignore_augroup
    autocmd!
    if exists('##DirChanged')
        autocmd DirChanged * call ZFIgnoreUpdate()
    endif
augroup END

function! ZFIgnoreLoadGitignore(option)
    if !get(a:option, 'gitignore', 1)
        return {}
    endif
    let ignoreData = {
                \   'file' : {},
                \   'dir' : {},
                \ }
    let pathList = ZFIgnoreDetectGitignore()
    for path in pathList
        call ZFIgnoreParseGitignore(file, d)
    endfor
    return ignoreData
endfunction

" detectOption : {
"   'cur' : 1, // find for getcwd()
"   'parent' : 1, // find in all parents until find one
"   'parentRecursive' : 1, // find in all parents even if found one
"   'childRecursive' : 0, // find in all child dirs, maybe very slow
" }
function! ZFIgnoreDetectGitignore(...)
    let detectOption = extend(
                \ copy(get(g:, 'ZFIgnore_ignore_gitignore_detectOption', {})),
                \ get(a:, 1, {}))
    let pathList = []

    if get(detectOption, 'cur', 1)
        call extend(pathList, split(globpath(getcwd(), '.gitignore', 1)))
    endif

    if get(detectOption, 'parentRecursive', 1)
        let detectParent = -1
    elseif get(detectOption, 'parentRecursive', 1)
        let detectParent = empty(pathList) ? 1 : 0
    else
        let detectParent = 0
    endif
    let parentPrev = substitute(getcwd(), '\\', '/', 'g')
    let parentCur = fnamemodify(parentPrev, ':h')
    while detectParent != 0 && parentCur != parentPrev
        call extend(pathList, split(globpath(parentCur, '.gitignore', 1)))
        if detectParent > 0
            let detectParent -= 1
        endif
        let parentPrev = parentCur
        let parentCur = fnamemodify(parentPrev, ':h')
    endwhile

    if get(detectOption, 'childRecursive', 0)
        call extend(pathList, split(globpath(getcwd(), '*/**/.gitignore', 1)))
    endif

    return pathList
endfunction

function! ZFIgnoreParseGitignore(ignoreData, gitignoreFilePath)
    for pattern in readfile(substitute(a:gitignoreFilePath, '\\', '/', 'g'))
        if match(pattern, '^[ \t]*#') >= 0
                    \ || match(pattern, '^[ \t]*!') >= 0
            continue
        endif
        let pattern = substitute(pattern, '^[ \t]*#.*', '', 'g')
        let pattern = substitute(pattern, '^[ \t]+', '', 'g')
        let pattern = substitute(pattern, '[ \t]+$', '', 'g')
        if empty(pattern)
            continue
        endif

        " no abs path support
        let pattern = substitute(pattern, '^/*', '', 'g')

        " explicit dir, `path/` or `path/*`
        if match(pattern, '/\+\**$') >= 0
            let pattern = substitute(pattern, '/\+\**$', '', 'g')
            if !empty(pattern)
                let a:ignoreData['dir'][pattern] = 1
            endif
            continue
        endif

        " `*/path/abc` to `path/abc`
        let pattern = substitute(pattern, '^\*\+/\+', '', 'g')

        let a:ignoreData['file'][pattern] = 1
        let a:ignoreData['dir'][pattern] = 1
    endfor
endfunction

if !exists('g:ZFIgnoreData')
    let g:ZFIgnoreData = {}
endif
let g:ZFIgnoreData['ZFIgnore_ignore_gitignore'] = function('ZFIgnoreLoadGitignore')

