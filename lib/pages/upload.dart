import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as Im;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final User currentUser;

  Upload({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> with AutomaticKeepAliveClientMixin<Upload> {
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  File file;
  bool isUploading = false;
  String postId = Uuid().v4();

  handleTakePhoto() async {
    Navigator.pop(context);
    PickedFile file = await ImagePicker().getImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,

    );
    setState(() {
      this.file = file as File;
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    File file = (await ImagePicker().getImage(
      source: ImageSource.gallery,
      maxHeight: 675,
      maxWidth: 960,
    )) as File;
    setState(() {
      this.file = file;
    });
  }

  selectImage(parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Create Post'),
            children: <Widget>[
              SimpleDialogOption(
                child: const Text('Photo with Camera'),
                onPressed: handleTakePhoto,
              ),
              SimpleDialogOption(
                child: const Text('Image from Gallery'),
                onPressed: handleChooseFromGallery,
              ),
              SimpleDialogOption(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  Container buildSplashScreen() {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/upload.svg',
            height: 260,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child:  RaisedButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Upload Image',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
              color: Theme.of(context).primaryColor.withOpacity(.8),
              onPressed: () => selectImage(context),
            ),
          ),
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      // ignore: unnecessary_statements
      file == null;
    });
  }

  // Image Compression to avoid the limit of firebase storage  QUALITY 100 = ORIGINAL SIZE
  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 80));
    setState(() {
      file = compressedImageFile;
    });
  }

  Future<String> uploadImage(imageFile) async {
    UploadTask uploadTask =
        storageRef.child('post_$postId.jpg').putFile(imageFile);
    TaskSnapshot storageSnap = await uploadTask;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFirestore(
      {String mediaUrl, String location, String description}) {
    postsRef
        .doc(widget.currentUser.id)
        .collection('userPosts')
        .doc(postId)
        .set({
      'postId': postId,
      'ownerId': widget.currentUser.id,
      'username': widget.currentUser.username,
      'mediaUrl': mediaUrl,
      'description': description,
      'location': location,
      'timestamp': timestamp,
      'likes': {},
    });
    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      isUploading = false;
      // Makes sure that every postId is different
      postId = Uuid().v4();
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(file);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text,
    );
    Navigator.push(context, MaterialPageRoute(builder: (context) => Profile(profileId: currentUser.id)));
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
          icon:const  Icon(Icons.arrow_back, color: Colors.black),
          onPressed: clearImage,
        ),
        title: const Text(
          'Caption Post',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          FlatButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: const  Text(
              'Post',
              style:  TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploading ? linearProgress() : Text(''),
          Container(
            height: 220,
            width: MediaQuery.of(context).size.width * .8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(file),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: 250,
              child: TextField(
                controller: captionController,
                decoration: const InputDecoration(
                    hintText: 'Write your caption...', border: InputBorder.none),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: const Icon(Icons.pin_drop, color: Colors.orange, size: 35),
            title: Container(
              width: 250,
              child: TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  hintText: 'Where was this photo taken?',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 200,
            height: 100,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              label: const Text(
                'Use Current Location',
                style: const TextStyle(color: Colors.white),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              color: Colors.blue,
              onPressed: getUserLocation,
              icon: const Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }

  getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String completeAddress =
        '${placemark.subThoroughfare}, ${placemark.thoroughfare}, ${placemark.subLocality},${placemark.locality},${placemark.subAdministrativeArea}, ${placemark.administrativeArea}, ${placemark.postalCode}, ${placemark.country} ';
    print(completeAddress);
    String formattedAddress = '${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.country}';
    locationController.text = formattedAddress;
  }

  bool get wantKeepAlive => true;

  // get updateKeepAlive if false
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
