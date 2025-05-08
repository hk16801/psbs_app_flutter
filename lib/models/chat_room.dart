import 'package:psbs_app_flutter/models/user.dart';

class ChatRoom {
  final String chatRoomId; // Guid converted to String
  final String serveFor; // Guid converted to String
  final String roomOwner; // Guid converted to String
  final String? lastMessage;
  final DateTime updatedAt;
  final bool isSeen;
  final bool isSupportRoom;
  final User? user; // Optional user details, fetched separately
  final List<User> staffs; // List of staffs in the room

  ChatRoom({
    required this.chatRoomId,
    required this.serveFor,
    required this.roomOwner,
    this.lastMessage,
    required this.updatedAt,
    required this.isSeen,
    required this.isSupportRoom,
    this.user,
    required this.staffs,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      chatRoomId: json['chatRoomId'].toString(), // Convert Guid to String
      serveFor: json['serveFor'].toString(), // Convert Guid to String
      roomOwner: json['roomOwner'].toString(), // Convert Guid to String
      lastMessage: json['lastMessage'],
      updatedAt: DateTime.parse(json['updateAt']), // Corrected key name
      isSeen: json['isSeen'],
      isSupportRoom: json['isSupportRoom'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      staffs: (json['staffs'] as List?)
              ?.map((item) => User.fromJson(item))
              .toList() ??
          [], // handle null staff list.
    );
  }

  ChatRoom copyWith({
    String? chatRoomId,
    String? serveFor,
    String? roomOwner,
    String? lastMessage,
    DateTime? updatedAt,
    bool? isSeen,
    bool? isSupportRoom,
    User? user,
    List<User>? staffs,
  }) {
    return ChatRoom(
      chatRoomId: chatRoomId ?? this.chatRoomId,
      serveFor: serveFor ?? this.serveFor,
      roomOwner: roomOwner ?? this.roomOwner,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      isSeen: isSeen ?? this.isSeen,
      isSupportRoom: isSupportRoom ?? this.isSupportRoom,
      user: user ?? this.user,
      staffs: staffs ?? this.staffs,
    );
  }
}
