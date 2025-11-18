python3 << EOF
# -*- coding: utf-8 -*-
import vim
import requests
import json
import copy
import re
import threading


# response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , verify=False ) SSL認証をしない場合の処理で、警告が出るのを止める。
# import urllib3
# from urllib3.exceptions import InsecureRequestWarning
# urllib3.disable_warnings(InsecureRequestWarning)
# ssl周りのエラーは下記を導入することで解決できる。
# pip install pip-system-certs


class PostJsonRPC:
    PluginName = 'VimPostJsonRPC://'
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
        "PERSONS"   : "PERSONS   :"                 ,
        "TAGS"      : "TAGS      :"                 ,
        "DATE"      : "yyyy-mm-dd:"                 ,
        "URL"       : "URL       :"                 ,
        "TEXT"      : "[TEXT] =====================",
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

    # vim の バッファを作成時のデフォルト処理をまとめる。
    # {{{
    def Buffer( self , Name = "Template" , Style = ":e " ):
        # すでに指定のバッファのウィンドウが存在する。
        win = vim.eval( "bufwinnr('" + self.PluginName + Name + "')" )
        if win == '-1' :
            vim.command( Style + self.PluginName + Name )
        else :
            # 指定のウィンドウに移動
            vim.command( win + 'wincmd w' )

        vim.command('setl buftype=nowrite' )
        vim.command("setl encoding=utf-8")
        vim.command('setl filetype=markdown' )
        vim.command("setl bufhidden=delete" )
        # vim.command('setl syntax=blogsyntax')
    # }}}
    # 記事投稿用のテンプレートを設置する。
    # {{{
    def Template( self , ID = "" , DATES = "" , PERSONS = "" , TAGS = "" , URL = "" , TEXT = "" ):
        self.Buffer()
        del vim.current.buffer[:]
        vim.current.buffer.append( self.TEMPLATE['DONT']                )
        vim.current.buffer.append( self.TEMPLATE['ID']       + ID       )
        vim.current.buffer.append( self.TEMPLATE['META']                )
        vim.current.buffer.append( self.TEMPLATE['DATE']     + DATES    )
        vim.current.buffer.append( self.TEMPLATE['PERSONS']  + PERSONS  )
        vim.current.buffer.append( self.TEMPLATE['TAGS']     + TAGS     )
        vim.current.buffer.append( self.TEMPLATE['URL']      + URL      )
        vim.current.buffer.append( self.TEMPLATE['TEXT']                )
        for line in TEXT.splitlines():
            vim.current.buffer.append( line )
        del vim.current.buffer[0]


    # }}}
    # 記事を送信する。
    # {{{
    def Add( self ):
        bn = self.PluginName + "Template"
        x = vim.current.buffer.name
        if x != bn :
            print( "not buffer")
            return

        ID          = vim.current.buffer[1].replace( self.TEMPLATE['ID']       , "" , 1 )
        DATE        = vim.current.buffer[3].replace( self.TEMPLATE['DATE']     , "" , 1 )
        PERSONS     = vim.current.buffer[4].replace( self.TEMPLATE['PERSONS']  , "" , 1 )
        TAGS        = vim.current.buffer[5].replace( self.TEMPLATE['TAGS']     , "" , 1 )
        BUFFER      = vim.current.buffer[8:]
        TEXT        = ""
        for line in BUFFER:
            TEXT = TEXT + line + "\n"

        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        # 適当に空白を除去する必要がある。
        PAYLOAD[ 'method' ]  = "archiveAdd"
        PAYLOAD[ 'params' ]  = {
            "ID"        : ID       , 
            "DATE"      : DATE     , 
            "PERSONS"   : PERSONS  , 
            "TAGS"      : TAGS     , 
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
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ) )
            # response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ) , verify=False )
        else:
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) )

        res = []
        # レスポンスの処理
        if response.status_code == 200:
            try:
                res = response.json()
                # print( "Response:" , res)
            except ValueError:
                print( "Response is not a valid JSON" )
                return

        else:
            print( "Request failed with status code:" , response.status_code )
            return

        vim.current.buffer[1] = self.TEMPLATE[ 'ID' ] + str( res[ 'result' ][ 'id' ] )
        if 'date' in res[ 'result' ] :
            vim.current.buffer[3] = self.TEMPLATE[ 'DATE' ] + str( res[ 'result' ][ 'date' ] )



    # }}}
    # テンプレートを読み込み、検索する。
    # {{{
    def Search( self ):

        # 現在のバッファーがTemplateじゃなければ終了。
        bn = self.PluginName + "Template"
        x = vim.current.buffer.name
        if x != bn :
            print( "not buffer")
            return


        # ID          = vim.current.buffer[1].replace( self.TEMPLATE['ID']       , "" , 1 )
        DATE        = vim.current.buffer[3].replace( self.TEMPLATE['DATE']     , "" , 1 )
        PERSONS     = vim.current.buffer[4].replace( self.TEMPLATE['PERSONS']  , "" , 1 )
        TAGS        = vim.current.buffer[5].replace( self.TEMPLATE['TAGS']     , "" , 1 )
        BUFFER      = vim.current.buffer[8:]
        # 検索では改行をスペースで区切って検索できるようにしたい。
        TEXT        = ""
        for line in BUFFER:
            TEXT = TEXT + line + ""

        TAGS            = re.sub( r',$' , '' , TAGS )
        TAGS            = re.sub( r'^,' , '' , TAGS )
        PERSONS         = re.sub( r',$' , '' , PERSONS )
        PERSONS         = re.sub( r'^,' , '' , PERSONS )
        tags_array      = TAGS.split( "," )
        persons_array   = PERSONS.split( "," )

        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        PAYLOAD[ 'method' ]  = "archiveSearch"
        PAYLOAD[ 'params' ] = {
            "TAGS"      : tags_array    ,   
            "PERSONS"   : persons_array , 
            "DATES"     : DATE          ,
            "TEXT"      : TEXT          ,
        }
        headers = {
            "Content-Type": "application/json"
        }
        # リクエストを送信
        if self.ID != "" and self.PW != "" :
            # print( "ID/PW mode" )
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ) )
        else:
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) )

        # レスポンスの処理
        res = []
        # {{{
        if response.status_code == 200:
            try:
                res = response.json()
                # print( "Response:" , res)
            except ValueError:
                print( "Response is not a valid JSON" )
                return

        else:
            print( "Request failed with status code:" , response.status_code )
            return
        # }}}

        # print( "Response:" , res)

        self.Buffer( Name="Results" , Style='abo sp ' )
        # vim.command('map <silent><buffer><enter>   :py3 VimPostJsonRPCInst.GetArchive()<cr>' )
        del vim.current.buffer[:]
        for record in res[ 'result' ]:
            text = str( record[ 'id' ] ) + ":" + record[ 'time' ] + ":"
            count = 0
            # print( record[ 'text' ] )
            for line in record[ 'text' ].splitlines():
                if count == 0 :
                    vim.current.buffer.append( text + line )
                    count = 1
                else :
                    vim.current.buffer.append( line )
        del vim.current.buffer[0]


    # }}}
    # 現在のカーソル行のIDの記事を読み込む。 
    # {{{
    def Open( self , id ):



        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        # 適当に空白を除去する必要がある。
        PAYLOAD[ 'method' ]  = "archiveOpen"
        PAYLOAD[ 'params' ]  = {
            "ID"        : id , 
        }
        headers = {
            "Content-Type": "application/json"
        }
        # リクエストを送信
        # {{{
        if self.ID != "" and self.PW != "" :
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ) )
        else:
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) )
        # }}}
        # レスポンスの処理
        res = []
        # {{{
        if response.status_code == 200:
            try:
                res = response.json()
            except ValueError:
                print( "Response is not a valid JSON" )
                return

        else:
            print( "Request failed with status code:" , response.status_code )
            return
        # }}}

        archive = res[ 'result' ]
        self.Template(
            ID      = str( archive[ 'id' ] ) ,
            TEXT    = archive[ 'text' ]      if archive [ 'text' ]     is not None else '' , 
            URL     = archive[ 'url' ]       if archive [ 'url' ]      is not None else '' , 
            DATES   = archive[ 'dates' ]     if archive [ 'dates' ]    is not None else '' , 
            TAGS    = archive[ 'tags' ]      if archive [ 'tags' ]     is not None else '' , 
            PERSONS = archive[ 'persons' ]   if archive [ 'persons' ]  is not None else '' , 
        )

    # }}}
    # 指定したIDの記事を削除する。
    # {{{
    def Delete( self , id ):
        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        # 適当に空白を除去する必要がある。
        PAYLOAD[ 'method' ]  = "archiveDelete"
        PAYLOAD[ 'params' ]  = {
            "ID"        : id       , 
        }
        headers = {
            "Content-Type": "application/json"
        }
        # リクエストを送信
        # {{{
        if self.ID != "" and self.PW != "" :
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ) )
        else:
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) )
        # }}}
        # レスポンスの処理
        res = []
        # {{{
        if response.status_code == 200:
            try:
                res = response.json()
                print( "Response:" , res[ 'result' ] )
            except ValueError:
                print( "Response is not a valid JSON" )
                return

        else:
            print( "Request failed with status code:" , response.status_code )
            return
        # }}}

    # }}}

    # check用のurl_listを表示する。
    def Url( self ):
        PAYLOAD[ 'method' ]  = "archiveUrl"
        PAYLOAD[ 'params' ] = {
            # "TAGS"      : tags_array    ,   
        }
        headers = {
            "Content-Type": "application/json"
        }
        # リクエストを送信
        if self.ID != "" and self.PW != "" :
            # print( "ID/PW mode" )
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ) )
        else:
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) )

        # レスポンスの処理
        res = []
        # {{{
        if response.status_code == 200:
            try:
                res = response.json()
                # print( "Response:" , res)
            except ValueError:
                print( "Response is not a valid JSON" )
                return

        else:
            print( "Request failed with status code:" , response.status_code )
            return
        # }}}

        self.Buffer( Name="Check" )
        # vim.command('map <silent><buffer><enter>   :py3 VimPostJsonRPCInst.GetArchive()<cr>' )
        del vim.current.buffer[:]
        for record in res[ 'result' ]:
            vim.current.buffer.append( str( record[ 'id' ] ) + ":" + record[ 'stamp' ] + ":" + record[ 'title' ] + ":" + record[ 'url' ] )
        del vim.current.buffer[0]

    def UrlAdd( self , TITLE="" , URL="" ):
        if TITLE == "" or URL == "" :
            print( "set 2 args" )
            return
        print( TITLE + ":" + URL )

    def UrlRemove( self , ID ):
        print( ID )






    # # コマンドラインから記事を検索する。
    # # {{{
    # def SearchTags( self , args ):
    #     if len( args ) == 0 :
    #         return

    #     tags_array = args.split( "," )

    #     PAYLOAD = copy.deepcopy( self.PAYLOAD )
    #     PAYLOAD[ 'method' ]  = "archiveSearchTag"
    #     PAYLOAD[ 'params' ] = {
    #         "TAGS" : tags_array
    #     }
    #     headers = {
    #         "Content-Type": "application/json"
    #     }
    #     # リクエストを送信
    #     if self.ID != "" and self.PW != "" :
    #         # print( "ID/PW mode" )
    #         response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ) )
    #     else:
    #         response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) )

    #     # レスポンスの処理
    #     res = []
    #     # {{{
    #     if response.status_code == 200:
    #         try:
    #             res = response.json()
    #             # print( "Response:" , res)
    #         except ValueError:
    #             print( "Response is not a valid JSON" )
    #             return

    #     else:
    #         print( "Request failed with status code:" , response.status_code )
    #         return
    #     # }}}

    #     # print( "Response:" , res)
    #     vim.command(':e '   + self.PluginName + "Results" )
    #     vim.command('setl buftype=nowrite' )
    #     vim.command('setl encoding=utf-8')
    #     vim.command('setl filetype=markdown' )
    #     vim.command('setl bufhidden=delete' )
    #     vim.command('map <silent><buffer><enter>   :py3 VimPostJsonRPCInst.GetArchive()<cr>' )
    #     del vim.current.buffer[:]
    #     for record in res[ 'result' ]:
    #         vim.current.buffer.append( "[" + record[ 'time' ] + "]" + str( record[ 'id' ] )  + ":" + record[ 'title' ] )
    #     del vim.current.buffer[0]




    # # }}}
    # # 記事を送信する。
    # # {{{
    # def ThreadPush( self , headers , PAYLOAD ):
    #     if self.ID != "" and self.PW != "" :
    #         # print( "ID/PW mode" )
    #         response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ) , verify=False )
    #         print(response.status_code)
    #     else:
    #         response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , verify=False )
    #         print(response.status_code)

    #     res = []
    #     # レスポンスの処理
    #     if response.status_code == 200:
    #         try:
    #             res = response.json()
    #             # print( "Response:" , res)
    #         except ValueError:
    #             print( "Response is not a valid JSON" )
    #             return

    #     else:
    #         print( "Request failed with status code:" , response.status_code )
    #         self.Retemplate( PAYLOAD )
    #         return
    #     print( "done : "  + str( result[ 'result' ] ) )
    #     return
    # # }}}



VimPostJsonRPCInst = PostJsonRPC( vim.eval( "g:VimPostJsonRPC_URL" ) , vim.eval( "g:VimPostJsonRPC_ID" ) , vim.eval( "g:VimPostJsonRPC_PW" ) )
EOF

let s:VimPostJsonRPC = "VimPostJsonRPCInst"
function! VimPostJsonRPC#pycmd( pyfunc )
    let s:x = py3eval( s:VimPostJsonRPC . "." . a:pyfunc )
endfunction




























