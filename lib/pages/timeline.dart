import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/progress.dart';

import 'home.dart';
import 'search.dart';

final usersRef = FirebaseFirestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User currentUser;

  Timeline({this.currentUser});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List <Post> posts;
  List<String>  followingList =[];

  @override
  void initState() {
    super.initState();
    getTimeline();
    getFollowing();
  }
  getTimeline() async{
   QuerySnapshot snapshot = await timelineRef.doc(widget.currentUser.id)
        .collection('timelinePosts')
        .orderBy('timestamp', descending: true)
        .get();
    List<Post> posts = snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .doc(currentUser.id)
        .collection('userFollowing')
        .get();
    setState(() {
      followingList = snapshot.docs.map((doc) => doc.id).toList();
    });
  }
  buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return buildUsersToFollow();
    } else {
      return ListView(children: posts);
    }
  }
   buildUsersToFollow(){
    return StreamBuilder(
      stream:  usersRef.orderBy('timestamp', descending: true).limit(30).snapshots(),
      builder: (context, snapshot){
        if(!snapshot.hasData){
        return circularProgress();
        }
          List<UserResult> userResults =[];
          snapshot.data.documents.forEach((doc) {
            User user = User.fromDocument(doc);
            final bool isAuthUser = currentUser.id == user.id;
            final bool isFollowingUser = followingList.contains(user.id);
            if(isAuthUser)
              {
                return;
              }else if(isFollowingUser){
              return;
            }else{
              UserResult userResult = UserResult(user);
              userResults.add(userResult);
            }
          });
          return Container(
            color: Colors.white,
            child: Column(
              children: <Widget>[
                Container(
                  padding: const  EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment:  MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.person_add,
                        color: Colors.black54,
                        size: 30,
                      ),
                      const SizedBox(width: 8,),
                      const Text('Users to follow', style: TextStyle(color: Colors.black54,
                          fontSize: 30),
                      ),
                      const  Divider(),
                    ],
                  ),
                ),
                Column(
                    children: userResults
                ),
              ],
            ),
          );
      },
    );
   }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true),
      body: RefreshIndicator(
        onRefresh: () => getTimeline(),
        child: buildTimeline(),
      ),
    );
  }
}
