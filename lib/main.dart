import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import './const.dart';
import './alarmdetail.dart';
import './playlist.dart';

List<Widget> _items = <Widget>[];
List<Map> map_stretchlist = <Map>[];
int notificationType = 0;

//didpop使う為
final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();
/*------------------------------------------------------------------
全共通のメソッド
 -------------------------------------------------------------------*/
//初回起動分の処理
Future<void> firstRun() async {
  debugPrint("firstRun START");
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

  debugPrint("firstRun END");
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
    String strPreSecondText = '';
    String strTimeText = '';
    DateTime dtTime = DateTime.now();
    int listPreSecond = 0;
    final lists = ['編集', '削除'];

    int index = 0;
    for (Map item in map_stretchlist) {
      //反対側ありなし判定
      dtTime = DateTime.parse(item['time']);
      strTimeText = '${dtTime.minute.toString().padLeft(2,'0')}分${dtTime.second.toString().padLeft(2,'0')}秒';

      // if (item['presecond'] > 0) {
      //   strPreSecondText = '　準備：${item['presecond'].toString()}秒';
      // }else{
      //   strPreSecondText = '';
      // }

      if(item['title'].toString().length > 10) {
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
            title: Text('${item['title']}  ', style: TextStyle(color: const Color(0xFF191970) , fontSize: titleFont),),
            subtitle: Row(children:  <Widget>[
              Text(' $strTimeText ', style:const TextStyle(color: Colors.blue , fontSize: 25) ),
            //  Icon(Icons.swap_horiz,size: 25,color:  ( item['otherside'] == cnsOtherSideOn) ?Colors.blue:Colors.white,) ,
              Text(strPreSecondText,  style: const TextStyle(color: Colors.grey , fontSize: 15) ),] ),
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

            //    isThreeLine: true,
            selected: listNo == item['alarmno'],
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
    debugPrint("loadList");
    await loadList();
    debugPrint("getItems");
    await getItems();
  }

}


