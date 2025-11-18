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
command! -nargs=0 ArchiveAdd            call VimPostJsonRPC#pycmd('Add()')
command! -nargs=0 ArchiveSearch         call VimPostJsonRPC#pycmd('Search()')
command! -nargs=1 ArchiveOpen           call VimPostJsonRPC#pycmd('Open(<args>)')
command! -nargs=1 ArchiveRemove         call VimPostJsonRPC#pycmd('Delete(<args>)')

" 特定のbufferでだけ読み込めると楽なんだけど。
command! -nargs=0 CheckUrl            call VimPostJsonRPC#pycmd('Url()')
command! -nargs=+ CheckUrlAdd         call VimPostJsonRPC#pycmd('UrlAdd(<f-args>)')
command! -nargs=1 CheckUrlRemove      call VimPostJsonRPC#pycmd('UrlRemove(<args>)')
" command! -nargs=0 ArchiveSearch         call VimPostJsonRPC#pycmd('SearchTemplate()')
" command! -nargs=1 RpcSearchTags     call VimPostJsonRPC#pycmd('SearchTags(<q-args>)')




















