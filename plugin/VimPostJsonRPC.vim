if !has("python3")
    finish
endif
" if exists('g:loaded_VimPostJsonRPC')
"     finish
" endif
" let g:loaded_VimPostJsonRPC= 1



" function! VimMarkdownWordpress#CompSave(lead, line, pos )
"     let l:matches = []
"     for file in [ "publish" , "Publish" , "draft" , "Draft" ]
"         if file =~? '^' . strpart(a:lead,0)
"             echo add(l:matches,file)
"         endif
"     endfor
"     return l:matches
" endfunction



" command! -nargs=* Rpc           call VimPostJsonRPC#pycmd('Send(<f-args>)')
command! -nargs=0 Archive               call VimPostJsonRPC#pycmd('Template()')
augroup VimPostJsonRPC
    autocmd!
    autocmd BufEnter VimPostJsonRPC://Template command! -buffer -nargs=0 ArchiveAdd           call VimPostJsonRPC#pycmd('Add()')
    autocmd BufEnter VimPostJsonRPC://Template command! -buffer -nargs=0 ArchiveSearch        call VimPostJsonRPC#pycmd('Search()')
    autocmd BufEnter VimPostJsonRPC://Template command! -buffer -nargs=1 ArchiveRemove        call VimPostJsonRPC#pycmd('Delete(<args>)')
    autocmd BufEnter VimPostJsonRPC://Template command! -buffer -nargs=0 ArchiveUrl           call VimPostJsonRPC#pycmd('Url()')
    autocmd BufEnter VimPostJsonRPC://Template command! -buffer -nargs=0 ArchiveUrlAdd        call VimPostJsonRPC#pycmd('UrlAdd(<f-args>)')
    autocmd BufEnter VimPostJsonRPC://Results  command! -buffer -nargs=1 ArchiveOpen          call VimPostJsonRPC#pycmd('Open(<args>)')
    autocmd BufEnter VimPostJsonRPC://Check    command! -buffer -nargs=0 ArchiveUrlUpdate     call VimPostJsonRPC#pycmd('UrlUpdate(<args>)')
    autocmd BufEnter VimPostJsonRPC://Check    command! -buffer -nargs=1 ArchiveUrlRemove     call VimPostJsonRPC#pycmd('UrlRemove(<args>)')
augroup END






















