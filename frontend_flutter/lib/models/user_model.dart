class LocationCoordinates {
  final double? lat;
  final double? lng;

  LocationCoordinates({this.lat, this.lng});

  factory LocationCoordinates.fromJson(Map<String, dynamic> json) {
    return LocationCoordinates(
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
      };
}

class LiveLocation {
  final double? lat;
  final double? lng;
  final DateTime? updatedAt;

  LiveLocation({this.lat, this.lng, this.updatedAt});

  factory LiveLocation.fromJson(Map<String, dynamic> json) => LiveLocation(
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        updatedAt: json['updatedAt'] == null
            ? null
            : DateTime.tryParse(json['updatedAt'].toString()),
      );

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? location;
  final LocationCoordinates? locationCoordinates;
  final LiveLocation? liveLocation;
  final String? profilePicture;
  final String? bio;
  final String? restaurantName;
  final String? restaurantAddress;
  final String? licenseNumber;
  final String? vehicleType;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.location,
    this.locationCoordinates,
    this.liveLocation,
    this.profilePicture,
    this.bio,
    this.restaurantName,
    this.restaurantAddress,
    this.licenseNumber,
    this.vehicleType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    LocationCoordinates? coords;
    if (json['locationCoordinates'] is Map) {
      coords = LocationCoordinates.fromJson(
        Map<String, dynamic>.from(json['locationCoordinates']),
      );
    }
    final liveLocation = json['liveLocation'] is Map
        ? LiveLocation.fromJson(Map<String, dynamic>.from(json['liveLocation']))
        : null;
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? '',
      location: json['location'],
      locationCoordinates: coords,
      liveLocation: liveLocation,
      profilePicture: json['profilePicture'],
      bio: json['bio'],
      restaurantName: json['restaurantName'],
      restaurantAddress: json['restaurantAddress'],
      licenseNumber: json['licenseNumber'],
      vehicleType: json['vehicleType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'location': location,
      'locationCoordinates': locationCoordinates?.toJson(),
      'liveLocation': liveLocation?.toJson(),
      'profilePicture': profilePicture,
      'bio': bio,
      'restaurantName': restaurantName,
      'restaurantAddress': restaurantAddress,
      'licenseNumber': licenseNumber,
      'vehicleType': vehicleType,
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? location,
    LocationCoordinates? locationCoordinates,
    LiveLocation? liveLocation,
    String? profilePicture,
    String? bio,
    String? restaurantName,
    String? restaurantAddress,
    String? licenseNumber,
    String? vehicleType,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      location: location ?? this.location,
      locationCoordinates: locationCoordinates ?? this.locationCoordinates,
      liveLocation: liveLocation ?? this.liveLocation,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      vehicleType: vehicleType ?? this.vehicleType,
    );
  }
}
