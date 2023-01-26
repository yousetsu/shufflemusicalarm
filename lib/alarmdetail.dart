import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import './const.dart';
import './playlist.dart';
import 'dart:math' as math;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import './main.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import './globalmethod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

@pragma('vm:entry-point')
class AlarmDetailScreen extends StatefulWidget {
  String mode = '';
  int alarmNo = 0;
  AlarmDetailScreen(this.mode,this.alarmNo);

  @override
  State<AlarmDetailScreen> createState() =>  _AlarmDetailScreenState(mode,alarmNo);
}
@pragma('vm:entry-point')
class _AlarmDetailScreenState extends State<AlarmDetailScreen> with RouteAware {
  //バナー広告初期化
  final BannerAd myBanner = BannerAd(
    adUnitId : strCnsBannerID,
    size: AdSize.banner,
    request: const AdRequest(),
    listener: BannerAdListener(
      onAdLoaded: (Ad ad) => print('バナー広告がロードされました'),
      // Called when an ad request failed.
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        // Dispose the ad here to free resources.
        ad.dispose();
        //  print('バナー広告の読み込みが次の理由で失敗しました: $error');
      },
      // Called when an ad opens an overlay that covers the screen.
      onAdOpened: (Ad ad) => print('バナー広告が開かれました'),
      // Called when an ad removes an overlay that covers the screen.
      onAdClosed: (Ad ad) => print('バナー広告が閉じられました'),
      // Called when an impression occurs on the ad.
      onAdImpression: (Ad ad) => print('Ad impression.'),
    ),
  );
  String mode = '';
  int alarmNo = 0;

  _AlarmDetailScreenState(this.mode, this.alarmNo);

  final _formTitleKey = GlobalKey<FormState>();
  final _textControllerTitle = TextEditingController();
  String title = 'モードなし';
  DateTime _time = DateTime.utc(0, 0, 0);
  String buttonName = '登録';
  String playListSelButtonText = '';
  bool playListFlg = false;
  bool monFlg = false;bool tueFlg = false;bool wedFlg = false;
  bool thuFlg = false;bool friFlg = false;bool satFlg = false;bool sunFlg = false;
  bool isAlarmOn = false;
  bool timePress = false;


  @pragma('vm:entry-point')
  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void didChangeDependencies() {
    // 遷移時に呼ばれる関数
    // routeObserverに自身を設定(didPopのため)
    super.didChangeDependencies();
    if (ModalRoute.of(context) != null) {
      routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
    }
  }

  @override
  void dispose() {
    // routeObserverから自身を外す(didPopのため)
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (timePress) {
      setState(() => { timePress = false});
      return;
    }
    // 再描画
    init();
  }

  @override
  Widget build(BuildContext context) {
    //動画バナーロード
    myBanner.load();
    final AdWidget adWidget = AdWidget(ad: myBanner);
    final Container adContainer = Container(
      alignment: Alignment.center,
      width: myBanner.size.width.toDouble(),
      height: myBanner.size.height.toDouble(),
      child: adWidget,
    );

    return Scaffold(
      appBar: AppBar(
          title: Text(title), backgroundColor: const Color(0xFF6495ed)),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.fromLTRB(15, 15, 15, 5),
          //padding: const EdgeInsets.all(5.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12, width: 2),
            borderRadius: BorderRadius.circular(20),
            //   color: Colors.lightBlueAccent,
            boxShadow: [
              BoxShadow(color: Colors.white,
                  blurRadius: 10.0,
                  spreadRadius: 1.0,
                  offset: Offset(5, 5))
            ],
          ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('ON/OFF',
                    style: TextStyle(fontSize: 20.0, color: Color(0xFF191970))),
                Switch(value: isAlarmOn, onChanged: switchChange),
                Padding(padding: EdgeInsets.all(5)),

                ///時刻
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: const <Widget>[
                    Icon(Icons.timer, size: 25, color: Colors.blue),
                    Text('時刻', style: TextStyle(
                        fontSize: 20.0, color: Color(0xFF191970))),
                  ],),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.lightBlueAccent,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),),),
                  onPressed: () async {
                    timePress = true;
                    Picker(
                        adapter: DateTimePickerAdapter(
                            type: PickerDateTimeType.kHMS,
                            value: _time,
                            customColumnType: [3, 4]),
                        title: const Text("Select Time"),
                        onConfirm: (Picker picker, List value) {
                          setState(() =>
                          {_time =
                              DateTime.utc(2016, 5, 1, value[0], value[1], 0)});
                        },
                        onSelect: (Picker picker, int index,
                            List<int> selected) {
                          setState(() =>
                          {_time = DateTime.utc(
                              2016, 5, 1, selected[0], selected[1], 0)});
                        }
                    ).showModal(context);
                  },
                  child: Text(
                    '${_time.hour.toString().padLeft(2, '0')}:${_time.minute
                        .toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 35),),
                ),
                Padding(padding: EdgeInsets.all(10)),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: const <Widget>[
                    Icon(Icons.calendar_month, size: 25, color: Colors.blue),
                    Text('曜日', style: TextStyle(
                        fontSize: 20.0, color: Color(0xFF191970))),
                  ],),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          backgroundColor: monFlg ? Colors.blue : Colors.grey),
                        onPressed: () {
                          setState(() {
                            monFlg = !monFlg;
                          });
                        },
                        child: Text('月', style: TextStyle(
                          fontSize: 15.0, color: Colors.white,),),),
                      ElevatedButton(style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          backgroundColor: tueFlg ? Colors.blue : Colors.grey),
                        onPressed: () {
                          setState(() {
                            tueFlg = !tueFlg;
                          });
                        },
                        child: Text('火', style: TextStyle(
                          fontSize: 15.0, color: Colors.white,),),),
                      ElevatedButton(style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(5),
                          shape: CircleBorder(),
                          backgroundColor: wedFlg ? Colors.blue : Colors.grey),
                        onPressed: () {
                          setState(() {
                            wedFlg = !wedFlg;
                          });
                        },
                        child: Text('水', style: TextStyle(
                          fontSize: 15.0, color: Colors.white,),),),
                      ElevatedButton(style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          backgroundColor: thuFlg ? Colors.blue : Colors.grey),
                        onPressed: () {
                          setState(() {
                            thuFlg = !thuFlg;
                          });
                        },
                        child: Text('木', style: TextStyle(
                          fontSize: 15.0, color: Colors.white,),),),
                      ElevatedButton(style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          backgroundColor: friFlg ? Colors.blue : Colors.grey),
                        onPressed: () {
                          setState(() {
                            friFlg = !friFlg;
                          });
                        },
                        child: Text('金', style: TextStyle(
                          fontSize: 15.0, color: Colors.white,),),),
                    ]
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          backgroundColor: satFlg ? Colors.blue : Colors.grey),
                        onPressed: () {
                          setState(() {
                            satFlg = !satFlg;
                          });
                        },
                        child: Text('土', style: TextStyle(
                          fontSize: 15.0, color: Colors.white,),),),
                      ElevatedButton(style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          backgroundColor: sunFlg ? Colors.blue : Colors.grey),
                        onPressed: () {
                          setState(() {
                            sunFlg = !sunFlg;
                          });
                        },
                        child: Text('日', style: TextStyle(
                          fontSize: 15.0, color: Colors.white,),),),
                    ]),
                const Padding(padding: EdgeInsets.all(10)),

                ///音楽ファイル選択ボタン
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: const <Widget>[
                    Icon(Icons.queue_music, size: 25, color: Colors.blue),
                    Text('プレイリスト登録', style: TextStyle(fontSize: 20.0, color: Color(0xFF191970))),
                  ],),
                SizedBox(width: 150, height: 50,
                  child: ElevatedButton(
                    onPressed: musicSelButtonPressed,
                    style: ElevatedButton.styleFrom(backgroundColor: playListFlg ? Colors.blue : Colors.grey, elevation: 16, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),),),
                    child: Text(playListSelButtonText, style: const TextStyle(fontSize: 20.0, color: Colors.white,),),),),
                ///ラベル
                const Padding(padding: EdgeInsets.all(10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const  <Widget>[
                    Icon(Icons.label, size: 25, color: Colors.blue),
                     Text('ラベル(任意)', style: TextStyle(fontSize: 20.0, color: Color(0xFF191970))),],),
                Container(
                  padding: const EdgeInsets.all(5.0),
                  alignment: Alignment.bottomCenter,
                  width: 300.0, height: 70,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.lightBlueAccent),
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.lightBlueAccent,),
                  child: Form(
                    key: _formTitleKey,
                    child: TextFormField(
                      controller: _textControllerTitle,
                      style: const TextStyle(fontSize: 15, color: Colors.white,),
                      textAlign: TextAlign.center,
                      maxLength: 20,
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.all(10)),

                ///保存ボタン
                SizedBox(width: 180, height: 60,
                  child: ElevatedButton(
                    onPressed: buttonPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      elevation: 16,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),),),
                    child: Text(buttonName,
                      style: TextStyle(fontSize: 25.0, color: Colors.white,),),
                  ),
                ),
               const Padding(padding: EdgeInsets.all(15)),
                adContainer,
                const Padding(padding: EdgeInsets.all(10)),
              ]),
        ),

      ),
    );
  }

  void switchChange(value) {
    setState(() {isAlarmOn = value;},);
  }

  void buttonPressed() async {
    ///曜日必須チェック
    if(chkWeek(context,monFlg,tueFlg,wedFlg,thuFlg,friFlg,satFlg,sunFlg) == false) {
      return;
    }
    ///アラームファイル必須チェック
    if (playListFlg == false) {
      showDialog(context: context,
        builder: (_) {
          return AlertDialog(
            title: Text("警告"),
            content: Text("プレイリストに音楽ファイルを登録してください"),
            actions: <Widget>[
              TextButton(onPressed: () => { Navigator.pop(context)},
                child: const Text('閉じる'),),
            ],);},);
      return;
    }
    ///更新処理
    //拡張予定（第一引数：アラームNo,第二引数：ファイルリストNo)
     await updateAlarmData(alarmNo,alarmNo);
    ///アラーム処理
    await judgeAlarm(alarmNo,isAlarmOn);

    Navigator.pop(context);
  }



  void musicSelButtonPressed() async {
    int fileListNo = alarmNo;  //拡張用（fileListNo　= alarmno）

    //拡張予定（第一引数：アラームNo,第二引数：ファイルリストNo)
    updateAlarmData(alarmNo,alarmNo);

    ///アラーム処理(画面遷移するまえにアラームON/OFFによって判断する)
    judgeAlarm(alarmNo,isAlarmOn);

    Navigator.push(context, MaterialPageRoute(builder: (context) => playListEditScreen(fileListNo)),);
  }

  Future<void> init() async {
    switch (mode) {
    //編集モード
      case cnsAlarmDetailScreenUpd:
        title = 'アラーム設定';
        buttonName = '更新';
        loadEditData(alarmNo);
        break;
    }
    int playListCnt = 0;
    int fileListNo = alarmNo; //拡張用(alarmNo = filelistNo)
    playListFlg = false;
    //playlist存在チェック
    playListCnt = await getPlayListCount(fileListNo);
    if (playListCnt > 0) {
      setState(() {
        playListFlg = true;
      });
      playListSelButtonText = '選択済($playListCnt曲)';
    } else {
      setState(() {
        playListFlg = false;
      });
      playListSelButtonText = '未選択';
    }
  }

  Future<int> getPlayListCount(int fileListNo) async {
    int playListCnt = 0;
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);
    List<Map> result = await database.rawQuery(
        "SELECT count(*) cnt From playList where filelistno = $fileListNo");
    for (Map item in result) {
      playListCnt = item['cnt'];
    }
    return playListCnt;
  }

  void loadEditData(int editNo) async {
    String lcTitle = '';
    String lcTime = '';
    int lcAlarmFlag = 0;
    int intLcMon = 0;int intLcTue = 0;int intLcWed = 0;int intLcThu = 0;int intLcFri = 0;int intLcSat = 0;int intLcSun = 0;
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);
    List<Map> result = await database.rawQuery(
        "SELECT * From alarmList where alarmno = $editNo");
    for (Map item in result) {
      lcTitle = item['title'].toString();
      lcTime = item['time'].toString();
      lcAlarmFlag = item['alarmflg'];
      intLcMon = item['mon'];intLcTue = item['tue'];intLcWed = item['wed'];
      intLcThu = item['thu'];intLcFri = item['fri'];intLcSat = item['sat'];intLcSun = item['sun'];
    }
    setState(() {
      _textControllerTitle.text = lcTitle;
      _time = DateTime.parse(lcTime);
      if (lcAlarmFlag == cnsFlgOff) {
        isAlarmOn = false;
      } else {
        isAlarmOn = true;
      }
      monFlg = (intLcMon == cnsFlgOn) ? true : false;tueFlg = (intLcTue == cnsFlgOn) ? true : false;wedFlg = (intLcWed == cnsFlgOn) ? true : false;
      thuFlg = (intLcThu == cnsFlgOn) ? true : false;friFlg = (intLcFri == cnsFlgOn) ? true : false;satFlg = (intLcSat == cnsFlgOn) ? true : false;sunFlg = (intLcSun == cnsFlgOn) ? true : false;
    });
  }

  Future<void> updateAlarmData(int alramNo, int filelistNo) async {
    String dbPath = await getDatabasesPath();
    String query = '';
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);

    //オンにした音楽鳴らす
    int lcAlarmFlg = isAlarmOn ? cnsFlgOn : cnsFlgOff;
    int intLcMon = monFlg ? cnsFlgOn : cnsFlgOff;int intLcTue = tueFlg ? cnsFlgOn : cnsFlgOff;int intLcWed = wedFlg ? cnsFlgOn : cnsFlgOff;
    int intLcThu = thuFlg ? cnsFlgOn : cnsFlgOff;int intLcFri = friFlg ? cnsFlgOn : cnsFlgOff;int intLcSat = satFlg ? cnsFlgOn : cnsFlgOff;int intLcSun = sunFlg ? cnsFlgOn : cnsFlgOff;

    query = 'UPDATE alarmList set '
        + 'time = "${_time.toString()}",title = "${_textControllerTitle
            .text}",alarmflg = $lcAlarmFlg, filelistno = $filelistNo, '
        + 'mon = $intLcMon,' + 'tue = $intLcTue,' + 'wed = $intLcWed,'
        + 'thu = $intLcThu,' + 'fri = $intLcFri,' + 'sat = $intLcSat,' + 'sun = $intLcSun'
        + ' where alarmno = $alramNo';
    await database.transaction((txn) async {
      await txn.rawInsert(query);
    });
  }
  Future<void> setAlarm(int alarmID) async{
    ///時刻設定処理(AndroidAlarmManager)
    //時刻を現在時刻と比較する
    DateTime dtNow = DateTime.now();
    DateTime dtSetTime = DateTime(dtNow.year, dtNow.month, dtNow.day, _time.hour, _time.minute);
    DateTime dtBaseDay = DateTime.now();

    //最終的なアラーム設定日時
    DateTime dtAlarmDayTime = DateTime.now();
    if (dtSetTime.isAfter(dtNow)) {
      // 設定時刻が現在の時刻よりも後の場合、今日設定
      dtBaseDay = dtSetTime;
    } else {
      // 設定時刻が現在の時刻よりも前の場合、明日
      dtBaseDay = dtSetTime.add(const Duration(days: 1));
    }
    //対象の曜日になるまで設定時刻を繰り返す(共通化)
    dtAlarmDayTime = calAlarDay(dtBaseDay, monFlg, tueFlg, wedFlg, thuFlg, friFlg, satFlg, sunFlg);

    ///通知バー時刻設定
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterNativeTimezone
        .getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, dtAlarmDayTime.year, dtAlarmDayTime.month,
        dtAlarmDayTime.day, dtAlarmDayTime.hour, dtAlarmDayTime.minute);

   // String _sound = ;
    await flutterLocalNotificationsPlugin.zonedSchedule(
        alarmID, 'シャッフル音楽アラーム', '通知バーをタップをしたら音楽を停止します',
        scheduledDate,
        const NotificationDetails(
            android: AndroidNotificationDetails(
                'your channel id', 'your channel name',
                channelDescription: 'your channel description',
                priority: Priority.high,
                playSound: true,
                sound:UriAndroidNotificationSound('content://storage/emulated/0/Music/HE-LOW/HE-LOW/07 - 勝利の未来.mp3'),
                importance: Importance.high,
                fullScreenIntent: true
            )), androidAllowWhileIdle: true,
        payload: alarmNo.toString(),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation
            .absoluteTime);

    ///音楽再生時刻設定
    //拡張用filelistno = alarmno
    //await AndroidAlarmManager.oneShotAt(dtAlarmDayTime, alarmID, playSound1, exact: true, wakeup: true, alarmClock: true, allowWhileIdle: true);


  }
  Future<void> judgeAlarm(int alarmNo, bool isAlarmOn) async{
    ///アラームIDの生成（固定の接頭辞＋アラームNo）
    String strAlarmID = cnsPreAlarmId + alarmNo.toString();
    int alarmID = int.parse(strAlarmID);
    if (isAlarmOn) {
      ///アラーム取消(先に取消しておく)
      await cancelAlarm(alarmID);
      ///アラームオン
      await setAlarm(alarmID);
    } else {
      ///アラーム取消
      await cancelAlarm(alarmID);
    }
  }
  Future<void> cancelAlarm(int alarmID) async{
    //通知の取消
    await flutterLocalNotificationsPlugin.cancel(alarmID);
    //音楽再生の取消
    AndroidAlarmManager.cancel(alarmID);
  }
}
//-------------------------------------------------------------
//   DB処理
//-------------------------------------------------------------
  Future<int> getPlayListRandomNo(int fileListNo) async {
    int lcRandomNo = 1;
    int lcMaxNo = 0;
    lcMaxNo = await getPlayListMaxNo(fileListNo);

    //ここでランダム範囲を設定(1 以上 lcMaxNo 未満)
    lcRandomNo = randomIntWithRange(1, lcMaxNo + 1);
    return lcRandomNo;
  }

  Future<int> getPlayListMaxNo(int fileListNo) async {
    int lcMaxNo = 0;
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);
    List<Map> lcMapPlayList = await database.rawQuery(
        "SELECT max(no) maxNo From playList where filelistno = $fileListNo");
    for (Map item in lcMapPlayList) {
      lcMaxNo = (item['maxNo'] != null) ? item['maxNo'] : 0;
    }
    return lcMaxNo;
  }

  int randomIntWithRange(int min, int max) {
    int value = math.Random().nextInt(max - min);
    return value + min;
  }

  Future<String> getPlayListPath(int playNo,int fileListNo) async {
    String musicPath = '';
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);
    List<Map> result = await database.rawQuery(
        "SELECT * From playList where no = $playNo and filelistno = $fileListNo ");
    for (Map item in result) {
      musicPath = (item['musicpath'].toString() != null)
          ? item['musicpath'].toString()
          : '';
    }
    return musicPath;
  }
