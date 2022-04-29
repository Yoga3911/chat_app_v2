import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
    MessageModel({
        required this.date,
        required this.message,
        required this.userId,
    });

    final DateTime date;
    final String message;
    final String userId;

    factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        date: (json["date"] as Timestamp).toDate(),
        message: json["message"],
        userId: json["user_id"],
    );

    Map<String, dynamic> toJson() => {
        "date": date,
        "message": message,
        "user_id": userId,
    };
}
