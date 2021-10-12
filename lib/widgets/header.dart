import 'package:flutter/material.dart';

AppBar header(context ,{ bool isAppTitle = false, String titleText, removeBackButton = false}) {
  return AppBar(
    automaticallyImplyLeading:removeBackButton ? false : true,
    title: Text(
      isAppTitle ?
      'Cake and Bake' : titleText,
      style:
          TextStyle(color: Colors.white, fontFamily: isAppTitle ? 'Signatra' : '', fontSize: isAppTitle ? 45: 25),
      overflow: TextOverflow.ellipsis
      ),
    centerTitle: true,
    backgroundColor: Theme.of(context).primaryColor,
  );
}
