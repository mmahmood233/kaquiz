// UserModel is the Dart version of a user row returned by the backend.
// Screens use this instead of reading raw JSON maps.
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final LocationModel? location;
  final List<String> friends;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    this.location,
    required this.friends,
    required this.createdAt,
  });

  // Show the saved name; if there is no name, use the part before @ in email.
  String get displayName => name.isNotEmpty ? name : email.split('@').first;

  // Convert backend JSON into a UserModel.
  // This supports a few field names because older endpoints returned different shapes.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Some backend responses use _id and others use id.
    final rawId = json['_id'] ?? json['id'];

    // Friends can arrive as just IDs or as full user objects.
    final rawFriends = json['friends'];
    return UserModel(
      id: rawId != null ? rawId.toString() : '',
      email: json['email'] ?? '',
      name: json['name'] ?? (json['email'] ?? '').toString().split('@').first,
      avatar: json['avatar'],
      // Location is optional because a user may not have opened the app yet.
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : null,
      // Normalize friends into a simple list of backend user IDs.
      friends: rawFriends is List
          ? rawFriends
                .map((friend) {
                  if (friend is Map<String, dynamic>) {
                    return (friend['_id'] ?? friend['id'] ?? '').toString();
                  }
                  return friend.toString();
                })
                .where((id) => id.isNotEmpty)
                .toList()
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // Convert this object back into JSON when code needs to send/store it.
  Map<String, dynamic> toJson() => {
    '_id': id,
    'email': email,
    'name': name,
    'avatar': avatar,
    'location': location?.toJson(),
    'friends': friends,
    'createdAt': createdAt.toIso8601String(),
  };
}

// LocationModel stores the last known coordinates returned by the backend.
class LocationModel {
  final double latitude;
  final double longitude;
  final DateTime? lastUpdated;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.lastUpdated,
  });

  // Convert backend location JSON into a LocationModel.
  // The map uses this to place friend markers.
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    // Support multiple coordinate key names from different API versions.
    final latRaw = json['latitude'] ?? json['lat'] ?? 0.0;
    final lngRaw = json['longitude'] ?? json['lng'] ?? json['lon'] ?? 0.0;
    final tsRaw = json['lastUpdated'] ?? json['timestamp'];
    return LocationModel(
      latitude: double.tryParse(latRaw.toString()) ?? 0.0,
      longitude: double.tryParse(lngRaw.toString()) ?? 0.0,
      lastUpdated: tsRaw != null ? DateTime.tryParse(tsRaw.toString()) : null,
    );
  }

  // Convert location back to JSON if it needs to be sent or cached.
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'lastUpdated': lastUpdated?.toIso8601String(),
  };
}
