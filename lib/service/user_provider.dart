import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../model/user_mode.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;

  set setU(UserModel user) => _user = user;

  UserModel get getU => _user!;

  final CollectionReference user =
      FirebaseFirestore.instance.collection("user");
  List<UserModel> userData = [];

  Future<void> getUserData() async {
    final data = await user.get();
    setUser = <UserModel>[
      for (QueryDocumentSnapshot<Object?> item in data.docs)
        UserModel.fromJson(item.data() as Map<String, dynamic>)
    ];
  }

  set setUser(List<UserModel> users) => userData = users;

  List<UserModel> get getUser => userData;
}
