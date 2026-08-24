import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class ProfileService {
  final ApiService _api = ApiService();

  Future<UserModel> getProfile() async {
    final response = await _api.get(ApiConfig.profile, authenticated: true);
    return UserModel.fromJson(Map<String, dynamic>.from(response['user']));
  }

  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? bio,
    String? location,
    Map<String, double>? locationCoordinates,
    String? profilePicture,
    String? restaurantName,
    String? restaurantAddress,
    String? licenseNumber,
    String? vehicleType,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (bio != null) body['bio'] = bio;
    if (location != null) body['location'] = location;
    if (locationCoordinates != null) body['locationCoordinates'] = locationCoordinates;
    if (profilePicture != null) body['profilePicture'] = profilePicture;
    if (restaurantName != null) body['restaurantName'] = restaurantName;
    if (restaurantAddress != null) body['restaurantAddress'] = restaurantAddress;
    if (licenseNumber != null) body['licenseNumber'] = licenseNumber;
    if (vehicleType != null) body['vehicleType'] = vehicleType;

    final response =
        await _api.put(ApiConfig.profile, body, authenticated: true);
    return UserModel.fromJson(Map<String, dynamic>.from(response['user']));
  }
}
