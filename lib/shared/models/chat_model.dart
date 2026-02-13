import 'package:cloud_firestore/cloud_firestore.dart';
import 'common_models.dart';
import 'user_model.dart';

// ============================================
// CHAT MODEL
// Firestore: /chats/{chatId}
//
// Supports: DM, group chat, business chat,
// order chat, and AI assistant chat.
// ============================================

class Chat {
  final String id;
  final ChatType type;

  // Participants
  final List<String> participantIds; // UIDs for Firestore queries
  final Map<String, ChatParticipant> participants; // keyed by UID

  // Group info (only for group chats)
  final String? groupName;
  final String? groupAvatarUrl;
  final String? groupDescription;

  // Last message preview (denormalized for chat list)
  final MessagePreview? lastMessage;

  // Linked context
  final String? orderId; // if this chat is about an order
  final String? postId; // if this chat started from a post
  final String? businessId; // if this is a business inquiry

  // Settings
  final bool isMuted;
  final bool isPinned;
  final bool isArchived;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const Chat({
    required this.id,
    this.type = ChatType.dm,
    required this.participantIds,
    required this.participants,
    this.groupName,
    this.groupAvatarUrl,
    this.groupDescription,
    this.lastMessage,
    this.orderId,
    this.postId,
    this.businessId,
    this.isMuted = false,
    this.isPinned = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chat.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chat.fromMap(data, doc.id);
  }

  factory Chat.fromMap(Map<String, dynamic> map, [String? docId]) {
    final participantsRaw = map['participants'] as Map?;
    final participantsMap = <String, ChatParticipant>{};
    if (participantsRaw != null) {
      participantsRaw.forEach((key, value) {
        participantsMap[key.toString()] =
            ChatParticipant.fromMap(Map<String, dynamic>.from(value as Map));
      });
    }

    return Chat(
      id: docId ?? map['id'] as String,
      type: ChatType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'dm'),
        orElse: () => ChatType.dm,
      ),
      participantIds: toStringList(map['participantIds']),
      participants: participantsMap,
      groupName: map['groupName'] as String?,
      groupAvatarUrl: map['groupAvatarUrl'] as String?,
      groupDescription: map['groupDescription'] as String?,
      lastMessage: map['lastMessage'] != null
          ? MessagePreview.fromMap(
              Map<String, dynamic>.from(map['lastMessage'] as Map))
          : null,
      orderId: map['orderId'] as String?,
      postId: map['postId'] as String?,
      businessId: map['businessId'] as String?,
      isMuted: map['isMuted'] as bool? ?? false,
      isPinned: map['isPinned'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
      createdAt: timestampToDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: timestampToDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'participantIds': participantIds,
        'participants':
            participants.map((k, v) => MapEntry(k, v.toMap())),
        if (groupName != null) 'groupName': groupName,
        if (groupAvatarUrl != null) 'groupAvatarUrl': groupAvatarUrl,
        if (groupDescription != null) 'groupDescription': groupDescription,
        if (lastMessage != null) 'lastMessage': lastMessage!.toMap(),
        if (orderId != null) 'orderId': orderId,
        if (postId != null) 'postId': postId,
        if (businessId != null) 'businessId': businessId,
        'isMuted': isMuted,
        'isPinned': isPinned,
        'isArchived': isArchived,
        'createdAt': dateTimeToTimestamp(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// Get the other participant in a DM
  ChatParticipant? otherParticipant(String myUid) {
    if (type != ChatType.dm) return null;
    final otherEntry = participants.entries
        .where((e) => e.key != myUid)
        .firstOrNull;
    return otherEntry?.value;
  }

  /// Display name for chat list
  String displayName(String myUid) {
    if (type == ChatType.group) return groupName ?? 'Group Chat';
    if (type == ChatType.ai) return 'Driba AI';
    final other = otherParticipant(myUid);
    return other?.displayName ?? 'Chat';
  }

  /// Avatar URL for chat list
  String? displayAvatar(String myUid) {
    if (type == ChatType.group) return groupAvatarUrl;
    return otherParticipant(myUid)?.avatarUrl;
  }

  /// Unread count for a specific user
  int unreadCount(String uid) => participants[uid]?.unreadCount ?? 0;
}

enum ChatType { dm, group, business, order, ai }

// ============================================
// CHAT PARTICIPANT
// Embedded in chat document
// ============================================

class ChatParticipant {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final bool isVerified;
  final String role; // member, admin, owner
  final int unreadCount;
  final DateTime? lastReadAt;
  final bool isTyping;
  final bool isOnline;

  const ChatParticipant({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.isVerified = false,
    this.role = 'member',
    this.unreadCount = 0,
    this.lastReadAt,
    this.isTyping = false,
    this.isOnline = false,
  });

  factory ChatParticipant.fromMap(Map<String, dynamic> map) => ChatParticipant(
        userId: map['userId'] as String,
        displayName: map['displayName'] as String? ?? '',
        avatarUrl: map['avatarUrl'] as String?,
        isVerified: map['isVerified'] as bool? ?? false,
        role: map['role'] as String? ?? 'member',
        unreadCount: map['unreadCount'] as int? ?? 0,
        lastReadAt: timestampToDateTime(map['lastReadAt']),
        isTyping: map['isTyping'] as bool? ?? false,
        isOnline: map['isOnline'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'isVerified': isVerified,
        'role': role,
        'unreadCount': unreadCount,
        if (lastReadAt != null) 'lastReadAt': dateTimeToTimestamp(lastReadAt),
        'isTyping': isTyping,
        'isOnline': isOnline,
      };

  factory ChatParticipant.fromUserRef(UserRef ref) => ChatParticipant(
        userId: ref.id,
        displayName: ref.displayName,
        avatarUrl: ref.avatarUrl,
        isVerified: ref.isVerified,
      );
}

// ============================================
// MESSAGE PREVIEW
// Denormalized on chat doc for the chat list UI
// ============================================

class MessagePreview {
  final String senderId;
  final String senderName;
  final String text; // truncated preview
  final String type; // text, image, video, voice, payment, system
  final DateTime sentAt;

  const MessagePreview({
    required this.senderId,
    required this.senderName,
    required this.text,
    this.type = 'text',
    required this.sentAt,
  });

  factory MessagePreview.fromMap(Map<String, dynamic> map) => MessagePreview(
        senderId: map['senderId'] as String,
        senderName: map['senderName'] as String? ?? '',
        text: map['text'] as String? ?? '',
        type: map['type'] as String? ?? 'text',
        sentAt: timestampToDateTime(map['sentAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'type': type,
        'sentAt': dateTimeToTimestamp(sentAt),
      };
}

// ============================================
// MESSAGE
// Firestore: /chats/{chatId}/messages/{messageId}
// ============================================

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;

  // Content
  final MessageType type;
  final String? text;
  final List<MediaItem> media;

  // Voice message
  final int? voiceDurationMs;
  final String? voiceWaveform; // base64 encoded waveform data

  // Reply
  final String? replyToId;
  final MessagePreview? replyTo; // denormalized preview of replied message

  // Payment message
  final PaymentMessage? payment;

  // Location share
  final GeoPoint2? sharedLocation;
  final String? locationName;

  // Post/product share
  final String? sharedPostId;

  // Reactions
  final Map<String, String> reactions; // userId -> emoji

  // Status
  final MessageStatus status;
  final bool isEdited;
  final bool isDeleted;
  final DateTime? editedAt;

  // AI
  final bool isAiGenerated; // smart reply
  final List<String>? aiSuggestions; // suggested quick replies

  // Timestamps
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.type = MessageType.text,
    this.text,
    this.media = const [],
    this.voiceDurationMs,
    this.voiceWaveform,
    this.replyToId,
    this.replyTo,
    this.payment,
    this.sharedLocation,
    this.locationName,
    this.sharedPostId,
    this.reactions = const {},
    this.status = MessageStatus.sent,
    this.isEdited = false,
    this.isDeleted = false,
    this.editedAt,
    this.isAiGenerated = false,
    this.aiSuggestions,
    required this.createdAt,
  });

  factory Message.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message.fromMap(data, doc.id);
  }

  factory Message.fromMap(Map<String, dynamic> map, [String? docId]) {
    final reactionsRaw = map['reactions'] as Map?;
    final reactionsMap = <String, String>{};
    if (reactionsRaw != null) {
      reactionsRaw.forEach((k, v) {
        reactionsMap[k.toString()] = v.toString();
      });
    }

    return Message(
      id: docId ?? map['id'] as String,
      chatId: map['chatId'] as String,
      senderId: map['senderId'] as String,
      senderName: map['senderName'] as String? ?? '',
      senderAvatar: map['senderAvatar'] as String?,
      type: MessageType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'text'),
        orElse: () => MessageType.text,
      ),
      text: map['text'] as String?,
      media: toModelList(map['media'], MediaItem.fromMap),
      voiceDurationMs: map['voiceDurationMs'] as int?,
      voiceWaveform: map['voiceWaveform'] as String?,
      replyToId: map['replyToId'] as String?,
      replyTo: map['replyTo'] != null
          ? MessagePreview.fromMap(
              Map<String, dynamic>.from(map['replyTo'] as Map))
          : null,
      payment: map['payment'] != null
          ? PaymentMessage.fromMap(
              Map<String, dynamic>.from(map['payment'] as Map))
          : null,
      sharedLocation: map['sharedLocation'] != null
          ? GeoPoint2.fromMap(
              Map<String, dynamic>.from(map['sharedLocation'] as Map))
          : null,
      locationName: map['locationName'] as String?,
      sharedPostId: map['sharedPostId'] as String?,
      reactions: reactionsMap,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      isEdited: map['isEdited'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
      editedAt: timestampToDateTime(map['editedAt']),
      isAiGenerated: map['isAiGenerated'] as bool? ?? false,
      aiSuggestions: map['aiSuggestions'] != null
          ? toStringList(map['aiSuggestions'])
          : null,
      createdAt: timestampToDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        if (senderAvatar != null) 'senderAvatar': senderAvatar,
        'type': type.name,
        if (text != null) 'text': text,
        'media': media.map((e) => e.toMap()).toList(),
        if (voiceDurationMs != null) 'voiceDurationMs': voiceDurationMs,
        if (voiceWaveform != null) 'voiceWaveform': voiceWaveform,
        if (replyToId != null) 'replyToId': replyToId,
        if (replyTo != null) 'replyTo': replyTo!.toMap(),
        if (payment != null) 'payment': payment!.toMap(),
        if (sharedLocation != null) 'sharedLocation': sharedLocation!.toMap(),
        if (locationName != null) 'locationName': locationName,
        if (sharedPostId != null) 'sharedPostId': sharedPostId,
        'reactions': reactions,
        'status': status.name,
        'isEdited': isEdited,
        'isDeleted': isDeleted,
        if (editedAt != null) 'editedAt': dateTimeToTimestamp(editedAt),
        'isAiGenerated': isAiGenerated,
        if (aiSuggestions != null) 'aiSuggestions': aiSuggestions,
        'createdAt': FieldValue.serverTimestamp(),
      };

  bool get isMine => false; // set in UI based on current user
  bool get hasMedia => media.isNotEmpty;
}

enum MessageType { text, image, video, voice, payment, location, post, system }

enum MessageStatus { sending, sent, delivered, read, failed }

// ============================================
// PAYMENT MESSAGE - In-chat payments
// ============================================

class PaymentMessage {
  final double amount;
  final String currency;
  final String? note;
  final PaymentStatus status;
  final String? transactionId;

  const PaymentMessage({
    required this.amount,
    this.currency = 'USD',
    this.note,
    this.status = PaymentStatus.pending,
    this.transactionId,
  });

  factory PaymentMessage.fromMap(Map<String, dynamic> map) => PaymentMessage(
        amount: (map['amount'] as num).toDouble(),
        currency: map['currency'] as String? ?? 'USD',
        note: map['note'] as String?,
        status: PaymentStatus.values.firstWhere(
          (e) => e.name == (map['status'] as String? ?? 'pending'),
          orElse: () => PaymentStatus.pending,
        ),
        transactionId: map['transactionId'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'currency': currency,
        if (note != null) 'note': note,
        'status': status.name,
        if (transactionId != null) 'transactionId': transactionId,
      };
}
