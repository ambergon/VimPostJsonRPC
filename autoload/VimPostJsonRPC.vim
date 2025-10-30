python3 << EOF
# -*- coding: utf-8 -*-
import vim
import requests
import json
import copy
import re
import threading


# response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , verify=False ) SSL認証をしない場合の処理で、警告が出るのを止める。
"{{{
import urllib3
from urllib3.exceptions import InsecureRequestWarning
urllib3.disable_warnings(InsecureRequestWarning)
"}}}


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
    # 記事投稿用のテンプレートを設置する。
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
        vim.current.buffer.append( self.TEMPLATE['THOUGHTS'] )
        del vim.current.buffer[0]


    # }}}
    # 送信が失敗した際に下書きを復旧する。
    # {{{
    def Retemplate( self , PAYLOAD ):
        vim.command(':sp '   + self.BufferName + "ReArchive" )
        vim.command('setl buftype=nowrite' )
        vim.command("setl encoding=utf-8")
        vim.command('setl filetype=markdown' )
        vim.command("setl bufhidden=delete" )


        del vim.current.buffer[:]
        vim.current.buffer.append( self.TEMPLATE['DONT']                                    )
        vim.current.buffer.append( self.TEMPLATE['ID']       + PAYLOAD[ 'params' ][ 'ID' ]  )
        vim.current.buffer.append( self.TEMPLATE['META']                                    )
        vim.current.buffer.append( self.TEMPLATE['TITLE']    + PAYLOAD[ 'params' ][ 'TITLE' ])
        vim.current.buffer.append( self.TEMPLATE['PERSONS']  + PAYLOAD[ 'params' ][ 'PERSONS' ])
        vim.current.buffer.append( self.TEMPLATE['TAGS']     + PAYLOAD[ 'params' ][ 'TAGS' ])
        vim.current.buffer.append( self.TEMPLATE['DATE']     + PAYLOAD[ 'params' ][ 'DATE' ])
        vim.current.buffer.append( self.TEMPLATE['THOUGHTS']        )
        vim.current.buffer.append( PAYLOAD[ 'params' ][ 'TEXT' ]    )
        del vim.current.buffer[0]
    # }}}
    # 記事を送信する。
    # {{{
    def ThreadPush( self , headers , PAYLOAD ):
        if self.ID != "" and self.PW != "" :
            # print( "ID/PW mode" )
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ) , verify=False )
            print(response.status_code)
        else:
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , verify=False )
            print(response.status_code)

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
            self.Retemplate( PAYLOAD )
            return
        print( "done : "  + str( result[ 'result' ] ) )
        return
    # }}}
    # 記事テンプレートを送信する。
    # {{{
    def PushArchive( self ):
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
        BUFFER      = vim.current.buffer[8:]
        TEXT        = ""
        for line in BUFFER:
            TEXT = TEXT + line + "\n"

        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        # 適当に空白を除去する必要がある。
        PAYLOAD[ 'method' ]  = "archiveAdd"
        PAYLOAD[ 'params' ]  = {
            "ID"        : ID       , 
            "TITLE"     : TITLE    , 
            "PERSONS"   : PERSONS  , 
            "TAGS"      : TAGS     , 
            "DATE"      : DATE     , 
            "TEXT"      : TEXT     , 
        }

        # print( PAYLOAD ) 
        headers = {
            "Content-Type": "application/json"
        }
        # リクエストを送信
        # thread = threading.Thread( target=self.ThreadPush , args=( headers , PAYLOAD ))
        # thread.start()

        if self.ID != "" and self.PW != "" :
            # print( "ID/PW mode" )
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ) , verify=False )
        else:
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , verify=False )

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
    # 検索用のテンプレートを表示する。
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
    # テンプレートを読み込み、検索する。
    # {{{
    def Search( self ):

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
        PAYLOAD[ 'method' ]  = "archiveSearch"
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
        if self.ID != "" and self.PW != "" :
            # print( "ID/PW mode" )
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ) , verify=False )
        else:
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , verify=False )

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
    # コマンドラインから記事を検索する。
    # {{{
    def SearchTags( self , args ):
        if len( args ) == 0 :
            return

        tags_array = args.split( "," )

        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        PAYLOAD[ 'method' ]  = "archiveSearchTag"
        PAYLOAD[ 'params' ] = {
            "TAGS" : tags_array
        }
        headers = {
            "Content-Type": "application/json"
        }
        # リクエストを送信
        if self.ID != "" and self.PW != "" :
            # print( "ID/PW mode" )
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ) , verify=False )
        else:
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , verify=False )

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
    # 他のコマンドから使用する。
    # 現在のカーソル行のIDの記事を読み込む。 
    # {{{
    def GetArchive( self ):
        archive_id = vim.current.line
        archive_id = re.sub( r'\[.*\]' , "" , archive_id )
        # archive_id = re.sub( "\[.*\]" , "" , archive_id )
        archive_id = re.sub( ":.*"    , "" , archive_id )

        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        # 適当に空白を除去する必要がある。
        PAYLOAD[ 'method' ]  = "archiveOpen"
        PAYLOAD[ 'params' ]  = {
            "ID"        : archive_id       , 
        }
        headers = {
            "Content-Type": "application/json"
        }
        # リクエストを送信
        # {{{
        if self.ID != "" and self.PW != "" :
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ) , verify=False )
        else:
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , verify=False )
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
        vim.current.buffer.append( self.TEMPLATE['THOUGHTS'] )
        # vim.current.buffer.append( archive[ 'think' ] )
        for line in archive[ 'think' ].splitlines():
            vim.current.buffer.append( line )
        del vim.current.buffer[0]

    # }}}
    # 指定したIDの記事を削除する。
    # {{{
    def DeleteArchive( self , id ):


        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        # 適当に空白を除去する必要がある。
        PAYLOAD[ 'method' ]  = "deleteArchive"
        PAYLOAD[ 'params' ]  = {
            "ID"        : id       , 
        }
        headers = {
            "Content-Type": "application/json"
        }
        # リクエストを送信
        # {{{
        if self.ID != "" and self.PW != "" :
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ) , verify=False )
        else:
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , verify=False )
        # }}}
        # レスポンスの処理
        result = []
        # {{{
        if response.status_code == 200:
            try:
                result = response.json()
                print( "Response:" , result[ 'result' ] )
            except ValueError:
                print( "Response is not a valid JSON" )
                return

        else:
            print( "Request failed with status code:" , response.status_code )
            return
        # }}}

    # }}}





VimPostJsonRPCInst = PostJsonRPC( vim.eval( "g:VimPostJsonRPC_URL" ) , vim.eval( "g:VimPostJsonRPC_ID" ) , vim.eval( "g:VimPostJsonRPC_PW" ) )
EOF

let s:VimPostJsonRPC = "VimPostJsonRPCInst"
function! VimPostJsonRPC#pycmd( pyfunc )
    let s:x = py3eval( s:VimPostJsonRPC . "." . a:pyfunc )
endfunction




























