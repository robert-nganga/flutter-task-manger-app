import 'package:flutter/material.dart';



class Events {

  String task;
  String category;
  int iscomplete;
  int id;

  Events({this.task, this.category, this.iscomplete, this.id});

  String toString() => this.task;

}