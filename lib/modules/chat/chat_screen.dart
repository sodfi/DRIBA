import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/driba_colors.dart';

// ============================================
// CHAT SCREEN v2
//
// Fixes:
// - Avatars use horizontal ListView (tight spacing, not PageView)
// - Replies stay inline (no navigation to new screen)
// - Input always at bottom like iMessage
// - Tapping avatar scrolls to that conversation
// ============================================

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  int _selectedIndex = 0;
  late PageController _chatController;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _avatarScroll = ScrollController();

  final List<_Contact> _contacts = List.generate(12, (i) => _Contact(
    id: 'user_$i',
    name: ['Alex', 'Sarah', 'Mike', 'Emma', 'James', 'Olivia', 'Daniel', 'Sophie', 'Chris', 'Amy', 'Leo', 'Zara'][i],
    avatar: 'https://i.pravatar.cc/150?img=${i + 1}',
    lastMsg: ['Hey!', 'Looks great ✨', 'Tomorrow?', 'Thanks!', 'Check this 🔥', 'Sounds good', 'Ready?', 'Perfect!', 'On my way', 'See you!', 'Love it 💜', 'Done ✅'][i],
    time: DateTime.now().subtract(Duration(minutes: i * 25)),
    unread: i < 3 ? (3 - i) : 0,
    online: i % 3 == 0,
  ));

  // Each contact has their own messages
  late final List<List<_Msg>> _allMessages;

  @override
  void initState() {
    super.initState();
    _chatController = PageController();
    _allMessages = _contacts.map((c) => [
      _Msg('Hey! How are you?', c.id, DateTime.now().subtract(const Duration(hours: 2))),
      _Msg("I'm great, thanks! Working on something cool.", 'me', DateTime.now().subtract(const Duration(hours: 1, minutes: 50))),
      _Msg(c.lastMsg, c.id, c.time),
    ]).toList();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _inputController.dispose();
    _avatarScroll.dispose();
    super.dispose();
  }

  void _selectContact(int index) {
    setState(() => _selectedIndex = index);
    _chatController.animateToPage(index,
      duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
    // Scroll avatar into view
    final offset = (index * 62.0) - 100;
    _avatarScroll.animateTo(offset.clamp(0, _avatarScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _allMessages[_selectedIndex].add(_Msg(text, 'me', DateTime.now()));
      _inputController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: DribaColors.background,
      body: Column(
        children: [
          SizedBox(height: topPad + 12),

          // ── Title ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('Messages', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const Spacer(),
                Icon(Icons.edit_square, color: DribaColors.primary, size: 22),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Avatar strip (tight horizontal list) ──
          SizedBox(
            height: 76,
            child: ListView.builder(
              controller: _avatarScroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _contacts.length,
              itemBuilder: (_, i) {
                final c = _contacts[i];
                final isSelected = i == _selectedIndex;
                return GestureDetector(
                  onTap: () => _selectContact(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar with ring
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? DribaColors.primary : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(color: DribaColors.primary.withOpacity(0.3), blurRadius: 12),
                            ] : null,
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundImage: NetworkImage(c.avatar),
                                ),
                              ),
                              // Online dot
                              if (c.online)
                                Positioned(right: 1, bottom: 1,
                                  child: Container(width: 12, height: 12,
                                    decoration: BoxDecoration(
                                      color: DribaColors.success,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: DribaColors.background, width: 2),
                                    ),
                                  ),
                                ),
                              // Unread badge
                              if (c.unread > 0)
                                Positioned(right: 0, top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: Text('${c.unread}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(c.name, style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                          fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // ── Chat messages (swipe between conversations) ──
          Expanded(
            child: PageView.builder(
              controller: _chatController,
              onPageChanged: (i) => setState(() => _selectedIndex = i),
              itemCount: _contacts.length,
              itemBuilder: (_, i) {
                final msgs = _allMessages[i];
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: msgs.length,
                  itemBuilder: (_, idx) {
                    final msg = msgs[msgs.length - 1 - idx];
                    final isMe = msg.sender == 'me';
                    return _Bubble(
                      text: msg.text,
                      isMe: isMe,
                      avatar: isMe ? null : _contacts[i].avatar,
                      time: msg.time,
                    );
                  },
                );
              },
            ),
          ),

          // ── Input bar (always visible, inline) ──
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.only(left: 16, right: 8, top: 10, bottom: bottomPad + 70),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1628).withOpacity(0.8),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
                ),
                child: Row(
                  children: [
                    // Attachment
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                        child: Icon(Icons.add, color: Colors.white.withOpacity(0.5), size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Input
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: TextField(
                          controller: _inputController,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Message ${_contacts[_selectedIndex].name}...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          gradient: DribaColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ──

class _Bubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String? avatar;
  final DateTime time;

  const _Bubble({required this.text, required this.isMe, this.avatar, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && avatar != null) ...[
            CircleAvatar(radius: 14, backgroundImage: NetworkImage(avatar!)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? DribaColors.primary.withOpacity(0.18)
                    : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: Border.all(
                  color: isMe
                      ? DribaColors.primary.withOpacity(0.25)
                      : Colors.white.withOpacity(0.06),
                ),
              ),
              child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Models ──

class _Contact {
  final String id, name, avatar, lastMsg;
  final DateTime time;
  final int unread;
  final bool online;
  const _Contact({required this.id, required this.name, required this.avatar,
    required this.lastMsg, required this.time, this.unread = 0, this.online = false});
}

class _Msg {
  final String text, sender;
  final DateTime time;
  const _Msg(this.text, this.sender, this.time);
}
