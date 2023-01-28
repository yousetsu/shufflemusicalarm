import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import './const.dart';
import './alarmdetail.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import './globalmethod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

RewardedAd? _rewardedAd;
const int maxFailedLoadAttempts = 3;
late AudioPlayer _player = AudioPlayer();
List<Widget> listWedgetitems = <Widget>[];
List<Map> alarmResetMap = <Map>[];
List<Map> mapAlarmList = <Map>[];
int notificationType = 0;
bool testFLG = false;
///android_alarm_manager_plusで必要な定義
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//didpop使う為
final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();
bool  playFlg = false;
/*------------------------------------------------------------------
全共通のメソッド
 -------------------------------------------------------------------*/
//初回起動分の処理
@pragma('vm:entry-point')
Future<void> firstRun() async {
  String dbpath = await getDatabasesPath();
  //設定テーブル作成
  String path = p.join(dbpath, "internal_assets.db");
  //設定テーブルがなければ、最初にassetsから作る
  var exists = await databaseExists(path);
  if (!exists) {
    // Make sure the parent directory exists
    //親ディレクリが存在することを確認
    try {
      await Directory(p.dirname(path)).create(recursive: true);
    } catch (_) {}
    // Copy from asset
    ByteData data = await rootBundle.load(p.join("assets", "exShuffle.db"));
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    // Write and flush the bytes written
    await File(path).writeAsBytes(bytes, flush: true);
  } else {
    //print("Opening existing database");
  }
}
@pragma('vm:entry-point')
Future<void> getAlarmData(int alarmNo) async {

  String dbPath = await getDatabasesPath();
  String path = p.join(dbPath, 'internal_assets.db');
  Database database = await openDatabase(path, version: 1);
  alarmResetMap = await database.rawQuery("SELECT * From alarmList where alarmno = $alarmNo");

}
@pragma('vm:entry-point')
void main() async{
  debugPrint('main通過');
  //SQLflite + android_alarm_manager_plusで必要  main関数内で非同期処理するときの決まり文句らしい
  WidgetsFlutterBinding.ensureInitialized();
  ///android_alarm_manager_plusで必要
  await AndroidAlarmManager.initialize();
  ///android_alarm_manager_plusで必要な初期設定


  await firstRun();
  runApp(const MyApp());
}

@pragma('vm:entry-point')
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // primaryColor: const Color(0xFF191970),
        primaryColor: Colors.blue,
        hintColor: const Color(0xFF2196f3),
        //canvasColor: Colors.black,
          backgroundColor: const Color(0xFF000000),
        canvasColor: const Color(0xFFFFf8f8ff),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(secondary: const Color(0xFF2196f3)),
      ),
      home: const MainScreen(),
       //didipop使うため
       navigatorObservers: [routeObserver],
    );
  }
}
@pragma('vm:entry-point')
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

@pragma('vm:entry-point')
class _MainScreenState extends State<MainScreen> with RouteAware {
  bool isAlarmOn = false;
  Key? listViewKey;
  int _numRewardedLoadAttempts = 0;

