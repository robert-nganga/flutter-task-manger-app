import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/ads/adState.dart';

import 'AllScreens/addTaskScreen.dart';
import 'AllScreens/homePage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

//shared preferences initialization
SharedPreferences prefs;
final String _cat = "categories";

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  //initializing ads sdk
  final initFuture = MobileAds.instance.initialize();
  final adState = AdState(initFuture);

  tz.initializeTimeZones();
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('app_icon');
  final IOSInitializationSettings initializationSettingsIOS =
  IOSInitializationSettings();
  final MacOSInitializationSettings initializationSettingsMacOS =
  MacOSInitializationSettings();
  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsMacOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: selectNotification);

  prefs = await SharedPreferences.getInstance();
  if(!prefs.containsKey(_cat)) {
    prefs.setStringList(_cat, ["Personal", "Work", "Business"]);
  }

  //make status bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      //statusBarIconBrightness: Brightness.dark,
      //statusBarBrightness: Brightness.dark
    ),
  );

  runApp(Provider.value(
      value: adState,
      builder:(context, child) => MyApp(),
  ),
  );
}

class MyApp extends StatelessWidget {
  Color color = Color(0xFF6C63FF);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Todo List',
      theme: ThemeData(
        primaryColor: color,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}



Future selectNotification(String payload) async{


}
