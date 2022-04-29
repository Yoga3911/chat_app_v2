import 'package:chat/model/user_mode.dart';
import 'package:chat/service/user_provider.dart';
import 'package:chat/view/room_chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ListUser extends StatelessWidget {
  const ListUser({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).getU;
    final CollectionReference getUser =
        FirebaseFirestore.instance.collection("user");
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: getUser.doc(user.id).collection("chats").snapshots(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("user").snapshots(),
            builder: (_, snapshot2) {
              if (snapshot2.connectionState == ConnectionState.waiting) {
                return const SizedBox();
              }
              return ListView.builder(
                itemCount: snapshot2.data?.docs.length ?? 0,
                itemBuilder: (_, index) {
                  final UserModel userModel = UserModel.fromJson(
                      snapshot2.data!.docs[index].data()
                          as Map<String, dynamic>);
                  if (userModel.id == user.id) {
                    return const SizedBox();
                  }
                  return ListTile(
                    title: Text(userModel.username),
                    onTap: () async {
                      for (var i
                          in snapshot.data!.docs) {
                        if ((i.data() as Map<String, dynamic>)["user_id"] == userModel.id) {
                          FirebaseFirestore.instance
                              .collection("user")
                              .doc(userModel.id)
                              .collection("chats")
                              .doc(i.id)
                              .update({
                            "unread": 0,
                            "onRoom": true,
                          });
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoomChat(
                                userModel: userModel,
                                docId: i.id,
                                onRoom: true,
                              ),
                            ),
                          );
                          return;
                        }
                      }
                      final doc =
                          FirebaseFirestore.instance.collection("chat").doc();
                      doc.set({
                        "members": [user.id, userModel.id]
                      });
                      await FirebaseFirestore.instance
                          .collection("user")
                          .doc(user.id)
                          .collection("chats")
                          .doc(doc.id)
                          .set({
                        "user_id": userModel.id,
                        "unread": 0,
                        "onRoom": false,
                        "date": DateTime.now(),
                      });
                      await FirebaseFirestore.instance
                          .collection("user")
                          .doc(userModel.id)
                          .collection("chats")
                          .doc(doc.id)
                          .set({
                        "user_id": user.id,
                        "unread": 0,
                        "onRoom": true,
                        "date": DateTime.now(),
                      });
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoomChat(
                            userModel: userModel,
                            docId: doc.id,
                            onRoom: true,
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
