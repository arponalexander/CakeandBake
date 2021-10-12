import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/create_account.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/pages/timeline.dart';
import 'package:fluttershare/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final storageRef = FirebaseStorage.instance.ref();
final usersRef = FirebaseFirestore.instance.collection('users');
final postsRef = FirebaseFirestore.instance.collection('posts');
final commentsRef = FirebaseFirestore.instance.collection('comments');
final activityFeedRef = FirebaseFirestore.instance.collection('feed');
final followersRef = FirebaseFirestore.instance.collection('followers');
final followingRef = FirebaseFirestore.instance.collection('following');
final timelineRef = FirebaseFirestore.instance.collection('timeline');
final DateTime timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  Home({this.analytics, this.observer});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    //Detects When user sign in
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {
      print('Error signing in: $err');
    });
    //Reauthenticate
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }).catchError((err) {
      print("Error sign in: $err");
    });
    _currentScreen();
  }

  Future<void> _currentScreen() async {
    await widget.analytics.setCurrentScreen(
        screenName: 'Home News Page', screenClassOverride: 'Home Page');
  }

  handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      await createUserInFirestore();
      print('User sign in: $account');
      setState(() {
        isAuth = true;
      });
      configurePushNotification();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotification() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    // if (Platform.isIOS) getiOSPermission();
   FirebaseMessaging.instance.getToken().then((token) {
      print('Firebase messaging Token: $token\n');
      usersRef
          .doc(user.id)
          .update({'androidNotificationToken': token});
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final String recipientId = message.data['data']['recipient'];
      final String body = message.data['notification']['body'];
      if (recipientId == user.id) {
        print('Notification shown!');
        SnackBar snackbar = SnackBar(
          content: Text(
            body,
            overflow: TextOverflow.ellipsis,
          ),
        );
        _scaffoldKey.currentState.showSnackBar(snackbar);
      }
      print('Notification Not shown');

    });
    // _firebaseMessaging.configure(
    //     // app not in use notification
    //     ///onLaunch: (Map<String, dynamic> message) async {}
    //     // app in use but in background notification
    //     ///onResume: (Map<String, dynamic> message) async {}
    //     // app currently on use
    //     onMessage: (Map<String, dynamic> message) async {
    //   final String recipientId = message['data']['recipient'];
    //   final String body = message['notification']['body'];
    //   if (recipientId == user.id) {
    //     print('Notification shown!');
    //     SnackBar snackbar = SnackBar(
    //       content: Text(
    //         body,
    //         overflow: TextOverflow.ellipsis,
    //       ),
    //     );
    //     _scaffoldKey.currentState.showSnackBar(snackbar);
    //   }
    //   print('Notification Not shown');
    // });
  }
  //
  // getiOSPermission() {
  //   _firebaseMessaging.requestNotificationPermissions(
  //       IosNotificationSettings(alert: true, badge: true, sound: true));
  //   _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
  //     print('Settings registered: $settings');
  //   });
  // }

  createUserInFirestore() async {
    //1. check if users exist in users collection in  data base
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.doc(user.id).get();
    //2. if the user doesn't exist, then we want to take them to the create account page
    if (!doc.exists) {
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));

      //3. get username from create account, use it to make new user document in users collection
      usersRef.doc(user.id).set({
        'id': user.id,
        'username': username,
        'photoUrl': user.photoUrl,
        'email': user.email,
        'displayName': user.displayName,
        'bio': '',
        'timestamp': timestamp,
      });
      // make new user their own follower (to include their post in their timeline

      await followersRef
          .doc(user.id)
          .collection('userFollowers')
          .doc(user.id)
          .set({});

      doc = await usersRef.doc(user.id).get();
    }
    currentUser = User.fromDocument(doc);
    print(currentUser);
    print(currentUser.username);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(pageIndex,
        duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
        key: _scaffoldKey,
        body: PageView(
          children: <Widget>[
            Timeline(currentUser: currentUser),
            ActivityFeed(),
            Upload(currentUser: currentUser),
            Search(),
            Profile(profileId: currentUser?.id)
          ],
          controller: pageController,
          onPageChanged: onPageChanged,
          physics: NeverScrollableScrollPhysics(),
        ),
        bottomNavigationBar: CupertinoTabBar(
            currentIndex: pageIndex,
            onTap: onTap,
            activeColor: Theme.of(context).accentColor,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.whatshot),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_active),
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.photo_camera,
                  size: 35,
                ),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle),
              ),
            ]));
//    return RaisedButton(child: Text('Logout'),onPressed: logout,);
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).accentColor,
              ]),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Cake and Bake',
              style: const TextStyle(
                  fontFamily: 'Signatra', fontSize: 70, color: Colors.white),
            ),
            InkWell(
              onTap: () => login(),
              child: Container(
                width: 200,
                height: 40,
                decoration: BoxDecoration(
                    image: DecorationImage(
                  image: AssetImage('assets/images/google_signin_button.png'),
                  fit: BoxFit.cover,
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
