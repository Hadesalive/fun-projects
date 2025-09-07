import 'package:json_annotation/json_annotation.dart';

part 'message_model.g.dart';

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

@JsonSerializable()
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final MessageType type;
  final String? text;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? replyToId;
  final List<String> reactions;
  
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    this.text,
    this.mediaUrl,
    this.thumbnailUrl,
    this.metadata,
    this.status = MessageStatus.sending,
    required this.createdAt,
    this.updatedAt,
    this.replyToId,
    this.reactions = const [],
  });
  
  factory MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);
  Map<String, dynamic> toJson() => _$MessageModelToJson(this);
  
  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    MessageType? type,
    String? text,
    String? mediaUrl,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? replyToId,
    List<String>? reactions,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replyToId: replyToId ?? this.replyToId,
      reactions: reactions ?? this.reactions,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id;
  
  @override
  int get hashCode => id.hashCode;
}
