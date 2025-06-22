" 設定が必要な項目
let g:VimPostJsonRPC_URL="http://localhost:8080/index.php"
let g:VimPostJsonRPC_ID=""
let g:VimPostJsonRPC_PW=""
python3 << EOF
# -*- coding: utf-8 -*-
import vim
import requests
import json
import copy
import re

class PostJsonRPC:
    BufferName = 'VimPostJsonRPC://'
    #BlogListNum         = 100
    URL = ""
    ID  = ""
    PW  = ""

    # Title           :タイトル
    # PERSONS         :人(カンマ区切り)
    # Tags            :タグ(カンマ区切り)
    # この記事が書かれた時期 : yyyymmdd


    TEMPLATE = {
        "DONT"      : "[Dont Touch] ===============",
        "ID"        : "ID        :"                 ,
        "META"      : "[Meta] =====================",
        "TITLE"     : "Title     :"                 ,
        "PERSONS"   : "PERSONS   :"                 ,
        "TAGS"      : "Tags      :"                 ,
        "DATE"      : "yyyy-mm-dd:"                 ,
        "URL"       : "Default   :"                 ,
        "PRIVATE"   : "Private   :"                 ,
        "PUBLIC"    : "Public    :"                 ,
        "THOUGHTS"  : "[Thoughts] =================",
    }
    SEARCH = {
        "TITLE"     : "Title     :"                 ,
        "PERSONS"   : "PERSONS   :"                 ,
        "TAGS"      : "Tags      :"                 ,
        "SINCE"     : "yyyy-mm-dd:"                 ,
        "UNTIL"     : "yyyy-mm-dd:"                 ,
    }

    # JSON-RPC
    PAYLOAD = {
            "jsonrpc"   : "2.0",
            "id"        : 1,
    }



    # {{{
    def __init__( self , URL , ID , PW ):
        self.URL = URL
        self.ID  = ID
        self.PW  = PW
    # }}}
    # {{{
    def Template( self ):
        vim.command( ':e '   + self.BufferName + "Archive" )
        # #新しいファイルを開く
        # if( PostID == "" ):
        # else:
        #     vim.command( ':e '   + self.BufferName + str(PostID) )

        vim.command('setl buftype=nowrite' )
        vim.command("setl encoding=utf-8")
        vim.command('setl filetype=markdown' )
        vim.command("setl bufhidden=delete" )
        # plugin側にsyntaxを入れてた名残
        # vim.command('setl syntax=blogsyntax')

        del vim.current.buffer[:]
        vim.current.buffer.append( self.TEMPLATE['DONT']     )
        vim.current.buffer.append( self.TEMPLATE['ID']       )
        vim.current.buffer.append( self.TEMPLATE['META']     )
        vim.current.buffer.append( self.TEMPLATE['TITLE']    )
        vim.current.buffer.append( self.TEMPLATE['PERSONS']  )
        vim.current.buffer.append( self.TEMPLATE['TAGS']     )
        vim.current.buffer.append( self.TEMPLATE['DATE']     )
        vim.current.buffer.append( self.TEMPLATE['URL']      )
        vim.current.buffer.append( self.TEMPLATE['PRIVATE']  )
        vim.current.buffer.append( self.TEMPLATE['PUBLIC']   )
        vim.current.buffer.append( self.TEMPLATE['THOUGHTS'] )
        del vim.current.buffer[0]


    # }}}
    # {{{
    def SendArchive( self ):
        bn = self.BufferName + "Archive"
        x = vim.current.buffer.name
        if x != bn :
            print( "not buffer")
            return

        ID          = vim.current.buffer[1].replace( self.TEMPLATE['ID']       , "" , 1 )
        TITLE       = vim.current.buffer[3].replace( self.TEMPLATE['TITLE']    , "" , 1 )
        PERSONS     = vim.current.buffer[4].replace( self.TEMPLATE['PERSONS']  , "" , 1 )
        TAGS        = vim.current.buffer[5].replace( self.TEMPLATE['TAGS']     , "" , 1 )
        DATE        = vim.current.buffer[6].replace( self.TEMPLATE['DATE']     , "" , 1 )
        URL         = vim.current.buffer[7].replace( self.TEMPLATE['URL']      , "" , 1 )
        PRIVATE     = vim.current.buffer[8].replace( self.TEMPLATE['PRIVATE']  , "" , 1 )
        PUBLIC      = vim.current.buffer[9].replace( self.TEMPLATE['PUBLIC']   , "" , 1 )
        BUFFER      = vim.current.buffer[11:]
        TEXT        = ""
        for line in BUFFER:
            TEXT = TEXT + line + "\n"

        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        # 適当に空白を除去する必要がある。
        PAYLOAD[ 'method' ]  = "AddArchive"
        PAYLOAD[ 'params' ]  = {
            "ID"        : ID       , 
            "TITLE"     : TITLE    , 
            "PERSONS"   : PERSONS  , 
            "TAGS"      : TAGS     , 
            "DATE"      : DATE     , 
            "URL"       : URL      , 
            "PRIVATE"   : PRIVATE  , 
            "PUBLIC"    : PUBLIC   , 
            "TEXT"      : TEXT     , 
        }

        # print( PAYLOAD ) 
        headers = {
            "Content-Type": "application/json"
        }
        # リクエストを送信
        response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) )
        if self.ID != "" and self.PW != "" :
            # print( "ID/PW mode" )
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ))

        result = []
        # レスポンスの処理
        if response.status_code == 200:
            try:
                result = response.json()
                # print( "Response:" , result )
            except ValueError:
                print( "Response is not a valid JSON" )
                return

        else:
            print( "Request failed with status code:" , response.status_code )
            return

        vim.current.buffer[1] = self.TEMPLATE[ 'ID' ] + str( result[ 'result' ] )


    # }}}
    # {{{
    def SearchTemplate( self ):
        vim.command(':e '   + self.BufferName + "Search" )
        vim.command('setl buftype=nowrite' )
        vim.command('setl encoding=utf-8')
        vim.command('setl filetype=markdown' )
        vim.command('setl bufhidden=delete' )

        del vim.current.buffer[:]
        vim.current.buffer.append( self.SEARCH["TITLE"  ]          )
        vim.current.buffer.append( self.SEARCH["PERSONS"]          )
        vim.current.buffer.append( self.SEARCH["TAGS"   ]          )
        vim.current.buffer.append( self.SEARCH["SINCE"  ]          )
        vim.current.buffer.append( self.SEARCH["UNTIL"  ]          )
        del vim.current.buffer[0]

    # }}}
    # {{{
    def Search( self ):
