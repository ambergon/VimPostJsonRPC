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

# "{{{
# class PythonClass:
#     BufferName = 'VimPostJsonRPC:/'
#     BlogListNum         = 100
#     def __init__( self ):
#         ConfigPath = os.path.expanduser("~") + "/" + ".VimPostJsonRPC"
# 
#         if not os.path.exists( ConfigPath ):
#             WriteConfig( ConfigPath )
# 
#         Config = ConfigParser()
#         Config.read( ConfigPath )
#         CoreSection = ConfigParser()
#         CoreSection = Config[ "core" ]
# 
#         ##BlogList
#         self.BlogListNum    = CoreSection[ "BlogListNum" ]
# 
#     #設定ファイルが存在しなければ。
#     def WriteConfig( self , ConfigPath ):
#         config = ConfigParser()
#         config["core"] = { 
#                 "MarkdownExtension"  : "extra,nl2br,"   ,
#                 "BlogListNum"        : "100"            ,
#                 "SetFileType"        : "markdown"       ,
#                 }
#         config["main"] = { 
#                 "user"      : "user_name"           ,
#                 "password"  : "wordpress_password"  ,
#                 "url"       : "https://localhost:8080/index.php" ,
#                 }
#         with open( ConfigPath , "w" ) as ConfigText:
#             config.write( ConfigText )
# 
# 
#     def BlogTemplate( self , PostID = "" , FieldID = "" , TITLE = "" , CATE = "" , TAG = "" , FieldText = ""):
#         #新しいファイルを開く
#         if( PostID == "" ):
#             vim.command( ':e '   + self.BufferName + "NewPost" )
#         else:
#             vim.command( ':e '   + self.BufferName + str(PostID) )
# 
#         vim.command('setl buftype=nowrite' )
#         vim.command("setl encoding=utf-8")
#         vim.command('setl syntax=blogsyntax')
#         vim.command('setl filetype=' + self.FileType )
# 
#         del vim.current.buffer[:]
#         vim.current.buffer.append( self.META_ME                             )
#         vim.current.buffer.append( self.META_ID              + str(PostID)  )
#         vim.current.buffer.append( self.META_CUSTOM_FIELD_ID + FieldID      )
#         vim.current.buffer.append( self.META_YOU                            )
#         vim.current.buffer.append( self.META_TITLE           + TITLE        )
#         vim.current.buffer.append( self.META_CATEGORY        + CATE         )
#         vim.current.buffer.append( self.META_TAGS            + TAG          )
#         vim.current.buffer.append( self.META_END                            )
#         #送られてきたテキストがあれば追加。
#         for line in FieldText :
#             #文末の空白を除去
#             line = re.sub( ' +$' , '' , line )
#             vim.current.buffer.append( line )
# 
#         del vim.current.buffer[0]
#         return
# 
# 
#     def BlogList( self ):
#         args  = { "number" : self.BlogListNum , "offset" : 0 , }
#         Posts = self.wp.call( GetPosts ( args ))
# 
#         vim.command( ":e " + self.BufferName + "List" )
#         #vim.command( ":vs " + self.BufferName + "List" )
# 
#         #bufferが隠れたら削除
#         vim.command( "setl bufhidden=delete" )
#         #削除時に保存するか聞かない
#         vim.command( "setl buftype=nowrite" )
#         vim.command( "map <silent><buffer><enter>   :py3 VimPostJsonRPCInst.BlogOpen()<cr>" )
#         #下記の形式でバッファに書き出す。
#         #ID [publish] TITLE
#         for Post in Posts:
#             vim.current.buffer.append( Post.id + " [" + Post.post_status + "] " + Post.title )
# 
#         #一行目を削除
#         del vim.current.buffer[0]
#         #規定の行を末尾に。
#         #これをenterしたときにさらに読み込めるように。
#         vim.current.buffer.append( self.MoreList )
# 
# 
#     def BlogListAdd( self ):
#         #現在の行数分、最新投稿を取り除く。
#         offset = len( vim.current.buffer ) - 1
#         BlogArgs = { "number" : self.BlogListNum , "offset" : offset }
#         Posts = self.wp.call(GetPosts( BlogArgs ))
#         #List追加
#         for Post in Posts:
#             vim.current.buffer.append( Post.id + ' [' + Post.post_status + '] ' + Post.title )
#         #最後の行/MoreListを削除
#         del vim.current.buffer[offset]
#         vim.current.buffer.append( self.MoreList )
# 
# 
#     def BlogOpen( self , PostID = 0 ):
#         #Listの再読み込み
#         #BlogListBuffer && current.line MoreList
#         if( PostID == 0 and vim.current.line == self.MoreList ):
#             self.BlogListAdd()
#             return
#             
#         #BlogListBuffer && IDから始まる行。
#         if( PostID == 0):
#             line = vim.current.line.split()
#             #空白行処理
#             if( len( line ) == 0 ):
#                 print( 'line is none' )
#                 return
#             PostID = line[0]
#         Post = self.wp.call( GetPost( PostID ) )
# 
#         #custom_fieldが存在しない場合
#         if( len( Post.custom_fields ) == 0 ):
#             print( 'not wiritten by this plugin' )
#             return
# 
#         #CustomField一覧をチェック
#         for CustomField in Post.custom_fields:
#             #key = mkd_textが存在する
#             if( self.CUSTOM_FIELD_KEY in CustomField.values() ):
#                 #新しいファイルを開く
#                 vim.command( ':e '   + self.BufferName + str( PostID ))
#                 del vim.current.buffer[:]
# 
#                 #削除時に保存するか聞かない
#                 vim.command( "setl buftype=nowrite"           )
#                 vim.command( "setl encoding=utf-8"            )
#                 vim.command( "setl syntax=blogsyntax"         )
#                 vim.command( "setl filetype=" + self.FileType )
# 
#                 ##WPは内部的にカテゴリとタグを混同していたような気がする。
#                 #記事事に正常にタグとカテゴリーを取得しなおすのが難しかった記憶。
#                 #カテゴリ一覧をリスト
#                 Categories =[]
#                 CategoriesRaw = self.wp.call( GetTerms("PERSONS") )
#                 for tag in CategoriesRaw:
#                     Categories.append( str( tag ) )
# 
#                 #同名のカテゴリが存在するならcate/無ければtag
#                 PostTags     = ""
#                 PostCate     = ""
#                 #タグにマッチするカテゴリが存在した場合、それをカテゴリとする。
#                 for One in Post.terms:
#                     PostTag = str( One )
#                     if PostTag in Categories:
#                         PostCate = PostCate + PostTag + ","
#                     else:
#                         PostTags = PostTags + PostTag + ","
# 
#                 FieldText = CustomField['value'].splitlines()
#                 self.BlogTemplate( PostID , CustomField["id"] , Post.title , PostCate , PostTags , FieldText )
#                 break
# 
# 
# 
# 
# VimPostJsonRPCInst = PythonClass()
# "}}}

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

    # JSON-RPC
    PAYLOAD = {
            "jsonrpc"   : "2.0",
            "id"        : 1,
            # "method"    : "add",
            # "params"    : [42, 23],
    }
    def __init__( self , URL , ID , PW ):
        self.URL = URL
        self.ID  = ID
        self.PW  = PW

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


        # [Meta] =====================
        # Title     :
        # PERSONS   :
        # Tags      :
        # yyyy-mm-dd:
        # https://  :
        # https://  :
        # [Thoughts] =================
        # 現在のバッファを読み取って、送信用のjsonを作り上げる。
        # 送信自体は一回でよい。
        # これらを受け取って、分解し、複数のsqlに分けるのはphp側でよい。
        # 上記のテンプレートに追加し、本文/感想を送信する必要がある。

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

        # レスポンスの処理
        if response.status_code == 200:
            try:
                result = response.json()
                print( "Response:" , result )
            except ValueError:
                print( "Response is not a valid JSON" )

        else:
            print( "Request failed with status code:" , response.status_code )
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
        vim.command( ':e '   + self.BufferName + "Results" )
        vim.command('setl buftype=nowrite' )
        vim.command("setl encoding=utf-8")
        vim.command('setl filetype=markdown' )
        vim.command("setl bufhidden=delete" )
        vim.command("map <silent><buffer><enter>   :py3 VimPostJsonRPCInst.GetArchive()<cr>" )
        del vim.current.buffer[:]
        for record in result[ 'result' ]:
            vim.current.buffer.append( "[" + record[ 'time' ] + "]" + str( record[ 'id' ] )  + ":" + record[ 'title' ] )
        del vim.current.buffer[0]




    # }}}
    # "{{{
    def GetArchive( self ):
        #BlogListBuffer && current.line MoreList
        #if( PostID == 0 and vim.current.line == self.MoreList ):
        #self.BlogListAdd()
        #return

        ##BlogListBuffer && IDから始まる行。
        #if( PostID == 0):
        archive_id = vim.current.line
        archive_id = re.sub( r'\[.*\]' , "" , archive_id )
        # archive_id = re.sub( "\[.*\]" , "" , archive_id )
        archive_id = re.sub( ":.*"    , "" , archive_id )

        # print( archive_id )
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
        print( archive )
        vim.command(':e '   + self.BufferName + "Archive" )
        vim.command('setl buftype=nowrite' )
        vim.command("setl encoding=utf-8")
        vim.command('setl filetype=markdown' )
        vim.command("setl bufhidden=delete" )
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

    # "}}}
    def SearchArchives( self ):
        # bn = self.BufferName + "Archive"
        # x = vim.current.buffer.name
        # if x != bn :
        #     print( "not buffer")
        #     return
        # TITLE       = vim.current.buffer[3].replace( self.TEMPLATE['TITLE']    , "" , 1 )
        # PERSONS     = vim.current.buffer[4].replace( self.TEMPLATE['PERSONS']  , "" , 1 )
        # TAGS        = vim.current.buffer[5].replace( self.TEMPLATE['TAGS']     , "" , 1 )
        # DATE        = vim.current.buffer[6].replace( self.TEMPLATE['DATE']     , "" , 1 )

        PAYLOAD = copy.deepcopy( self.PAYLOAD )
        PAYLOAD[ 'method' ]  = "SearchTemplate"
        PAYLOAD[ 'params' ] = {
            "TITLE"     : "",
            "TAGS"      : [ "aa","bb" ],
            "PERSONS"   : [ "aa","bb" ],
            "START"     : "2000-1-1",
            "END"       : "2000-1-1",
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
        # vim.command( ':e '   + self.BufferName + "Results" )
        # vim.command('setl buftype=nowrite' )
        # vim.command("setl encoding=utf-8")
        # vim.command('setl filetype=markdown' )
        # vim.command("setl bufhidden=delete" )
        # vim.command("map <silent><buffer><enter>   :py3 VimPostJsonRPCInst.GetArchive()<cr>" )
        # del vim.current.buffer[:]
        # for record in result[ 'result' ]:
        #     vim.current.buffer.append( "[" + record[ 'time' ] + "]" + str( record[ 'id' ] )  + ":" + record[ 'title' ] )
        # del vim.current.buffer[0]







VimPostJsonRPCInst = PostJsonRPC( vim.eval( "g:VimPostJsonRPC_URL" ) , vim.eval( "g:VimPostJsonRPC_ID" ) , vim.eval( "g:VimPostJsonRPC_PW" ) )
EOF

let s:VimPostJsonRPC = "VimPostJsonRPCInst"
function! VimPostJsonRPC#pycmd( pyfunc )
    let s:x = py3eval( s:VimPostJsonRPC . "." . a:pyfunc )
endfunction




























