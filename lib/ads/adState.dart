import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';


class AdState{
  Future<InitializationStatus> initialization;

  AdState(this.initialization);

  String get bannerAdUnitId => Platform.isAndroid ? "ca-app-pub-7969802832324818/5350554204" : "";
}