import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_header.dart';

/// Revolutionary Chat Screen
/// Features horizontal carousel avatars instead of vertical list
/// Chat exchanges slide left/right synced with avatar selection
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  late PageController _avatarController;
  late PageController _chatController;
  int _currentIndex = 0;
  bool _isSyncing = false;

  // Demo data - will be replaced with Firestore
  final List<ChatContact> _contacts = List.generate(
    10,
    (i) => ChatContact(
      id: 'user_$i',
      name: ['Alex', 'Sarah', 'Mike', 'Emma', 'James', 'Olivia', 'Daniel', 'Sophie', 'Chris', 'Amy'][i],
      avatar: 'https://i.pravatar.cc/150?img=${i + 1}',
      lastMessage: ['Hey! How are you?', 'The project looks great', 'Can we meet tomorrow?', 'Thanks for your help!', 'Check this out 🔥', 'Sounds good to me', 'Let me know when ready', 'Perfect!', 'On my way', 'See you soon!'][i],
      timestamp: DateTime.now().subtract(Duration(minutes: i * 30)),
      unreadCount: i < 3 ? (3 - i) : 0,
      isOnline: i % 3 == 0,
    ),
  );

  @override
  void initState() {
    super.initState();
    _avatarController = PageController(
      viewportFraction: 0.14,
      initialPage: 0,
    );
    _chatController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _avatarController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _onAvatarPageChanged(int index) {
    if (_isSyncing) return;
    setState(() {
      _currentIndex = index;
      _isSyncing = true;
    });
    _chatController.animateToPage(
      index,
      duration: DribaDurations.normal,
      curve: DribaCurves.defaultCurve,
    ).then((_) => _isSyncing = false);
  }

  void _onChatPageChanged(int index) {
    if (_isSyncing) return;
    setState(() {
      _currentIndex = index;
      _isSyncing = true;
    });
    _avatarController.animateToPage(
      index,
      duration: DribaDurations.normal,
      curve: DribaCurves.defaultCurve,
    ).then((_) => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DribaColors.background,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Header space
              SizedBox(height: MediaQuery.of(context).padding.top + 60),
              
              // Animated Avatar Carousel
              _buildAvatarCarousel(),
              
              const SizedBox(height: DribaSpacing.lg),
              
              // Chat content (slides horizontally)
              Expanded(
                child: _buildChatPageView(),
              ),
            ],
          ),
          
          // Glass Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassHeader(
              title: 'Messages',
              screenId: 'chat',
              onSearchTap: () {
                // Open search
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCarousel() {
    return SizedBox(
      height: 100,
      child: PageView.builder(
        controller: _avatarController,
        onPageChanged: _onAvatarPageChanged,
        itemCount: _contacts.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _avatarController,
            builder: (context, child) {
              double value = 0.0;
              if (_avatarController.position.haveDimensions) {
                value = index - (_avatarController.page ?? 0);
                value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
              } else if (index == _currentIndex) {
                value = 1.0;
              } else {
                value = 0.7;
              }
              
              return _AnimatedAvatar(
                contact: _contacts[index],
                scale: value,
                isSelected: index == _currentIndex,
                onTap: () {
                  _avatarController.animateToPage(
                    index,
                    duration: DribaDurations.normal,
                    curve: DribaCurves.defaultCurve,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatPageView() {
    return PageView.builder(
      controller: _chatController,
      onPageChanged: _onChatPageChanged,
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        return _ChatConversation(
          contact: _contacts[index],
          isActive: index == _currentIndex,
        );
      },
    );
  }
}

/// Animated avatar with scale, glow, and online indicator
class _AnimatedAvatar extends StatelessWidget {
  final ChatContact contact;
  final double scale;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedAvatar({
    required this.contact,
    required this.scale,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = 60.0 * scale;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: DribaDurations.fast,
            width: size + 8,
            height: size + 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? DribaColors.primary
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: DribaColors.primary.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Avatar
                Center(
                  child: AnimatedContainer(
                    duration: DribaDurations.fast,
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(contact.avatar),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                
                // Online indicator
                if (contact.isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: DribaColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: DribaColors.background,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                
                // Unread badge
                if (contact.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: DribaColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        contact.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 6),
          
          // Name
          AnimatedOpacity(
            duration: DribaDurations.fast,
            opacity: isSelected ? 1.0 : 0.6,
            child: Text(
              contact.name,
              style: TextStyle(
                fontSize: isSelected ? 13 : 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? DribaColors.textPrimary
                    : DribaColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual chat conversation view
class _ChatConversation extends StatefulWidget {
  final ChatContact contact;
  final bool isActive;

  const _ChatConversation({
    required this.contact,
    required this.isActive,
  });

  @override
  State<_ChatConversation> createState() => _ChatConversationState();
}

class _ChatConversationState extends State<_ChatConversation> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Generate demo messages
    _messages.addAll([
      ChatMessage(
        id: '1',
        content: 'Hey! How are you doing?',
        senderId: widget.contact.id,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatMessage(
        id: '2',
        content: 'I\'m great, thanks! Just finished working on the new project.',
        senderId: 'me',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
      ),
      ChatMessage(
        id: '3',
        content: widget.contact.lastMessage,
        senderId: widget.contact.id,
        timestamp: widget.contact.timestamp,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Messages list
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.symmetric(
              horizontal: DribaSpacing.lg,
              vertical: DribaSpacing.md,
            ),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[_messages.length - 1 - index];
              final isMe = message.senderId == 'me';
              
              return _MessageBubble(
                message: message,
                isMe: isMe,
                showAvatar: !isMe,
                avatarUrl: widget.contact.avatar,
              );
            },
          ),
        ),
        
        // Message input
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageInput() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DribaBlur.medium, sigmaY: DribaBlur.medium),
        child: Container(
          padding: EdgeInsets.only(
            left: DribaSpacing.lg,
            right: DribaSpacing.lg,
            top: DribaSpacing.md,
            bottom: MediaQuery.of(context).padding.bottom + 100, // Space for dock
          ),
          decoration: BoxDecoration(
            color: DribaColors.glassFill,
            border: Border(
              top: BorderSide(color: DribaColors.glassBorder),
            ),
          ),
          child: Row(
            children: [
              // Attachment button
              GlassCircleButton(
                size: 44,
                child: const Icon(
                  Icons.add,
                  color: DribaColors.textSecondary,
                  size: 22,
                ),
                onTap: () {},
              ),
              
              const SizedBox(width: DribaSpacing.sm),
              
              // Text input
              Expanded(
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                  padding: const EdgeInsets.symmetric(
                    horizontal: DribaSpacing.lg,
                    vertical: DribaSpacing.xs,
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: DribaColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      hintStyle: TextStyle(color: DribaColors.textTertiary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: DribaSpacing.sm),
              
              // Send button
              GlassCircleButton(
                size: 44,
                selectedColor: DribaColors.primary,
                isSelected: true,
                child: const Icon(
                  Icons.send_rounded,
                  color: DribaColors.primary,
                  size: 20,
                ),
                onTap: () {
                  // Send message
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Message bubble with glass effect
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showAvatar;
  final String? avatarUrl;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.showAvatar = false,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DribaSpacing.sm),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAvatar && avatarUrl != null) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(avatarUrl!),
            ),
            const SizedBox(width: DribaSpacing.sm),
          ],
          
          Flexible(
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(
                horizontal: DribaSpacing.lg,
                vertical: DribaSpacing.md,
              ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(DribaBorderRadius.lg),
                topRight: const Radius.circular(DribaBorderRadius.lg),
                bottomLeft: Radius.circular(isMe ? DribaBorderRadius.lg : DribaBorderRadius.xs),
                bottomRight: Radius.circular(isMe ? DribaBorderRadius.xs : DribaBorderRadius.lg),
              ),
              fillColor: isMe
                  ? DribaColors.primary.withOpacity(0.15)
                  : DribaColors.glassFill,
              borderColor: isMe
                  ? DribaColors.primary.withOpacity(0.3)
                  : DribaColors.glassBorder,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: DribaColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: DribaColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// Data models
class ChatContact {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final bool isOnline;

  ChatContact({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.timestamp,
    this.unreadCount = 0,
    this.isOnline = false,
  });
}

class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final DateTime timestamp;
  final String? mediaUrl;
  final String type;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.timestamp,
    this.mediaUrl,
    this.type = 'text',
  });
}
