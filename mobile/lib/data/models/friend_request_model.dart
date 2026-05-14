// InviteUserModel is the small user object the backend sends inside invites.
// It is smaller than UserModel because requests only need id, name, avatar, email.
class InviteUserModel {
  final String id;
  final String name;
  final String? avatar;
  final String email;

  InviteUserModel({
    required this.id,
    required this.name,
    this.avatar,
    required this.email,
  });

  // Show the user's name, or fall back to the email prefix.
  String get displayName => name.isNotEmpty ? name : email.split('@').first;

  // Convert the sender/recipient JSON from the backend into a Dart object.
  factory InviteUserModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    return InviteUserModel(
      id: rawId != null ? rawId.toString() : '',
      name: json['name'] ?? (json['email'] ?? '').toString().split('@').first,
      avatar: json['avatar'],
      email: json['email'] ?? '',
    );
  }
}

// FriendRequestModel represents one pending friend request shown in the UI.
class FriendRequestModel {
  final String id;
  final InviteUserModel sender;
  final InviteUserModel receiver;
  final String status;
  final DateTime createdAt;
  final bool isIncoming;

  FriendRequestModel({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.status,
    required this.createdAt,
    required this.isIncoming,
  });

  // Build a request from the backend's incoming list.
  // Incoming means someone else sent a request to the logged-in user.
  factory FriendRequestModel.fromIncoming(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      sender: InviteUserModel.fromJson(json['sender'] ?? {}),
      receiver: InviteUserModel(id: '', name: '', email: ''),
      status: 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isIncoming: true,
    );
  }

  // Build a request from the backend's outgoing list.
  // Outgoing means the logged-in user sent a request and is waiting.
  factory FriendRequestModel.fromOutgoing(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      sender: InviteUserModel(id: '', name: '', email: ''),
      receiver: InviteUserModel.fromJson(json['recipient'] ?? {}),
      status: 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isIncoming: false,
    );
  }

  // Kept for older backend responses that used sender/receiver directly.
  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      sender: InviteUserModel.fromJson(json['sender'] ?? {}),
      receiver: InviteUserModel.fromJson(json['receiver'] ?? {}),
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isIncoming: true,
    );
  }
}
