import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import 'chat_demo_data.dart';

/// Full conversation screen with message bubbles,
/// typing indicator, smart replies, reactions, input bar
class ConversationScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;
  final String chatAvatar;
  final bool isOnline;
  final bool isGroup;

  const ConversationScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.chatAvatar,
    this.isOnline = false,
    this.isGroup = false,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  late List<DemoMessage> _messages;
  DemoMessage? _replyingTo;
  bool _showSmartReplies = true;
  bool _showAttachMenu = false;

  static const Color _accent = Color(0xFF00D68F);
  static const String _myId = 'current_user';

  final _reactions = ['❤️', '😂', '😮', '👍', '🔥', '😢'];

  @override
  void initState() {
    super.initState();
    _messages = ChatDemoData.messagesForChat(widget.chatId);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      _messages.insert(
        0,
        DemoMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          senderId: _myId,
          senderName: 'You',
          text: text,
          timestamp: DateTime.now(),
          replyTo: _replyingTo,
          status: 'sent',
        ),
      );
      _replyingTo = null;
      _showSmartReplies = false;
    });
    _textController.clear();

    // Simulate reply after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _messages.insert(
          0,
          DemoMessage(
            id: 'msg_reply_${DateTime.now().millisecondsSinceEpoch}',
            senderId: widget.chatId,
            senderName: widget.chatName,
            senderAvatar: widget.chatAvatar,
            text: _getAutoReply(text),
            timestamp: DateTime.now(),
            status: 'delivered',
          ),
        );
        _showSmartReplies = true;
      });
    });
  }

  String _getAutoReply(String input) {
    final replies = [
      'That sounds great! Tell me more.',
      'I was just thinking about that!',
      'Absolutely, let\'s do it 🙌',
      'Hmm, interesting perspective.',
      'Love that idea! When can we start?',
      'Sure thing, I\'ll send you the details.',
      'Ha, you always know what to say 😄',
    ];
    return replies[math.Random().nextInt(replies.length)];
  }

  void _showReactionPicker(DemoMessage message) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReactionPicker(
        reactions: _reactions,
        accent: _accent,
        onSelect: (emoji) {
          Navigator.pop(context);
          HapticFeedback.selectionClick();
          setState(() {
            message.reactions[_myId] = emoji;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DribaColors.background,
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Messages
          Expanded(
            child: GestureDetector(
              onTap: () => _inputFocus.unfocus(),
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: DribaSpacing.lg,
                  vertical: DribaSpacing.md,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg.senderId == _myId;
                  final prevMsg =
                      index < _messages.length - 1 ? _messages[index + 1] : null;
                  final showAvatar = !isMe &&
                      (prevMsg == null || prevMsg.senderId != msg.senderId);

                  return _MessageBubble(
                    message: msg,
                    isMe: isMe,
                    showAvatar: showAvatar,
                    accent: _accent,
                    onReply: () {
                      HapticFeedback.selectionClick();
                      setState(() => _replyingTo = msg);
                      _inputFocus.requestFocus();
                    },
                    onLongPress: () => _showReactionPicker(msg),
                  );
                },
              ),
            ),
          ),

          // Smart replies
          if (_showSmartReplies && _messages.isNotEmpty) _buildSmartReplies(),

          // Reply preview
          if (_replyingTo != null) _buildReplyPreview(),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────
  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            DribaSpacing.md,
            MediaQuery.of(context).padding.top + DribaSpacing.sm,
            DribaSpacing.lg,
            DribaSpacing.md,
          ),
          decoration: BoxDecoration(
            color: DribaColors.glassFill,
            border: Border(
              bottom: BorderSide(color: DribaColors.glassBorder),
            ),
          ),
          child: Row(
            children: [
              // Back
              GlassCircleButton(
                size: 38,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: const Icon(Icons.arrow_back_ios_new,
                    color: DribaColors.textPrimary, size: 18),
              ),
              const SizedBox(width: DribaSpacing.md),

              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(widget.chatAvatar),
                  ),
                  if (widget.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: DribaColors.background, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: DribaSpacing.md),

              // Name + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chatName,
                      style: const TextStyle(
                        color: DribaColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.isOnline ? 'Online' : 'Last seen recently',
                      style: TextStyle(
                        color: widget.isOnline
                            ? _accent
                            : DribaColors.textTertiary,
                        fontSize: 12,
                        fontWeight:
                            widget.isOnline ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              GlassCircleButton(
                size: 38,
                onTap: () => HapticFeedback.lightImpact(),
                child: const Icon(Icons.videocam_outlined,
                    color: DribaColors.textSecondary, size: 20),
              ),
              const SizedBox(width: DribaSpacing.sm),
              GlassCircleButton(
                size: 38,
                onTap: () => HapticFeedback.lightImpact(),
                child: const Icon(Icons.more_vert,
                    color: DribaColors.textSecondary, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Smart Replies ───────────────────────────
  Widget _buildSmartReplies() {
    final replies = ['Sounds great! 🙌', 'When works for you?', 'Tell me more', 'On my way!'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: DribaSpacing.sm),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.lg),
          itemCount: replies.length,
          separatorBuilder: (_, __) => const SizedBox(width: DribaSpacing.sm),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                _textController.text = replies[index];
                _sendMessage();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: DribaSpacing.md, vertical: DribaSpacing.sm),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                  border: Border.all(color: _accent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index == 0)
                      Padding(
                        padding: const EdgeInsets.only(right: DribaSpacing.xs),
                        child: Icon(Icons.auto_awesome,
                            color: _accent, size: 14),
                      ),
                    Text(
                      replies[index],
                      style: TextStyle(
                        color: _accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Reply Preview ───────────────────────────
  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          DribaSpacing.lg, DribaSpacing.sm, DribaSpacing.lg, 0),
      child: Container(
        padding: const EdgeInsets.all(DribaSpacing.md),
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.08),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DribaBorderRadius.lg),
          ),
          border: Border(
            left: BorderSide(color: _accent, width: 3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _replyingTo!.senderName,
                    style: TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _replyingTo!.text,
                    style: TextStyle(
                      color: DribaColors.textTertiary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _replyingTo = null),
              child:
                  Icon(Icons.close, color: DribaColors.textTertiary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ── Input Bar ───────────────────────────────
  Widget _buildInputBar() {
    final hasText = _textController.text.isNotEmpty;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            DribaSpacing.md,
            DribaSpacing.md,
            DribaSpacing.md,
            MediaQuery.of(context).padding.bottom + DribaSpacing.md,
          ),
          decoration: BoxDecoration(
            color: DribaColors.glassFill,
            border: Border(
              top: BorderSide(color: DribaColors.glassBorder),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attach
              GlassCircleButton(
                size: 42,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _showAttachMenu = !_showAttachMenu);
                },
                child: Icon(
                  _showAttachMenu ? Icons.close : Icons.add,
                  color: DribaColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: DribaSpacing.sm),

              // Text field
              Expanded(
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                  padding: const EdgeInsets.symmetric(
                    horizontal: DribaSpacing.lg,
                    vertical: DribaSpacing.xs,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _inputFocus,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            color: DribaColors.textPrimary,
                            fontSize: 15,
                          ),
                          maxLines: 5,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Message...',
                            hintStyle:
                                TextStyle(color: DribaColors.textTertiary),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: DribaSpacing.sm),
                            isDense: true,
                          ),
                        ),
                      ),
                      if (!hasText)
                        GestureDetector(
                          onTap: () => HapticFeedback.lightImpact(),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: DribaSpacing.sm,
                                bottom: DribaSpacing.sm),
                            child: Icon(Icons.camera_alt_outlined,
                                color: DribaColors.textTertiary, size: 22),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: DribaSpacing.sm),

              // Send / Voice
              GlassCircleButton(
                size: 42,
                isSelected: hasText,
                selectedColor: _accent,
                onTap: hasText
                    ? _sendMessage
                    : () => HapticFeedback.lightImpact(),
                child: Icon(
                  hasText ? Icons.send_rounded : Icons.mic_outlined,
                  color: hasText ? _accent : DribaColors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// MESSAGE BUBBLE
// ============================================

class _MessageBubble extends StatelessWidget {
  final DemoMessage message;
  final bool isMe;
  final bool showAvatar;
  final Color accent;
  final VoidCallback? onReply;
  final VoidCallback? onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.showAvatar = false,
    required this.accent,
    this.onReply,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return _buildSystemMessage();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: DribaSpacing.xs),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar
          if (!isMe)
            SizedBox(
              width: 32,
              child: showAvatar && message.senderAvatar != null
                  ? CircleAvatar(
                      radius: 14,
                      backgroundImage: NetworkImage(message.senderAvatar!),
                    )
                  : null,
            ),
          if (!isMe) const SizedBox(width: DribaSpacing.xs),

          // Bubble
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity!.abs() > 200) {
                  onReply?.call();
                }
              },
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Reply preview
                  if (message.replyTo != null) _buildReplyPreview(context),

                  // Bubble
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DribaSpacing.lg,
                      vertical: DribaSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? accent.withOpacity(0.15)
                          : DribaColors.glassFill,
                      borderRadius: BorderRadius.only(
                        topLeft:
                            const Radius.circular(DribaBorderRadius.lg),
                        topRight:
                            const Radius.circular(DribaBorderRadius.lg),
                        bottomLeft: Radius.circular(
                            isMe ? DribaBorderRadius.lg : DribaBorderRadius.xs),
                        bottomRight: Radius.circular(
                            isMe ? DribaBorderRadius.xs : DribaBorderRadius.lg),
                      ),
                      border: Border.all(
                        color: isMe
                            ? accent.withOpacity(0.25)
                            : DribaColors.glassBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: const TextStyle(
                            color: DribaColors.textPrimary,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                color: DribaColors.textDisabled,
                                fontSize: 11,
                              ),
                            ),
                            if (message.isEdited) ...[
                              const SizedBox(width: 4),
                              Text(
                                'edited',
                                style: TextStyle(
                                  color: DribaColors.textDisabled,
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              _StatusIcon(status: message.status),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Reactions
                  if (message.reactions.isNotEmpty)
                    _buildReactions(context),
                ],
              ),
            ),
          ),

          if (isMe) const SizedBox(width: DribaSpacing.xs),
          if (isMe) const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(DribaSpacing.sm),
      decoration: BoxDecoration(
        color: DribaColors.glassFill,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DribaBorderRadius.md),
        ),
        border: Border(left: BorderSide(color: accent, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyTo!.senderName,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            message.replyTo!.text,
            style: TextStyle(
              color: DribaColors.textTertiary,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReactions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: DribaColors.glassFillActive,
          borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
          border: Border.all(color: DribaColors.glassBorder),
        ),
        child: Text(
          message.reactions.values.join(' '),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DribaSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: DribaSpacing.lg, vertical: DribaSpacing.xs),
          decoration: BoxDecoration(
            color: DribaColors.glassFill,
            borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: DribaColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// ── Status Icon ───────────────────────────────
class _StatusIcon extends StatelessWidget {
  final String status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'sending':
        return Icon(Icons.access_time, size: 13, color: DribaColors.textDisabled);
      case 'sent':
        return Icon(Icons.check, size: 13, color: DribaColors.textDisabled);
      case 'delivered':
        return Icon(Icons.done_all, size: 13, color: DribaColors.textDisabled);
      case 'read':
        return const Icon(Icons.done_all, size: 13, color: Color(0xFF00D68F));
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Reaction Picker ───────────────────────────
class _ReactionPicker extends StatelessWidget {
  final List<String> reactions;
  final Color accent;
  final void Function(String) onSelect;

  const _ReactionPicker({
    required this.reactions,
    required this.accent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(DribaSpacing.lg),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(
          horizontal: DribaSpacing.xl,
          vertical: DribaSpacing.lg,
        ),
        borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: reactions.map((emoji) {
            return GestureDetector(
              onTap: () => onSelect(emoji),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
