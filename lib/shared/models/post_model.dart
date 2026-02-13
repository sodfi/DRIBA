import 'package:cloud_firestore/cloud_firestore.dart';
import 'common_models.dart';
import 'user_model.dart';

// ============================================
// POST MODEL
// Firestore: /posts/{postId}
//
// The universal content unit in Driba OS.
// A post can be: content, product, service,
// food item, listing, job, event, etc.
// It flows into whichever screen matches its categories.
// ============================================

class Post {
  final String id;
  final UserRef author;

  // Content
  final String? title;
  final String description;
  final List<MediaItem> media; // multiple images/videos
  final String? thumbnailUrl;

  // Classification - determines which screens this appears in
  final PostType type; // content, product, service, food, listing, event, job
  final List<String> categories; // screen IDs: ['food', 'learn']
  final List<String> tags; // hashtags and search terms
  final ContentStatus status;
  final Visibility visibility;

  // Commerce (optional - when post is sellable)
  final Price? price;
  final List<ProductVariant>? variants; // size, color, etc.
  final int? stockCount; // null = unlimited/digital
  final String? shippingInfo;
  final bool isDigital;

  // Service (optional - when post is a service)
  final ServiceInfo? serviceInfo;

  // Food (optional - when post is a food item)
  final FoodInfo? foodInfo;

  // Location
  final Address? location;
  final double? deliveryRadius; // km

  // Engagement (denormalized counters for fast reads)
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int savesCount;
  final int viewsCount;
  final double engagementScore; // AI-calculated ranking score

  // AI metadata
  final AiMeta? aiMeta; // if generated/enhanced by AI

  // Scheduling
  final DateTime? scheduledAt;
  final DateTime? expiresAt;

