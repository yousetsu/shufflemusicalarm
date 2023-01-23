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
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import './playlist.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
int alarmID = 8765;
late AudioPlayer _player;

List<Widget> listWedgetitems = <Widget>[];
List<Map> mapAlarmList = <Map>[];
int notificationType = 0;
bool testFLG = false;
///android_alarm_manager_plusで必要な定義
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//didpop使う為
final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();
/*------------------------------------------------------------------
全共通のメソッド
 -------------------------------------------------------------------*/
//初回起動分の処理
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
Future<void> playSound() async {
  int playNo = 0;
  debugPrint('スタート！');

  ///PlaylistからNOを取得し、ランダムで1つ返す
  playNo = await getPlayListRandomNo(0);

  ///そのナンバーからpath名を取得
  String musicPath = await getPlayListPath(playNo);
  debugPrint('no:$playNo  path:$musicPath ');

  ///ここでmusicを鳴らす
  _player = AudioPlayer();
  await _player.setLoopMode(LoopMode.all);
  await _player.setFilePath(musicPath);
  await _player.play();
}

@pragma('vm:entry-point')
Future<void> stopSound() async {
  debugPrint('ストップ！');
  await _player.stop();
}

void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse) async {
  final String? payload = notificationResponse.payload;
  if (notificationResponse.payload != null) {
    debugPrint('notification payload: $payload');
  }
  debugPrint('タップされました！');
  await AndroidAlarmManager.oneShot(const Duration(seconds: 0), alarmID, stopSound,exact: true, wakeup: true, alarmClock: true, allowWhileIdle: true);

}
void main() async{
  //SQLflite + android_alarm_manager_plusで必要
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('main通過');

  ///android_alarm_manager_plusで必要
  await AndroidAlarmManager.initialize();

  ///android_alarm_manager_plusで必要な初期設定
   // //Android13だと通知を要求するか聞いてくれるらしい？
   flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestPermission();

   const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

   //OSごとに初期化をする(今はandroidのみ)
   final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

   //通知バーをタップしたら飛ぶメソッドを定義する
   await flutterLocalNotificationsPlugin.initialize(initializationSettings,
     onDidReceiveNotificationResponse:onDidReceiveNotificationResponse);


  NotificationAppLaunchDetails? _lanuchDeatil
  =await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  if (_lanuchDeatil!=null){
    if (_lanuchDeatil.didNotificationLaunchApp) {
      debugPrint('タップから呼ばれたぜ！');
      await AndroidAlarmManager.oneShot(const Duration(seconds: 0), alarmID, stopSound,exact: true, wakeup: true, alarmClock: true, allowWhileIdle: true);

    }else {
      debugPrint('タップから呼ばなかったよ・・・');
    }
  }
  //
  // //通知バーの表示分定義(andorid分)
  // const AndroidNotificationDetails androidNotificationDetails
  // = AndroidNotificationDetails('your channel id', 'your channel name',
  //     channelDescription: 'your channel description',
  //     importance: Importance.high,
  //     priority: Priority.high,
  //     fullScreenIntent: true,
  //     ticker: 'ticker');
  // const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

  // //即時通知される
  // await flutterLocalNotificationsPlugin.show(0, 'plain title', 'plain body', notificationDetails, payload: 'item x');


  // // //時刻起動する場合のタイムゾーン設定
  // tz.initializeTimeZones();
  // final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
  // tz.setLocalLocation(tz.getLocation(timeZoneName));
  //
  // //時間起動通知される
  // await flutterLocalNotificationsPlugin.zonedSchedule(
  //     0,
  //     'scheduled title',
  //     'scheduled body',
  //     tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
  //     const NotificationDetails(
  //         android: AndroidNotificationDetails(
  //             'your channel id', 'your channel name',
  //             channelDescription: 'your channel description',
  //             priority: Priority.high,
  //             playSound:false,
  //             importance: Importance.high,
  //             fullScreenIntent: true)),
  //     androidAllowWhileIdle: true,
  //     uiLocalNotificationDateInterpretation:
  //     UILocalNotificationDateInterpretation.absoluteTime);


  await firstRun();
  runApp(const MyApp());
}

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
        //  backgroundColor: const Color(0xFF191970),
        canvasColor: const Color(0xFFf8f8ff),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(secondary: const Color(0xFF2196f3)),
      ),
      home: const MainScreen(),
       //didipop使うため
       navigatorObservers: [routeObserver],
    );
  }
}
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with RouteAware {
  bool isAlarmOn = false;
  Key? listViewKey;
  @override
  void initState() {
    super.initState();
    init();


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
          const Padding(padding: EdgeInsets.all(10)),
          Expanded(
            child: ListView(
              key: listViewKey,
              children: listWedgetitems, //List<Widget>
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: insertAlarmList,
        tooltip: '登録',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatt

    );
  }

  void insertAlarmList() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => StretchScreen(cnsStretchScreenIns,-1)),
    // );
  }
  void updAlarmList(int lcNo){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlarmDetailScreen(cnsAlarmDetailScreenUpd,lcNo)),
    );
  }

  Future<void> delAlarmList(int lcNo) async{

    await delStretchDB(lcNo);
    await loadList();
    await getItems();
  }
  Future<void>  delStretchDB(int lcNo)async{
    String dbPath = await getDatabasesPath();
    String query = '';
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);
    query = 'DELETE From alarmList where alarmno = $lcNo';
    await database.transaction((txn) async {
      await txn.rawInsert(query);
    });
  }

  Future<void> getItems() async {
    List<Widget> list = <Widget>[];
    int alarmListNo = 0;
    double titleFont = 25;
    String strWeekText = '';
    String strTimeText = '';
    DateTime dtTime = DateTime.now();
    final lists = ['削除'];

    int index = 0;
    for (Map item in mapAlarmList) {
      //反対側ありなし判定
      dtTime = DateTime.parse(item['time']);
      strTimeText = '${dtTime.hour.toString().padLeft(2,'0')}:${dtTime.minute.toString().padLeft(2,'0')}';
      if(item['mon'] == 1) {
        strWeekText = '$strWeekText月';
      }
      if(item['tue'] == 1) {
        strWeekText =  '$strWeekText火';
      }
      if(item['wed'] == 1) {
        strWeekText =  '$strWeekText水';
      }
      if(item['thu'] == 1) {
        strWeekText =  '$strWeekText木';
      }
      if(item['fri'] == 1) {
        strWeekText =  '$strWeekText金';
      }
      if(item['sat'] == 1) {
        strWeekText =  '$strWeekText土';
      }
      if(item['sun'] == 1) {
        strWeekText =  '$strWeekText日';
      }
      if(strWeekText == '月火水木金土日')
      {
        strWeekText = '毎日';
      }

      if(item['title'].toString().length > 10) {
        titleFont = 10;
      }else{
        titleFont = 15;
      }

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
            contentPadding: const EdgeInsets.all(10),
            leading: Column(children:  <Widget>[
              Icon(Icons.alarm,size: 25,color: alarmFlg?Colors.blue:Colors.grey),
              Text(alarmFlg?'ON':'OFF', style:const TextStyle(color: Colors.grey , fontSize: 10)),
              ]
            ),
            title: Text(' $strTimeText ', style:const TextStyle(color: Colors.blue , fontSize: 30) ),
            subtitle:
            Column(
              children:  <Widget>[
                      Text('${item['title']}  ', style: TextStyle(color: const Color(0xFF191970) , fontSize: titleFont),),
                Text(strWeekText, style: TextStyle(color: const Color(0xFF191970) , fontSize: titleFont),),
              ],
            ),

            trailing: PopupMenuButton(
              itemBuilder: (context) {
                return lists.map((String list) {
                  return PopupMenuItem(
                    value: list,
                    child: Text(list),
                  );
                }).toList();
              },
              onSelected: (String list) {
                switch (list) {
                  case '削除':
                    delAlarmList(item['alarmno']);
                    break;
                }
              },
            ),
            selected: alarmListNo == item['alarmno'],
            onTap: () {
              alarmListNo= item['alarmno'];
              debugPrint('ListNo:$alarmListNo');
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlarmDetailScreen(cnsAlarmDetailScreenUpd,alarmListNo)),
    );
  }
  /*------------------------------------------------------------------
第一画面ロード
 -------------------------------------------------------------------*/
  Future<void>  loadList() async {
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);
    mapAlarmList = await database.rawQuery("SELECT * From alarmList order by alarmno");


  }
  /*------------------------------------------------------------------
初期処理
 -------------------------------------------------------------------*/
  void init() async {
    // await  testEditDB();
    await loadList();
    await getItems();
  }

}

