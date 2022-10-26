
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
        call ZFIgnoreParseGitignore(ignoreData, path)
    endfor
    return ignoreData
endfunction

" detectOption : {
"   'pattern' : '\.gitignore', // pattern of gitignore file
"   'path' : '', // find for specified path, can be string or list
"   'cur' : 1, // find for getcwd()
"   'parent' : 1, // find in all parents until find one
"   'parentRecursive' : 1, // find in all parents even if found one
"   'callback' : function(), // func that return a list of gitignore file
" }
function! ZFIgnoreDetectGitignore(...)
    let detectOption = extend(
                \ copy(get(g:, 'ZFIgnore_ignore_gitignore_detectOption', {})),
                \ get(a:, 1, {}))
    let pattern = get(detectOption, 'pattern', '')
    if empty(pattern)
        let pattern = '\.gitignore'
    endif
    let pathList = []

    if !empty(get(detectOption, 'path', ''))
        if type(detectOption['path']) == type('')
            call extend(pathList, split(globpath(detectOption['path'], pattern, 1)))
        elseif type(detectOption['path']) == type([])
            for path in detectOption['path']
                call extend(pathList, split(globpath(path, pattern, 1)))
            endfor
        endif
    endif

    if get(detectOption, 'cur', 1)
        call extend(pathList, split(globpath(getcwd(), pattern, 1)))
    endif

    if get(detectOption, 'parentRecursive', 1)
        let detectParent = -1
    elseif get(detectOption, 'parent', 1)
        let detectParent = empty(pathList) ? 1 : 0
    else
        let detectParent = 0
    endif
    let parentPrev = substitute(getcwd(), '\\', '/', 'g')
    let parentCur = fnamemodify(parentPrev, ':h')
    while detectParent != 0 && parentCur != parentPrev
        call extend(pathList, split(globpath(parentCur, pattern, 1)))
        if detectParent > 0
            let detectParent -= 1
        endif
        let parentPrev = parentCur
        let parentCur = fnamemodify(parentPrev, ':h')
    endwhile

    let Fn_callback = get(detectOption, 'callback', '')
    if !empty(Fn_callback)
        call extend(Fn_callback)
    endif

    let pathMap = {}
    for path in pathList
        let pathMap[path] = 1
    endfor
    return keys(pathMap)
endfunction

function! ZFIgnoreParseGitignore(ignoreData, gitignoreFilePath)
    for pattern in readfile(substitute(a:gitignoreFilePath, '\\', '/', 'g'))
        if match(pattern, '^[ \t]*#') >= 0
                    \ || match(pattern, '^[ \t]*!') >= 0
            continue
        endif

        " comments: `# xxx`
        let pattern = substitute(pattern, '^[ \t]*#.*', '', 'g')

        " head or tail spaces
        let pattern = substitute(pattern, '^[ \t]+', '', 'g')
        let pattern = substitute(pattern, '[ \t]+$', '', 'g')

        " no abs path support
        "   `*/path/abc` => `path/abc`
        "   `/path/abc` => `path/abc`
        let pattern = substitute(pattern, '^\**\/\+', '', 'g')

        if empty(pattern)
            continue
        endif

        if match(pattern, '/\+\**$') >= 0
            " explicit dir, `path/` or `path/*`
            let pattern = substitute(pattern, '/\+\**$', '', 'g')
            if !empty(pattern)
                let a:ignoreData['dir'][pattern] = 1
            endif
        else
            let a:ignoreData['file'][pattern] = 1
            let a:ignoreData['dir'][pattern] = 1
        endif
    endfor
endfunction

if !exists('g:ZFIgnoreData')
    let g:ZFIgnoreData = {}
endif
let g:ZFIgnoreData['ZFIgnore_ignore_gitignore'] = function('ZFIgnoreLoadGitignore')

