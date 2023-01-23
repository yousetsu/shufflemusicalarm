import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import './const.dart';
import './playlist.dart';
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import './main.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';


@pragma('vm:entry-point')
class AlarmDetailScreen extends StatefulWidget {
  String mode = '';
  int no = 0;
  AlarmDetailScreen(this.mode,this.no);

  @override
  State<AlarmDetailScreen> createState() =>  _AlarmDetailScreenState(mode,no);
}
@pragma('vm:entry-point')
class _AlarmDetailScreenState extends State<AlarmDetailScreen> {
  String mode = '';
  int no = 0;
  _AlarmDetailScreenState(this.mode,this.no);
  final _formTitleKey = GlobalKey<FormState>();
  final _textControllerTitle = TextEditingController();
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
  bool isAlarmOn = false;

  @override
  @pragma('vm:entry-point')
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
          decoration: BoxDecoration(border: Border.all(color: Colors.black12,width: 2), borderRadius: BorderRadius.circular(20),
            //   color: Colors.lightBlueAccent,
            boxShadow: [BoxShadow(color: Colors.white, blurRadius: 10.0, spreadRadius: 1.0, offset: Offset(5, 5))],
          ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children:  <Widget>[
                Text('アラームON/OFF',style:TextStyle(fontSize: 20.0,color: Color(0xFF191970))),
                Switch(value: isAlarmOn, onChanged: switchChange),
                Padding(padding: EdgeInsets.all(10)),
                ///時間
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: const <Widget>[
                    Icon(Icons.timer,size: 25,color: Colors.blue),
                    Text('時間',style:TextStyle(fontSize: 20.0,color: Color(0xFF191970))),
                  ],),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.lightBlueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),),),
                  onPressed: () async {
                    Picker(
                        adapter: DateTimePickerAdapter(
                            type: PickerDateTimeType.kHMS,
                            value: _time,
                            customColumnType: [3, 4]),
                        title: const Text("Select Time"),
                        onConfirm: (Picker picker, List value) {
                          setState(() => {_time = DateTime.utc(2016, 5, 1, value[0], value[1],0),});
                        },
                        onSelect: (Picker picker, int index, List<int> selected){
                          _time = DateTime.utc(2016, 5, 1, selected[0], selected[1],0);
                        }
                    ).showModal(context);
                  },
                  child: Text('${_time.hour.toString().padLeft(2,'0')}:${_time.minute.toString().padLeft(2,'0')}', style: const TextStyle(fontSize: 35),),
                ),
                Padding(padding: EdgeInsets.all(10)),
                Text('曜日',style:TextStyle(fontSize: 20.0,color: Color(0xFF191970))),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:  <Widget>[
                      SizedBox(width:50, height:50,
                      child:ElevatedButton(style: ElevatedButton.styleFrom(shape: CircleBorder(),backgroundColor: monFlg?Colors.blue:Colors.grey),
                        onPressed: () {setState(() {monFlg = !monFlg;});},
                        child: Text('月', style: TextStyle(fontSize: 15.0, color: Colors.white,),),),
                      ),
                      SizedBox(width:50, height:50,
                        child:ElevatedButton(style: ElevatedButton.styleFrom(shape: CircleBorder(),backgroundColor: tueFlg?Colors.blue:Colors.grey),
                        onPressed: () {setState(() {tueFlg = !tueFlg;});},
                        child: Text( '火', style:  TextStyle(fontSize: 15.0, color: Colors.white,),),),
                      ),
                      ElevatedButton(style: ElevatedButton.styleFrom(shape: CircleBorder(),backgroundColor: wedFlg?Colors.blue:Colors.grey),
                        onPressed: () {setState(() {wedFlg = !wedFlg;});},
                        child: Text( '水', style:  TextStyle(fontSize: 10.0, color: Colors.white,),),),
                      ElevatedButton(style: ElevatedButton.styleFrom(shape: CircleBorder(),backgroundColor: thuFlg?Colors.blue:Colors.grey),
                        onPressed: () {setState(() {thuFlg = !thuFlg;});},
                        child: Text( '木', style:  TextStyle(fontSize: 10.0, color: Colors.white,),),),
                      ElevatedButton(style: ElevatedButton.styleFrom(shape: CircleBorder(),backgroundColor: friFlg?Colors.blue:Colors.grey),
                        onPressed: () {setState(() {friFlg = !friFlg;});},
                        child: Text( '金', style:  TextStyle(fontSize: 10.0, color: Colors.white,),),),
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
                    ]),
                const Padding(padding: EdgeInsets.all(10)),
                ///音楽ファイル選択ボタン
                SizedBox(
                  width: 200, height: 70,
                  child: ElevatedButton(
                    onPressed: musicSelButtonPressed,
                    style: ElevatedButton.styleFrom(foregroundColor: Colors.blue, elevation: 16,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),),),
                    child: Text( '音楽ファイル選択', style:  TextStyle(fontSize: 20.0, color: Colors.white,),),
                  ),
                ),
               // Text('再生モード',style:TextStyle(fontSize: 20.0,color: Color(0xFF191970))),
                Padding(padding: EdgeInsets.all(10)),
                ///保存ボタン
                SizedBox(width: 200, height: 70,
                  child: ElevatedButton(
                    onPressed: buttonPressed,
                    style: ElevatedButton.styleFrom(foregroundColor: Colors.blue, elevation: 16,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),),),
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
  void switchChange(value){
    setState(() {isAlarmOn = value;},);
    setAlarm();
  }
  void buttonPressed() async{

    int intMax = 0;
    switch (mode) {
    //登録モード
      case cnsAlarmDetailScreenIns:
       // intMax =  await getMaxStretchNo();
        await insertStretchData(intMax+1);
        break;
    //編集モード
      case cnsAlarmDetailScreenUpd:
        await updateAlarmData(no);
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
    int    lcAlarmFlag = 0;
    int intLcMon = 0;
    int intLcTue = 0;
    int intLcWed = 0;
    int intLcThu = 0;
    int intLcFri = 0;
    int intLcSat = 0;
    int intLcSun = 0;
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);
    List<Map> result = await database.rawQuery("SELECT * From alarmList where alarmno = $editNo");
    for (Map item in result) {
      lcTitle = item['title'].toString();
      lcTime = item['time'].toString();
      lcAlarmFlag = item['alarmflg'];
      intLcMon = item['mon'];
      intLcTue = item['tue'];
      intLcWed = item['wed'];
      intLcThu = item['thu'];
      intLcFri = item['fri'];
      intLcSat = item['sat'];
      intLcSun = item['sun'];
    }
    setState(() {
      _textControllerTitle.text = lcTitle;
      _time = DateTime.parse(lcTime);
       if(lcAlarmFlag == cnsOtherSideOff){
         isAlarmOn = false;
       }else{
         isAlarmOn = true;
       }
       monFlg = (intLcMon == cnsFlgOn)?true:false;
       tueFlg = (intLcTue == cnsFlgOn)?true:false;
       wedFlg = (intLcWed == cnsFlgOn)?true:false;
       thuFlg = (intLcThu == cnsFlgOn)?true:false;
       friFlg = (intLcFri == cnsFlgOn)?true:false;
       satFlg = (intLcSat == cnsFlgOn)?true:false;
       sunFlg = (intLcSun == cnsFlgOn)?true:false;
    });
  }
  Future<void>  insertStretchData(int lcNo)async{
    int lcOtherSide = 0 ;
    String dbPath = await getDatabasesPath();
    String query = '';
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);

  //  query = 'INSERT INTO stretchlist(no,title,time,otherside,presecond,kaku1,kaku2,kaku3,kaku4) values($lcNo,"${_textControllerTitle.text}","${_time.toString()}",$lcOtherSide,"$preSecond",null,null,null,null) ';
    await database.transaction((txn) async {
      await txn.rawInsert(query);
    });
  }
  Future<void>  updateAlarmData(int lcNo)async{
    int lcAlarmFlg = 0 ;
    String dbPath = await getDatabasesPath();
    String query = '';
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);

    int intLcMon = 0;
    int intLcTue = 0;
    int intLcWed = 0;
    int intLcThu = 0;
    int intLcFri = 0;
    int intLcSat = 0;
    int intLcSun = 0;

    //オンにした音楽鳴らす
    lcAlarmFlg =  isAlarmOn?cnsFlgOn:cnsFlgOff;
    intLcMon = monFlg?cnsFlgOn:cnsFlgOff;
    intLcTue = tueFlg?cnsFlgOn:cnsFlgOff;
    intLcWed = wedFlg?cnsFlgOn:cnsFlgOff;
    intLcThu = thuFlg?cnsFlgOn:cnsFlgOff;
    intLcFri = friFlg?cnsFlgOn:cnsFlgOff;
    intLcSat = satFlg?cnsFlgOn:cnsFlgOff;
    intLcSun = sunFlg?cnsFlgOn:cnsFlgOff;

    query = 'UPDATE alarmList set '
          + 'time = "${_time.toString()}",title = "${_textControllerTitle.text}",alarmflg = $lcAlarmFlg, filelistno = 0, '
          + 'mon = $intLcMon,'
          + 'tue = $intLcTue,'
          + 'wed = $intLcWed,'
          + 'thu = $intLcThu,'
          + 'fri = $intLcFri,'
          + 'sat = $intLcSat,'
          + 'sun = $intLcSun'
          +' where alarmno = $lcNo';
    await database.transaction((txn) async {
      await txn.rawInsert(query);
    });
  }

  Future<void> setAlarm()  async{
    if(isAlarmOn) {
      debugPrint('alarmSet');

      await AndroidAlarmManager.oneShot(const Duration(seconds: 5), alarmID, playSound,exact: true, wakeup: true, alarmClock: true, allowWhileIdle: true);
      //OSごとの通知バーの表示分定義(今はandoridのみ)


      //通知バーの表示分定義(andorid分)
      // const AndroidNotificationDetails androidNotificationDetails
      // = AndroidNotificationDetails('your channel id', 'your channel name',
      //     channelDescription: 'your channel description',
      //     importance: Importance.high,
      //     priority: Priority.high,
      //     fullScreenIntent: true,
      //     ticker: 'ticker');
      // const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

      //即時通知される
     // await flutterLocalNotificationsPlugin.show(0, 'plain title', 'plain body', notificationDetails, payload: 'item x');
      //時刻起動する場合のタイムゾーン設定
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      //時間起動通知される
      await flutterLocalNotificationsPlugin.zonedSchedule(
          0,
          'scheduled title',
          'scheduled body',
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
          const NotificationDetails(
              android: AndroidNotificationDetails(
                  'your channel id', 'your channel name',
                  channelDescription: 'your channel description',
                  priority: Priority.high,
                  playSound:false,
                  importance: Importance.high,
                  fullScreenIntent: true
              )),
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime);

    }else {
      debugPrint('alarmStop');

    }
  }

