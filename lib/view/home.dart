import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat/model/user_mode.dart';
import 'package:chat/service/auth_provider.dart';
import 'package:chat/service/user_provider.dart';
import 'package:chat/view/list_user.dart';
import 'package:chat/view/login.dart';
import 'package:chat/view/room_chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = Provider.of<UserProvider>(context, listen: false).getU;
    final CollectionReference getUser =
        FirebaseFirestore.instance.collection("user");
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ListUser())),
        child: const Icon(Icons.message_rounded),
      ),
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(7),
          child: CircleAvatar(
            child: ClipOval(
              child: CachedNetworkImage(
                height: double.infinity,
                width: double.infinity,
                imageUrl: user.image,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        title: Text(user.username),
        actions: [
          IconButton(
            onPressed: () async {
              final users =
                  FirebaseFirestore.instance.collection("user").doc(user.id);
              users.update({
                "isActive": false,
              });
              final pref = await SharedPreferences.getInstance();
              pref.remove("id");
              await auth.logout().then(
                    (value) => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(),
                      ),
                      (route) => false,
                    ),
                  );
            },
            icon: const Icon(Icons.logout_rounded),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getUser
            .doc(user.id)
            .collection("chats")
            .orderBy("date", descending: true)
            .snapshots(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (_, index) {
              final userData =
                  (snapshot.data!.docs[index].data() as Map<String, dynamic>);
              return StreamBuilder<DocumentSnapshot>(
                stream: getUser.doc(userData["user_id"]).snapshots(),
                builder: (_, snapshot2) {
                  if (!snapshot2.hasData) {
                    return const SizedBox();
                  }
                  final UserModel userModel = UserModel.fromJson(
                      snapshot2.data!.data() as Map<String, dynamic>);
                  return ListTile(
                    leading: CircleAvatar(
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: userModel.image,
                          fit: BoxFit.cover,
                          height: double.infinity,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    trailing: (userData["unread"] == 0)
                        ? const SizedBox()
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle),
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  userData["unread"].toString(),
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                              ((DateTime.now().millisecondsSinceEpoch -
                                          (userData["date"] as Timestamp)
                                              .toDate()
                                              .millisecondsSinceEpoch) <
                                      86400000)
                                  ? Text(
                                      DateFormat.Hm().format(
                                        (userData["date"] as Timestamp)
                                            .toDate(),
                                      ),
                                      style: const TextStyle(fontSize: 12),
                                    )
                                  : ((DateTime.now().millisecondsSinceEpoch -
                                              (userData["date"] as Timestamp)
                                                  .toDate()
                                                  .millisecondsSinceEpoch) <
                                          172800000)
                                      ? const Text(
                                          "Kemarin",
                                          style: TextStyle(fontSize: 12),
                                        )
                                      : Text(
                                          DateFormat("dd/MM/yyyy").format(
                                            (userData["date"] as Timestamp)
                                                .toDate(),
                                          ),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                            ],
                          ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userModel.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("chat")
                              .doc(snapshot.data!.docs[index].id)
                              .collection("message")
                              .orderBy("date", descending: false)
                              .snapshots(),
                          builder: (_, snapshot2) {
                            if (!snapshot2.hasData) {
                              return const SizedBox();
                            }
                            if (snapshot2.data!.docs.isEmpty) {
                              return const SizedBox();
                            }
                            return Text(
                              (snapshot2.data!.docs.last.data()
                                  as Map<String, dynamic>)["message"],
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                            );
                          },
                        )
                      ],
                    ),
                    onTap: () {
                      FirebaseFirestore.instance
                          .collection("user")
                          .doc(userModel.id)
                          .collection("chats")
                          .doc(snapshot.data!.docs[index].id)
                          .update({
                        "onRoom": true,
                      });
                      FirebaseFirestore.instance
                          .collection("user")
                          .doc(user.id)
                          .collection("chats")
                          .doc(snapshot.data!.docs[index].id)
                          .update({
                        "unread": 0,
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoomChat(
                            userModel: userModel,
                            docId: snapshot.data!.docs[index].id,
                            onRoom: (snapshot.data!.docs[index].data()
                                as Map<String, dynamic>)["onRoom"],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