  @pragma('vm:entry-point')
  @override
  void initState() {
    super.initState();
    init();
    initAlarm();
   // _createRewardedAd();
  }
  Future<void> alarmStopNextSet(String? payload)async{
    int alarmID = 0;
    int alarmNo = 0;

    if (payload != null) {
      alarmNo = int.parse(payload);
      alarmID = int.parse(cnsPreAlarmId + payload);
    }
    ///アラームを止める
    await AndroidAlarmManager.oneShot(const Duration(seconds: 0), alarmID, stopSound,exact: true, wakeup: true, alarmClock: true, allowWhileIdle: true);
    ///止めたら次のアラームを設定する
    //次回のアラーム時刻を算出する
    String strTime = '';
    int intMonFlg = 0;int intTueFlg = 0;int intWedFlg = 0;int intThuFlg = 0;int intFriFlg = 0;int intSatFlg = 0;int intSunFlg = 0;
    //アラームテーブルから曜日と時刻を取り出す。
    await getAlarmData(alarmNo);
    for(Map item in alarmResetMap ){
      strTime = item['time'].toString();
      intMonFlg = item['mon'];intTueFlg = item['tue'];intWedFlg = item['wed'];
      intThuFlg = item['thu'];intFriFlg = item['fri'];intSatFlg = item['sat'];intSunFlg = item['sun'];
    }

    //その情報を元に明日の起床時刻を割り出す。
    DateTime dtTime = DateTime.parse(strTime);
    DateTime dtNowTime = DateTime.now();
    bool monFlg = false;bool tueFlg = false;bool wedFlg = false;
    bool thuFlg = false;bool friFlg = false;bool satFlg = false;bool sunFlg = false;

    monFlg = (intMonFlg == cnsFlgOn)?true:false;tueFlg = (intTueFlg == cnsFlgOn)?true:false;
    wedFlg = (intWedFlg == cnsFlgOn)?true:false;thuFlg = (intThuFlg == cnsFlgOn)?true:false;
    friFlg = (intFriFlg == cnsFlgOn)?true:false;satFlg = (intSatFlg == cnsFlgOn)?true:false;
    sunFlg = (intSunFlg == cnsFlgOn)?true:false;

    //次の日の起床時刻を算出
    DateTime dtBaseTime = DateTime(dtNowTime.year,dtNowTime.month,dtNowTime.day,dtTime.hour,dtTime.minute).add(const Duration(days: 1));

    //曜日を考慮した時刻を算出
    DateTime dtNextAlarmTime = calAlarDay(dtBaseTime,monFlg,tueFlg,wedFlg,thuFlg,friFlg,satFlg,sunFlg);

    ///音楽再生時刻設定
    await AndroidAlarmManager.oneShotAt(dtNextAlarmTime, alarmID, playSound,exact: true, wakeup: true, alarmClock: true, allowWhileIdle: true);
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    ///通知バー時刻設定
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, dtNextAlarmTime.year, dtNextAlarmTime.month, dtNextAlarmTime.day, dtNextAlarmTime.hour,dtNextAlarmTime.minute);

