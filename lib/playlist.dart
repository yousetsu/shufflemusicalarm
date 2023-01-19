import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:external_path/external_path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import './const.dart';

List<Widget> _items = <Widget>[];
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
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:  <Widget>[
          const Padding(padding: EdgeInsets.all(10)),
          Expanded(
            child: ListView(
              children: _items,
            ),
          ),
        ],
      ),
    );
  }
  void buttonPressed() async{

    Navigator.pop(context);
  }
  Future<void> getItems() async {
    List<Widget> list = <Widget>[];
    int listNo = 0;
    double titleFont = 25;
    String listTitle ='';
    String listTime ='';
    int listOtherSide = 0;
    String strPreSecondText = '';
    String strTimeText = '';
    DateTime dtTime = DateTime.now();


    int index = 0;
    for (Map item in mapPlayList) {

      if(item['musicname'].toString().length > 10) {
        titleFont = 15;
      }else{
        titleFont = 25;
      }

      list.add(
        Card(

          margin: const EdgeInsets.fromLTRB(15,0,15,15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          key: Key('$index'),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            //  key: Key('$index'),
            //tileColor: Colors.grey,
            // tileColor: (item['getupstatus'].toString() == cnsGetupStatusS)
            //     ? Colors.green
            //     : Colors.grey,
            //  leading: boolAchieveReleaseFlg
            //      ? const Icon(Icons.play_circle, color: Colors.blue, size: 18,)
            //      : const Icon(Icons.stop_circle, size: 18,),
            title: Text('${item['musicname']}  ', style: TextStyle(color: const Color(0xFF191970) , fontSize: titleFont),),
            // subtitle: Row(children:  <Widget>[
            //   Text(' $strTimeText ', style:const TextStyle(color: Colors.blue , fontSize: 25) ),
            //   //  Icon(Icons.swap_horiz,size: 25,color:  ( item['otherside'] == cnsOtherSideOn) ?Colors.blue:Colors.white,) ,
            //   Text(strPreSecondText,  style: const TextStyle(color: Colors.grey , fontSize: 15) ),] ),

            //    isThreeLine: true,
            selected: listNo == item['filelistno'],
            onTap: () {
              // listNo = item['no'];
              // listTitle = item['title'];
              // listTime = item['time'];
              // listOtherSide = item['otherside'];
              // listPreSecond = (item['presecond'] == null)? 0 : item['presecond'];
              // _tapTile(listTitle,listTime,listOtherSide,listPreSecond);
            },
          ),
        ),
      );
      index++;
    }
    setState(() {_items = list;});
  }
  void _tapTile(String listTitle ,String listTime, int listOtherSide,int listPreSecond) {


  }
  /*------------------------------------------------------------------
第一画面ロード
 -------------------------------------------------------------------*/
  Future<void>  loadList() async {
    // String dbPath = await getDatabasesPath();
    // String path = p.join(dbPath, 'internal_assets.db');
    // Database database = await openDatabase(path, version: 1);
    // mapPlayList = await database.rawQuery("SELECT * From alarmList order by alarmno");

    int no = 3;
  //  Directory appDocDir = await getApplicationDocumentsDirectory();
  //  String appDocPath = appDocDir.path;

    String path;
    path = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_MUSIC);

    debugPrint('外部パス:$path');

    Directory pDir = Directory(path);
    ///ここを可変でとりたい！！

    var plist = pDir.listSync(recursive: true);
  //  debugPrint('Directory:$appDocPath');

    // List<Directory>? ListDir = await getExternalStorageDirectories( );
    //
    // for( var p in ListDir! ){
    //   debugPrint('ListDir:${p.path}');
    // }

    // Directory? exDir = await getExternalStorageDirectory( );
    //  String? strExDir = exDir?.path;
    //   debugPrint('ExDir:$strExDir');

    // String? strDir = Dir?.path;
    // debugPrint('Directory:$strDir');
    // var plist = Dir?.listSync();
    mapPlayList = [
      {'No':1, 'filelistno':0,'musicname':'電撃戦隊チェンジマン.mp3','musicpath':'musicpath1'},
      {'No':2, 'filelistno':0,'musicname':'超電子バイオマン.mp3','musicpath':'musicpath2'},

    ];
    for( var p in plist! ){
      final reg = RegExp(r'\.mp3');
      if(reg.hasMatch(p.path)) {
        mapPlayList.add({
          'No': no,
          'filelistno': 0,
          'musicname': p.path,
          'musicpath': 'musicpath1'
        });
      }
      debugPrint('path:${p.path}');
      no++;
    }



  }
  void init() async {
    // await  testEditDB();
    await loadList();
    await getItems();
  }


}
