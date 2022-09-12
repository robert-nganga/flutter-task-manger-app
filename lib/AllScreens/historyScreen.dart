import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:todo_list/AllScreens/homePage.dart';
import 'package:todo_list/Helper/sqliteHelper.dart';
import 'package:todo_list/Models/events.dart';
import 'package:todo_list/Models/taskModel.dart';
import 'addTaskScreen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final DateFormat _dateFormat = DateFormat('MMM, dd, yyyy');
  List<Events> _myList = [];
  List<Map<String, dynamic>> _mapList = [];
  Map<DateTime, List<Events>> _events = {};
  ValueNotifier<List<Events>> _selectedEvents;
  final _eventsHashMap = LinkedHashMap(
    equals: isSameDay,
    //hashCode: getHashCode,
  );


  _update() async{
    List<TaskModel> list = await SqliteHelper.instance.getHistoryTaskList(_selectedDay.toIso8601String());

    setState(() {
      //_myList = list;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchMapList();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay));

  }

  _updateTasks() {
    _fetchMapList();
    setState(() {
      _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay));
    });
    print("update task run in calendar view");
  }

  _assignTask(int id) async{
    TaskModel task = await SqliteHelper.instance.getTask(id);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                AddTask(updateTasks: _updateTasks, task: task, num: 22)));
  }

  List<Events> _getEventsForDay(DateTime day) {
    DateTime date = DateTime(day.year, day.month, day.day);
    return _eventsHashMap[date] ?? [];

  }

  _fetchMapList() async{
    List<String> x = await SqliteHelper.instance.getTaskMapList();
    x.sort();
    x = x.toSet().toList();
    print('list after removing duplicates is ${x.length}');

    Map<DateTime, List<Events>> y = await _createMap(x);
    setState(() {
      _eventsHashMap.addAll(y);
      _events = y;

    });
    print(" data fetched $_eventsHashMap");
  }

  Future<Map<DateTime, List<Events>>> _createMap(List<String> list) async{
    final Map<DateTime, List<Events>> dateMap = {};
    String date = 'date';
    String task = 'task';
    for(int x =0; x<list.length; x++){
      List<Events> myList = [];
      print(x);
      List<Map<String, dynamic>> fetchedList = await SqliteHelper.instance.getTasksOnlyList(list[x]);
      fetchedList.forEach((element) {
        Events event = Events(task: element[task], category: element["category"], iscomplete: element["iscomplete"], id: element["id"]);
        myList.add(event);
      });

      setState(() {
        dateMap[DateTime.parse(list[x])] = myList;
      });

      print('My list is:${dateMap[DateTime.parse(list[x])]}');
    }
    return dateMap;
  }

  Widget _buildEventsMarker(DateTime date, List events) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Theme.of(context).primaryColor,

      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Calendar View"),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),

      body: Column(
        children: <Widget>[
          TableCalendar<Events>(

                    firstDay: DateTime(2010),
                    lastDay: DateTime(2050),
                    focusedDay: _focusedDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 30,
                      canMarkersOverflow: true,
                      weekendTextStyle: TextStyle(
                        color: Colors.orange[700],
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.deepPurple[200],
                        borderRadius: BorderRadius.all(Radius.circular(5.0)),
                        //border: Border.fromBorderSide(BorderSide(color: Theme.of(context).primaryColor)),
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonShowsNext: false,
                      formatButtonDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        border: Border.fromBorderSide(BorderSide(color: Colors.white)),
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      ),
                      formatButtonTextStyle: TextStyle(
                        color: Colors.white,
                      ),
                    ),

                    calendarBuilders: CalendarBuilders(
                      dowBuilder: (context, day) {
                        if(day.weekday == DateTime.saturday){
                          final text = DateFormat.E().format(day);
                          return Center(
                            child: Text(
                              text,
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          );
                        }
                        if(day.weekday == DateTime.sunday){
                          final text = DateFormat.E().format(day);
                          return Center(
                            child: Text(
                              text,
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          );
                        }
                        return null;
                      },
                      markerBuilder: (context, date, events) {
                        //final children = <Widget>[];
                        if (events.isNotEmpty) {
                            return Positioned(
                              right: 1,
                              bottom: 1,
                              child: _buildEventsMarker(date, events),
                            );
                        }
                        return null;
                      },
                    ),

                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },

                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                          _myList = _getEventsForDay(selectedDay);
                        });
                        _selectedEvents.value = _getEventsForDay(selectedDay);

                        print('The list for day ${_selectedDay} is ${_getEventsForDay(selectedDay).toString()}');
                      }
                    },
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    eventLoader: _getEventsForDay,
                  ),

          SizedBox(height: 10.0),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                // logging
                print("Listview about to run with data: ${_selectedEvents.value.length}" );
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    Events events = value[index];

                    return Dismissible(
                      background: stackBehindDismiss(),
                      key: ObjectKey(events),
                      child: listTileWidget(events),
                      onDismissed: (direction) {

                        //var event = value[index];
                        setState(() {
                          value.removeAt(index);
                        });
                       //delete the task
                        SqliteHelper.instance.deleteTask(events.id);
                        print("Deleted item with id: ${events.id}");
                        //_fetchMapList();

                        final snackBar = SnackBar(content: Text(
                            'Task deleted', style: TextStyle(fontSize: 15.0),));
                        ScaffoldMessenger.of(context).showSnackBar(
                            snackBar);
                      },
                    );
                  },
                );

              },
            ),
          ),
        ],
      ),
    );
  }

  Widget listTileWidget(Events event) {
    return ListTile(
      leading: Checkbox(
        onChanged: null,
        value: event.iscomplete == 1 ? true : false,
        checkColor: Colors.white,
        activeColor: Theme.of(context).primaryColor,
      ),
      title: Text(
        "${event.task}",
        style: TextStyle(
            fontSize: 18.0,
            letterSpacing: 0.0,
            decoration: event.iscomplete == 1
                ? TextDecoration.lineThrough
                : TextDecoration.none),
      ),
      subtitle: Text(
        "${event.category}",
        style: TextStyle(
            fontSize: 12.0,
            letterSpacing: 1.0,
            decoration: event.iscomplete == 1
                ? TextDecoration.lineThrough
                : TextDecoration.none),
      ),
      onTap: () {
        _assignTask(event.id);
        print("On tap clicked for event: ${event.task}");
      },
    );
  }

  Widget stackBehindDismiss() {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20.0),
      color: Theme.of(context).primaryColor,
      child: Icon(
        Icons.delete,
        color: Colors.white,
      ),
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