    await flutterLocalNotificationsPlugin.zonedSchedule(
        alarmID, 'シャッフル音楽アラーム', '通知バーをタップをしたら音楽を停止します',
        scheduledDate,
        const NotificationDetails(
            android: AndroidNotificationDetails('your channel id', 'your channel name',
                channelDescription: 'your channel description',
                priority: Priority.high, playSound:false, importance: Importance.high, fullScreenIntent: true
            )), androidAllowWhileIdle: true,
        payload: alarmID.toString(),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
  }
  @pragma('vm:entry-point')
  Future<void> playSoundChek(int alarmID) async {
    debugPrint('プレイしてますか？state:${_player.playerState.playing.toString()}');
  }
  @pragma('vm:entry-point')
  Future<void> playSound(int alarmID) async {
    int playNo = 0;
    String strAlarmID = alarmID.toString();
    strAlarmID = strAlarmID.replaceFirst(cnsPreAlarmId, '');
    int playListNo = int.parse(strAlarmID);//拡張(アラームNO = プレイリストNo)

    ///PlaylistからNOを取得し、ランダムで1つ返す
    playNo = await getPlayListRandomNo(playListNo);
    ///そのナンバーからpath名を取得
    String musicPath = await getPlayListPath(playNo,playListNo);

    ///ここでmusicを鳴らす

    await _player.setLoopMode(LoopMode.all);
    await _player.setFilePath(musicPath);
    await _player.play();
  }
  @pragma('vm:entry-point')
  static  stopSound() async {
    debugPrint('stopsound');
    await _player.stop();
  }
  @pragma('vm:entry-point')
  void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {

    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      int alarmID = 0;
      int alarmNo = 0;

      if (payload != null) {
        alarmNo = int.parse(payload);
        alarmID = int.parse(cnsPreAlarmId + payload);
      }
      debugPrint('音楽停止');
       await AndroidAlarmManager.oneShot(const Duration(seconds: 0), alarmID, stopSound1, exact: true, wakeup: true, alarmClock: true, allowWhileIdle: true);

      //   await alarmStopNextSet(payload);
    }

  }
  @pragma('vm:entry-point')
  void initAlarm() async {
    //Android13だと通知を要求するか聞いてくれるらしい？
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestPermission();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher');
    //OSごとに初期化をする(今はandroidのみ)
    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid);
    //通知バーをタップしたら飛ぶメソッドを定義する
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

    NotificationAppLaunchDetails? _lanuchDeatil = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (_lanuchDeatil != null) {
      if (_lanuchDeatil.didNotificationLaunchApp) {
        String? payload = _lanuchDeatil!.notificationResponse?.payload;
        int alarmID = 0;
        int alarmNo = 0;
        if (payload != null) {
          alarmNo = int.parse(payload);
          alarmID = int.parse(cnsPreAlarmId + payload);
        }


        //スマホ自体がスリープだと通知が出ないので以下の処理をする。
        //通知とアラームを取り消す

        ///プレイヤーが起動していなかったら(通常パターン(アプリが終了してて、スマホがスリープ))
        debugPrint('プレイしてますか？state:${_player.playerState.playing.toString()}');
        await AndroidAlarmManager.oneShot(const Duration(seconds: 0), alarmID, playSoundChek, exact: true, wakeup: true, alarmClock: true, allowWhileIdle: true);

        if(_player.playerState.playing == false){

          debugPrint('通知とアラームを取り消す');
          await flutterLocalNotificationsPlugin.cancel(alarmID);
          await AndroidAlarmManager.cancel(alarmID);

        //再度showする
        await flutterLocalNotificationsPlugin.show(
            alarmID, 'シャッフル音楽アラーム', '通知バーをタップをしたら音楽を停止します',
            const NotificationDetails(android: AndroidNotificationDetails(
                'shuffleMusicAlarm', 'シャッフル音楽アラームの通知',
                channelDescription: 'シャッフル音楽アラームの通知',
                priority: Priority.high,
                playSound: false,
                importance: Importance.high,
                fullScreenIntent: true)),
            payload: payload);
        //音楽を即時起動させる
        debugPrint('音楽即時起動');
        await AndroidAlarmManager.oneShot(const Duration(seconds: 0), alarmID, playSound1, exact: true, wakeup: true, alarmClock: true, allowWhileIdle: true);
        debugPrint('initのdidNotificationLaunchApp');
        //    await alarmStopNextSet(payload);
      }
        ///プレイヤーが起動している()
        else{
          debugPrint('アプリが終了してて、スマホが立ち上がっているレアパターンstate:${_player.playerState.playing.toString()}');
          await AndroidAlarmManager.oneShot(const Duration(seconds: 0), alarmID, stopSound1, exact: true, wakeup: true, alarmClock: true, allowWhileIdle: true);

        }

      }
    }
  }

  @override
  void didChangeDependencies() { // 遷移時に呼ばれる関数
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
    // 再描画
    init();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('シャッフル音楽アラーム'),backgroundColor: const Color(0xFF6495ed),),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:  <Widget>[
          const Padding(padding: EdgeInsets.all(5)),
          Expanded(child: ListView(key: listViewKey,children: listWedgetitems, ),),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: insertAlarmList,
        tooltip: '登録',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatt
    );
  }
  void insertAlarmList() async{
  //  Navigator.push(context, MaterialPageRoute(builder: (context) => AlarmDetailScreen(cnsAlarmDetailScreenIns,-1)),);
    int intMax = await getMaxAlarmNo();
    //アラームが3個以上なら動画視聴
//    _showRewardedAd(intMax + 1); TODO
    await insertAlarmData(intMax + 1); //拡張予定（引数にファイルリストNoを追加）
    init();
  }
  Future<void> insertAlarmData(int lcNo) async {
    String dbPath = await getDatabasesPath();
    String query = '';
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);
    int filelistNo = lcNo; //拡張予定（アラームナンバーと同じのを入れる）
    int lcAlarmFlg = 0;
    DateTime initTime = DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day,7,0,0);
    query =
    'INSERT INTO alarmList(alarmno,time,title,alarmflg,playmode,filelistno,soundtime,week,mon,tue,wed,thu,fri,sat,sun,vol,snooze,fadein,kaku1,kaku2,kaku3,kaku4) '
        + 'values($lcNo,"${initTime.toString()}","",$lcAlarmFlg,0, $filelistNo,  "",0,1,1,1,1,1,1,1,0,0,0,null,null,null,null)';
    await database.transaction((txn) async {
      await txn.rawInsert(query);
    });
  }
  Future<int> getMaxAlarmNo() async {
    int maxNo = 0;
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);
    List<Map> result = await database.rawQuery(
        "SELECT MAX(alarmno) no From alarmList");
    for (Map item in result) {
      maxNo = (item['no'] != null) ? item['no'] : 0;
    }
    return maxNo;
  }
  void updAlarmList(int lcNo){
    Navigator.push(context, MaterialPageRoute(builder: (context) => AlarmDetailScreen(cnsAlarmDetailScreenUpd,lcNo)),);
  }
  Future<void> delAlarmList(int lcNo) async{
    int alarmListCnt = 0;
    alarmListCnt = await  cntAlarmList();
    if(alarmListCnt <= 1){
      showDialog(context: context,
        builder: (_) {
          return AlertDialog(
            title: Text("警告"),
            content: Text("アラームが１つしかないので削除できません"),
            actions: <Widget>[TextButton(onPressed: () => { Navigator.pop(context)}, child: const Text('閉じる'),),],
          );
        },
      );
      return;
    }
    //指定したアラームを削除
    await delAlarmDB(lcNo);
    //番号振り直し
    await updAlarmListReNo();
    await loadList();
    await getItems();
  }
  Future<void>  delAlarmDB(int lcNo)async{
    String dbPath = await getDatabasesPath();
    String query = '';
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);
    query = 'DELETE From alarmList where alarmno = $lcNo';
    await database.transaction((txn) async {
      await txn.rawInsert(query);
    });
  }
  Future<void> updAlarmListReNo() async{
    //番号順にリスト再取得
    int reNo = 1;
    String dbPath = await getDatabasesPath();
    String query = '';
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);
    List<Map> lcMapList = await database.rawQuery("SELECT * From alarmList order by alarmno");
    //番号を振り直しして更新
    for (Map item in lcMapList) {
      query = 'UPDATE alarmList set alarmno = $reNo where alarmno = ${item['alarmno']}';
      await database.transaction((txn) async {
        await txn.rawInsert(query);
      });
      reNo++;
    }
  }
  Future<void> getItems() async {
    List<Widget> list = <Widget>[];
    int alarmListNo = 0;
    String strWeekText = '';
    String strTimeText = '';
    DateTime dtTime = DateTime.now();
    final lists = ['削除'];
    int index = 0;
    for (Map item in mapAlarmList) {
      strWeekText = '';
      dtTime = DateTime.parse(item['time']);
      strTimeText = '${dtTime.hour.toString().padLeft(2,'0')}:${dtTime.minute.toString().padLeft(2,'0')}';
      if(item['mon'] == 1) {strWeekText = '$strWeekText月';}
      if(item['tue'] == 1) {strWeekText =  '$strWeekText火';}
      if(item['wed'] == 1) {strWeekText =  '$strWeekText水';}
      if(item['thu'] == 1) {strWeekText =  '$strWeekText木';}
      if(item['fri'] == 1) {strWeekText =  '$strWeekText金';}
      if(item['sat'] == 1) {strWeekText =  '$strWeekText土';}
      if(item['sun'] == 1) {strWeekText =  '$strWeekText日';}
      if(strWeekText == '月火水木金土日') {strWeekText = '毎日';}
      bool alarmFlg = false;
      if (item['alarmflg'] == cnsFlgOn){
        alarmFlg = true;
      }
      list.add(
        Card(
          margin: const EdgeInsets.fromLTRB(15,0,15,15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          key: Key('$index'),
          child: ListTile(
         //   tileColor: const Color(0xFFFFFFF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15),),
            contentPadding: const EdgeInsets.all(10),
            leading: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children:  <Widget>[
                  Icon(Icons.alarm,size: 25,color: alarmFlg?Colors.blue:Colors.grey),
                  Text(alarmFlg?'ON':'OFF', style:const TextStyle(color: Colors.grey , fontSize: 10)),
                ]
            ),
            title: Text('$strTimeText ', style:const TextStyle(color: Colors.blue , fontSize: 35) ),
            subtitle:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:  <Widget>[
                Text('${item['title']}  ', style: TextStyle(color: const Color(0xFF191970) , fontSize: 15),),
                Text('  ' + strWeekText, style: TextStyle(color: const Color(0xFF191970) , fontSize: 15),),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) {
                return lists.map((String list) {return PopupMenuItem(value: list, child: Text(list),);}).toList();
              },
              onSelected: (String list) {
                switch (list) {
                  case '削除':delAlarmList(item['alarmno']);
                    break;
                }
              },
            ),
            selected: alarmListNo == item['alarmno'],
            onTap: () {
              alarmListNo= item['alarmno'];
              _tapTile(alarmListNo);
            },
          ),
        ),
      );
      index++;
    }
    setState(() {listWedgetitems = list;});
  }
  Future<void> _tapTile(int alarmListNo) async{
    Navigator.push(context, MaterialPageRoute(builder: (context) => AlarmDetailScreen(cnsAlarmDetailScreenUpd,alarmListNo)),);
  }
  /*------------------------------------------------------------------
第一画面ロード
 -------------------------------------------------------------------*/
  Future<void>  loadList() async {
    mapAlarmList = <Map>[];
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);
    mapAlarmList = await database.rawQuery("SELECT * From alarmList order by alarmno");
  }

  Future<int>  cntAlarmList() async {
    int cnt = 1;
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);
    List<Map> lcMapAlarmList = await database.rawQuery("SELECT count(*) cnt From alarmList");
    for(Map item in lcMapAlarmList){
      cnt = item['cnt'];
    }
    return cnt;
  }
  /*------------------------------------------------------------------
初期処理
 -------------------------------------------------------------------*/
  void init() async {
  //  TODO
    debugPrint('init通過');
    // await  testEditDB();
  //  await permissionAllCheck();
 //   permissionCheckGroup();
 //   permissionCheckReadAudio();
  //  permissionCheckmanageExternalStorage();
 //   permissionCheckStorage();
  //  permissionCheckmanageAudioGroup();
    await loadList();
    await getItems();
  }
  Future<void>permissionCheckmanageAudioGroup() async {
    Map<Permission, PermissionStatus> statuses;

    var   statusvideos = await Permission.videos.status;
    var  statusphotos = await Permission.photos.status;
    var  statusaudio= await Permission.audio.status;
    if (statusvideos != PermissionStatus.granted
        || statusphotos != PermissionStatus.granted
        || statusaudio != PermissionStatus.granted
    ) {
      statuses = await [
        Permission.videos,
        Permission.photos,
        Permission.audio,
      ].request();
    }
    debugPrint('videos:$statusvideos');
    debugPrint('photos:$statusphotos');
    debugPrint('audio:$statusaudio');

  }
    Future<void>permissionCheckGroup() async{

    Map<Permission, PermissionStatus> statuses;

    var   statusvideos = await Permission.videos.status;
    var  statusphotos = await Permission.photos.status;
    var  statusaudio= await Permission.audio.status;
    var  statusaccessMediaLocation= await Permission.accessMediaLocation.status;
    var  statusaccessnotification= await Permission.notification.status;
    var  statusaccessmanageExternalStorage= await Permission.manageExternalStorage.status;
    if (statusvideos != PermissionStatus.granted
        || statusphotos != PermissionStatus.granted
        || statusaudio != PermissionStatus.granted
        || statusaccessMediaLocation != PermissionStatus.granted
        || statusaccessnotification != PermissionStatus.granted
        || statusaccessmanageExternalStorage != PermissionStatus.granted
    ) {
       statuses = await [
        Permission.videos,
        Permission.photos,
        Permission.audio,
        Permission.accessMediaLocation,
        Permission.notification,
        Permission.manageExternalStorage,
      ].request();
    }
     debugPrint('videos:$statusvideos');
     debugPrint('photos:$statusphotos');
     debugPrint('audio:$statusaudio');
    debugPrint('accessMediaLocation:$statusaccessMediaLocation');
    debugPrint('notification:$statusaccessnotification');
    debugPrint('ExternalStorage:$statusaccessmanageExternalStorage');


   }
  Future<void>permissionCheckReadAudio() async {
    var status = await Permission.manageExternalStorage.status;
    if ( status != PermissionStatus.granted) {
      status = await Permission.manageExternalStorage.request();
    }
  }

  Future<void>permissionCheckStorage() async {
    var status = await Permission.storage.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.storage.request();
    }
  }
  Future<void>permissionCheckmanageExternalStorage() async {
    var status = await Permission.audio.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.audio.request();
    }
    // 権限がない場合の処理.
    // if (status != PermissionStatus.granted) {
    //   showDialog(context: context,
    //     builder: (_) {
    //       return AlertDialog(
    //         title: Text("権限を許可してください。"),
    //         content: Text("設定->アプリ->シャッフル音楽アラーム->権限->音楽とオーディオと動画を許可にしてください。"),
    //         actions: <Widget>[TextButton(onPressed: () => {SystemNavigator.pop()}, child: const Text('閉じる'),),],
    //       );
    //     },
    //   );
    // }
  }
