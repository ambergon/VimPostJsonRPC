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
#                 CategoriesRaw = self.wp.call( GetTerms("category") )
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
    #BufferName = 'VimPostJsonRPC:/'
    #BlogListNum         = 100
    URL = ""
    ID  = ""
    PW  = ""

    # JSON-RPC
    PAYLOAD = {
            "jsonrpc"   : "2.0",
            "id"        : 1,
            "method"    : "add",
            "params"    : [42, 23],
    }
    def __init__( self , URL , ID , PW ):
        self.URL = URL
        self.ID  = ID
        self.PW  = PW



    def Send( self , method=None , *args ):
        if method == None :
            print( "set method" )
            exit
        # 参照渡しになるので、テンプレートを綺麗に保持する為コピー。
        # payload = self.PAYLOAD
        payload = copy.deepcopy( self.PAYLOAD )
        payload[ 'params' ]  = args
        # print( method)
        # print( args[0] )

        # HTTPヘッダーの設定
        headers = {
            "Content-Type": "application/json"
        }
        # リクエストを送信
        response = requests.post( self.URL , headers=headers , data=json.dumps( payload ) )

        # レスポンスの処理
        if response.status_code == 200:
            try:
                result = response.json()
                print( "Response:" , result )
            except ValueError:
                print( "Response is not a valid JSON" )

        else:
            print( "Request failed with status code:" , response.status_code )


VimPostJsonRPCInst = PostJsonRPC( vim.eval( "g:VimPostJsonRPC_URL" ) , vim.eval( "g:VimPostJsonRPC_URL" ) , vim.eval( "g:VimPostJsonRPC_URL" ) )
EOF

let s:VimPostJsonRPC = "VimPostJsonRPCInst"
function! VimPostJsonRPC#pycmd( pyfunc )
    let s:x = py3eval( s:VimPostJsonRPC . "." . a:pyfunc )
endfunction




























