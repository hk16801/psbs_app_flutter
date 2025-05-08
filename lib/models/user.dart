class User {
  final String accountId;
  final String accountName;
  final String avatar;
  final String roleId;
  final String? accountImage;

  User({required this.accountId, required this.accountName, required this.avatar, required this.roleId, this.accountImage});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      accountId: json['accountId'],
      accountName: json['accountName'],
      avatar: json['avatar'] ?? './default-avatar.png',
      roleId: json['roleId'],
      accountImage: json['accountImage']
    );
  }
}