// Future<void> playMusic(Stirng musicPath) async {
//   String? strSePath;
//   strSePath = await _loadStrSetting('mpath');
//   _player = AudioPlayer();
//   await _player.setLoopMode(LoopMode.all);
//   if(strSePath != null && strSePath != "") {
//     await _player.setFilePath(strSePath);
//   }else{
//     await _player.setAsset('assets/alarm.mp3');
//   }
//   await _player.play();
// }

}
// @pragma('vm:entry-point')
// void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
//
//   debugPrint('通知バーが表示されました！');
//
// }
//-------------------------------------------------------------
//   DB処理
//-------------------------------------------------------------
Future<int>  getPlayListRandomNo(int fileListNo) async {
  int lcRandomNo = 1;
  int lcMaxNo = 0;
  lcMaxNo = await getPlayListMaxNo(fileListNo);

  //ここでランダム範囲を設定(1 以上 lcMaxNo 未満)
  lcRandomNo = randomIntWithRange(1,lcMaxNo+1);
  debugPrint('RandomNo:$lcRandomNo');
  return lcRandomNo;

}
Future<int> getPlayListMaxNo(int fileListNo) async {

  int lcMaxNo = 0;
  String dbPath = await getDatabasesPath();
  String path = p.join(dbPath, 'internal_assets.db');
  Database database = await openDatabase(path, version: 1);
  List<Map> lcMapPlayList = await database.rawQuery("SELECT max(no) maxNo From playList where filelistno = $fileListNo");
  for(Map item in lcMapPlayList){
    lcMaxNo = (item['maxNo'] != null)?item['maxNo']:0;
  }
  debugPrint('MaxNo:$lcMaxNo');
  return lcMaxNo;
}
int randomIntWithRange(int min, int max) {
  int value =  math.Random().nextInt(max - min);
  return value + min;
}

Future<String>  getPlayListPath(int fileListNo) async {
  String musicPath = '';
  String dbPath = await getDatabasesPath();
  String path = p.join(dbPath, 'internal_assets.db');
  Database database = await openDatabase(path, version: 1);
  List<Map> result = await database.rawQuery("SELECT * From playList where no = $fileListNo ");
  for (Map item in result) {
    musicPath = (item['musicpath'].toString() != null)?item['musicpath'].toString():'';
  }
  return musicPath;
}

