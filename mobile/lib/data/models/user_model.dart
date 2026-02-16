class UserModel {
  final String id;
  final String email;
  final LocationModel? location;
  final List<String> friends;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.location,
    required this.friends,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      location: json['location'] != null 
          ? LocationModel.fromJson(json['location']) 
          : null,
      friends: json['friends'] != null 
          ? List<String>.from(json['friends']) 
          : [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'location': location?.toJson(),
      'friends': friends,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class LocationModel {
  final double latitude;
  final double longitude;
  final DateTime? lastUpdated;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.lastUpdated,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }
}
