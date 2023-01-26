import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:external_path/external_path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import './const.dart';
import 'package:fluttertoast/fluttertoast.dart';
//Musicフォルダ用一覧
List<Widget> _itemsMusicFolder = <Widget>[];
List<Map> mapMusicFolder = <Map>[];
//プレイリスト用一覧
List<Widget> _itemsPlayList = <Widget>[];
List<Map> mapPlayList = <Map>[];

class playListEditScreen extends StatefulWidget {
  int fileListNo = 0;
  playListEditScreen(this.fileListNo);

  //const playListEditScreen({Key? key}) : super(key: key); //コンストラクタ

  @override
  State<playListEditScreen> createState() =>  _playListEditScreenState(fileListNo);
}
class _playListEditScreenState extends State<playListEditScreen> {
  int fileListNo = 0;
  _playListEditScreenState(this.fileListNo);

  @override
  void initState() {
    super.initState();
    init();
  }
  @override
  Widget build(BuildContext context) {
     return DefaultTabController(
            length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('プレイリスト編集画面'),
              bottom: const TabBar(tabs: <Widget>[
                Tab(text: 'Musicフォルダ'),
                Tab(text: 'プレイリスト')
              ]),
            ),
            body:  TabBarView(
            children: <Widget>[
              ///MusicFolder
              Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:  <Widget>[Expanded(child: ListView(children: _itemsMusicFolder,),),],
                ),),
              ///PlayList
              Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children:  <Widget>[Expanded(child: ListView(children: _itemsPlayList,),),],
              ),),
        ],
          ),
        ),
       );
  }
/*------------------------------------------------------------------
MusicFolderデータ取得
 -------------------------------------------------------------------*/
  Future<void> getitemsMusicFolder() async {
    List<Widget> list = <Widget>[];
    int listNo = 0;
    String strMusicName ='';
    String strMusicPath ='';
    int intFileListNo = 0;
    int index = 0;
    list.add(
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            title: Text('【説明】曲をタップするとプレイリストに登録されます。',style: TextStyle(color: Colors.black , fontSize: 13)),
          ),
        )
    );
    for (Map item in mapMusicFolder) {
      list.add(
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15),),
          key: Key('$index'),
          child: ListTile(
            title: Text('${item['musicname']}  ', style: TextStyle(color: const Color(0xFF191970) , fontSize: 15),),
            selected: listNo == item['filelistno'],
            onTap: () {
              intFileListNo = fileListNo;  //拡張用
              strMusicName = item['musicname'];
              strMusicPath = item['musicpath'];
              _tapTile(strMusicName,strMusicPath,intFileListNo);
            },
          ),
        ),
      );
      index++;
    }
    setState(() {_itemsMusicFolder = list;});
  }
  Future<void> _tapTile(String name ,String path, int fileListNo) async{

    int intPlayListMaxNo = 0;
    //ファイルリストNo（現在固定ゼロ）の最大MaxNoを取得
    intPlayListMaxNo = await getPlayListMaxNo(fileListNo);

    debugPrint('MaxNo:$intPlayListMaxNo');
    //プレイリストテーブルに登録
    await insPlayList(intPlayListMaxNo+1,fileListNo,name,path);
    //トーストで登録された旨を表示
    Fluttertoast.showToast(msg: 'プレイリストに$nameが登録されました');

    init();
  }
  Future<int> getPlayListMaxNo(int fileListNo) async{
    int maxNo = 0;
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);
    List<Map> result = await database.rawQuery("SELECT MAX(no) no From playList where filelistno = $fileListNo");
    for (Map item in result) {
      maxNo = (item['no'] != null)?item['no']:0;
    }
    return maxNo;
  }
  Future<void> insPlayList(int intPlayListMaxNo, int fileListNo, String name, String musicPath) async{
    String dbPath = await getDatabasesPath();
    String query = '';
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);

    query = 'INSERT INTO playList(no,filelistno,musicname,musicpath,kaku1,kaku2,kaku3,kaku4) values($intPlayListMaxNo,$fileListNo,"$name","$musicPath",null,null,null,null) ';
    await database.transaction((txn) async {
      await txn.rawInsert(query);
    });
  }
  Future<void>  loadMusicFolder(int fileListNo) async {
    int no = 0;
    String path;
    mapMusicFolder = <Map>[];
    path = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_MUSIC);
    Directory pDir = Directory(path);
    List<FileSystemEntity>  plist = pDir.listSync(recursive: true);

    for( var item in plist! ){
      final reg = RegExp(r'\.mp3|\.MP3|\.wav|\.WAV');
      if(reg.hasMatch(item.path)) {
        mapMusicFolder.add({
          'No': no,
          'filelistno': fileListNo.toString(),
          'musicname': p.basename(item.path),
          'musicpath': item.path,
        });
      }
      no++;
    }
  }
