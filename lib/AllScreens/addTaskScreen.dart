import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:todo_list/Helper/sqliteHelper.dart';
import 'package:todo_list/Models/taskModel.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:todo_list/main.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:todo_list/Widgets/expandableFab.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_list/AllScreens/historyScreen.dart';


class AddTask extends StatefulWidget {
  final TaskModel task;
  final Function updateTaskList;
  final Function updateTasks;
  final int num;

  AddTask({this.updateTaskList, this.task, this.updateTasks, this.num});

  @override
  _AddTaskState createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask> {
  String _task = "";
  String _category;
  DateTime _reminder = DateTime(DateTime
      .now()
      .year, DateTime
      .now()
      .month, DateTime
      .now()
      .day);
  bool _reminderStatus;
  DateTime _date = DateTime(DateTime
      .now()
      .year, DateTime
      .now()
      .month, DateTime
      .now()
      .day);
  TimeOfDay _time = TimeOfDay.now();
  String _timeHolder = "";
  Color color = Color(0xFF6C63FF);
  final _formKey = GlobalKey<FormState>();
  final _addCategoryForm = GlobalKey<FormState>();
  final DateFormat _dateFormat = DateFormat('MMM, dd, yyyy');
  final String _cat = "categories";
  List<String> _categories = [];
  TextEditingController _dateController = TextEditingController();


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (!prefs.containsKey(_cat)) {
      prefs.setStringList(_cat, ["Personal", "Work", "Business"]);
      _categories = prefs.getStringList(_cat);
    } else {
      _categories = prefs.getStringList(_cat);
    }

    if (widget.task != null) {
      _task = widget.task.task;
      _dateController.text = _dateFormat.format(widget.task.date);
      _date = widget.task.date;
      _category = widget.task.category;
      _reminder = widget.task.reminder;
      _reminderStatus = widget.task.isreminder == 1 ? true : false;
      if (!_categories.contains(_category)) {
        _categories.add(_category);
        prefs.setStringList(_cat, _categories);
      }
    } else {
      _reminderStatus = false;
      _dateController.text = _dateFormat.format(_date);
    }
    _timeHolder =
    "${_reminder.hour.toString().padLeft(2, '0')}:${_reminder.minute.toString()
        .padLeft(2, '0')}";
    //_updateTaskList();
  }

  _cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    print('Reminder with id $id cancelled');
  }


  _updateCategoryList(String cat) {
    _categories.add(cat);
    prefs.setStringList(_cat, _categories);
    setState(() {
      _categories = prefs.getStringList(_cat);
    });

    print("update category list called with: " + _categories.toString());
  }

  _handleDatePicker() async {
    final DateTime date = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100));

    if (date != null && date != _date) {
      setState(() {
        _date = date;
        _reminder = DateTime(date.year, date.month, date.day);
      });
      _dateController.text = _dateFormat.format(date);
    }
  }

  _submit() async {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      TaskModel task = TaskModel(
          task: _task, category: _category, date: _date, reminder: _reminder);
      if (widget.task == null) {
        task.iscomplete = 0;
        task.isreminder = 0;
        print('New task');
        await SqliteHelper.instance.insertTask(task);
      } else {
        task.id = widget.task.id;
        task.iscomplete = widget.task.iscomplete;
        task.isreminder = _reminderStatus ? 1 : 0;
        print('Updating task...');
        await SqliteHelper.instance.updateTask(task);
        print('Task updated');
      }
      print('$_task, $_date, $_category');
      if(widget.num != null){
        widget.updateTasks();
      }else{
        widget.updateTaskList();
      }
      Navigator.pop(context);
    }
  }

  Future showNotification(int id) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
        'channel id', 'channel name', 'channel description',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        visibility: NotificationVisibility.public);
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    DateTime nows = DateTime.now();
    await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Task',
        '$_task',
        tz.TZDateTime.now(tz.local).add(_reminder.difference(nows)),
        const NotificationDetails(
            android: androidPlatformChannelSpecifics),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime);
  }

  _createNotification(int id) {
    showNotification(id);
    print('Notification created for task: $id');
    final snackBar = SnackBar(content: Text('${_stringBuilder(_reminder)}'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<Null> _showTimePicker(BuildContext context) async {
    final timePicked = await showTimePicker(context: context,
        initialTime: TimeOfDay(hour: _reminder.hour, minute: _reminder.minute));
    if (timePicked != null && timePicked != _time) {
      setState(() {
        _time = timePicked;
        _reminder = DateTime(
            _date.year, _date.month, _date.day, _time.hour, _time.minute);
        _timeHolder = "${_time.toString().substring(10, 15)}";
        print("Time picked${_time.toString()}");
      });
    }
    DateTime rightNow = DateTime.now();
    var secs = _reminder
        .difference(rightNow)
        .inSeconds;
    // schedule a notification because the switch is on
    if (_reminderStatus) {
      // if the time picked is before the time now
      if (secs <= 0) {
        final snackBar = SnackBar(content: Text('Please select future time'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        setState(() {
          _reminderStatus = !_reminderStatus;
        });
      } else {
        print(secs);
        int id = widget.task.id;
        _createNotification(id);
      }
    } else {

      if (secs <= 0) {
        final snackBar = SnackBar(content: Text('Please select future time'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } else {
        print(secs);
        int id = widget.task.id;
        _createNotification(id);
        setState(() {
          _reminderStatus = !_reminderStatus;
        });
      }
    }
  }

  _delete() {
    SqliteHelper.instance.deleteTask(widget.task.id);
    widget.updateTaskList();
    Navigator.pop(context);
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    return await showDialog(context: context, builder: (context) {
      TextEditingController _categoryController = TextEditingController();
      return AlertDialog(
        content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "Add Category",
                style: TextStyle(color: Theme
                    .of(context)
                    .primaryColor, fontSize: 15.0),
              ),
              Form(
                key: _addCategoryForm,
                child: TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(hintText: "Category"),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'invalid category';
                    }
                    return null;
                  },
                ),
              ),
            ]
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel", style: TextStyle(color: Theme
                .of(context)
                .primaryColor)),
            onPressed: () {
              prefs.remove(_cat);
              prefs.setStringList(_cat, ["Personal", "Work", "Business"]);
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text("Save", style: TextStyle(color: Theme
                .of(context)
                .primaryColor)),
            onPressed: () {
              if (_addCategoryForm.currentState.validate()) {
                _updateCategoryList(_categoryController.text);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      );
    });
  }

  String _stringBuilder(DateTime reminder) {
    String result = "";
    DateTime time = DateTime.now();
    var diff = reminder.difference(time).toString();
    List<String> dif = diff.split(':');
    int hours = int.parse(dif[0]);
    //String secs = int.parse(dif[2]).toString();
    double x = hours / 24;
    if (x >= 1) {
      String y = x.truncate().toString();
      int z = hours % 24;
      result =
      'Reminder set $y days ${z.toString()} hours ${dif[1]} minutes ${dif[2]
          .substring(0, 1)} seconds';
    } else {
      if (hours <= 0) {
        result =
        'Reminder set in ${dif[1]} minutes ${dif[2].substring(0, 1)} seconds';
      } else {
        result =
        'Reminder set in ${hours.toString()} hours ${dif[1]} minutes ${dif[2]
            .substring(0, 1)} seconds';
      }
    }
    print('Time difference is $dif');
    return result;
  }


  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        floatingActionButton: widget.task != null ? ExpandableFab(
          distance: 60.0,
          children: [
            ActionButton(
              onPressed: () {
                print("save button clicked");
                _submit();
              },
              icon: const Icon(Icons.check),
            ),
            ActionButton(
              onPressed: () {
                _delete();
              },
              icon: const Icon(Icons.delete),
            ),
          ],
        ) : FloatingActionButton(
          backgroundColor: Theme
              .of(context)
              .primaryColor,
          child: Icon(
            Icons.check,
          ),
          onPressed: () {
            print("save button clicked");
            _submit();
          },
        ),

        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width,
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: 45.0, left: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.arrow_back_ios,
                            size: 30.0,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 20.0),
                        Text(
                          widget.task == null ? "New Task" : "Update Task",
                          style: TextStyle(
                            fontSize: 28.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10.0),
                Form(
                  key: _formKey,
                  child: Padding(
                    padding:
                    EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextFormField(
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please enter task';
                            }
                            return null;
                          },
                          style: TextStyle(fontSize: 18.0),
                          decoration: InputDecoration(
                            labelText: "Task",
                            labelStyle: TextStyle(fontSize: 18.0),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                          ),
                          onSaved: (value) => _task = value,
                          initialValue: _task,
                        ),
                        SizedBox(height: 20.0),
                        TextFormField(
                          controller: _dateController,
                          onTap: () => _handleDatePicker(),
                          style: TextStyle(fontSize: 18.0),
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Date",
                            labelStyle: TextStyle(fontSize: 18.0),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                          ),
                        ),
                        SizedBox(height: 20.0),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: DropdownButtonFormField(
                                icon: Icon(Icons.arrow_drop_down_circle),
                                iconSize: 25.0,
                                iconEnabledColor: Theme
                                    .of(context)
                                    .primaryColor,
                                items: _categories.map((String category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.black),
                                    ),
                                  );
                                }).toList(),
                                validator: (value) {
                                  if (_category == null) {
                                    return 'Please select a category';
                                  }
                                  return null;
                                },
                                style: TextStyle(fontSize: 18.0),
                                decoration: InputDecoration(
                                  labelText: "Category",
                                  labelStyle: TextStyle(fontSize: 18.0),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0)),
                                ),
                                onSaved: (value) => _category = value,
                                onChanged: (value) {
                                  setState(() {
                                    _category = value;
                                  });
                                },
                                value: _category,
                              ),
                            ),
                            SizedBox(width: 25.0),
                            Padding(
                              padding: const EdgeInsets.only(top: 18.0),
                              child: GestureDetector(
                                onTap: () async {
                                  await _showAddCategoryDialog(context);
                                },
                                child: Column(
                                  children: <Widget>[
                                    Icon(
                                      Icons.add,
                                      size: 35.0,
                                      color: Theme
                                          .of(context)
                                          .primaryColor,
                                    ),
                                    SizedBox(height: 2.0),
                                    Text(
                                      "add",
                                      style: TextStyle(
                                          fontSize: 15.0, color: Theme
                                          .of(context)
                                          .primaryColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 5.0),
                widget.task != null ?Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Card(
                    color: Colors.white,
                    elevation: 4.5,
                    child: ExpansionTile(
                      title: Row(
                        children: <Widget>[
                          Text(
                            "Reminder",
                            style: TextStyle(fontSize: 18.0),
                          ),
                        ],
                      ),
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            SizedBox(width: 12.0),
                            GestureDetector(
                              onTap: () {
                                _showTimePicker(context);
                              },
                              child: Text(
                                "$_timeHolder",
                                style: TextStyle(
                                  fontSize: 60.0,
                                ),
                              ),
                            ),
                            SizedBox(width: 35.0),
                            Switch(
                              value: _reminderStatus,
                              activeColor: Theme
                                  .of(context)
                                  .primaryColor,

                              onChanged: (value) {
                                // check the status of the switch
                                if (_reminderStatus) {
                                  // if it is on we cancel the notification

                                  int id = widget.task.id;
                                  _cancelNotification(id);
                                  setState(() {
                                    _reminderStatus = !_reminderStatus;
                                  });
                                } else {
                                  // if it is off the following is executes
                                  DateTime rightNow = DateTime.now();
                                  var secs = _reminder
                                      .difference(rightNow)
                                      .inSeconds;
                                  // if the time picked is before the time now
                                  if (secs <= 0) {
                                    final snackBar = SnackBar(content: Text(
                                        'Please select future time'));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        snackBar);
                                    setState(() {
                                      _reminderStatus = !_reminderStatus;
                                    });
                                  } else {
                                    int id = widget.task.id;
                                    _createNotification(id);
                                    print(secs);
                                  }
                                  setState(() {
                                    _reminderStatus = !_reminderStatus;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ) : SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

