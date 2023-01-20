import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import './const.dart';
import './playlist.dart';

class AlarmDetailScreen extends StatefulWidget {
  String mode = '';
  int no = 0;
  AlarmDetailScreen(this.mode,this.no);

  //const AlarmDetailScreen({Key? key}) : super(key: key); //コンストラクタ

  @override
  State<AlarmDetailScreen> createState() =>  _AlarmDetailScreenState(mode,no);
}
class _AlarmDetailScreenState extends State<AlarmDetailScreen> {
  String mode = '';
  int no = 0;
  _AlarmDetailScreenState(this.mode,this.no);

  final _formTitleKey = GlobalKey<FormState>();
  final _formPreSecondKey = GlobalKey<FormState>();
  final _textControllerTitle = TextEditingController();
  final _textControllerPreSecond = TextEditingController();

  String title = 'モードなし';
  DateTime _time = DateTime.utc(0, 0, 0);
  String buttonName = '登録';

  bool monFlg = false;
  bool tueFlg = false;
  bool wedFlg = false;
  bool thuFlg = false;
  bool friFlg = false;
  bool satFlg = false;
  bool sunFlg = false;

  @override
  void initState() {
    super.initState();
    init();

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  Text(title),backgroundColor: const Color(0xFF6495ed),),
      body: SingleChildScrollView(

        child: Container(
          margin: const EdgeInsets.fromLTRB(15,50,15,5),
          //padding: const EdgeInsets.all(5.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12,width: 2),
            borderRadius: BorderRadius.circular(20),
            //   color: Colors.lightBlueAccent,
            boxShadow: [
              BoxShadow(
                  color: Colors.white,
                  blurRadius: 10.0,
                  spreadRadius: 1.0,
                  offset: Offset(5, 5))
            ],
          ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children:  <Widget>[
                Padding(padding: EdgeInsets.all(10)),
                ///時間
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const <Widget>[
                    Icon(Icons.timer,size: 25,color: Colors.blue),
                    Text('時間',style:TextStyle(fontSize: 25.0,color: Color(0xFF191970))),
                  ],
                ),
                const Padding(padding: EdgeInsets.all(10)),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.lightBlueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),),
                  onPressed: () async {
                    Picker(
                        adapter: DateTimePickerAdapter(
                            type: PickerDateTimeType.kHMS,
                            value: _time,
                            customColumnType: [3, 4]),
                        title: const Text("Select Time"),
                        onConfirm: (Picker picker, List value) {
                          setState(() => {
                            _time = DateTime.utc(2016, 5, 1, value[0], value[1],0),
                          });
                        },
                        onSelect: (Picker picker, int index, List<int> selected){
                          _time = DateTime.utc(2016, 5, 1, selected[0], selected[1],0);
                        }
                    ).showModal(context);
                  },
                  child: Text('${_time.hour.toString().padLeft(2,'0')}:${_time.minute.toString().padLeft(2,'0')}', style: const TextStyle(fontSize: 35),),
                ),
                Padding(padding: EdgeInsets.all(10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:  <Widget>[
                    Icon(Icons.label,size: 25,color: Colors.blue),
                    Text('タイトル',style:TextStyle(fontSize: 25.0,color: Color(0xFF191970))),
                  ],),

                Container(
                  padding: const EdgeInsets.all(5.0),
                  alignment: Alignment.bottomCenter,
                  width: 300.0,
                  height: 70,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.lightBlueAccent),
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.lightBlueAccent,
                  ),
                  child:Form(
                    key: _formTitleKey,
                    child: TextFormField(
                      controller: _textControllerTitle,
                      validator: (value) {
                        if (value == null  || value.isEmpty) {
                          return '必ず何か入力してください。';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(hintText: "タイトルを入力してください"),
                      style: const TextStyle(fontSize: 20, color: Colors.white,),
                      textAlign: TextAlign.center,
                      onFieldSubmitted: (String value){
                      },
                      maxLength: 20,
                    ),
                  ),
                ),

                const Padding(padding: EdgeInsets.all(10)),
                ///音楽ファイル選択ボタン
                SizedBox(
                  width: 200, height: 70,
                  child: ElevatedButton(
                    onPressed: musicSelButtonPressed,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blue
                      , elevation: 16
                      ,shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    ),
                    child: Text( '音楽ファイル選択', style:  TextStyle(fontSize: 20.0, color: Colors.white,),),
                  ),
                ),
                Text('曜日',style:TextStyle(fontSize: 25.0,color: Color(0xFF191970))),

                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:  <Widget>[
                      ElevatedButton(style: ElevatedButton.styleFrom(shape: CircleBorder(),backgroundColor: monFlg?Colors.blue:Colors.grey),
                        onPressed: () {setState(() {monFlg = !monFlg;});},
                        child: Text( '月', style:  TextStyle(fontSize: 15.0, color: Colors.white,),),),
                      ElevatedButton(style: ElevatedButton.styleFrom(shape: CircleBorder(),backgroundColor: tueFlg?Colors.blue:Colors.grey),
                        onPressed: () {setState(() {tueFlg = !tueFlg;});},
                        child: Text( '火', style:  TextStyle(fontSize: 15.0, color: Colors.white,),),),
                      ElevatedButton(style: ElevatedButton.styleFrom(shape: CircleBorder(),backgroundColor: wedFlg?Colors.blue:Colors.grey),
                        onPressed: () {setState(() {wedFlg = !wedFlg;});},
                        child: Text( '水', style:  TextStyle(fontSize: 15.0, color: Colors.white,),),),
                      ElevatedButton(style: ElevatedButton.styleFrom(shape: CircleBorder(),backgroundColor: thuFlg?Colors.blue:Colors.grey),
                        onPressed: () {setState(() {thuFlg = !thuFlg;});},
                        child: Text( '木', style:  TextStyle(fontSize: 15.0, color: Colors.white,),),),
                       ElevatedButton(style: ElevatedButton.styleFrom(shape: CircleBorder(),backgroundColor: friFlg?Colors.blue:Colors.grey),
                         onPressed: () {setState(() {friFlg = !friFlg;});},
                         child: Text( '金', style:  TextStyle(fontSize: 15.0, color: Colors.white,),),),
                    ]
                ),
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:  <Widget>[
                      ElevatedButton(style: ElevatedButton.styleFrom(shape: CircleBorder(),backgroundColor: satFlg?Colors.blue:Colors.grey),
                        onPressed: () {setState(() {satFlg = !satFlg;});},
                        child: Text( '土', style:  TextStyle(fontSize: 15.0, color: Colors.white,),),),
                      ElevatedButton(style: ElevatedButton.styleFrom(shape: CircleBorder(),backgroundColor: sunFlg?Colors.blue:Colors.grey),
                        onPressed: () {setState(() {sunFlg = !sunFlg;});},
                        child: Text( '日', style:  TextStyle(fontSize: 15.0, color: Colors.white,),),),
            ]
        ),

                Text('再生モード',style:TextStyle(fontSize: 25.0,color: Color(0xFF191970))),

                Padding(padding: EdgeInsets.all(10)),
                ///保存ボタン
                SizedBox(
                  width: 200, height: 70,
                  child: ElevatedButton(
                    onPressed: buttonPressed,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blue
                      , elevation: 16
                      ,shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    ),
                    child: Text( buttonName, style:  TextStyle(fontSize: 30.0, color: Colors.white,),),
                  ),
                ),
                Padding(padding: EdgeInsets.all(10)),
              ]
          ),
        ),
      ),

    );
  }
  void buttonPressed() async{
    if (!_formTitleKey.currentState!.validate() || !_formPreSecondKey.currentState!.validate()) {
      // If the form is valid, display a snackbar. In the real world,
      // you'd often call a server or save the information in a database.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('入力内容を見直してください'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (_time.minute == 0 && _time.second == 0){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('必ず時間（分秒）を設定してください。'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    int intMax = 0;
    switch (mode) {
    //登録モード
      case cnsAlarmDetailScreenIns:
        intMax =  await getMaxStretchNo();
        await insertStretchData(intMax+1);
        break;
    //編集モード
      case cnsAlarmDetailScreenUpd:
        await updateStretchData(no);
        break;
    }

    Navigator.pop(context);
  }
  void musicSelButtonPressed() async{
    int fileListNo = 0;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => playListEditScreen(fileListNo)),
    );
  }
  Future<void> init()async{
    switch (mode) {
    //登録モード
      case cnsAlarmDetailScreenIns:
        title = '登録画面';
        buttonName  = '登録';
        break;
    //編集モード
      case cnsAlarmDetailScreenUpd:
        title = '編集画面';
        buttonName  = '更新';
        loadEditData(no);
        break;
    }
  }
  void loadEditData(int editNo) async{

    String lcTitle = '';
    String lcTime = '';
    int    lcOtherSideFlag = 0;

    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);
    List<Map> result = await database.rawQuery("SELECT * From alarmList where alarmno = $editNo");
    for (Map item in result) {
      lcTitle = item['title'];
      lcTime = item['time'];
      // lcOtherSideFlag = item['otherside'];
    }
    setState(() {
      _textControllerTitle.text = lcTitle;
      _time = DateTime.parse(lcTime);
      // if(lcOtherSideFlag == cnsOtherSideOff){
      //   _otherSideFlag = false;
      // }else{
      //   _otherSideFlag = true;
      // }

   //   _textControllerPreSecond.text = lcPreSecond.toString();

    });

  }
  Future<void>  insertStretchData(int lcNo)async{
    int lcOtherSide = 0 ;
    String dbPath = await getDatabasesPath();
    String query = '';
    String path = p.join(dbPath, 'internal_assets.db');
    int preSecond = 0;
    Database database = await openDatabase(path, version: 1,);


    //準備時間がnullだったらゼロにする
    preSecond = (_textControllerPreSecond.text.isEmpty)? 0:int.parse(_textControllerPreSecond.text);

    query = 'INSERT INTO stretchlist(no,title,time,otherside,presecond,kaku1,kaku2,kaku3,kaku4) values($lcNo,"${_textControllerTitle.text}","${_time.toString()}",$lcOtherSide,"$preSecond",null,null,null,null) ';
    await database.transaction((txn) async {
      await txn.rawInsert(query);
    });
  }
  Future<void>  updateStretchData(int lcNo)async{
    int lcOtherSide = 0 ;
    int lcPreSecond = 0 ;
    String dbPath = await getDatabasesPath();
    String query = '';
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);

    lcPreSecond =  int.parse(_textControllerPreSecond.text);
    query = "UPDATE stretchlist set title = '${_textControllerTitle.text}', time = '${_time.toString()}',otherside = $lcOtherSide, presecond = ${lcPreSecond} where no = $lcNo ";
    await database.transaction((txn) async {
      await txn.rawInsert(query);
    });
  }
  Future<int>  getMaxStretchNo() async{
    int lcMaxNo = 0;
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);
    List<Map> result = await database.rawQuery("SELECT MAX(no) no From stretchlist");
    for (Map item in result) {
      lcMaxNo = item['no'];
    }
    return lcMaxNo;
  }

}
