import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roundcheckbox/roundcheckbox.dart';
import 'package:todo_list/AllScreens/addTaskScreen.dart';
import 'package:todo_list/AllScreens/categoryScreen.dart';
import 'package:todo_list/AllScreens/historyScreen.dart';
import 'package:todo_list/Helper/sqliteHelper.dart';
import 'package:todo_list/Models/taskModel.dart';
import 'package:todo_list/ads/adState.dart';
import 'package:todo_list/main.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Color color = Color(0xFF6C63FF);
  final DateFormat _dateFormat = DateFormat('MMM, dd, yyyy');
  List<TaskModel> _taskList = [];
  final rightnow = DateTime.now();
  DateTime now = DateTime.now();
  int _completedItemCount = 0;
  final String _cat = "categories";
  List<String> items = prefs.getStringList("categories");
  int _total = 0;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  BannerAd banner;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _updateTaskList();
    print('init state called with data $_total');
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    final adState = Provider.of<AdState>(context);
    adState.initialization.then((value) {
      setState(() {
        banner = BannerAd(
            adUnitId: adState.bannerAdUnitId,
            size: AdSize(height: 50, width: MediaQuery.of(context).size.width.toInt()),
            request: AdRequest(),
            listener: BannerAdListener(
                onAdImpression: (ad) {print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Ad shown for ad: $ad');},
                onAdFailedToLoad: (ad, error) {print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Ad failed to load with error: $error');}
            )
        )..load();
      });
    });
  }

  String _checkDate(DateTime date) {
    String result;
    final taskDate = DateTime(date.year, date.month, date.day);
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final tomorrow = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day + 1);
    if (taskDate == today) {
      result = "Today";
      return result;
    } else if (taskDate == tomorrow) {
      result = "Tomorrow";
      return result;
    } else {
      return _dateFormat.format(date);
    }
  }

  _updateTaskList() async {
    List<TaskModel> taskList = await SqliteHelper.instance.getSortedTaskList();

    setState(() {
      _taskList = taskList;
    });
    if (_taskList != null) {
      _total = _taskList.length;
      _completedItemCount =
          _taskList.where((element) => element.iscomplete == 1).toList().length;
    }
    print('update list called with data $_total');
  }

  Future<void> _refreshList() async{
    await _updateTaskList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Theme.of(context).primaryColor,

      // Navigation Drawer
      drawer: Container(
        color: Colors.white,
        width: 250.0,
        child: Drawer(
          child: ListView(
            children: <Widget>[

              //Drawer header
              Container(
                height: 200.0,
                child: DrawerHeader(
                  //margin: EdgeInsets.all(5.0),
                  padding: EdgeInsets.only(top: 160.0, left: 15.0, bottom: 5.0),
                  decoration: BoxDecoration(color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("My menu", style: TextStyle(fontSize: 20.0),)
                    ],
                  ),
                ),
              ),

              // Drawer body
              ListTile(
                onTap: () {
                  _updateTaskList();
                  Navigator.pop(context);
                },
                leading: Icon(Icons.home, color: Colors.black),
                title: Text("Home", style: TextStyle(letterSpacing: 2.0, fontSize: 20.0)),
              ),
              ExpansionTile(
                onExpansionChanged: (state) {setState(() {
                  items = prefs.getStringList("categories");
                });},
                leading: Icon(Icons.category, color: Colors.black),
                title: Text("Category", style: TextStyle(letterSpacing: 2.0, fontSize: 20.0)),
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 80.0),
                    child: SizedBox(
                      height: 200.0,
                      child: ListView.builder(
                         itemCount: items.length,
                         itemBuilder: (context, index) {
                         return ListTile(
                           onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryScreen(cat: items[index])));
                           },
                           title: Text(items[index], style: TextStyle(color: Colors.black54)),
                      );
                },
              ),
                    ),
                  )
                ],
              ),
              ListTile(
                onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen()));},
                leading: Icon(Icons.today, color: Colors.black),
                title: Text("Calendar view", style: TextStyle(letterSpacing: 2.0, fontSize: 20.0)),
              ),
              ListTile(
                onTap: () {
                  showAboutDialog(
                      context: context,
                    applicationVersion: "1.0.0",
                    applicationName: "Todo Task List",
                    //applicationIcon: Expanded(child: Image.asset("images/ic_launcher.png")),
                    applicationLegalese: "Developed by Robert"
                  );
                },
                leading: Icon(Icons.info, color: Colors.black),
                title: Text("About", style: TextStyle(letterSpacing: 2.0, fontSize: 20.0)),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 40.0),
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          child: Icon(
            Icons.add,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddTask(updateTaskList: _updateTaskList)),
            );
          },
        ),
      ),
      body: Column(
          children: <Widget>[
            Container(
              height: 130.0,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Padding(
                padding: EdgeInsets.only(top: 45, left: 20.0, bottom: 10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {scaffoldKey.currentState.openDrawer();},
                      child: Icon(
                          Icons.menu,
                          size: 30.0,
                          color: Colors.white,
                        ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 20.0, top: 0.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                              Text(
                              "My Tasks",
                              style: TextStyle(
                                fontSize: 25.0,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.normal,
                                color: Colors.white,
                                letterSpacing: 2.0,
                              ),
                            ),
                            SizedBox(height: 10.0),

                            Text(
                              "$_completedItemCount of $_total tasks completed",
                              style: TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.normal,
                                fontStyle: FontStyle.normal,
                                color: Colors.white,
                                letterSpacing: 2.0,
                              ),
                            ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              child: Container(
                height: MediaQuery.of(context).size.height - 180.0,
                decoration: BoxDecoration(
                  borderRadius:
                  BorderRadius.only(topLeft: Radius.circular(60.0)),
                  color: Colors.white
                ),
                child: FutureBuilder(
                  future: SqliteHelper.instance.getSortedTaskList(),
                  builder: (context, snapshot) {

                    //When the future is still executing
                    if (ConnectionState.active != null && !snapshot.hasData) {
                      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
                    }

                    _taskList = snapshot.data;

                    if(_taskList.isEmpty){
                      return Center(child: Text(
                        'No tasks available',
                        style: TextStyle(color: Colors.black54),
                      )
                      );
                    }
                    return ListView.builder(
                      itemCount: _taskList.length,
                      itemBuilder: (context, index) {
                        print('$index');
                        print(
                            '${_taskList[index].iscomplete}, ${_taskList[index].task}, ${_taskList[index].category}, ${_taskList[index].date}');
                        TaskModel task = _taskList[index];
                        return listTileWidget(task);
                      },
                    );
                  },
                ),
              ),
            ),

            //banner ad
            banner == null ? Container(
              color: Colors.white,
              height: 50.0,
            ) : Container(
              color: Colors.white,
              height: 50.0,
              width: MediaQuery.of(context).size.width,
              child: AdWidget(ad: banner),
            ),
          ],
        ),
    );
  }

  Widget listTileWidget(TaskModel task) {
    return ListTile(
      leading: Checkbox(
        onChanged: ((value) async {
          value ? task.iscomplete = 1 : task.iscomplete = 0;
          await SqliteHelper.instance.updateTask(task);
          _updateTaskList();
        }),
        value: task.iscomplete == 1 ? true : false,
        checkColor: Colors.white,
        activeColor: Theme.of(context).primaryColor,
      ),
      title: Text(
        "${task.task}",
        style: TextStyle(
            fontSize: 18.0,
            letterSpacing: 0.0,
            decoration: task.iscomplete == 1
                ? TextDecoration.lineThrough
                : TextDecoration.none),
      ),
      subtitle: Row(
        children: <Widget>[
          Text(
            "${_checkDate(task.date)} ",
            style: TextStyle(
                fontSize: 12.0,
                letterSpacing: 1.0,
                decoration: task.iscomplete == 1
                    ? TextDecoration.lineThrough
                    : TextDecoration.none),
          ),
          task.isreminder == 1 ? Row(
            children: <Widget>[
              Icon(Icons.alarm, size: 14.0, color: Colors.black26),
              Text(' ${task.reminder.hour.toString().padLeft(2, '0')}:${task.reminder.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
              fontSize: 12.0,
              letterSpacing: 1.0,
              decoration: task.iscomplete == 1
              ? TextDecoration.lineThrough
                  : TextDecoration.none),
              )
            ],
          ) : Text(''),
        ],
      ),
      trailing: Text(
        "${task.category}",
        style: TextStyle(
            fontSize: 8.0,
            decoration: task.iscomplete == 1
                ? TextDecoration.lineThrough
                : TextDecoration.none),
      ),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    AddTask(updateTaskList: _updateTaskList, task: task)));
      },
    );
  }
}
