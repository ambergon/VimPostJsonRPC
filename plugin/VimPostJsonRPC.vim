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
command! -nargs=0 Rpc               call VimPostJsonRPC#pycmd('Template(<f-args>)')
command! -nargs=0 RpcPush           call VimPostJsonRPC#pycmd('PushArchive(<f-args>)')
command! -nargs=0 RpcSearch         call VimPostJsonRPC#pycmd('SearchTemplate()')
command! -nargs=0 RpcSearchPush     call VimPostJsonRPC#pycmd('Search()')
" command! -nargs=1 RpcSearchTags     call VimPostJsonRPC#pycmd('SearchTags(<q-args>)')
command! -nargs=1 RpcDelete         call VimPostJsonRPC#pycmd('DeleteArchive(<args>)')




















