import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/shell/shell_state.dart';
import 'chat_demo_data.dart';
import 'conversation_screen.dart';

// ============================================
// CHAT SCREEN — CAROUSEL + FULLSCREEN MESSAGES
// Horizontal avatar carousel at top.
// Central avatar = active chat.
// Fullscreen messages below.
// Swipe horizontally between conversations.
// ============================================

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});
  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  late PageController _avatarController;
  late PageController _messageController;
  int _activeIndex = 0;
  int _selectedFilter = 0;
  bool _syncing = false;

  static const Color _accent = Color(0xFF00D68F);
  static const _filterLabels = ['All', 'Unread', 'Groups', 'AI Agents'];
  static const _filterEmojis = ['💬', '🔴', '👥', '🤖'];

  late final List<DemoChat> _chats;

  @override
  void initState() {
    super.initState();
    _chats = ChatDemoData.chats;
    _avatarController = PageController(viewportFraction: 0.22, initialPage: 0);
    _messageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _avatarController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onAvatarChanged(int index) {
    if (_syncing) return;
    _syncing = true;
    setState(() => _activeIndex = index);
    _messageController.animateToPage(index,
      duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    ref.read(shellProvider.notifier).onContentChanged();
    Future.delayed(const Duration(milliseconds: 350), () => _syncing = false);
  }

  void _onMessageChanged(int index) {
    if (_syncing) return;
    _syncing = true;
    setState(() => _activeIndex = index);
    _avatarController.animateToPage(index,
      duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    ref.read(shellProvider.notifier).onContentChanged();
    Future.delayed(const Duration(milliseconds: 350), () => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: DribaColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(children: [
            SizedBox(height: topPad + 56 + 44), // header + filters

            // Avatar carousel
            SizedBox(
              height: 90,
              child: PageView.builder(
                controller: _avatarController,
                onPageChanged: _onAvatarChanged,
                itemCount: _chats.length,
                itemBuilder: (_, i) => _AvatarItem(
                  chat: _chats[i],
                  isActive: _activeIndex == i,
                  accent: _accent,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Active name
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _chats[_activeIndex].name,
                key: ValueKey(_activeIndex),
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            if (_chats[_activeIndex].isOnline)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF00D68F), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Online', style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w500)),
                ]),
              ),
            const SizedBox(height: 16),

            // Fullscreen messages
            Expanded(
              child: PageView.builder(
                controller: _messageController,
                onPageChanged: _onMessageChanged,
                itemCount: _chats.length,
                itemBuilder: (_, i) => _ChatMessageView(
                  chat: _chats[i],
                  accent: _accent,
                  onOpenFull: () => _openConversation(_chats[i]),
                ),
              ),
            ),
          ]),

          // Header
          _buildHeader(topPad),
          // Filters
          Positioned(
            top: topPad + 56, left: 0, right: 0,
            child: _buildFilters(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double topPad) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: ClipRRect(child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: topPad + 56,
          padding: EdgeInsets.only(top: topPad, left: 16, right: 16),
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [DribaColors.background.withOpacity(0.9), DribaColors.background.withOpacity(0.7)])),
          child: Row(children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(gradient: LinearGradient(colors: [_accent, _accent.withOpacity(0.5)]), borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('D', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)))),
            const SizedBox(width: 10),
            Text('Messages', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 18)),
            const Spacer(),
            Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: Icon(Icons.search, color: Colors.white.withOpacity(0.7), size: 20)),
          ]),
        ),
      )),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: DribaColors.background.withOpacity(0.5),
      child: SizedBox(height: 36, child: ListView.separated(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterLabels.length, separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sel = _selectedFilter == i;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedFilter = i); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? _accent.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: sel ? _accent.withOpacity(0.5) : Colors.white.withOpacity(0.08)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_filterEmojis[i], style: const TextStyle(fontSize: 13)), const SizedBox(width: 4),
                Text(_filterLabels[i], style: TextStyle(color: sel ? _accent : Colors.white.withOpacity(0.6), fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
              ]),
            ),
          );
        },
      )),
    );
  }

  void _openConversation(DemoChat chat) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => ConversationScreen(
        chatId: chat.id, chatName: chat.name,
        chatAvatar: chat.avatarUrl, isOnline: chat.isOnline, isGroup: chat.isGroup),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }
}

// ── Avatar carousel item ──

class _AvatarItem extends StatelessWidget {
  final DemoChat chat;
  final bool isActive;
  final Color accent;
  const _AvatarItem({required this.chat, required this.isActive, required this.accent});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(isActive ? 4 : 12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 56 : 40, height: isActive ? 56 : 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? accent : (chat.unreadCount > 0 ? accent.withOpacity(0.5) : Colors.white.withOpacity(0.15)), width: isActive ? 2.5 : 1.5),
            boxShadow: isActive ? [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 12)] : [],
          ),
          child: ClipOval(child: Container(
            color: accent.withOpacity(0.15),
            child: Center(child: Text(chat.name[0],
              style: TextStyle(color: isActive ? accent : Colors.white.withOpacity(0.6), fontWeight: FontWeight.w700, fontSize: isActive ? 22 : 16))),
          )),
        ),
        if (chat.unreadCount > 0 && !isActive) ...[
          const SizedBox(height: 2),
          Container(width: 6, height: 6, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
        ],
      ]),
    );
  }
}

// ── Fullscreen message view ──

class _ChatMessageView extends StatelessWidget {
  final DemoChat chat;
  final Color accent;
  final VoidCallback onOpenFull;
  const _ChatMessageView({required this.chat, required this.accent, required this.onOpenFull});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpenFull,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(children: [
          Expanded(child: ListView(padding: const EdgeInsets.all(20), reverse: true, children: [
            _Bubble(text: chat.lastMessagePreview, isMe: false, accent: accent, time: chat.lastMessageTime),
            const SizedBox(height: 12),
            _Bubble(text: 'That sounds great! Let me check.', isMe: true, accent: accent, time: chat.lastMessageTime.subtract(const Duration(minutes: 2))),
            const SizedBox(height: 12),
            _Bubble(text: chat.isGroup ? 'Hey everyone, quick update...' : 'Hey! How\'s everything going?', isMe: false, accent: accent, time: chat.lastMessageTime.subtract(const Duration(minutes: 5))),
          ])),
          // Input hint
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.08))),
            child: Row(children: [
              Icon(Icons.add, color: Colors.white.withOpacity(0.3), size: 20),
              const SizedBox(width: 12),
              Text('Type a message...', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14)),
              const Spacer(),
              Icon(Icons.mic_none, color: accent.withOpacity(0.5), size: 20),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final Color accent;
  final DateTime time;
  const _Bubble({required this.text, required this.isMe, required this.accent, required this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? accent.withOpacity(0.15) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18)),
          border: Border.all(color: isMe ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.06)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.4)),
          const SizedBox(height: 4),
          Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
        ]),
      ),
    );
  }
}
