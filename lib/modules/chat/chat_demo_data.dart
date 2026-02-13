// ============================================
// CHAT DEMO DATA
//
// Rich demo data for the chat screens.
// Replaces Firestore streams during development.
// ============================================

class DemoChat {
  final String id;
  final String name;
  final String avatarUrl;
  final String lastMessagePreview;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isGroup;
  final bool isBusiness;
  final bool isPinned;
  final bool isMuted;
  final bool isVerified;
  final bool isTyping;

  const DemoChat({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.lastMessagePreview,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isGroup = false,
    this.isBusiness = false,
    this.isPinned = false,
    this.isMuted = false,
    this.isVerified = false,
    this.isTyping = false,
  });
}

class DemoMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String text;
  final DateTime timestamp;
  final String status; // sending, sent, delivered, read
  final bool isEdited;
  final bool isSystem;
  final DemoMessage? replyTo;
  final Map<String, String> reactions; // userId → emoji

  DemoMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.text,
    required this.timestamp,
    this.status = 'read',
    this.isEdited = false,
    this.isSystem = false,
    this.replyTo,
    Map<String, String>? reactions,
  }) : reactions = reactions ?? {};
}

class ChatDemoData {
  ChatDemoData._();

  static final List<DemoChat> chats = [
    DemoChat(
      id: 'chat_1',
      name: 'Sara El Amrani',
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      lastMessagePreview: 'Let me know when you\'re free for lunch! 🍽️',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 2)),
      unreadCount: 3,
      isOnline: true,
      isPinned: true,
      isVerified: true,
    ),
    DemoChat(
      id: 'chat_2',
      name: 'Youssef Khalil',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      lastMessagePreview: 'The design looks amazing, great work!',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 15)),
      unreadCount: 1,
      isOnline: true,
      isTyping: true,
    ),
    DemoChat(
      id: 'chat_3',
      name: 'Driba Team',
      avatarUrl: 'https://i.pravatar.cc/150?img=20',
      lastMessagePreview: 'Karim: Sprint planning at 3pm today',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 45)),
      unreadCount: 5,
      isGroup: true,
      isPinned: true,
    ),
    DemoChat(
      id: 'chat_4',
      name: 'Amina Benali',
      avatarUrl: 'https://i.pravatar.cc/150?img=9',
      lastMessagePreview: 'Thanks for the recommendation!',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
      isOnline: true,
    ),
    DemoChat(
      id: 'chat_5',
      name: 'The Golden Dragon',
      avatarUrl: 'https://i.pravatar.cc/150?img=30',
      lastMessagePreview: 'Your order is being prepared 🧑‍🍳',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      isBusiness: true,
      isVerified: true,
      unreadCount: 1,
    ),
    DemoChat(
      id: 'chat_6',
      name: 'Omar Tazi',
      avatarUrl: 'https://i.pravatar.cc/150?img=15',
      lastMessagePreview: 'Can you send me the Figma link?',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
      isOnline: false,
    ),
    DemoChat(
      id: 'chat_7',
      name: 'Startup Founders',
      avatarUrl: 'https://i.pravatar.cc/150?img=25',
      lastMessagePreview: 'Fatima: Who\'s going to the meetup Friday?',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
      isGroup: true,
      isMuted: true,
    ),
    DemoChat(
      id: 'chat_8',
      name: 'Lina Moussaoui',
      avatarUrl: 'https://i.pravatar.cc/150?img=32',
      lastMessagePreview: 'The flight lands at 8pm ✈️',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 8)),
      isOnline: true,
    ),
    DemoChat(
      id: 'chat_9',
      name: 'Karim Adda',
      avatarUrl: 'https://i.pravatar.cc/150?img=18',
      lastMessagePreview: '📷 Photo',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DemoChat(
      id: 'chat_10',
      name: 'Casa Bella Pizza',
      avatarUrl: 'https://i.pravatar.cc/150?img=40',
      lastMessagePreview: 'Your order has been delivered! Enjoy 🍕',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 2)),
      isBusiness: true,
      isVerified: true,
    ),
  ];

  // ── Messages per chat ─────────────────────

  static List<DemoMessage> messagesForChat(String chatId) {
    switch (chatId) {
      case 'chat_1':
        return _saraMessages;
      case 'chat_2':
        return _youssefMessages;
      case 'chat_3':
        return _teamMessages;
      default:
        return _defaultMessages(chatId);
    }
  }

  static final List<DemoMessage> _saraMessages = [
    DemoMessage(
      id: 's1',
      senderId: 'chat_1',
      senderName: 'Sara',
      senderAvatar: 'https://i.pravatar.cc/150?img=5',
      text: 'Let me know when you\'re free for lunch! 🍽️',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      status: 'delivered',
    ),
    DemoMessage(
      id: 's2',
      senderId: 'chat_1',
      senderName: 'Sara',
      senderAvatar: 'https://i.pravatar.cc/150?img=5',
      text: 'I found this amazing new Thai place near the park',
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      status: 'delivered',
    ),
    DemoMessage(
      id: 's3',
      senderId: 'current_user',
      senderName: 'You',
      text: 'That sounds perfect! I was just craving pad thai 😋',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      status: 'read',
    ),
    DemoMessage(
      id: 's4',
      senderId: 'chat_1',
      senderName: 'Sara',
      senderAvatar: 'https://i.pravatar.cc/150?img=5',
      text: 'Did you see the new Driba food feature? You can order directly now',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      status: 'read',
    ),
    DemoMessage(
      id: 's5',
      senderId: 'current_user',
      senderName: 'You',
      text: 'Yeah! I already tried it. The 0% fee thing is actually real',
      timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
      status: 'read',
      reactions: {'chat_1': '🔥'},
    ),
    DemoMessage(
      id: 's6',
      senderId: 'chat_1',
      senderName: 'Sara',
      senderAvatar: 'https://i.pravatar.cc/150?img=5',
      text: 'How\'s the app coming along? I heard you\'re building something big',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      status: 'read',
    ),
    DemoMessage(
      id: 's7',
      senderId: 'current_user',
      senderName: 'You',
      text: 'It\'s going great! Just finished the AI content router. Claude, GPT, and Gemini all integrated',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
      status: 'read',
      reactions: {'chat_1': '😮'},
    ),
    DemoMessage(
      id: 's_sys',
      senderId: 'system',
      senderName: 'System',
      text: 'Today',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isSystem: true,
    ),
  ];

  static final List<DemoMessage> _youssefMessages = [
    DemoMessage(
      id: 'y1',
      senderId: 'chat_2',
      senderName: 'Youssef',
      senderAvatar: 'https://i.pravatar.cc/150?img=12',
      text: 'The design looks amazing, great work!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      status: 'delivered',
      reactions: {'current_user': '❤️'},
    ),
    DemoMessage(
      id: 'y2',
      senderId: 'current_user',
      senderName: 'You',
      text: 'Thanks! I went with the glass morphism approach. Dark background with frosted glass cards.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      status: 'read',
    ),
    DemoMessage(
      id: 'y3',
      senderId: 'chat_2',
      senderName: 'Youssef',
      senderAvatar: 'https://i.pravatar.cc/150?img=12',
      text: 'That sounds premium. Can you share the color palette?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
      status: 'read',
    ),
    DemoMessage(
      id: 'y4',
      senderId: 'current_user',
      senderName: 'You',
      text: 'Sure! Background is #050B14, primary accent is cyan #00E1FF, food screen uses orange #FF6B35',
      timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
      status: 'read',
      isEdited: true,
    ),
    DemoMessage(
      id: 'y5',
      senderId: 'chat_2',
      senderName: 'Youssef',
      senderAvatar: 'https://i.pravatar.cc/150?img=12',
      text: 'Each screen has its own accent color? That\'s a nice touch',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      status: 'read',
    ),
  ];

  static final List<DemoMessage> _teamMessages = [
    DemoMessage(
      id: 't_sys',
      senderId: 'system',
      senderName: 'System',
      text: 'Karim created the group "Driba Team"',
      timestamp: DateTime.now().subtract(const Duration(days: 7)),
      isSystem: true,
    ),
    DemoMessage(
      id: 't1',
      senderId: 'karim',
      senderName: 'Karim',
      senderAvatar: 'https://i.pravatar.cc/150?img=18',
      text: 'Sprint planning at 3pm today. Don\'t forget!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      status: 'delivered',
    ),
    DemoMessage(
      id: 't2',
      senderId: 'fatima',
      senderName: 'Fatima',
      senderAvatar: 'https://i.pravatar.cc/150?img=23',
      text: 'I\'ll present the user research findings',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      status: 'read',
    ),
    DemoMessage(
      id: 't3',
      senderId: 'current_user',
      senderName: 'You',
      text: 'I\'ll demo the new chat system and AI router',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
      status: 'read',
      reactions: {'karim': '👍', 'fatima': '🔥'},
    ),
    DemoMessage(
      id: 't4',
      senderId: 'karim',
      senderName: 'Karim',
      senderAvatar: 'https://i.pravatar.cc/150?img=18',
      text: 'Perfect. Also let\'s review the food screen flow',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      status: 'read',
    ),
  ];

  static List<DemoMessage> _defaultMessages(String chatId) {
    return [
      DemoMessage(
        id: 'd1',
        senderId: chatId,
        senderName: 'Contact',
        senderAvatar: 'https://i.pravatar.cc/150?img=10',
        text: 'Hey! How are you doing?',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        status: 'read',
      ),
      DemoMessage(
        id: 'd2',
        senderId: 'current_user',
        senderName: 'You',
        text: 'I\'m great, thanks! What\'s up?',
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 50)),
        status: 'read',
      ),
      DemoMessage(
        id: 'd3',
        senderId: chatId,
        senderName: 'Contact',
        senderAvatar: 'https://i.pravatar.cc/150?img=10',
        text: 'Just wanted to catch up. It\'s been a while!',
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
        status: 'delivered',
      ),
    ];
  }
}
