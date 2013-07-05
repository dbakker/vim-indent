if !exists('g:autodetectindent') || g:autodetectindent!=0
  aug detectIndent
    autocmd!
    autocmd FileType * call indent#detect_indent()
  aug END
endif

