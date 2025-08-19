enum UserType {
  general('general', '일반 회원'),
  shopOwner('shop_owner', '상점 회원'),
  admin('admin', '관리자');

  final String value;
  final String displayName;
  
  const UserType(this.value, this.displayName);
  
  static UserType fromString(String value) {
    return UserType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => UserType.general,
    );
  }
}

class UserProfile {
  final String id;
  final String? email;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final UserType userType;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    this.email,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.userType = UserType.general,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      userType: UserType.fromString(json['user_type'] ?? 'general'),
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
      updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'user_type': userType.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    String? avatarUrl,
    UserType? userType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}