import 'package:json_annotation/json_annotation.dart';
import 'message_model.dart';
import 'user_model.dart';

part 'conversation_model.g.dart';

enum ConversationType {
  direct,
  group,
  channel,
}

@JsonSerializable()
class ConversationModel {
  final String id;
  final ConversationType type;
  final String? name;
  final String? description;
  final String? avatarUrl;
  final List<String> memberIds;
  final List<String> adminIds;
  final MessageModel? lastMessage;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? settings;
  
  // Computed properties (not serialized)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<UserModel>? members;
  
  const ConversationModel({
    required this.id,
    required this.type,
    this.name,
    this.description,
    this.avatarUrl,
    required this.memberIds,
    this.adminIds = const [],
    this.lastMessage,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.settings,
    this.members,
  });
  
  factory ConversationModel.fromJson(Map<String, dynamic> json) => _$ConversationModelFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationModelToJson(this);
  
  ConversationModel copyWith({
    String? id,
    ConversationType? type,
    String? name,
    String? description,
    String? avatarUrl,
    List<String>? memberIds,
    List<String>? adminIds,
    MessageModel? lastMessage,
    int? unreadCount,
    bool? isMuted,
    bool? isPinned,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? settings,
    List<UserModel>? members,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settings: settings ?? this.settings,
      members: members ?? this.members,
    );
  }
  
  // Helper methods
  String getDisplayName(String currentUserId) {
    if (type == ConversationType.direct) {
      final otherMember = members?.firstWhere(
        (member) => member.id != currentUserId,
        orElse: () => UserModel(
          id: '',
          email: '',
          username: 'Unknown',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return otherMember?.displayName ?? otherMember?.username ?? 'Unknown';
    }
    return name ?? 'Group Chat';
  }
  
  String? getAvatarUrl(String currentUserId) {
    if (type == ConversationType.direct) {
      final otherMember = members?.firstWhere(
        (member) => member.id != currentUserId,
        orElse: () => UserModel(
          id: '',
          email: '',
          username: 'Unknown',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return otherMember?.avatarUrl;
    }
    return avatarUrl;
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;
  
  @override
  int get hashCode => id.hashCode;
}
