import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/AllScreens/homePage.dart';
import 'package:todo_list/Helper/sqliteHelper.dart';
import 'package:todo_list/Models/taskModel.dart';
import 'package:todo_list/AllScreens/addTaskScreen.dart';
import 'package:todo_list/ads/adState.dart';





class CategoryScreen extends StatefulWidget {
final String cat;
CategoryScreen({this.cat});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
String _category = "";
final DateFormat _dateFormat = DateFormat('MMM, dd, yyyy');
List<TaskModel> _list = [];


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if(widget.cat != null){
      _category = widget.cat;
    }

  }

  _updateTaskList() async{
    List<TaskModel> taskList = await SqliteHelper.instance.getTaskListQuery(_category);
    setState(() {
      _list = taskList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
            height: 130.0,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(50.0)),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: 30, left: 25.0, bottom: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 5.0,
                  ),
                  GestureDetector(
                    onTap: () {Navigator.pop(context);},
                    child: Icon(
                      Icons.arrow_back_ios,
                      size: 30.0,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Padding(
                    padding: EdgeInsets.only(left: 40.0, top: 10.0),
                    child: Text(
                      "$_category",
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder(
              future: SqliteHelper.instance.getTaskListQuery(_category),
              builder: (context, snapshot) {
                // When the future is still fetching data
                if (ConnectionState.active != null && !snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
                }
                if (ConnectionState.done != null && !snapshot.hasData) {

                }

                _list = snapshot.data;
                if(_list.isEmpty){
                  return Center(child: Text(
                    'No data for this category',
                    style: TextStyle(color: Colors.black54),
                  )
                  );
                }

                return ListView.builder(
                  itemCount: _list.length,
                  itemBuilder: (context, index) {
                    TaskModel task = snapshot.data[index];
                    return listTileWidget(task);
                  },
                );

              },
            ),
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
    subtitle: Text(
      "${_checkDate(task.date)}",
      style: TextStyle(
          fontSize: 12.0,
          letterSpacing: 1.0,
          decoration: task.iscomplete == 1
              ? TextDecoration.lineThrough
              : TextDecoration.none),
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
}
