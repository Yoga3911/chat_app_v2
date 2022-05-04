import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat/model/user_mode.dart';
import 'package:chat/service/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RoomChat extends StatefulWidget {
  const RoomChat({
    Key? key,
    required this.userModel,
    required this.onRoom,
    required this.docId,
  }) : super(key: key);
  final UserModel userModel;
  final String docId;
  final bool onRoom;

  @override
  State<RoomChat> createState() => _RoomChatState();
}

class Debouncer {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;
  Debouncer({required this.milliseconds});
  run(VoidCallback action) {
    if (_timer != null) {
      _timer?.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class _RoomChatState extends State<RoomChat> {
  late TextEditingController _controller;
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> msgListener;
  late Stream time;

  @override
  void initState() {
    _controller = TextEditingController();
    msgListener = FirebaseFirestore.instance
        .collection("chat")
        .doc(widget.docId)
        .collection("message")
        .where("isRead", isEqualTo: false)
        .snapshots()
        .listen(
      (event) {
        for (QueryDocumentSnapshot<Map<String, dynamic>> i in event.docs) {
          if (i["isRead"] == false && widget.userModel.email == i["user"]) {
            FirebaseFirestore.instance
                .collection("chat")
                .doc(widget.docId)
                .collection("message")
                .doc(i.id)
                .update({
              "isRead": true,
            });
          }
        }
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    msgListener.cancel();
    super.dispose();
  }

  final _debouncer = Debouncer(milliseconds: 2000);
  @override
  Widget build(BuildContext context) {
    final CollectionReference chat =
        FirebaseFirestore.instance.collection("chat");
    final user = Provider.of<UserProvider>(context, listen: false);
    return WillPopScope(
      onWillPop: () async {
        FirebaseFirestore.instance
            .collection("user")
            .doc(widget.userModel.id)
            .collection("chats")
            .doc(widget.docId)
            .update({
          "onRoom": false,
        });
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection("user")
                  .doc(widget.userModel.id)
                  .collection("chats")
                  .doc(widget.docId)
                  .update({
                "onRoom": false,
              });
              // streamController.close();
              // time.;
              setState(() {});
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios),
          ),
          title: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("user")
                  .doc(widget.userModel.id)
                  .snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }
                final UserModel userData = UserModel.fromJson(
                    snapshot.data!.data() as Map<String, dynamic>);
                return Row(
                  children: [
                    CircleAvatar(
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: widget.userModel.image,
                          fit: BoxFit.cover,
                          height: double.infinity,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.userModel.username),
                        const SizedBox(height: 5),
                        StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("user")
                                .doc(user.getU.id)
                                .collection("chats")
                                .doc(widget.docId)
                                .snapshots(),
                            builder: (_, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox();
                              }
                              return (snapshot.data!["isTyping"])? const Text(
                                          "Sedang mengetik ...",
                                          style: TextStyle(fontSize: 10),
                                        ) : (userData.isActive)
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "online",
                                          style: TextStyle(fontSize: 10),
                                        ),
                                        Container(
                                          margin:
                                              const EdgeInsets.only(left: 3),
                                          height: 5,
                                          width: 5,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "offline",
                                          style: TextStyle(fontSize: 10),
                                        ),
                                        Container(
                                          margin:
                                              const EdgeInsets.only(left: 3),
                                          height: 5,
                                          width: 5,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      ],
                                    );
                            })
                      ],
                    ),
                  ],
                );
              }),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: chat
              .doc(widget.docId)
              .collection("message")
              .orderBy("date", descending: false)
              .snapshots(),
          builder: (_, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return Column(
              children: [
                Expanded(
                  child: GroupedListView<QueryDocumentSnapshot, DateTime>(
                      reverse: true,
                      order: GroupedListOrder.DESC,
                      elements: snapshot.data!.docs,
                      groupBy: (message) => DateTime(
                            (message["date"] as Timestamp).toDate().year,
                            (message["date"] as Timestamp).toDate().month,
                            (message["date"] as Timestamp).toDate().day,
                          ),
                      groupHeaderBuilder: (QueryDocumentSnapshot message) =>
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.only(
                                  top: 5,
                                  bottom: 5,
                                  right: 10,
                                  left: 10,
                                ),
                                decoration: BoxDecoration(
                                    color: Colors.yellow,
                                    borderRadius: BorderRadius.circular(5)),
                                child: Text(
                                  DateFormat.yMMMd().format(
                                      (message["date"] as Timestamp).toDate()),
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                      itemBuilder: (_, QueryDocumentSnapshot message) {
                        return Row(
                          mainAxisAlignment: (message["user"] == user.getU.id)
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 20, right: 20, top: 20),
                                  child: (message["user"] == user.getU.email)
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 5),
                                                padding: const EdgeInsets.only(
                                                    top: 5,
                                                    bottom: 5,
                                                    left: 10,
                                                    right: 10),
                                                decoration: const BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(15),
                                                    bottomLeft:
                                                        Radius.circular(15),
                                                    bottomRight:
                                                        Radius.circular(15),
                                                  ),
                                                ),
                                                child:
                                                    Text(message["message"])),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(DateFormat.Hm().format(
                                                    (message["date"]
                                                            as Timestamp)
                                                        .toDate())),
                                                const SizedBox(width: 5),
                                                (message["isRead"])
                                                    ? const Icon(
                                                        Icons.check,
                                                        color: Colors.blue,
                                                        size: 20,
                                                      )
                                                    : (message["isSend"])
                                                        ? const Icon(
                                                            Icons.check,
                                                            size: 20,
                                                          )
                                                        : const Icon(
                                                            Icons
                                                                .access_time_rounded,
                                                            size: 20,
                                                          ),
                                              ],
                                            )
                                          ],
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 5),
                                              padding: const EdgeInsets.only(
                                                  top: 5,
                                                  bottom: 5,
                                                  left: 10,
                                                  right: 10),
                                              decoration: const BoxDecoration(
                                                color: Color.fromARGB(255, 113, 113, 113),
                                                borderRadius: BorderRadius.only(
                                                  topRight: Radius.circular(15),
                                                  bottomLeft:
                                                      Radius.circular(15),
                                                  bottomRight:
                                                      Radius.circular(15),
                                                ),
                                              ),
                                              child: Text(message["message"]),
                                            ),
                                            Text(
                                              DateFormat.Hm().format(
                                                  (message["date"] as Timestamp)
                                                      .toDate()),
                                            )
                                          ],
                                        )),
                            ),
                          ],
                        );
                      }),
                ),
                Container(
                  width: double.infinity,
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(flex: 1, child: SizedBox()),
                      Flexible(
                        flex: 12,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: double.infinity,
                              maxWidth: double.infinity,
                              minHeight: 25.0,
                              maxHeight: 135.0,
                            ),
                            child: Scrollbar(
                              child: TextField(
                                onChanged: (val) {
                                  if (val.isNotEmpty) {
                                    FirebaseFirestore.instance
                                        .collection("user")
                                        .doc(widget.userModel.id)
                                        .collection("chats")
                                        .doc(widget.docId)
                                        .update(
                                      {
                                        "isTyping": true,
                                      },
                                    );
                                  }
                                  _debouncer.run(
                                    () => FirebaseFirestore.instance
                                        .collection("user")
                                        .doc(widget.userModel.id)
                                        .collection("chats")
                                        .doc(widget.docId)
                                        .update(
                                      {
                                        "isTyping": false,
                                      },
                                    ),
                                  );
                                },
                                controller: _controller,
                                cursorColor: Colors.red,
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  fillColor: Colors.white,
                                  filled: true,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.all(10),
                                  hintText: "Type your message",
                                  hintStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("user")
                              .doc(user.getU.id)
                              .collection("chats")
                              .doc(widget.docId)
                              .snapshots(),
                          builder: (_, snapshot3) {
                            if (snapshot3.connectionState ==
                                ConnectionState.waiting) {
                              return IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.send_rounded));
                            }
                            return Flexible(
                              child: IconButton(
                                  onPressed: () async {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    final text = _controller.text;
                                    _controller.text = "";
                                    // await Future.delayed(Duration(seconds: 5));
                                    final msgDoc = chat
                                        .doc(widget.docId)
                                        .collection("message")
                                        .doc();
                                    await msgDoc.set({
                                      "message": text,
                                      "user": user.getU.email,
                                      "isRead": false,
                                      "date": DateTime.now(),
                                      "isSend": false,
                                    }).whenComplete(() {
                                      msgDoc.update({"isSend": true});
                                    });
                                    final unread = await FirebaseFirestore
                                        .instance
                                        .collection("user")
                                        .doc(widget.userModel.id)
                                        .collection("chats")
                                        .doc(widget.docId)
                                        .get();
                                    if ((snapshot3.data?.data() as Map<String,
                                            dynamic>)["onRoom"] ==
                                        false) {
                                      FirebaseFirestore.instance
                                          .collection("user")
                                          .doc(widget.userModel.id)
                                          .collection("chats")
                                          .doc(widget.docId)
                                          .update({
                                        "unread": unread["unread"] + 1,
                                        "date": DateTime.now(),
                                      });
                                    } else {
                                      await FirebaseFirestore.instance
                                          .collection("user")
                                          .doc(widget.userModel.id)
                                          .collection("chats")
                                          .doc(widget.docId)
                                          .update({
                                        "date": DateTime.now(),
                                      });
                                      chat
                                          .doc(widget.docId)
                                          .collection("message")
                                          .doc(msgDoc.id)
                                          .update({
                                        "isRead": true,
                                      });
                                    }
                                    FirebaseFirestore.instance
                                        .collection("user")
                                        .doc(user.getU.id)
                                        .collection("chats")
                                        .doc(widget.docId)
                                        .update({
                                      "date": DateTime.now(),
                                    });
                                  },
                                  icon: const Icon(Icons.send)),
                              flex: 2,
                            );
                          }),
                      const Flexible(flex: 1, child: SizedBox())
                    ],
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
