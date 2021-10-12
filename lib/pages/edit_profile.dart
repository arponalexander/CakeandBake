import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import "package:flutter/material.dart";
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool isLoading = false;
  User user;
  bool _displayNameValid = true;
  bool _bioValid = true;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await usersRef.doc(widget.currentUserId).get();
    user = User.fromDocument(doc);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: const Text(
            'Display Name',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(hintText: 'Update Display Name',
          errorText: _displayNameValid ? null : 'Display Name is too short'),
        )
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: const Text(
            'Bio',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(hintText: 'Update Bio', errorText: _bioValid ? null: 'Bio is too long'),
        )
      ],
    );
  }

  updateProfileData(){
    setState(() {
      displayNameController.text.trim().length <3 || displayNameController.text.isEmpty ? _displayNameValid = false : _displayNameValid = true;
      bioController.text.trim().length > 100 ? _bioValid = false : _bioValid = true;
    });
    if(_displayNameValid && _bioValid){
      usersRef.doc(widget.currentUserId).update({
        'displayName': displayNameController.text, 'bio': bioController.text
      });
      SnackBar snackbar = SnackBar(content: Text('Profile Updated'));
      _scaffoldKey.currentState.showSnackBar(snackbar);
    }
  }
  logout() async{
  await googleSignIn.signOut();
  Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Edit Profile',
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.done,
              size: 30,
              color: Colors.green,
            ),
          )
        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              CachedNetworkImageProvider(user.photoUrl),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: <Widget>[
                            buildDisplayNameField(),
                            buildBioField(),
                          ],
                        ),
                      ),
                      RaisedButton(
                        onPressed: updateProfileData,
                        color: Colors.white.withOpacity(.8),
                        child: const Text(
                          'Update Profile Data',
                          style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child:  FlatButton.icon(
                            onPressed: logout,
                            icon: Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                            label: const  Text(
                              'Logout',
                              style: const TextStyle(color: Colors.red, fontSize: 20),
                            )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
