import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/models.dart';
import '../../shared/ai/ai.dart';
import 'chat_service.dart';

// ============================================
// CHAT PROVIDERS
//
// Riverpod providers that expose chat features
// to the UI. Real-time streams, typing state,
// smart replies, and message actions.
// ============================================

// ── Service ─────────────────────────────────

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

// ── Current User (placeholder until auth) ───

final currentChatUserIdProvider = Provider<String>((ref) {
  // TODO: Replace with actual auth state
  return 'current_user';
});

// ── Chat List (Inbox) ───────────────────────

final chatsStreamProvider = StreamProvider<List<Chat>>((ref) {
  final service = ref.watch(chatServiceProvider);
  final userId = ref.watch(currentChatUserIdProvider);
  return service.chatsStream(userId);
});

final totalUnreadStreamProvider = StreamProvider<int>((ref) {
  final service = ref.watch(chatServiceProvider);
  final userId = ref.watch(currentChatUserIdProvider);
  return service.totalUnreadStream(userId);
});

// ── Messages (per chat) ─────────────────────

final messagesStreamProvider =
    StreamProvider.family<List<Message>, String>((ref, chatId) {
  final service = ref.watch(chatServiceProvider);
  return service.messagesStream(chatId);
});

// ── Typing Indicators ───────────────────────

final typingStreamProvider =
    StreamProvider.family<Map<String, bool>, String>((ref, chatId) {
  final service = ref.watch(chatServiceProvider);
  return service.typingStream(chatId);
});

// ── Smart Replies ───────────────────────────

final chatSmartRepliesProvider =
    FutureProvider.family<List<String>, List<Message>>((ref, messages) async {
  if (messages.isEmpty) return [];

  final tasks = ref.watch(aiTasksProvider);

  // Convert recent messages to the format expected by AI
  final recentMessages = messages
      .take(6)
      .toList()
      .reversed
      .map((m) => {
            'sender': m.senderName,
            'text': m.text ?? '',
          })
      .toList();

  try {
    return await tasks.suggestSmartReplies(recentMessages: recentMessages);
  } catch (_) {
    return [];
  }
});

// ── Active Conversation State ───────────────

class ConversationState {
  final String chatId;
  final bool isTyping;
  final Message? replyingTo;
  final bool showSmartReplies;
  final bool showAttachmentMenu;

  const ConversationState({
    required this.chatId,
    this.isTyping = false,
    this.replyingTo,
    this.showSmartReplies = true,
    this.showAttachmentMenu = false,
  });

  ConversationState copyWith({
    String? chatId,
    bool? isTyping,
    Message? replyingTo,
    bool clearReply = false,
    bool? showSmartReplies,
    bool? showAttachmentMenu,
  }) {
    return ConversationState(
      chatId: chatId ?? this.chatId,
      isTyping: isTyping ?? this.isTyping,
      replyingTo: clearReply ? null : (replyingTo ?? this.replyingTo),
      showSmartReplies: showSmartReplies ?? this.showSmartReplies,
      showAttachmentMenu: showAttachmentMenu ?? this.showAttachmentMenu,
    );
  }
}

class ConversationNotifier extends StateNotifier<ConversationState> {
  final ChatService _service;
  final String _userId;
  Timer? _typingTimer;

  ConversationNotifier(this._service, this._userId, String chatId)
      : super(ConversationState(chatId: chatId));

  /// Send a text message
  Future<void> sendText(String text, {String senderName = 'You'}) async {
    if (text.trim().isEmpty) return;

    await _service.sendMessage(
      chatId: state.chatId,
      senderId: _userId,
      senderName: senderName,
      text: text.trim(),
      replyToId: state.replyingTo?.id,
      replyTo: state.replyingTo != null
          ? MessagePreview(
              senderId: state.replyingTo!.senderId,
              senderName: state.replyingTo!.senderName,
              text: state.replyingTo!.text ?? '',
              sentAt: state.replyingTo!.createdAt,
            )
          : null,
    );

    // Clear reply state
    state = state.copyWith(clearReply: true);
    _stopTyping();
  }

  /// Send an image message
  Future<void> sendImage(String imageUrl, {String senderName = 'You'}) async {
    await _service.sendMessage(
      chatId: state.chatId,
      senderId: _userId,
      senderName: senderName,
      type: MessageType.image,
      media: [MediaItem(url: imageUrl, type: 'image')],
    );
  }

  /// Send a voice message
  Future<void> sendVoice(
    String audioUrl,
    int durationMs, {
    String? waveform,
    String senderName = 'You',
  }) async {
    await _service.sendMessage(
      chatId: state.chatId,
      senderId: _userId,
      senderName: senderName,
      type: MessageType.voice,
      voiceDurationMs: durationMs,
      voiceWaveform: waveform,
      text: audioUrl,
    );
  }

  /// Set reply-to message
  void setReplyTo(Message message) {
    state = state.copyWith(replyingTo: message);
  }

  /// Clear reply-to
  void clearReplyTo() {
    state = state.copyWith(clearReply: true);
  }

  /// Handle typing (with auto-stop timer)
  void onTypingChanged(String text) {
    if (text.isNotEmpty && !state.isTyping) {
      state = state.copyWith(isTyping: true);
      _service.setTyping(state.chatId, _userId, true);
    }

    // Reset the auto-stop timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), _stopTyping);

    if (text.isEmpty) {
      _stopTyping();
    }
  }

  void _stopTyping() {
    if (state.isTyping) {
      state = state.copyWith(isTyping: false);
      _service.setTyping(state.chatId, _userId, false);
    }
    _typingTimer?.cancel();
  }

  /// Toggle attachment menu
  void toggleAttachmentMenu() {
    state = state.copyWith(showAttachmentMenu: !state.showAttachmentMenu);
  }

  /// React to a message
  Future<void> toggleReaction(String messageId, String emoji) async {
    await _service.toggleReaction(
      chatId: state.chatId,
      messageId: messageId,
      userId: _userId,
      emoji: emoji,
    );
  }

  /// Mark chat as read
  Future<void> markAsRead() async {
    await _service.markAsRead(state.chatId, _userId);
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    await _service.deleteMessage(state.chatId, messageId);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _stopTyping();
    super.dispose();
  }
}

/// Provider factory for conversation state (per chat)
final conversationProvider = StateNotifierProvider.family<
    ConversationNotifier, ConversationState, String>((ref, chatId) {
  final service = ref.watch(chatServiceProvider);
  final userId = ref.watch(currentChatUserIdProvider);
  return ConversationNotifier(service, userId, chatId);
});
