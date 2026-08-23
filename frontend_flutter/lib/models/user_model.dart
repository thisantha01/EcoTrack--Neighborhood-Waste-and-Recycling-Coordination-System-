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

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? location;
  final LocationCoordinates? locationCoordinates;
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
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? '',
      location: json['location'],
      locationCoordinates: coords,
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
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      vehicleType: vehicleType ?? this.vehicleType,
    );
  }
}