import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import './const.dart';
import './alarmdetail.dart';
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import './playlist.dart';

List<Widget> _items = <Widget>[];
List<Map> map_stretchlist = <Map>[];
int notificationType = 0;
bool testFLG = false;
late AudioPlayer _player;
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
void main() async{
  //SQLfliteで必要？
  WidgetsFlutterBinding.ensureInitialized();
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
            child: ReorderableListView(
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  Widget itemDummy = _items.removeAt(oldIndex);
                  _items.insert(newIndex, itemDummy);
                });
                //入れ替えロジック
                changeList(oldIndex+1,newIndex+1);
              },
              children: _items,
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: insertStretch,
        tooltip: '登録',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatt

    );
  }
  void changeList(int oldDbNo, int newDbNo) async{

    await changeListUpd(oldDbNo,newDbNo);
    await loadList();
    await getItems();
  }
  Future<void> changeListUpd(int oldDbNo, int newDbNo) async{

    ///oldを -1にする
    await updListNo(oldDbNo,-1);
    ///newをoldにする
    await updListNo(newDbNo,oldDbNo);
    /// -1をnewにする
    await updListNo(-1,newDbNo);

  }
  Future<void> updListNo( int whereNo ,int updNo)async{
    String dbPath = await getDatabasesPath();
    String query = '';
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1,);
    query = ' UPDATE alarmList set alarmno = $updNo where alarmno = $whereNo';
    await database.transaction((txn) async {
      await txn.rawInsert(query);
    });
  }

  void insertStretch() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => StretchScreen(cnsStretchScreenIns,-1)),
    // );
  }
  void updStretch(int lcNo){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlarmDetailScreen(cnsAlarmDetailScreenUpd,lcNo)),
    );
  }

  Future<void> delStretch(int lcNo) async{

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
    int listNo = 0;
    double titleFont = 25;
    String listTitle ='';
    String listTime ='';
    int listOtherSide = 0;
    String strWeekText = '';
    String strTimeText = '';
    DateTime dtTime = DateTime.now();
    int listPreSecond = 0;
    final lists = ['編集', '削除'];
    var isAlarmOn = false;
    int index = 0;
    for (Map item in map_stretchlist) {
      //反対側ありなし判定
      dtTime = DateTime.parse(item['time']);
      strTimeText = '${dtTime.hour.toString().padLeft(2,'0')}:${dtTime.minute.toString().padLeft(2,'0')}';
      // if (item['presecond'] > 0) {
      //   strPreSecondText = '　準備：${item['presecond'].toString()}秒';
      // }else{
      //   strPreSecondText = '';
      // }
      int weekcnt = 0;
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

      list.add(
        Card(
          margin: const EdgeInsets.fromLTRB(15,0,15,15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          key: Key('$index'),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
              leading: Switch(
                value: isAlarmOn,
                onChanged: (bool? value) {
                  if (value != null) {
                    setState(() {isAlarmOn = value;});
                    setAlarm(item['alarmno'],isAlarmOn,dtTime,strWeekText,item['playmode'],item['filelistno']);
                  }},),

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
                  case '編集':
                    updStretch(item['alarmno']);
                    break;
                  case '削除':
                    delStretch(item['alarmno']);
                    break;
                }
              },
            ),
            selected: listNo == item['alarmno'],
          ),
        ),
      );
      index++;
    }
    setState(() {_items = list;});
  }
  /*------------------------------------------------------------------
第一画面ロード
 -------------------------------------------------------------------*/
  Future<void>  loadList() async {
    String dbPath = await getDatabasesPath();
    String path = p.join(dbPath, 'internal_assets.db');
    Database database = await openDatabase(path, version: 1);
    map_stretchlist = await database.rawQuery("SELECT * From alarmList order by alarmno");
  }
  /*------------------------------------------------------------------
初期処理
 -------------------------------------------------------------------*/
  void init() async {
    // await  testEditDB();
    await loadList();
    await getItems();
  }
//item['alarmno'],isAlarmOn,dtTime,strWeekText,item['playmode']
  Future<void> setAlarm(int alarmNo, bool isAlarmOn, DateTime alarmTime, String strWeekText, int playMode,int filelistno)  async{
    int no = 0;
    debugPrint('setAlarm Start');
    testFLG = !testFLG;
    if(testFLG) {
      debugPrint('スイッチオン');
      ///PlaylistからNOを取得し、ランダムで1つ返す
      no = await getPlayListRandomNo(filelistno);


      ///そのナンバーからpath名を取得
      String musicPath = await getPlayListPath(no);
      debugPrint('no:$no  path:$musicPath ');
      ///ここでmusicを鳴らす
      _player = AudioPlayer();
      await _player.setLoopMode(LoopMode.all);
    await _player.setFilePath(musicPath);
    await _player.play();
     // playMusic(musicPath);
    }else{
      debugPrint('スイッチオフ');
      await _player.stop();
      //音止める
    }
    debugPrint('setAlarm END');

  }
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