/*------------------------------------------------------------------
Playlistデータ取得
 -------------------------------------------------------------------*/
  Future<void> getitemsPlayList() async {
    List<Widget> list = <Widget>[];
    int intAlarmNo = 0;
    double titleFont = 15;
    String strMusicName ='';
    String strMusicPath ='';
    int intFileListNo = 0;
    int index = 0;
    list.add(
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            title: Text('※プレイリストから曲を外す場合は長押しタップしてください',style: TextStyle(color: Colors.black , fontSize: 13)),
          ),
        )
    );
    for (Map item in mapPlayList) {
      debugPrint('alarmNo:${item['no']}  name:${item['musicname']} path:${item['musicpath']}');
      list.add(
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15),),
          key: Key('$index'),
          child: ListTile(
            title: Text('${item['musicname']}  ', style: TextStyle(color: const Color(0xFF191970) , fontSize: titleFont),),
            selected: intAlarmNo == item['no'],
            onLongPress: () {
              intAlarmNo = item['no'];
              intFileListNo = fileListNo;  //拡張用
              strMusicName = item['musicname'];
              strMusicPath = item['musicpath'];
              tapLongPlayListTile(intAlarmNo,strMusicName,strMusicPath,intFileListNo);
            },
          ),
        ),
      );
      index++;
    }
    setState(() {_itemsPlayList = list;});
  }
  Future<void> tapLongPlayListTile(int alarmNo,String name ,String path, int fileListNo) async{
    //指定したPlayListNoを削除
    await delPlayList(alarmNo,fileListNo);
    //番号振り直し
   await updPlayListReNo(fileListNo);
    //トーストで登録解除された旨を表示
    Fluttertoast.showToast(msg: 'プレイリストから$nameが外れました');
    //再取得
    init();
  }
  Future<void> delPlayList(int intPlayListNo, int intfileListNo) async{
    String dbPath = await getDatabasesPath();
    String query = '';
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);
    query = 'DELETE From playList where no = $intPlayListNo and filelistno = $intfileListNo';
    debugPrint('query:$query');
    await database.transaction((txn) async {
      await txn.rawInsert(query);
    });
  }
  Future<void> updPlayListReNo(int lcFileListNo) async{
    //番号順にリスト再取得
    int reNo = 1;
    String dbPath = await getDatabasesPath();
    String query = '';
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);
    List<Map> lcMapPlayList = await database.rawQuery("SELECT * From playList where filelistno = $lcFileListNo order by no");
    //番号を振り直しして更新
    for (Map item in lcMapPlayList) {
      query = 'UPDATE playList set no = $reNo where no = ${item['no']} and filelistno = $lcFileListNo';
      await database.transaction((txn) async {
        await txn.rawInsert(query);
      });
      reNo++;
    }
  }
  Future<void>  loadPlayList(int fileListNo) async {
    mapPlayList = <Map>[];
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);
    mapPlayList = await database.rawQuery("SELECT * From playList where filelistno = $fileListNo order by no");
  }
  /*------------------------------------------------------------------
初期処理
 -------------------------------------------------------------------*/
  void init() async {
    // await  testEditDB();
    await loadMusicFolder(fileListNo);
    await loadPlayList(fileListNo);
    await getitemsMusicFolder();
    await getitemsPlayList();
  }

}