#        # {{{
#        # テスト
#        PAYLOAD = copy.deepcopy( self.PAYLOAD )
#        PAYLOAD[ 'method' ]  = "Search"
#        PAYLOAD[ 'params' ] = {
#        }
#        headers = {
#            "Content-Type": "application/json"
#        }
#        # リクエストを送信
#        response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) )
#        if self.ID != "" and self.PW != "" :
#            # print( "ID/PW mode" )
#            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ))
#
#        # レスポンスの処理
#        result = []
#        # {{{
#        if response.status_code == 200:
#            try:
#                result = response.json()
#            except ValueError:
#                print( "Response is not a valid JSON" )
#                return
#
#        else:
#            print( "Request failed with status code:" , response.status_code )
#            return
#        # }}}
#        return 
#        # }}}









        bn = self.BufferName + "Search"
        x = vim.current.buffer.name
        if x != bn :
            print( "not buffer")
            return

        TITLE       = vim.current.buffer[0].replace( self.SEARCH["TITLE"  ] , "" , 1 )
        PERSONS     = vim.current.buffer[1].replace( self.SEARCH["PERSONS"] , "" , 1 )
        TAGS        = vim.current.buffer[2].replace( self.SEARCH["TAGS"   ] , "" , 1 )
        SINCE       = vim.current.buffer[3].replace( self.SEARCH["SINCE"  ] , "" , 1 )
        UNTIL       = vim.current.buffer[4].replace( self.SEARCH["UNTIL"  ] , "" , 1 )

        TAGS            = re.sub( r',$' , '' , TAGS )
        TAGS            = re.sub( r'^,' , '' , TAGS )
        PERSONS         = re.sub( r',$' , '' , PERSONS )
        PERSONS         = re.sub( r'^,' , '' , PERSONS )
        tags_array      = TAGS.split( "," )
        persons_array   = PERSONS.split( "," )

        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        PAYLOAD[ 'method' ]  = "Search"
        PAYLOAD[ 'params' ] = {
            "TITLE"     : TITLE         ,
            "TAGS"      : tags_array    ,   
            "PERSONS"   : persons_array , 
            "START"     : SINCE         ,
            "END"       : UNTIL         ,
        }
        headers = {
            "Content-Type": "application/json"
        }
        # リクエストを送信
        response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) )
        if self.ID != "" and self.PW != "" :
            # print( "ID/PW mode" )
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ))

        # レスポンスの処理
        result = []
        # {{{
        if response.status_code == 200:
            try:
                result = response.json()
                # print( "Response:" , result )
            except ValueError:
                print( "Response is not a valid JSON" )
                return

        else:
            print( "Request failed with status code:" , response.status_code )
            return
        # }}}

        print( "Response:" , result )
        vim.command(':e '   + self.BufferName + "Results" )
        vim.command('setl buftype=nowrite' )
        vim.command('setl encoding=utf-8')
        vim.command('setl filetype=markdown' )
        vim.command('setl bufhidden=delete' )
        vim.command('map <silent><buffer><enter>   :py3 VimPostJsonRPCInst.GetArchive()<cr>' )
        del vim.current.buffer[:]
        for record in result[ 'result' ]:
            vim.current.buffer.append( "[" + record[ 'time' ] + "]" + str( record[ 'id' ] )  + ":" + record[ 'title' ] )
        del vim.current.buffer[0]


    # }}}
    # {{{
    def SearchTags( self , args ):
        if len( args ) == 0 :
            return

        tags_array = args.split( "," )

        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        PAYLOAD[ 'method' ]  = "SearchTags"
        PAYLOAD[ 'params' ] = {
            "TAGS" : tags_array
        }
        headers = {
            "Content-Type": "application/json"
        }
        # リクエストを送信
        response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) )
        if self.ID != "" and self.PW != "" :
            # print( "ID/PW mode" )
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ))

        # レスポンスの処理
        result = []
        # {{{
        if response.status_code == 200:
            try:
                result = response.json()
                # print( "Response:" , result )
            except ValueError:
                print( "Response is not a valid JSON" )
                return

        else:
            print( "Request failed with status code:" , response.status_code )
            return
        # }}}

        # print( "Response:" , result )
        vim.command(':e '   + self.BufferName + "Results" )
        vim.command('setl buftype=nowrite' )
        vim.command('setl encoding=utf-8')
        vim.command('setl filetype=markdown' )
        vim.command('setl bufhidden=delete' )
        vim.command('map <silent><buffer><enter>   :py3 VimPostJsonRPCInst.GetArchive()<cr>' )
        del vim.current.buffer[:]
        for record in result[ 'result' ]:
            vim.current.buffer.append( "[" + record[ 'time' ] + "]" + str( record[ 'id' ] )  + ":" + record[ 'title' ] )
        del vim.current.buffer[0]




    # }}}
    # {{{
    def GetArchive( self ):
        archive_id = vim.current.line
        archive_id = re.sub( r'\[.*\]' , "" , archive_id )
        # archive_id = re.sub( "\[.*\]" , "" , archive_id )
        archive_id = re.sub( ":.*"    , "" , archive_id )

        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        # 適当に空白を除去する必要がある。
        PAYLOAD[ 'method' ]  = "GetArchive"
        PAYLOAD[ 'params' ]  = {
            "ID"        : archive_id       , 
        }
        headers = {
            "Content-Type": "application/json"
        }
        # リクエストを送信
        # {{{
        response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) )
        if self.ID != "" and self.PW != "" :
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ))
        # }}}
        # レスポンスの処理
        result = []
        # {{{
        if response.status_code == 200:
            try:
                result = response.json()
            except ValueError:
                print( "Response is not a valid JSON" )
                return

        else:
            print( "Request failed with status code:" , response.status_code )
            return
        # }}}

        archive = result[ 'result' ]
        # print( archive )
        vim.command(':e '   + self.BufferName + "Archive" )
        vim.command('setl buftype=nowrite' )
        vim.command('setl encoding=utf-8')
        vim.command('setl filetype=markdown' )
        vim.command('setl bufhidden=delete' )
        del vim.current.buffer[:]
        vim.current.buffer.append( self.TEMPLATE['DONT']     )
        vim.current.buffer.append( self.TEMPLATE['ID']       + archive[ 'id' ] )
        vim.current.buffer.append( self.TEMPLATE['META']     )
        vim.current.buffer.append( self.TEMPLATE['TITLE']    + archive[ 'title' ] )
        vim.current.buffer.append( self.TEMPLATE['PERSONS']  + archive[ 'persons' ] )
        vim.current.buffer.append( self.TEMPLATE['TAGS']     + archive[ 'tags' ] )
        vim.current.buffer.append( self.TEMPLATE['DATE']     + archive[ 'date' ] )
        vim.current.buffer.append( self.TEMPLATE['URL']      + archive[ 'url' ] )
        vim.current.buffer.append( self.TEMPLATE['PRIVATE']  + archive[ 'private' ] )
        vim.current.buffer.append( self.TEMPLATE['PUBLIC']   + archive[ 'public' ] )
        vim.current.buffer.append( self.TEMPLATE['THOUGHTS'] )
        # vim.current.buffer.append( archive[ 'think' ] )
        for line in archive[ 'think' ].splitlines():
            vim.current.buffer.append( line )
        del vim.current.buffer[0]

    # }}}





VimPostJsonRPCInst = PostJsonRPC( vim.eval( "g:VimPostJsonRPC_URL" ) , vim.eval( "g:VimPostJsonRPC_ID" ) , vim.eval( "g:VimPostJsonRPC_PW" ) )
EOF

let s:VimPostJsonRPC = "VimPostJsonRPCInst"
function! VimPostJsonRPC#pycmd( pyfunc )
    let s:x = py3eval( s:VimPostJsonRPC . "." . a:pyfunc )
endfunction




























