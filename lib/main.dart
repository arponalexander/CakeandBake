import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_crashlytics/flutter_crashlytics.dart';
import 'package:fluttershare/pages/home.dart';

void main() async{
  bool isInDebugMode = false;
  runApp(MyApp());

  FlutterError.onError = (FlutterErrorDetails details) {
    if (isInDebugMode) {
      // In development mode simply print to console.
      FlutterError.dumpErrorToConsole(details);
      Zone.current.handleUncaughtError(details.exception, details.stack);
    } else {
      // In production mode report to the application zone to report to
      // Crashlytics.
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };

  bool optIn = true;
  if (optIn) {
    await FlutterCrashlytics().initialize();
    FlutterCrashlytics().setUserInfo('test1', 'test@test.com', 'tester');
  } else {
    // In this case Crashlytics won't send any reports.
    // Usually handling opt in/out is required by the Privacy Regulations
  }

  runZonedGuarded<Future<Null>>(() async {
    runApp(MyApp());
  }, (Object error, StackTrace stackTrace) async {
    // Whenever an error occurs, call the `reportCrash` function. This will send
    // Dart errors to our dev console or Crashlytics depending on the environment.
    debugPrint(error.toString());
    await FlutterCrashlytics().reportCrash(error, stackTrace, forceCrash: true);
  });
}



class MyApp extends StatelessWidget {
  static FirebaseAnalytics analytics = FirebaseAnalytics();
  static FirebaseAnalyticsObserver observer =
  FirebaseAnalyticsObserver(analytics: analytics);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cake and Bake',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        accentColor: Colors.green,
      ),
      navigatorObservers: <NavigatorObserver>[observer],
      home: Home(analytics:analytics, observer: observer),


    );
  }
}



