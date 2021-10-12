import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;

  handleSearch(String query) {
    Future<QuerySnapshot> users = usersRef
        .where('displayName', isGreaterThanOrEqualTo: query).where('username', isGreaterThanOrEqualTo: query)
        .get();
    setState(() {
      searchResultsFuture = users;
    });
    if(users=null){
      return Text('User not found');
    }
  }

  clearSearch() {
    searchController.clear();

  }

  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title:
          TextFormField(
            controller: searchController,
            decoration: InputDecoration(
              hintText:  'Search for a user...',
              filled: true,
              prefixIcon: const Icon(
                Icons.account_box,
                size: 40,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey,),
                onPressed: clearSearch,
              ),
            ),
            onFieldSubmitted: handleSearch,
          ),
    );
  }

  buildNoContent() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/search.svg',
              height: orientation == Orientation.portrait ? 200 : 150,
            ),
            const  Text(
              'Find Users',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildSearchResults() {
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          UserResult searchResult = UserResult(user);
          searchResults.add(searchResult);
        });
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildSearchField(),
      body:
          searchResultsFuture == null ? buildNoContent() : buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;

  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.withOpacity(.1),
      child: Column(children: <Widget>[
        GestureDetector(
          onTap: () => showProfile(context, profileId: user.id),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey,
              backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            ),
            title: Text(
              user.displayName,
              style:
              const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              user.username,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ),
        const  Divider(
          height: 2,
          color: Colors.white54,
        ),
      ]),
    );
  }
}
