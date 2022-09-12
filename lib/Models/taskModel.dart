


import 'package:flutter/material.dart';

class TaskModel{
  int id;
  String task;
  DateTime date;
  String category;
  int iscomplete;
  int isreminder;
  DateTime reminder;

  TaskModel({this.task, this.date, this.category, this.iscomplete, this.isreminder, this.reminder});
  TaskModel.withId({this.id, this.task, this.date, this.category, this.iscomplete, this.isreminder, this.reminder});

  Map<String, dynamic> toMap(){
    final map = Map<String, dynamic>();
    map['id'] = id;
    map['task'] = task;
    map['date'] = date.toIso8601String();
    map['category'] = category;
    map['iscomplete'] = iscomplete;
    map['isreminder'] = isreminder;
    map['reminder'] = reminder.toIso8601String();
    return map;
  }

  factory TaskModel.fromMap(Map<String, dynamic> map){
    return TaskModel.withId(id: map['id'], task: map['task'], date: DateTime.parse(map['date']), category: map['category'],
        iscomplete: map['iscomplete'], isreminder: map['isreminder'], reminder: DateTime.parse(map['reminder']));
  }


}