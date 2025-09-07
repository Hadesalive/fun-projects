class Message {
  final String id;
  final String conversationId;
  final MessageSender sender;
  final MessageType type;
  final MessageContent content;
  final String? replyToId;
  final List<MessageReaction> reactions;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isMe;
  final bool isDeleted;

  const Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.type,
    required this.content,
    this.replyToId,
    this.reactions = const [],
    required this.status,
    required this.createdAt,
    this.editedAt,
    required this.isMe,
    this.isDeleted = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      conversationId: json['conversation'] ?? '',
      sender: MessageSender.fromJson(json['sender'] ?? {}),
      type: MessageType.fromString(json['type'] ?? 'text'),
      content: MessageContent.fromJson(json['content'] ?? {}, json['type'] ?? 'text'),
      replyToId: json['replyTo'],
      reactions: (json['reactions'] as List<dynamic>? ?? [])
          .map((r) => MessageReaction.fromJson(r))
          .toList(),
      status: MessageStatus.fromString(json['status'] ?? 'sent'),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      isMe: json['isMe'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'sender': sender.toJson(),
      'type': type.toString(),
      'content': content.toJson(),
      'replyToId': replyToId,
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'isMe': isMe,
      'isDeleted': isDeleted,
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    MessageSender? sender,
    MessageType? type,
    MessageContent? content,
    String? replyToId,
    List<MessageReaction>? reactions,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? editedAt,
    bool? isMe,
    bool? isDeleted,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      content: content ?? this.content,
      replyToId: replyToId ?? this.replyToId,
      reactions: reactions ?? this.reactions,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      isMe: isMe ?? this.isMe,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

class MessageSender {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  const MessageSender({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? json['username'] ?? 'Unknown',
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
    };
  }
}

class MessageContent {
  final String? text;
  final MessageMedia? media;
  final MessageSystem? system;

  const MessageContent({
    this.text,
    this.media,
    this.system,
  });

  factory MessageContent.fromJson(Map<String, dynamic> json, String type) {
    switch (type) {
      case 'text':
        return MessageContent(text: json['text']);
      case 'image':
      case 'video':
      case 'audio':
      case 'file':
        return MessageContent(
          media: json['media'] != null ? MessageMedia.fromJson(json['media']) : null,
        );
      case 'system':
        return MessageContent(
          system: json['system'] != null ? MessageSystem.fromJson(json['system']) : null,
        );
      default:
        return MessageContent(text: json['text']);
    }
  }

  Map<String, dynamic> toJson() {
    if (text != null) return {'text': text};
    if (media != null) return {'media': media!.toJson()};
    if (system != null) return {'system': system!.toJson()};
    return {};
  }
}

class MessageMedia {
  final String url;
  final String? thumbnailUrl;
  final String? filename;
  final int? size;
  final String? mimeType;
  final int? duration;
  final MessageDimensions? dimensions;

  const MessageMedia({
    required this.url,
    this.thumbnailUrl,
    this.filename,
    this.size,
    this.mimeType,
    this.duration,
    this.dimensions,
  });

  factory MessageMedia.fromJson(Map<String, dynamic> json) {
    return MessageMedia(
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      filename: json['filename'],
      size: json['size'],
      mimeType: json['mimeType'],
      duration: json['duration'],
      dimensions: json['dimensions'] != null 
          ? MessageDimensions.fromJson(json['dimensions']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'filename': filename,
      'size': size,
      'mimeType': mimeType,
      'duration': duration,
      'dimensions': dimensions?.toJson(),
    };
  }
}

class MessageDimensions {
  final int width;
  final int height;

  const MessageDimensions({
    required this.width,
    required this.height,
  });

  factory MessageDimensions.fromJson(Map<String, dynamic> json) {
    return MessageDimensions(
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
    };
  }
}

class MessageSystem {
  final String action;
  final Map<String, dynamic>? data;

  const MessageSystem({
    required this.action,
    this.data,
  });

  factory MessageSystem.fromJson(Map<String, dynamic> json) {
    return MessageSystem(
      action: json['action'] ?? '',
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'data': data,
    };
  }
}

class MessageReaction {
  final String emoji;
  final int count;
  final bool hasReacted;

  const MessageReaction({
    required this.emoji,
    required this.count,
    required this.hasReacted,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] ?? '',
      count: json['count'] ?? 0,
      hasReacted: json['hasReacted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'count': count,
      'hasReacted': hasReacted,
    };
  }
}

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  system;

  static MessageType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  @override
  String toString() {
    return name;
  }
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  static MessageStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  @override
  String toString() {
    return name;
  }
}
