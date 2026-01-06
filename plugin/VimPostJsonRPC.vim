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



command! -nargs=0 Archive               call VimPostJsonRPC#pycmd('Template()')
augroup VimPostJsonRPC
    autocmd!

    " :w を ArchiveAdd に変更
    autocmd BufEnter VimPostJsonRPC://Template cabbrev w W
    autocmd BufLeave VimPostJsonRPC://Template cunabbrev w
    autocmd BufEnter VimPostJsonRPC://Template command! -buffer -nargs=0 W                  call VimPostJsonRPC#pycmd('Add()')
    " autocmd BufEnter VimPostJsonRPC://Template command! -buffer -nargs=0 ArchiveAdd         call VimPostJsonRPC#pycmd('Add()')
    autocmd BufEnter VimPostJsonRPC://Template command! -buffer -nargs=0 ArchiveSearch      call VimPostJsonRPC#pycmd('Search()')
    autocmd BufEnter VimPostJsonRPC://Template command! -buffer -nargs=0 ArchiveUrl         call VimPostJsonRPC#pycmd('Url()')
    autocmd BufEnter VimPostJsonRPC://Template command! -buffer -nargs=0 ArchiveUrlAdd      call VimPostJsonRPC#pycmd('UrlAdd(<f-args>)')
    autocmd BufEnter VimPostJsonRPC://Results  command! -buffer -nargs=1 ArchiveRemove      call VimPostJsonRPC#pycmd('Delete(<args>)')
    " autocmd BufEnter VimPostJsonRPC://Results  command! -buffer -nargs=1 ArchiveOpen        call VimPostJsonRPC#pycmd('Open(<args>)')
    autocmd BufEnter VimPostJsonRPC://Check    command! -buffer -nargs=0 ArchiveUrlUpdate   call VimPostJsonRPC#pycmd('UrlUpdate(<args>)')
    autocmd BufEnter VimPostJsonRPC://Check    command! -buffer -nargs=1 ArchiveUrlRemove   call VimPostJsonRPC#pycmd('UrlRemove(<args>)')
    autocmd BufEnter VimPostJsonRPC://Template command! -buffer -nargs=0 ArchiveTags        call VimPostJsonRPC#pycmd('Tags()')

    autocmd BufEnter VimPostJsonRPC://Tags     command! -buffer -nargs=0 Tags               call VimPostJsonRPC#pycmd('Tags()')
    autocmd BufEnter VimPostJsonRPC://Tags     command! -buffer -nargs=1 Parent             call VimPostJsonRPC#pycmd('TagParent(<args>)')
    autocmd BufEnter VimPostJsonRPC://Tags     command! -buffer -nargs=1 Delete             call VimPostJsonRPC#pycmd('TagDelete(<args>)')
    autocmd BufEnter VimPostJsonRPC://Tags     command! -buffer -nargs=1 Rename             call VimPostJsonRPC#pycmd('TagRename(<f-args>)')

    "" 初回ハイライトが機能しない問題がある。
    "" 検索結果のハイライト
    " 赤:重要な事件
    " 黄:未来の予定
    " 緑:行動しないといけない。購入など かかわる必要のあるもの。
    autocmd BufEnter VimPostJsonRPC://Results highlight archiveRed ctermfg=Red    guifg=Red
    autocmd BufEnter VimPostJsonRPC://Results highlight archiveYel ctermfg=yellow guifg=yellow
    autocmd BufEnter VimPostJsonRPC://Results highlight archiveGre ctermfg=green  guifg=green
    autocmd BufEnter VimPostJsonRPC://Results syntax match archiveRed /^[0-9 |-]*!.*$/
    autocmd BufEnter VimPostJsonRPC://Results syntax match archiveYel /^[0-9 |-]*?.*$/
    autocmd BufEnter VimPostJsonRPC://Results syntax match archiveGre /^[0-9 |-]*#.*$/
augroup END





















