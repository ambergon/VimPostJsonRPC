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



" command! -nargs=* Rpc           call VimPostJsonRPC#pycmd('Other(<f-args>)')
" command! -nargs=* Rpc           call VimPostJsonRPC#pycmd('Send(<f-args>)')
command! -nargs=* RpcTemplate   call VimPostJsonRPC#pycmd('Template(<f-args>)')
command! -nargs=* RpcSendAchive call VimPostJsonRPC#pycmd('SendArchive(<f-args>)')
command! -nargs=1 RpcSearchTags call VimPostJsonRPC#pycmd('SearchTags(<q-args>)')
" command! -nargs=0                                                       RPC   call VimPostJsonRPC#pycmd('Send(<f-args>)')
" command! -nargs=? -complete=customlist,VimMarkdownWordpress#CompSave    BlogSave   call VimMarkdownWordpress#pycmd('BlogSave(<f-args>)')
" 
" command! -nargs=0                                                       BlogNew    call VimMarkdownWordpress#pycmd('BlogTemplate()')
" command! -nargs=1                                                       BlogOpen   call VimMarkdownWordpress#pycmd('BlogOpen(<f-args>)')
" "command! -nargs=1 -complete=customlist,CompSwitch                       BlogSwitch call VimMarkdownWordpress#pycmd('readConfig(<f-args>)')
" "command! -nargs=1 -complete=file                                        BlogUpload call VimMarkdownWordpress#pycmd('blogPictureUploadCheck(<f-args>)')
" command! -nargs=0                                                       BlogTest   call VimMarkdownWordpress#pycmd('BlogTest(<f-args>)')
" command! -nargs=1 -complete=file                                        BlogMedia  call VimMarkdownWordpress#pycmd('BlogMedia(<f-args>)')

