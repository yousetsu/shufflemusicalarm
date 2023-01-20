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

  String title = 'モードなし';
  DateTime _time = DateTime.utc(0, 0, 0);
  String buttonName = '登録';

  @override
  void initState() {
    super.initState();
    init();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: DefaultTabController(
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
        ),
    );
  }
  void buttonPressed() async{

    Navigator.pop(context);
  }
/*------------------------------------------------------------------
MusicFolderデータ取得
 -------------------------------------------------------------------*/
  Future<void> getitemsMusicFolder() async {
    List<Widget> list = <Widget>[];
    int listNo = 0;
    double titleFont = 25;
    String strMusicName ='';
    String strMusicPath ='';
    int intFileListNo = 0;

    int index = 0;
    for (Map item in mapMusicFolder) {
      if(item['musicname'].toString().length > 10) {
        titleFont = 15;
      }else{
        titleFont = 25;
      }
      list.add(
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          key: Key('$index'),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            title: Text('${item['musicname']}  ', style: TextStyle(color: const Color(0xFF191970) , fontSize: titleFont),),
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
  Future<void> insPlayList(int intPlayListMaxNo, int fileListNo, String name, String path) async{
    String dbPath = await getDatabasesPath();
    String query = '';
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);

    query = 'INSERT INTO playList(no,filelistno,musicname,musicpath,kaku1,kaku2,kaku3,kaku4) values($intPlayListMaxNo,$fileListNo,"$name","$path",null,null,null,null) ';
    await database.transaction((txn) async {
      await txn.rawInsert(query);
    });
  }
  Future<void>  loadMusicFolder() async {
    int no = 0;
    String path;
    mapMusicFolder = <Map>[];

    path = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_MUSIC);

    Directory pDir = Directory(path);

    var plist = pDir.listSync(recursive: true);

    for( var p in plist! ){
      final reg = RegExp(r'\.mp3');
      if(reg.hasMatch(p.path)) {
        mapMusicFolder.add({
          'No': no,
          'filelistno': 0,
          'musicname': p.path,
          'musicpath': p.path,
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
    int listNo = 0;
    double titleFont = 15;
    String strMusicName ='';
    String strMusicPath ='';
    int intFileListNo = 0;

    int index = 0;
    for (Map item in mapPlayList) {

      list.add(
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          key: Key('$index'),
          child: ListTile(
            title: Text('${item['musicname']}  ', style: TextStyle(color: const Color(0xFF191970) , fontSize: titleFont),),
            selected: listNo == item['filelistno'],
            onLongPress: () {
              intFileListNo = fileListNo;  //拡張用
              strMusicName = item['musicname'];
              strMusicPath = item['musicpath'];
              tapLongPlayListTile(strMusicName,strMusicPath,intFileListNo);
            },
          ),
        ),
      );
      index++;
    }
    setState(() {_itemsPlayList = list;});
  }
  Future<void> tapLongPlayListTile(String name ,String path, int fileListNo) async{


    //プレイリストテーブルに登録


    //トーストで登録された旨を表示
    Fluttertoast.showToast(msg: 'プレイリストから$nameが削除されました');
    init();
  }

  Future<void> delPlayList(int intPlayListMaxNo, int fileListNo, String name, String path) async{
    String dbPath = await getDatabasesPath();
    String query = '';
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);

   // query = 'INSERT INTO playList(no,filelistno,musicname,musicpath,kaku1,kaku2,kaku3,kaku4) values($intPlayListMaxNo,$fileListNo,"$name","$path",null,null,null,null) ';
    await database.transaction((txn) async {
      await txn.rawInsert(query);
    });
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
    await loadMusicFolder();

    await loadPlayList(fileListNo);

    await getitemsMusicFolder();

    await getitemsPlayList();


  }



}
