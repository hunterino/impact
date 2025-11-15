import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? location;
  final String? profileImageUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? roles;
  final bool isVerified;
  final String? status;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.location,
    this.profileImageUrl,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
    this.roles,
    required this.isVerified,
    this.status,
  });

  // Full name getter
  String get fullName => '$firstName $lastName';

  // Initial getter for avatar
  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}';
    } else if (firstName.isNotEmpty) {
      return firstName[0];
    } else if (lastName.isNotEmpty) {
      return lastName[0];
    }
    return '';
  }

  // Has role method
  bool hasRole(String role) {
    return roles?.contains(role) ?? false;
  }

  // Factory method to create user from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);

  // Method to convert user to JSON
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  // Copy with method to create a new instance with some properties changed
  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? location,
    String? profileImageUrl,
    String? bio,
    List<String>? roles,
    bool? isVerified,
    String? status,
  }) {
    return UserModel(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      roles: roles ?? this.roles,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
    );
  }
}
