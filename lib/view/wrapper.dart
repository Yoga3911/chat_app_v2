import 'package:chat/model/user_mode.dart';
import 'package:chat/service/user_provider.dart';
import 'package:chat/view/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({Key? key, required this.id}) : super(key: key);
  final String id;

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    final user = FirebaseFirestore.instance.collection("user").doc(widget.id);
    user.update({
      "isActive": true,
    });
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = FirebaseFirestore.instance.collection("user").doc(widget.id);
    if (state == AppLifecycleState.resumed) {
      user.update({
        "isActive": true,
      });
    } else if (state == AppLifecycleState.paused) {
      user.update({
        "isActive": false,
      });
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseFirestore.instance.collection("user");
    final userC = Provider.of<UserProvider>(context, listen: false);
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: user.doc(widget.id).get(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox();
          }
          userC.setU =
              UserModel.fromJson(snapshot.data!.data() as Map<String, dynamic>);
          // log(notif.name);
          return const HomePage();
        },
      ),
    );
  }
}