  // Cross-posting
  final List<String> crossPostedTo; // external platform IDs

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const Post({
    required this.id,
    required this.author,
    this.title,
    required this.description,
    this.media = const [],
    this.thumbnailUrl,
    this.type = PostType.content,
    this.categories = const [],
    this.tags = const [],
    this.status = ContentStatus.published,
    this.visibility = Visibility.public,
    this.price,
    this.variants,
    this.stockCount,
    this.shippingInfo,
    this.isDigital = false,
    this.serviceInfo,
    this.foodInfo,
    this.location,
    this.deliveryRadius,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.savesCount = 0,
    this.viewsCount = 0,
    this.engagementScore = 0,
    this.aiMeta,
    this.scheduledAt,
    this.expiresAt,
    this.crossPostedTo = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post.fromMap(data, doc.id);
  }

  factory Post.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Post(
      id: docId ?? map['id'] as String,
      author: UserRef.fromMap(Map<String, dynamic>.from(map['author'] as Map)),
      title: map['title'] as String?,
      description: map['description'] as String? ?? '',
      media: toModelList(map['media'], MediaItem.fromMap),
      thumbnailUrl: map['thumbnailUrl'] as String?,
      type: PostType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'content'),
        orElse: () => PostType.content,
      ),
      categories: toStringList(map['categories']),
      tags: toStringList(map['tags']),
      status: ContentStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'published'),
        orElse: () => ContentStatus.published,
      ),
      visibility: Visibility.values.firstWhere(
        (e) => e.name == (map['visibility'] as String? ?? 'public'),
        orElse: () => Visibility.public,
      ),
      price: map['price'] != null
          ? Price.fromMap(Map<String, dynamic>.from(map['price'] as Map))
          : null,
      variants: map['variants'] != null
          ? toModelList(map['variants'], ProductVariant.fromMap)
          : null,
      stockCount: map['stockCount'] as int?,
      shippingInfo: map['shippingInfo'] as String?,
      isDigital: map['isDigital'] as bool? ?? false,
      serviceInfo: map['serviceInfo'] != null
          ? ServiceInfo.fromMap(Map<String, dynamic>.from(map['serviceInfo'] as Map))
          : null,
      foodInfo: map['foodInfo'] != null
          ? FoodInfo.fromMap(Map<String, dynamic>.from(map['foodInfo'] as Map))
          : null,
      location: map['location'] != null
          ? Address.fromMap(Map<String, dynamic>.from(map['location'] as Map))
          : null,
      deliveryRadius: (map['deliveryRadius'] as num?)?.toDouble(),
      likesCount: map['likesCount'] as int? ?? 0,
      commentsCount: map['commentsCount'] as int? ?? 0,
      sharesCount: map['sharesCount'] as int? ?? 0,
      savesCount: map['savesCount'] as int? ?? 0,
      viewsCount: map['viewsCount'] as int? ?? 0,
      engagementScore: (map['engagementScore'] as num?)?.toDouble() ?? 0,
      aiMeta: map['aiMeta'] != null
          ? AiMeta.fromMap(Map<String, dynamic>.from(map['aiMeta'] as Map))
          : null,
      scheduledAt: timestampToDateTime(map['scheduledAt']),
      expiresAt: timestampToDateTime(map['expiresAt']),
      crossPostedTo: toStringList(map['crossPostedTo']),
      createdAt: timestampToDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: timestampToDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'author': author.toMap(),
        if (title != null) 'title': title,
        'description': description,
        'media': media.map((e) => e.toMap()).toList(),
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        'type': type.name,
        'categories': categories,
        'tags': tags,
        'status': status.name,
        'visibility': visibility.name,
        if (price != null) 'price': price!.toMap(),
        if (variants != null)
          'variants': variants!.map((e) => e.toMap()).toList(),
        if (stockCount != null) 'stockCount': stockCount,
        if (shippingInfo != null) 'shippingInfo': shippingInfo,
        'isDigital': isDigital,
        if (serviceInfo != null) 'serviceInfo': serviceInfo!.toMap(),
        if (foodInfo != null) 'foodInfo': foodInfo!.toMap(),
        if (location != null) 'location': location!.toMap(),
        if (deliveryRadius != null) 'deliveryRadius': deliveryRadius,
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'sharesCount': sharesCount,
        'savesCount': savesCount,
        'viewsCount': viewsCount,
        'engagementScore': engagementScore,
        if (aiMeta != null) 'aiMeta': aiMeta!.toMap(),
        if (scheduledAt != null) 'scheduledAt': dateTimeToTimestamp(scheduledAt),
        if (expiresAt != null) 'expiresAt': dateTimeToTimestamp(expiresAt),
        'crossPostedTo': crossPostedTo,
        'createdAt': dateTimeToTimestamp(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  // Convenience getters
  bool get isSellable => price != null;
  bool get isService => type == PostType.service;
  bool get isFood => type == PostType.food;
  bool get isEvent => type == PostType.event;
  bool get hasVideo => media.any((m) => m.isVideo);
  bool get hasMultipleMedia => media.length > 1;
  MediaItem? get primaryMedia => media.isNotEmpty ? media.first : null;
  bool get isAiGenerated => aiMeta != null;
  bool get isInStock => stockCount == null || stockCount! > 0;

  Post copyWith({
    UserRef? author,
    String? title,
    String? description,
    List<MediaItem>? media,
    String? thumbnailUrl,
    PostType? type,
    List<String>? categories,
    List<String>? tags,
    ContentStatus? status,
    Visibility? visibility,
    Price? price,
    List<ProductVariant>? variants,
    int? stockCount,
    String? shippingInfo,
    bool? isDigital,
    ServiceInfo? serviceInfo,
    FoodInfo? foodInfo,
    Address? location,
    double? deliveryRadius,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? savesCount,
    int? viewsCount,
    double? engagementScore,
    AiMeta? aiMeta,
    DateTime? scheduledAt,
    DateTime? expiresAt,
    List<String>? crossPostedTo,
  }) {
    return Post(
      id: id,
      author: author ?? this.author,
      title: title ?? this.title,
      description: description ?? this.description,
      media: media ?? this.media,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      type: type ?? this.type,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      price: price ?? this.price,
      variants: variants ?? this.variants,
      stockCount: stockCount ?? this.stockCount,
      shippingInfo: shippingInfo ?? this.shippingInfo,
      isDigital: isDigital ?? this.isDigital,
      serviceInfo: serviceInfo ?? this.serviceInfo,
      foodInfo: foodInfo ?? this.foodInfo,
      location: location ?? this.location,
      deliveryRadius: deliveryRadius ?? this.deliveryRadius,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      savesCount: savesCount ?? this.savesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      engagementScore: engagementScore ?? this.engagementScore,
      aiMeta: aiMeta ?? this.aiMeta,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      expiresAt: expiresAt ?? this.expiresAt,
      crossPostedTo: crossPostedTo ?? this.crossPostedTo,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// ============================================
// POST TYPE - What kind of content this is
// ============================================

enum PostType {
  content,  // regular post/video/image
  product,  // physical product for sale
  service,  // service offering (freelance, etc.)
  food,     // food item / menu item
  listing,  // rental, real estate, auto
  event,    // event with date/location
  job,      // job posting
}

// ============================================
// COMMENT
// Firestore: /posts/{postId}/comments/{commentId}
// ============================================

class Comment {
  final String id;
  final String postId;
  final UserRef author;
  final String text;
  final String? replyToId; // null = top-level, otherwise reply
  final int likesCount;
  final bool isPinned;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.text,
    this.replyToId,
    this.likesCount = 0,
    this.isPinned = false,
    required this.createdAt,
  });

  factory Comment.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      postId: data['postId'] as String,
      author: UserRef.fromMap(Map<String, dynamic>.from(data['author'] as Map)),
      text: data['text'] as String,
      replyToId: data['replyToId'] as String?,
      likesCount: data['likesCount'] as int? ?? 0,
      isPinned: data['isPinned'] as bool? ?? false,
      createdAt: timestampToDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'author': author.toMap(),
        'text': text,
        if (replyToId != null) 'replyToId': replyToId,
        'likesCount': likesCount,
        'isPinned': isPinned,
        'createdAt': dateTimeToTimestamp(createdAt),
      };
}

