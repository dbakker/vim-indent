if exists("autoloaded_indent") || &cp
  finish
endif

" sw - shiftwidth - number of spaces to use for each step of indent
" sts - softtabstop - number of spaces that tab counts for while performing
"                     editing operations
" ts - tabstop - number of spaces that a tab counts for
" et - expandtab - use spaces instead of actual tabs

let g:autoloaded_indent = '0.0.1' " version number
let s:keepcpo = &cpo
set cpo&vim

fun! s:indent_info(line)
  let ind = matchstr(a:line, '^\s*')
  let tabs = len(matchstr(ind, '^\t*'))
  let spaces = len(matchstr(ind, '^\t*\zs *'))
  return {'tabs': tabs, 'spaces': spaces, 'length': len(ind)}
endf

fun! s:analyze(lines, data) abort
  let data = a:data

  for line in a:lines
    if line !~ '^\s*$'
      let ind = s:indent_info(line)
      if ind.tabs + ind.spaces == ind.length
        let data.total_tabs += ind.tabs ? 1 : 0
        let data.total_lines += 1
        if exists('l:lastind') && ind != lastind
          let data.diffs += 1
          let diff_spaces = ind.spaces - lastind.spaces
          let diff_tabs = ind.tabs - lastind.tabs
          if diff_spaces != 0 && diff_tabs == 0
            let data.space_diffs[abs(diff_spaces)] = get(data.space_diffs, abs(diff_spaces), 0) + 1
          elseif diff_tabs != 0 && diff_spaces == 0
            let data.tab_diffs += 1
          else
            let data.mixed_diffs += 1
          endif
        endif
        let lastind = ind
      endif
    endif
  endfor
endf

fun! s:guessoptions(data) abort
  " setlocal ai sta sw=2 sts=2 ts=2

  let data = a:data
  if data.diffs < 5
    return []
  endif

  let diff2 = get(data.space_diffs, 2, 0)
  let diff4 = get(data.space_diffs, 4, 0)
  let sw = diff2 > diff4/10 ? 2 : 4

  if data.tab_diffs + data.mixed_diffs <= data.diffs/10
    return ['et', 'sw='.sw, 'sts='.sw]
  endif

  if data.mixed_diffs >= data.diffs/10
    let ts = sw * 2
    return ['noet', 'sw='.sw, 'sts='.sw, 'ts='.ts]
  endif

  if data.tab_diffs > 0
    let ts = 4
    return ['noet', 'sw='.sw, 'sts='.sw, 'ts='.ts]
  endif
  return []
endf

fun! s:new_data()
  return {'total_tabs': 0, 'total_lines': 0, 'space_diffs': {}, 'tab_diffs': 0, 'mixed_diffs':0, 'diffs': 0}
endf

fun! s:scan_indent()
  let data = s:new_data()
  call s:analyze(getline(1, 1024), data)
  let options = s:guessoptions(data)
  if len(options) > 0
    return options
  endif

  let patterns = s:patterns_for(&filetype)
  call filter(patterns, 'v:val !~# "/"')
  let dir = expand('%:p:h')
  while isdirectory(dir) && dir !=# fnamemodify(dir, ':h')
    for pattern in patterns
      for neighbor in split(glob(dir.'/'.pattern), "\n")
        if neighbor !=# expand('%:p')
          call s:analyze(readfile(neighbor, '', 1024), data)
          let options = s:guessoptions(data)
        endif
        if len(options) > 0
          return options
        endif
      endfor
    endfor
    let dir = fnamemodify(dir, ':h')
  endwhile
endf

function! s:patterns_for(type) abort
  " This routine was taken from tpope's sleuth plugin
  if a:type ==# ''
    return []
  endif
  if !exists('s:patterns')
    redir => capture
    silent autocmd BufRead
    redir END
    let patterns = {
          \ 'c': ['*.c'],
          \ 'html': ['*.html'],
          \ 'sh': ['*.sh'],
          \ }
    let setfpattern = '\s\+\%(setf\%[iletype]\s\+\|set\%[local]\s\+\%(ft\|filetype\)=\|call SetFileTypeSH(["'']\%(ba\|k\)\=\%(sh\)\@=\)'
    for line in split(capture, "\n")
      let match = matchlist(line, '^\s*\(\S\+\)\='.setfpattern.'\(\w\+\)')
      if !empty(match)
        call extend(patterns, {match[2]: []}, 'keep')
        call extend(patterns[match[2]], [match[1] ==# '' ? last : match[1]])
      endif
      let last = matchstr(line, '\S.*')
    endfor
    let s:patterns = patterns
  endif
  return copy(get(s:patterns, a:type, []))
endf

fun! indent#detect_indent()
  if index(['help'], &ft) != -1
    return
  endif

  let options = s:scan_indent()
  if type(options) == type([])
    exe 'setl ' . join(options)
  elseif exists('g:default_indent_'.&ft)
    exe g:default_indent_{&ft}
  endif
endf

fun! indent#show()
  let data = s:new_data()
  call s:analyze(getline(1,line('$')), data)
  echo string(data)
  echo string(s:guessoptions(data))
endf

fun! indent#test() abort
  let paths = substitute(escape(&runtimepath, ' '), '\(,\|$\)', '/**\1', 'g')
  let test_base = finddir('indent_test', paths)
  for test in readfile(test_base.'/tests.txt')
    let test = matchstr(test, '^[^#]*')
    if test!~'^\s*$'
      let expected = split(test)
      let file = remove(expected, 0)
      let data = s:new_data()
      call s:analyze(readfile(test_base.'/'.file), data)
      let result = s:guessoptions(data)
      call sort(expected)
      call sort(result)
      if result != expected
        echo 'failed for '.file.': expected='.string(expected).'; result='.string(result).'; data='.string(data)
        return
      endif
    endif
  endfor
  echo 'Success!'
endf

let &cpo = s:keepcpo
unlet s:keepcpo
