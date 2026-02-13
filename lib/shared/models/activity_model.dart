import 'package:cloud_firestore/cloud_firestore.dart';
import 'common_models.dart';
import 'user_model.dart';

// ============================================
// ACTIVITY MODEL
// Firestore: /activities/{activityId}
//
// Notifications, interactions, and system events.
// Powers the activity feed / notification center.
// ============================================

class Activity {
  final String id;
  final String userId; // recipient
  final ActivityType type;

  // Who triggered it
  final UserRef? actor; // null for system notifications
  final String? actorGroupLabel; // "and 12 others liked your post"

  // What it's about
  final String? postId;
  final String? commentId;
  final String? orderId;
  final String? chatId;

  // Display
  final String title;
  final String body;
  final String? imageUrl; // thumbnail or avatar
  final String? actionUrl; // deep link

  // State
  final bool isRead;
  final bool isActionable; // requires user response
  final String? actionLabel; // "Accept", "View", "Reply"

  // Timestamps
  final DateTime createdAt;
  final DateTime? readAt;

  const Activity({
    required this.id,
    required this.userId,
    required this.type,
    this.actor,
    this.actorGroupLabel,
    this.postId,
    this.commentId,
    this.orderId,
    this.chatId,
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionUrl,
    this.isRead = false,
    this.isActionable = false,
    this.actionLabel,
    required this.createdAt,
    this.readAt,
  });

  factory Activity.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      userId: data['userId'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.name == (data['type'] as String? ?? 'system'),
        orElse: () => ActivityType.system,
      ),
      actor: data['actor'] != null
          ? UserRef.fromMap(Map<String, dynamic>.from(data['actor'] as Map))
          : null,
      actorGroupLabel: data['actorGroupLabel'] as String?,
      postId: data['postId'] as String?,
      commentId: data['commentId'] as String?,
      orderId: data['orderId'] as String?,
      chatId: data['chatId'] as String?,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      actionUrl: data['actionUrl'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      isActionable: data['isActionable'] as bool? ?? false,
      actionLabel: data['actionLabel'] as String?,
      createdAt: timestampToDateTime(data['createdAt']) ?? DateTime.now(),
      readAt: timestampToDateTime(data['readAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type.name,
        if (actor != null) 'actor': actor!.toMap(),
        if (actorGroupLabel != null) 'actorGroupLabel': actorGroupLabel,
        if (postId != null) 'postId': postId,
        if (commentId != null) 'commentId': commentId,
        if (orderId != null) 'orderId': orderId,
        if (chatId != null) 'chatId': chatId,
        'title': title,
        'body': body,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (actionUrl != null) 'actionUrl': actionUrl,
        'isRead': isRead,
        'isActionable': isActionable,
        if (actionLabel != null) 'actionLabel': actionLabel,
        'createdAt': dateTimeToTimestamp(createdAt),
        if (readAt != null) 'readAt': dateTimeToTimestamp(readAt),
      };
}

enum ActivityType {
  // Social
  like,
  comment,
  follow,
  mention,
  share,
  repost,

  // Commerce
  orderPlaced,
  orderConfirmed,
  orderShipped,
  orderDelivered,
  orderCancelled,
  paymentReceived,
  reviewReceived,

  // Business
  newCustomer,
  newBooking,
  invoicePaid,
  lowStock,

  // System
  system,
  promotion,
  milestone, // "You reached 1000 followers!"
  aiContent, // AI created content for you
}
