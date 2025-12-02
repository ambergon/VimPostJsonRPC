" 必須の変数類
"{{{
if !exists( 'let g:VimPostJsonRPC_ID' )
    let g:VimPostJsonRPC_ID=""
endif
if !exists( 'g:VimPostJsonRPC_PW' )
    let g:VimPostJsonRPC_PW=""
endif
"}}}
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

        vim.command("setl encoding=utf-8")
        vim.command('setl filetype=markdown' )
        vim.command('setl nobuflisted' )
        vim.command('setl buftype=nofile' )
        vim.command("setl bufhidden=delete" )
        vim.command("setl noswapfile")
        # バッファリストにないバッファも補完検索対象とする。
        vim.command("setl complete+=U")
        # vim.command('setl syntax=blogsyntax')

        # バッファが存在しなければ補完バッファを作る。
        flag = 0
        for b in vim.buffers:
            bn = self.PluginName + "AutoComplete"
            if b.name == bn :
                flag = 1
        if flag == 0 :
            self.AutoComplete()


    # }}}
    # 補完に必要な名前を一覧で取得し、隠れたバッファに格納する。
    # {{{
    def AutoComplete( self ):

        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        # 適当に空白を除去する必要がある。
        PAYLOAD[ 'method' ]  = "archiveNames"
        PAYLOAD[ 'params' ]  = {
        }
        headers = {
            "Content-Type": "application/json"
        }
        if self.ID != "" and self.PW != "" :
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) , auth=( self.ID , self.PW ) )
        else:
            response = requests.post( self.URL , headers=headers , data=json.dumps( PAYLOAD ) )

        res = []
        # レスポンスの処理
        if response.status_code == 200:
            try:
                res = response.json()
            except ValueError:
                print( "Response is not a valid JSON" )
                return
        else:
            print( "Request failed with status code:" , response.status_code )
            return

        vim.command( 'let buf = bufadd( "' + self.PluginName + "AutoComplete" + '" )' )
        vim.command( 'call bufload( buf )   ' )
        # vim.command( 'call appendbufline( buf , 0 , "test" )' )
        # {{{
        # # scratch buffer 
        # # 保存しない
        # vim.command( '# :setlocal buftype=nofile' )
        # # バッファを隠す。
        # vim.command( '# :setlocal bufhidden=hide' )
        # # bnextで移動しない。
        # vim.command( '# :setlocal nobuflisted' )
        # # バックアップを取らない。
        # vim.command( '# :setlocal noswapfile' )
        # }}}
        vim.command( 'call setbufvar( buf , "&buftype"   , "nofile" ) ')
        vim.command( 'call setbufvar( buf , "&bufhidden" , "hide" ) ')
        vim.command( 'call setbufvar( buf , "&buflisted" , "0" ) ')
        vim.command( 'call setbufvar( buf , "&swapfile"  , "0" ) ')

        # print( "Response:" , res[ 'result' ] )
        for record in res[ 'result' ]:
            # print( record[ 'name' ] )
            vim.command( 'call appendbufline( buf , 0 , "' + record[ 'name' ] + '" )' )

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
        # print( self.URL )


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
        URL         = vim.current.buffer[6].replace( self.TEMPLATE['URL']     , "" , 1 )
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
            "URL"       : URL      , 
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

        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        if DATE    == "" and PERSONS == "" and TAGS    == "" and TEXT    == "" :
            PAYLOAD[ 'method' ]  = "archiveSearchAll"
            PAYLOAD[ 'params' ] = {}
        else :
            TAGS            = re.sub( r',$' , '' , TAGS )
            TAGS            = re.sub( r'^,' , '' , TAGS )
            PERSONS         = re.sub( r',$' , '' , PERSONS )
            PERSONS         = re.sub( r'^,' , '' , PERSONS )
            tags_array      = TAGS.split( "," )
            persons_array   = PERSONS.split( "," )

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
            # id桁を4桁にする。
            while len( record[ 'id' ] ) < 4:
                record[ 'id' ] = " " + record[ 'id' ]
            text = str( record[ 'id' ] ) + " | " + record[ 'time' ] + " | "
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
    # 指定したIDの記事を表示する。
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
            except ValueError:
                print( "Response is not a valid JSON" )
                return

        else:
            print( "Request failed with status code:" , response.status_code )
            return
        # }}}
        print( "Response:" , res[ 'result' ] )


    # }}}
    # check用のurl_listを表示する。
    # {{{
    def Url( self ):
        PAYLOAD = copy.deepcopy( self.PAYLOAD )
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
            except ValueError:
                print( "Response is not a valid JSON" )
                return

        else:
            print( "Request failed with status code:" , response.status_code )
            return
        # }}}

        self.Buffer( Name="Check" , Style=":sp " )
        # vim.command('map <silent><buffer><enter>   :py3 VimPostJsonRPCInst.GetArchive()<cr>' )
        del vim.current.buffer[:]
        # タイトル要素の最大値を取得する。
        max_title = 0
        for record in res[ 'result' ]:
            n = len( record[ 'title' ] )
            if max_title < n :
                max_title = n
        # vim.current.buffer.append( str( max_title ) )

        for record in res[ 'result' ]:
            # id桁を4桁にする。
            while len( record[ 'id' ] ) < 4:
                record[ 'id' ] = " " + record[ 'id' ]
            vim.current.buffer.append( record[ 'id' ] + " | " + record[ 'stamp' ] + " | " + record[ 'title' ] + " | " + record[ 'url' ] )
        del vim.current.buffer[0]


    # }}}
    # urlを追加する。
    # {{{
    def UrlAdd( self ):
        # 専用のバッファのみで稼働する。 使いまわす。
        bn = self.PluginName + "Template"
        x = vim.current.buffer.name
        if x != bn :
            print( "not buffer")
            return

        URL         = vim.current.buffer[6].replace( self.TEMPLATE['URL']     , "" , 1 )
        TITLE       = vim.current.buffer[8]

        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        PAYLOAD[ 'method' ]  = "archiveUrlAdd"
        PAYLOAD[ 'params' ] = {
            "TITLE" : TITLE ,   
            "URL"   : URL   ,   
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
            except ValueError:
                print( "Response is not a valid JSON" )
                return

        else:
            print( "Request failed with status code:" , response.status_code )
            return
        # }}}
        print( "Response:" , res[ 'result' ] )


    # }}}
    # urlを削除する。
    # {{{
    def UrlRemove( self , ID=""):
        if ID == "" :
            print( "set ID = num " )
            return
        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        PAYLOAD[ 'method' ]  = "archiveUrlRemove"
        PAYLOAD[ 'params' ] = {
            "ID" : ID ,   
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
            except ValueError:
                print( "Response is not a valid JSON" )
                return

        else:
            print( "Request failed with status code:" , response.status_code )
            return
        # }}}
        print( "Response:" , res[ 'result' ] )



    # }}}
    # 現在の行で更新をかける。date欄が空行ならば現在時刻、指定があればそれで更新する。
    # {{{
    def UrlUpdate( self ):
        b = vim.current.line
        a = b.split( "|" )
        if len( a ) <= 1:
            return

        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        PAYLOAD[ 'method' ]  = "archiveUrlUpdate"
        PAYLOAD[ 'params' ] = {
            "ID" : a[0] ,   
            "DATE" : a[1] ,   
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
            except ValueError:
                print( "Response is not a valid JSON" )
                return

        else:
            print( "Request failed with status code:" , response.status_code )
            return
        # }}}
        print( "Response:" , res[ 'result' ] )

        # }}}

    # タグ一覧を表示する。
    # {{{
    def Tags( self ):
        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        PAYLOAD[ 'method' ]  = "archiveTags"
        PAYLOAD[ 'params' ] = {}
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
            except ValueError:
                print( "Response is not a valid JSON" )
                return

        else:
            print( "Request failed with status code:" , response.status_code )
            return
        # }}}

        # print( "Response:" , res)
        self.Buffer( Name="Tags" , Style='sp ' )
        del vim.current.buffer[:]
        for record in res[ 'result' ]:
        #     vim.current.buffer.append( record[ 'id' ] + " | " + record[ 'indent' ] + record[ 'name' ] )
            vim.current.buffer.append( record[ 'id' ] + " | " + record[ 'tree_view' ] )
        del vim.current.buffer[0]
        return 
    # }}}
    # タグに対して親要素を指定する。
    # {{{
    def TagParent( self , parent_id ):
        lines = vim.current.line.split( "|" )
        id = lines[0].replace( " "  , "" )

        # 数値のみ受け付ける。
        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        # 適当に空白を除去する必要がある。
        PAYLOAD[ 'method' ]  = "archiveTagParent"
        PAYLOAD[ 'params' ]  = {
            "ID"        : id , 
            "PARENT_ID" : parent_id, 
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
        print( res[ 'result' ] )
        return
    # }}}





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




























