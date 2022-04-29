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

class _RoomChatState extends State<RoomChat> {
  late TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                        (userData.isActive)
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "online",
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 3),
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
                                    margin: const EdgeInsets.only(left: 3),
                                    height: 5,
                                    width: 5,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                ],
                              ),
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
                    groupHeaderBuilder: (QueryDocumentSnapshot message) => Row(
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
                    itemBuilder: (_, QueryDocumentSnapshot message) => Row(
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
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(15),
                                                bottomLeft: Radius.circular(15),
                                                bottomRight:
                                                    Radius.circular(15),
                                              ),
                                            ),
                                            child: Text(message["message"])),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(DateFormat.Hm().format(
                                                (message["date"] as Timestamp)
                                                    .toDate())),
                                            const SizedBox(width: 5),
                                            const Icon(Icons.check, size: 20)
                                          ],
                                        )
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 5),
                                          padding: const EdgeInsets.only(
                                              top: 5,
                                              bottom: 5,
                                              left: 10,
                                              right: 10),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.only(
                                              topRight: Radius.circular(15),
                                              bottomLeft: Radius.circular(15),
                                              bottomRight: Radius.circular(15),
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
                    ),
                  ),
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
                              return const SizedBox();
                            }
                            return Flexible(
                              child: IconButton(
                                  onPressed: () async {
                                    chat
                                        .doc(widget.docId)
                                        .collection("message")
                                        .add({
                                      "message": _controller.text,
                                      "user": user.getU.email,
                                      "date": DateTime.now(),
                                    });
                                    _controller.text = "";
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
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
                                      FirebaseFirestore.instance
                                          .collection("user")
                                          .doc(widget.userModel.id)
                                          .collection("chats")
                                          .doc(widget.docId)
                                          .update({
                                        "date": DateTime.now(),
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