Future<void> permissionAllCheck() async{
  Map<Permission, PermissionStatus> statuses;
  var  statusaccessmanageExternalStorage= await Permission.manageExternalStorage.status;
  if (statusaccessmanageExternalStorage != PermissionStatus.granted
  ) {
    statuses = await [
      Permission.manageExternalStorage,
    ].request();
  }
  debugPrint('ExternalStorage:$statusaccessmanageExternalStorage');
}


/*------------------------------------------------------------------
動画準備
 -------------------------------------------------------------------*/
  void _createRewardedAd() {
    RewardedAd.load(
        adUnitId: strCnsRewardID,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            print('$ad loaded.');
            _rewardedAd = ad;
            _numRewardedLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('RewardedAd failed to load: $error');
            _rewardedAd = null;
            _numRewardedLoadAttempts += 1;
            if (_numRewardedLoadAttempts < maxFailedLoadAttempts) {
              _createRewardedAd();
            }
          },
        ));
  }
/*------------------------------------------------------------------
動画実行
 -------------------------------------------------------------------*/
  void _showRewardedAd(int alarmCnt) async {
    if(alarmCnt >= 3 ) {
      if (_rewardedAd == null) {
        print('Warning: attempt to show rewarded before loaded.');
        return;
      }
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (RewardedAd ad) =>
            print('ad onAdShowedFullScreenContent.'),
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          print('$ad onAdDismissedFullScreenContent.');
          ad.dispose();
          _createRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          print('$ad onAdFailedToShowFullScreenContent: $error');
          ad.dispose();
          _createRewardedAd();
        },
      );
      _rewardedAd!.setImmersiveMode(true);
      _rewardedAd!.show(
          onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            print('$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
          });
      _rewardedAd = null;
    }
  }
}

