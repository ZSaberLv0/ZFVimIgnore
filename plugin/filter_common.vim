
if !get(g:, 'ZFIgnore_filter_common', 1)
    finish
endif

" some werid thing would happen if:
" * cwd or cwd's parent is ignored
" * `~` or user directory is ignored
" * special patterns: `.` `*`
" * vim's rtp is ignored

function! ZFIgnore_filter_common(ignore)
    let filterMap = {}
    let filterMap['~'] = 1
    let filterMap['.'] = 1
    let filterMap['..'] = 1
    let filterMap['*'] = 1
    let filterMap['**'] = 1
    for item in split(substitute($HOME, '\\', '/', 'g'), '/')
        let filterMap[item] = 1
    endfor
    for item in split(substitute(getcwd(), '\\', '/', 'g'), '/')
        let filterMap[item] = 1
    endfor
    for rtp in split(&rtp, ',')
        for item in split(substitute(rtp, '\\', '/', 'g'), '/')
            let filterMap[item] = 1
        endfor
    endfor
    let filter = keys(filterMap)

    for type in ['dir']
        let i = len(a:ignore[type]) - 1
        while i >= 0
            if s:check(filter, a:ignore[type][i])
                call add(a:ignore[type . '_filtered'], remove(a:ignore[type], i))
            endif
            let i -= 1
        endwhile
    endfor
endfunction

if !exists('g:ZFIgnoreFilter')
    let g:ZFIgnoreFilter = {}
endif
let g:ZFIgnoreFilter['path'] = function('ZFIgnore_filter_common')

function! s:check(filter, pattern)
    let pattern = ZFIgnorePatternToRegexp(a:pattern)
    if empty(pattern)
        return 0
    endif
    let pattern = '\c' . pattern
    for item in a:filter
        if match(item, pattern) >= 0
            return 1
        endif
    endfor
    return 0
endfunction

