
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

    if get(g:, 'ZFIgnore_ignore_gitignore_findRecursive', 0)
        let pattern = '**/.gitignore'
    else
        let pattern = '.gitignore'
    endif
    let pathList = split(globpath(getcwd(), pattern, 1))
    let file = {}
    let dir = {}
    for path in pathList
        for pattern in readfile(substitute(path, '\\', '/', 'g'))
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
                    let dir[pattern] = 1
                endif
                continue
            endif

            " `*/path/abc` to `path/abc`
            let pattern = substitute(pattern, '^\*\+/\+', '', 'g')

            let file[pattern] = 1
            let dir[pattern] = 1
        endfor
    endfor
    return {
                \   'file' : file,
                \   'dir' : dir,
                \ }
endfunction

if !exists('g:ZFIgnoreData')
    let g:ZFIgnoreData = {}
endif
let g:ZFIgnoreData['ZFIgnore_ignore_gitignore'] = function('ZFIgnoreLoadGitignore')