@pragma('vm:entry-point')
Future<void> playSound1(int alarmID) async {
  int playNo = 0;

  //1分ごとに再設定
 // await AndroidAlarmManager.cancel(alarmID);

  DateTime dtNowTime = DateTime.now();
  debugPrint('playSound1起動時刻:$dtNowTime ');
//  DateTime dtGetupTime = DateTime(dtNowTime.year,dtNowTime.month,dtNowTime.day,12,54,0);
 // debugPrint('dtGetupTime:$dtGetupTime dtNowTime:$dtNowTime ');
  //時間になったかを判定する。
  //起床時刻 > 現在時刻
  // if(dtGetupTime.isAfter(dtNowTime)) {
  //   debugPrint("まだです。");
  //   await AndroidAlarmManager.oneShot(const Duration(minutes: 1), alarmID, playSound1, exact: true, wakeup: true, alarmClock: true, allowWhileIdle: true);
  // }else{

    debugPrint("時間になりました！");
    //時間になったら音を鳴らす
    String strAlarmID = alarmID.toString();
    strAlarmID = strAlarmID.replaceFirst(cnsPreAlarmId, '');
    int playListNo = int.parse(strAlarmID);//拡張(アラームNO = プレイリストNo)

    ///PlaylistからNOを取得し、ランダムで1つ返す
    playNo = await getPlayListRandomNo(playListNo);
    ///そのナンバーからpath名を取得
    String musicPath = await getPlayListPath(playNo,playListNo);

   debugPrint('musicPath:$musicPath');

    ///ここでmusicを鳴らす
    await _player.setLoopMode(LoopMode.all);
    await _player.setFilePath(musicPath);
  debugPrint('state:${_player.playerState.toString()}');
  debugPrint('play');
    await _player.play();
  debugPrint('state:${_player.playerState.toString()}');
 // }
}

@pragma('vm:entry-point')
stopSound1() async {
  debugPrint('state:${_player.playerState.toString()}');
  debugPrint('stopsound1');
  await _player.stop();
  debugPrint('state:${_player.playerState.toString()}');
}
