import 'user_model.dart';

class FriendRequestModel {
  final String id;
  final UserModel sender;
  final UserModel receiver;
  final String status;
  final DateTime createdAt;

  FriendRequestModel({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: json['_id'] ?? '',
      sender: UserModel.fromJson(json['sender']),
      receiver: UserModel.fromJson(json['receiver']),
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': sender.toJson(),
      'receiver': receiver.toJson(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