// ============================================
// PRODUCT VARIANT - Size, color, etc.
// ============================================

class ProductVariant {
  final String id;
  final String name; // "Large", "Blue", "64GB"
  final String? group; // "size", "color", "storage"
  final Price? priceOverride; // if different from base price
  final int? stockCount;
  final String? imageUrl;

  const ProductVariant({
    required this.id,
    required this.name,
    this.group,
    this.priceOverride,
    this.stockCount,
    this.imageUrl,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map) => ProductVariant(
        id: map['id'] as String,
        name: map['name'] as String,
        group: map['group'] as String?,
        priceOverride: map['priceOverride'] != null
            ? Price.fromMap(Map<String, dynamic>.from(map['priceOverride'] as Map))
            : null,
        stockCount: map['stockCount'] as int?,
        imageUrl: map['imageUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        if (group != null) 'group': group,
        if (priceOverride != null) 'priceOverride': priceOverride!.toMap(),
        if (stockCount != null) 'stockCount': stockCount,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}

// ============================================
// SERVICE INFO - For service-type posts
// ============================================

class ServiceInfo {
  final String deliveryMethod; // remote, onsite, both
  final int? durationMinutes;
  final List<String> includes; // what's included
  final int? maxRevisions;
  final String? turnaroundTime; // "2-3 days", "1 week"

  const ServiceInfo({
    this.deliveryMethod = 'remote',
    this.durationMinutes,
    this.includes = const [],
    this.maxRevisions,
    this.turnaroundTime,
  });

  factory ServiceInfo.fromMap(Map<String, dynamic> map) => ServiceInfo(
        deliveryMethod: map['deliveryMethod'] as String? ?? 'remote',
        durationMinutes: map['durationMinutes'] as int?,
        includes: toStringList(map['includes']),
        maxRevisions: map['maxRevisions'] as int?,
        turnaroundTime: map['turnaroundTime'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'deliveryMethod': deliveryMethod,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        'includes': includes,
        if (maxRevisions != null) 'maxRevisions': maxRevisions,
        if (turnaroundTime != null) 'turnaroundTime': turnaroundTime,
      };
}

// ============================================
// FOOD INFO - For food-type posts
// ============================================

class FoodInfo {
  final List<String> allergens; // gluten, dairy, nuts, etc.
  final List<String> dietaryTags; // vegan, halal, keto, etc.
  final int? calories;
  final int? prepTimeMinutes;
  final String? spiceLevel; // mild, medium, hot, extra_hot
  final bool isAvailable;
  final List<String>? ingredients;

  const FoodInfo({
    this.allergens = const [],
    this.dietaryTags = const [],
    this.calories,
    this.prepTimeMinutes,
    this.spiceLevel,
    this.isAvailable = true,
    this.ingredients,
  });

  factory FoodInfo.fromMap(Map<String, dynamic> map) => FoodInfo(
        allergens: toStringList(map['allergens']),
        dietaryTags: toStringList(map['dietaryTags']),
        calories: map['calories'] as int?,
        prepTimeMinutes: map['prepTimeMinutes'] as int?,
        spiceLevel: map['spiceLevel'] as String?,
        isAvailable: map['isAvailable'] as bool? ?? true,
        ingredients: map['ingredients'] != null
            ? toStringList(map['ingredients'])
            : null,
      );

  Map<String, dynamic> toMap() => {
        'allergens': allergens,
        'dietaryTags': dietaryTags,
        if (calories != null) 'calories': calories,
        if (prepTimeMinutes != null) 'prepTimeMinutes': prepTimeMinutes,
        if (spiceLevel != null) 'spiceLevel': spiceLevel,
        'isAvailable': isAvailable,
        if (ingredients != null) 'ingredients': ingredients,
      };
}

// ============================================
// AI META - Metadata for AI-generated content
// ============================================

class AiMeta {
  final String model; // claude-3.5-sonnet, gpt-4, gemini-pro
  final String? creatorId; // AI creator agent ID
  final String? prompt; // original prompt used
  final double? confidence; // 0-1
  final bool isFullyGenerated; // vs AI-enhanced
  final DateTime generatedAt;

  const AiMeta({
    required this.model,
    this.creatorId,
    this.prompt,
    this.confidence,
    this.isFullyGenerated = true,
    required this.generatedAt,
  });

  factory AiMeta.fromMap(Map<String, dynamic> map) => AiMeta(
        model: map['model'] as String,
        creatorId: map['creatorId'] as String?,
        prompt: map['prompt'] as String?,
        confidence: (map['confidence'] as num?)?.toDouble(),
        isFullyGenerated: map['isFullyGenerated'] as bool? ?? true,
        generatedAt: timestampToDateTime(map['generatedAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'model': model,
        if (creatorId != null) 'creatorId': creatorId,
        if (prompt != null) 'prompt': prompt,
        if (confidence != null) 'confidence': confidence,
        'isFullyGenerated': isFullyGenerated,
        'generatedAt': dateTimeToTimestamp(generatedAt),
      };
}
