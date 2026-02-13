import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/models.dart';

// ============================================
// CHAT SERVICE
//
// Firestore backend for all chat operations.
// Real-time streams, message sending, typing
// indicators, read receipts, reactions.
//
// Collection structure:
// /chats/{chatId}                → Chat document
// /chats/{chatId}/messages/{id}  → Message subcollection
// ============================================

class ChatService {
  final FirebaseFirestore _db;

  ChatService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ── Collections ─────────────────────────────

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
      _chats.doc(chatId).collection('messages');

  // ============================================
  // CHAT LIST (Inbox)
  // ============================================

  /// Stream all chats for a user, ordered by last activity
  Stream<List<Chat>> chatsStream(String userId) {
    return _chats
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Chat.fromMap(doc.data(), doc.id))
            .where((chat) => !chat.isArchived)
            .toList());
  }

  /// Get a single chat document
  Future<Chat?> getChat(String chatId) async {
    final doc = await _chats.doc(chatId).get();
    if (!doc.exists) return null;
    return Chat.fromMap(doc.data()!, doc.id);
  }

  /// Find or create a DM chat between two users
  Future<Chat> getOrCreateDm(UserRef me, UserRef other) async {
    // Check if DM already exists
    final existing = await _chats
        .where('type', isEqualTo: 'dm')
        .where('participantIds', arrayContains: me.id)
        .get();

    for (final doc in existing.docs) {
      final ids = List<String>.from(doc.data()['participantIds'] ?? []);
      if (ids.contains(other.id)) {
        return Chat.fromMap(doc.data(), doc.id);
      }
    }

    // Create new DM
    final chatRef = _chats.doc();
    final now = DateTime.now();

    final chat = Chat(
      id: chatRef.id,
      type: ChatType.dm,
      participantIds: [me.id, other.id],
      participants: {
        me.id: ChatParticipant.fromUserRef(me),
        other.id: ChatParticipant.fromUserRef(other),
      },
      createdAt: now,
      updatedAt: now,
    );

    await chatRef.set(chat.toMap());
    return chat;
  }

  /// Create a group chat
  Future<Chat> createGroupChat({
    required String name,
    required UserRef creator,
    required List<UserRef> members,
    String? avatarUrl,
  }) async {
    final chatRef = _chats.doc();
    final now = DateTime.now();
    final allMembers = [creator, ...members];

    final participants = <String, ChatParticipant>{};
    for (final member in allMembers) {
      participants[member.id] = ChatParticipant(
        userId: member.id,
        displayName: member.displayName,
        avatarUrl: member.avatarUrl,
        isVerified: member.isVerified,
        role: member.id == creator.id ? 'admin' : 'member',
      );
    }

    final chat = Chat(
      id: chatRef.id,
      type: ChatType.group,
      participantIds: allMembers.map((m) => m.id).toList(),
      participants: participants,
      groupName: name,
      groupAvatarUrl: avatarUrl,
      createdAt: now,
      updatedAt: now,
    );

    await chatRef.set(chat.toMap());

    // Send system message
    await sendMessage(
      chatId: chatRef.id,
      senderId: creator.id,
      senderName: creator.displayName,
      type: MessageType.system,
      text: '${creator.displayName} created the group "$name"',
    );

    return chat;
  }

  // ============================================
  // MESSAGES
  // ============================================

  /// Stream messages for a chat (real-time)
  Stream<List<Message>> messagesStream(String chatId, {int limit = 50}) {
    return _messages(chatId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Message.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Load older messages (pagination)
  Future<List<Message>> loadOlderMessages(
    String chatId, {
    required DateTime before,
    int limit = 30,
  }) async {
    final snap = await _messages(chatId)
        .orderBy('createdAt', descending: true)
        .where('createdAt', isLessThan: Timestamp.fromDate(before))
        .limit(limit)
        .get();

    return snap.docs
        .map((doc) => Message.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Send a message
  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    MessageType type = MessageType.text,
    String? text,
    List<MediaItem>? media,
    String? replyToId,
    MessagePreview? replyTo,
    PaymentMessage? payment,
    GeoPoint2? sharedLocation,
    String? locationName,
    String? sharedPostId,
    int? voiceDurationMs,
    String? voiceWaveform,
  }) async {
    final msgRef = _messages(chatId).doc();
    final now = DateTime.now();

    final message = Message(
      id: msgRef.id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: type,
      text: text,
      media: media ?? [],
      replyToId: replyToId,
      replyTo: replyTo,
      payment: payment,
      sharedLocation: sharedLocation,
      locationName: locationName,
      sharedPostId: sharedPostId,
      voiceDurationMs: voiceDurationMs,
      voiceWaveform: voiceWaveform,
      status: MessageStatus.sent,
      createdAt: now,
    );

    // Write message
    await msgRef.set(message.toMap());

    // Update chat document with last message preview
    final previewText = _messagePreviewText(type, text);
    await _chats.doc(chatId).update({
      'lastMessage': MessagePreview(
        senderId: senderId,
        senderName: senderName,
        text: previewText,
        type: type.name,
        sentAt: now,
      ).toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Increment unread count for other participants
    final chatDoc = await _chats.doc(chatId).get();
    final participants = List<String>.from(
        chatDoc.data()?['participantIds'] ?? []);
    for (final uid in participants) {
      if (uid != senderId) {
        await _chats.doc(chatId).update({
          'participants.$uid.unreadCount': FieldValue.increment(1),
        });
      }
    }

    return message;
  }

  /// Generate preview text for different message types
  String _messagePreviewText(MessageType type, String? text) {
    switch (type) {
      case MessageType.text:
        return text ?? '';
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.voice:
        return '🎤 Voice message';
      case MessageType.payment:
        return '💰 Payment';
      case MessageType.location:
        return '📍 Location';
      case MessageType.post:
        return '📱 Shared a post';
      case MessageType.system:
        return text ?? '';
    }
  }

  // ============================================
  // REACTIONS
  // ============================================

  /// Add or toggle a reaction on a message
  Future<void> toggleReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final msgRef = _messages(chatId).doc(messageId);
    final doc = await msgRef.get();

    if (!doc.exists) return;
    final reactions = Map<String, String>.from(
        doc.data()?['reactions'] ?? {});

    if (reactions[userId] == emoji) {
      // Remove reaction
      reactions.remove(userId);
    } else {
      // Add/change reaction
      reactions[userId] = emoji;
    }

    await msgRef.update({'reactions': reactions});
  }

  // ============================================
  // READ RECEIPTS
  // ============================================

  /// Mark all messages as read for a user
  Future<void> markAsRead(String chatId, String userId) async {
    await _chats.doc(chatId).update({
      'participants.$userId.unreadCount': 0,
      'participants.$userId.lastReadAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update message status (delivered → read)
  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    MessageStatus status,
  ) async {
    await _messages(chatId).doc(messageId).update({
      'status': status.name,
    });
  }

  // ============================================
  // TYPING INDICATORS
  // ============================================

  /// Set typing status for a user in a chat
  Future<void> setTyping(String chatId, String userId, bool isTyping) async {
    await _chats.doc(chatId).update({
      'participants.$userId.isTyping': isTyping,
    });
  }

  /// Stream typing status for a chat
  Stream<Map<String, bool>> typingStream(String chatId) {
    return _chats.doc(chatId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return {};
      final participants = data['participants'] as Map?;
      if (participants == null) return {};

      final typing = <String, bool>{};
      participants.forEach((uid, value) {
        final p = value as Map;
        if (p['isTyping'] == true) {
          typing[uid.toString()] = true;
        }
      });
      return typing;
    });
  }

  // ============================================
  // CHAT MANAGEMENT
  // ============================================

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _messages(chatId).doc(messageId).update({
      'isDeleted': true,
      'text': 'This message was deleted',
    });
  }

  /// Edit a message
  Future<void> editMessage(
    String chatId,
    String messageId,
    String newText,
  ) async {
    await _messages(chatId).doc(messageId).update({
      'text': newText,
      'isEdited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mute/unmute a chat
  Future<void> toggleMute(String chatId, bool isMuted) async {
    await _chats.doc(chatId).update({'isMuted': isMuted});
  }

  /// Pin/unpin a chat
  Future<void> togglePin(String chatId, bool isPinned) async {
    await _chats.doc(chatId).update({'isPinned': isPinned});
  }

  /// Archive a chat
  Future<void> archiveChat(String chatId) async {
    await _chats.doc(chatId).update({'isArchived': true});
  }

  /// Delete a chat (for the current user)
  Future<void> deleteChat(String chatId, String userId) async {
    // Remove user from participants
    await _chats.doc(chatId).update({
      'participantIds': FieldValue.arrayRemove([userId]),
    });
  }

  // ============================================
  // ONLINE STATUS
  // ============================================

  /// Set online status
  Future<void> setOnlineStatus(String chatId, String userId, bool isOnline) async {
    await _chats.doc(chatId).update({
      'participants.$userId.isOnline': isOnline,
    });
  }

  // ============================================
  // UNREAD COUNT
  // ============================================

  /// Get total unread count across all chats
  Stream<int> totalUnreadStream(String userId) {
    return _chats
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snap) {
      int total = 0;
      for (final doc in snap.docs) {
        final chat = Chat.fromMap(doc.data(), doc.id);
        total += chat.unreadCount(userId);
      }
      return total;
    });
  }
}
