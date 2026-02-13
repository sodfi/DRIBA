import 'package:cloud_firestore/cloud_firestore.dart';
import 'common_models.dart';
import 'user_model.dart';

// ============================================
// BUSINESS PROFILE (Full)
// Firestore: /users/{userId}/business/info
//
// Complete business data beyond the BusinessMini
// embedded on the user profile.
// ============================================

class BusinessProfile {
  final String userId;
  final String name;
  final String? description;
  final String? category;
  final String? subcategory;
  final String? logoUrl;
  final String? bannerUrl;
  final Address? address;
  final List<DayHours> operatingHours;
  final RatingInfo rating;
  final String? taxId;
  final String? registrationNumber;
  final String? stripeConnectId;
  final bool acceptsDelivery;
  final bool acceptsPickup;
  final double? deliveryRadius;
  final Price? minimumOrder;
  final DateTime createdAt;

  const BusinessProfile({
    required this.userId,
    required this.name,
    this.description,
    this.category,
    this.subcategory,
    this.logoUrl,
    this.bannerUrl,
    this.address,
    this.operatingHours = const [],
    this.rating = const RatingInfo(),
    this.taxId,
    this.registrationNumber,
    this.stripeConnectId,
    this.acceptsDelivery = false,
    this.acceptsPickup = false,
    this.deliveryRadius,
    this.minimumOrder,
    required this.createdAt,
  });

  factory BusinessProfile.fromMap(Map<String, dynamic> map) => BusinessProfile(
        userId: map['userId'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        category: map['category'] as String?,
        subcategory: map['subcategory'] as String?,
        logoUrl: map['logoUrl'] as String?,
        bannerUrl: map['bannerUrl'] as String?,
        address: map['address'] != null
            ? Address.fromMap(Map<String, dynamic>.from(map['address'] as Map))
            : null,
        operatingHours: toModelList(map['operatingHours'], DayHours.fromMap),
        rating: map['rating'] != null
            ? RatingInfo.fromMap(Map<String, dynamic>.from(map['rating'] as Map))
            : const RatingInfo(),
        taxId: map['taxId'] as String?,
        registrationNumber: map['registrationNumber'] as String?,
        stripeConnectId: map['stripeConnectId'] as String?,
        acceptsDelivery: map['acceptsDelivery'] as bool? ?? false,
        acceptsPickup: map['acceptsPickup'] as bool? ?? false,
        deliveryRadius: (map['deliveryRadius'] as num?)?.toDouble(),
        minimumOrder: map['minimumOrder'] != null
            ? Price.fromMap(Map<String, dynamic>.from(map['minimumOrder'] as Map))
            : null,
        createdAt: timestampToDateTime(map['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (subcategory != null) 'subcategory': subcategory,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (bannerUrl != null) 'bannerUrl': bannerUrl,
        if (address != null) 'address': address!.toMap(),
        'operatingHours': operatingHours.map((e) => e.toMap()).toList(),
        'rating': rating.toMap(),
        if (taxId != null) 'taxId': taxId,
        if (registrationNumber != null) 'registrationNumber': registrationNumber,
        if (stripeConnectId != null) 'stripeConnectId': stripeConnectId,
        'acceptsDelivery': acceptsDelivery,
        'acceptsPickup': acceptsPickup,
        if (deliveryRadius != null) 'deliveryRadius': deliveryRadius,
        if (minimumOrder != null) 'minimumOrder': minimumOrder!.toMap(),
        'createdAt': dateTimeToTimestamp(createdAt),
      };
}

// ============================================
// INVOICE
// Firestore: /users/{userId}/business/invoices/{invoiceId}
// ============================================

class Invoice {
  final String id;
  final String invoiceNumber; // INV-2026-001
  final String sellerId;
  final String? buyerId;

  // Client info (may not be a Driba user)
  final String clientName;
  final String? clientEmail;
  final Address? clientAddress;

  // Items
  final List<InvoiceItem> items;
  final double subtotal;
  final double taxRate; // percentage
  final double taxAmount;
  final double discount;
  final double total;
  final String currency;

  // Status
  final InvoiceStatus status;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? paymentMethod;
  final String? stripePaymentIntentId;

  // Notes
  final String? notes;
  final String? termsAndConditions;

  // Timestamps
  final DateTime createdAt;
  final DateTime? sentAt;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.sellerId,
    this.buyerId,
    required this.clientName,
    this.clientEmail,
    this.clientAddress,
    required this.items,
    this.subtotal = 0,
    this.taxRate = 0,
    this.taxAmount = 0,
    this.discount = 0,
    this.total = 0,
    this.currency = 'USD',
    this.status = InvoiceStatus.draft,
    this.dueDate,
    this.paidAt,
    this.paymentMethod,
    this.stripePaymentIntentId,
    this.notes,
    this.termsAndConditions,
    required this.createdAt,
    this.sentAt,
  });

  factory Invoice.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Invoice(
      id: doc.id,
      invoiceNumber: data['invoiceNumber'] as String? ?? '',
      sellerId: data['sellerId'] as String,
      buyerId: data['buyerId'] as String?,
      clientName: data['clientName'] as String? ?? '',
      clientEmail: data['clientEmail'] as String?,
      clientAddress: data['clientAddress'] != null
          ? Address.fromMap(
              Map<String, dynamic>.from(data['clientAddress'] as Map))
          : null,
      items: toModelList(data['items'], InvoiceItem.fromMap),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0,
      taxAmount: (data['taxAmount'] as num?)?.toDouble() ?? 0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? 'USD',
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'draft'),
        orElse: () => InvoiceStatus.draft,
      ),
      dueDate: timestampToDateTime(data['dueDate']),
      paidAt: timestampToDateTime(data['paidAt']),
      paymentMethod: data['paymentMethod'] as String?,
      stripePaymentIntentId: data['stripePaymentIntentId'] as String?,
      notes: data['notes'] as String?,
      termsAndConditions: data['termsAndConditions'] as String?,
      createdAt: timestampToDateTime(data['createdAt']) ?? DateTime.now(),
      sentAt: timestampToDateTime(data['sentAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'invoiceNumber': invoiceNumber,
        'sellerId': sellerId,
        if (buyerId != null) 'buyerId': buyerId,
        'clientName': clientName,
        if (clientEmail != null) 'clientEmail': clientEmail,
        if (clientAddress != null) 'clientAddress': clientAddress!.toMap(),
        'items': items.map((e) => e.toMap()).toList(),
        'subtotal': subtotal,
        'taxRate': taxRate,
        'taxAmount': taxAmount,
        'discount': discount,
        'total': total,
        'currency': currency,
        'status': status.name,
        if (dueDate != null) 'dueDate': dateTimeToTimestamp(dueDate),
        if (paidAt != null) 'paidAt': dateTimeToTimestamp(paidAt),
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (stripePaymentIntentId != null)
          'stripePaymentIntentId': stripePaymentIntentId,
        if (notes != null) 'notes': notes,
        if (termsAndConditions != null)
          'termsAndConditions': termsAndConditions,
        'createdAt': dateTimeToTimestamp(createdAt),
        if (sentAt != null) 'sentAt': dateTimeToTimestamp(sentAt),
      };

  bool get isOverdue =>
      status == InvoiceStatus.sent &&
      dueDate != null &&
      dueDate!.isBefore(DateTime.now());
}

class InvoiceItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double total;

  const InvoiceItem({
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
    required this.total,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) => InvoiceItem(
        description: map['description'] as String,
        quantity: map['quantity'] as int? ?? 1,
        unitPrice: (map['unitPrice'] as num).toDouble(),
        total: (map['total'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'total': total,
      };
}

enum InvoiceStatus { draft, sent, viewed, paid, overdue, cancelled }

// ============================================
// CRM CONTACT
// Firestore: /users/{userId}/business/contacts/{contactId}
// ============================================

class CrmContact {
  final String id;
  final String ownerId; // business owner
  final String? dribaUserId; // if they're on Driba

  // Info
  final String name;
  final String? email;
  final String? phone;
  final String? company;
  final String? avatarUrl;
  final Address? address;

  // CRM fields
  final String stage; // lead, prospect, customer, churned
  final String? source; // driba, referral, website, social
  final double? lifetimeValue;
  final int orderCount;
  final List<String> tags;
  final String? notes;

  // Last interaction
  final DateTime? lastContactedAt;
  final String? lastInteractionType; // order, message, call

  final DateTime createdAt;

  const CrmContact({
    required this.id,
    required this.ownerId,
    this.dribaUserId,
    required this.name,
    this.email,
    this.phone,
    this.company,
    this.avatarUrl,
    this.address,
    this.stage = 'lead',
    this.source,
    this.lifetimeValue,
    this.orderCount = 0,
    this.tags = const [],
    this.notes,
    this.lastContactedAt,
    this.lastInteractionType,
    required this.createdAt,
  });

  factory CrmContact.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CrmContact(
      id: doc.id,
      ownerId: data['ownerId'] as String,
      dribaUserId: data['dribaUserId'] as String?,
      name: data['name'] as String? ?? '',
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      company: data['company'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      address: data['address'] != null
          ? Address.fromMap(Map<String, dynamic>.from(data['address'] as Map))
          : null,
      stage: data['stage'] as String? ?? 'lead',
      source: data['source'] as String?,
      lifetimeValue: (data['lifetimeValue'] as num?)?.toDouble(),
      orderCount: data['orderCount'] as int? ?? 0,
      tags: toStringList(data['tags']),
      notes: data['notes'] as String?,
      lastContactedAt: timestampToDateTime(data['lastContactedAt']),
      lastInteractionType: data['lastInteractionType'] as String?,
      createdAt: timestampToDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        if (dribaUserId != null) 'dribaUserId': dribaUserId,
        'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (company != null) 'company': company,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (address != null) 'address': address!.toMap(),
        'stage': stage,
        if (source != null) 'source': source,
        if (lifetimeValue != null) 'lifetimeValue': lifetimeValue,
        'orderCount': orderCount,
        'tags': tags,
        if (notes != null) 'notes': notes,
        if (lastContactedAt != null)
          'lastContactedAt': dateTimeToTimestamp(lastContactedAt),
        if (lastInteractionType != null)
          'lastInteractionType': lastInteractionType,
        'createdAt': dateTimeToTimestamp(createdAt),
      };
}

// ============================================
// INVENTORY ITEM
// Firestore: /users/{userId}/business/inventory/{itemId}
// ============================================

class InventoryItem {
  final String id;
  final String ownerId;
  final String? postId; // linked product post

  final String name;
  final String? sku;
  final String? barcode;
  final String? imageUrl;
  final String? category;

  final int quantity;
  final int? lowStockThreshold;
  final Price costPrice;
  final Price sellingPrice;

  final String? supplier;
  final String? location; // warehouse, shelf, etc.

  final DateTime createdAt;
  final DateTime? lastRestockedAt;

  const InventoryItem({
    required this.id,
    required this.ownerId,
    this.postId,
    required this.name,
    this.sku,
    this.barcode,
    this.imageUrl,
    this.category,
    this.quantity = 0,
    this.lowStockThreshold,
    required this.costPrice,
    required this.sellingPrice,
    this.supplier,
    this.location,
    required this.createdAt,
    this.lastRestockedAt,
  });

  factory InventoryItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryItem(
      id: doc.id,
      ownerId: data['ownerId'] as String,
      postId: data['postId'] as String?,
      name: data['name'] as String,
      sku: data['sku'] as String?,
      barcode: data['barcode'] as String?,
      imageUrl: data['imageUrl'] as String?,
      category: data['category'] as String?,
      quantity: data['quantity'] as int? ?? 0,
      lowStockThreshold: data['lowStockThreshold'] as int?,
      costPrice: Price.fromMap(
          Map<String, dynamic>.from(data['costPrice'] as Map)),
      sellingPrice: Price.fromMap(
          Map<String, dynamic>.from(data['sellingPrice'] as Map)),
      supplier: data['supplier'] as String?,
      location: data['location'] as String?,
      createdAt: timestampToDateTime(data['createdAt']) ?? DateTime.now(),
      lastRestockedAt: timestampToDateTime(data['lastRestockedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        if (postId != null) 'postId': postId,
        'name': name,
        if (sku != null) 'sku': sku,
        if (barcode != null) 'barcode': barcode,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (category != null) 'category': category,
        'quantity': quantity,
        if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold,
        'costPrice': costPrice.toMap(),
        'sellingPrice': sellingPrice.toMap(),
        if (supplier != null) 'supplier': supplier,
        if (location != null) 'location': location,
        'createdAt': dateTimeToTimestamp(createdAt),
        if (lastRestockedAt != null)
          'lastRestockedAt': dateTimeToTimestamp(lastRestockedAt),
      };

  bool get isLowStock =>
      lowStockThreshold != null && quantity <= lowStockThreshold!;
  bool get isOutOfStock => quantity <= 0;
  double get profit => sellingPrice.amount - costPrice.amount;
  double get margin =>
      sellingPrice.amount > 0 ? (profit / sellingPrice.amount) * 100 : 0;
}

// ============================================
// CAMPAIGN (Marketing)
// Firestore: /campaigns/{campaignId}
// ============================================

class Campaign {
  final String id;
  final String authorId;
  final String name;
  final String? description;
  final CampaignType type;
  final CampaignStatus status;

  // Targeting
  final List<String> targetScreens; // which screens to show on
  final List<String> targetTags;
  final Address? targetLocation;
  final double? targetRadius;

  // Content
  final String? headline;
  final String? body;
  final MediaItem? media;
  final String? ctaLabel;
  final String? ctaUrl;
  final String? linkedPostId;

  // Budget & Schedule
  final double? budget;
  final double? spent;
  final DateTime? startDate;
  final DateTime? endDate;

  // Performance
  final int impressions;
  final int clicks;
  final int conversions;
  final double? revenue;

  final DateTime createdAt;

  const Campaign({
    required this.id,
    required this.authorId,
    required this.name,
    this.description,
    this.type = CampaignType.promoted,
    this.status = CampaignStatus.draft,
    this.targetScreens = const [],
    this.targetTags = const [],
    this.targetLocation,
    this.targetRadius,
    this.headline,
    this.body,
    this.media,
    this.ctaLabel,
    this.ctaUrl,
    this.linkedPostId,
    this.budget,
    this.spent,
    this.startDate,
    this.endDate,
    this.impressions = 0,
    this.clicks = 0,
    this.conversions = 0,
    this.revenue,
    required this.createdAt,
  });

  factory Campaign.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Campaign(
      id: doc.id,
      authorId: data['author'] as String? ?? data['authorId'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      type: CampaignType.values.firstWhere(
        (e) => e.name == (data['type'] as String? ?? 'promoted'),
        orElse: () => CampaignType.promoted,
      ),
      status: CampaignStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'draft'),
        orElse: () => CampaignStatus.draft,
      ),
      targetScreens: toStringList(data['targetScreens']),
      targetTags: toStringList(data['targetTags']),
      targetLocation: data['targetLocation'] != null
          ? Address.fromMap(
              Map<String, dynamic>.from(data['targetLocation'] as Map))
          : null,
      targetRadius: (data['targetRadius'] as num?)?.toDouble(),
      headline: data['headline'] as String?,
      body: data['body'] as String?,
      media: data['media'] != null
          ? MediaItem.fromMap(Map<String, dynamic>.from(data['media'] as Map))
          : null,
      ctaLabel: data['ctaLabel'] as String?,
      ctaUrl: data['ctaUrl'] as String?,
      linkedPostId: data['linkedPostId'] as String?,
      budget: (data['budget'] as num?)?.toDouble(),
      spent: (data['spent'] as num?)?.toDouble(),
      startDate: timestampToDateTime(data['startDate']),
      endDate: timestampToDateTime(data['endDate']),
      impressions: data['impressions'] as int? ?? 0,
      clicks: data['clicks'] as int? ?? 0,
      conversions: data['conversions'] as int? ?? 0,
      revenue: (data['revenue'] as num?)?.toDouble(),
      createdAt: timestampToDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'author': authorId, // for firestore rules
        'name': name,
        if (description != null) 'description': description,
        'type': type.name,
        'status': status.name,
        'targetScreens': targetScreens,
        'targetTags': targetTags,
        if (targetLocation != null) 'targetLocation': targetLocation!.toMap(),
        if (targetRadius != null) 'targetRadius': targetRadius,
        if (headline != null) 'headline': headline,
        if (body != null) 'body': body,
        if (media != null) 'media': media!.toMap(),
        if (ctaLabel != null) 'ctaLabel': ctaLabel,
        if (ctaUrl != null) 'ctaUrl': ctaUrl,
        if (linkedPostId != null) 'linkedPostId': linkedPostId,
        if (budget != null) 'budget': budget,
        if (spent != null) 'spent': spent,
        if (startDate != null) 'startDate': dateTimeToTimestamp(startDate),
        if (endDate != null) 'endDate': dateTimeToTimestamp(endDate),
        'impressions': impressions,
        'clicks': clicks,
        'conversions': conversions,
        if (revenue != null) 'revenue': revenue,
        'createdAt': dateTimeToTimestamp(createdAt),
      };

  double get ctr => impressions > 0 ? (clicks / impressions) * 100 : 0;
  double get conversionRate =>
      clicks > 0 ? (conversions / clicks) * 100 : 0;
}

enum CampaignType { promoted, discount, announcement, seasonal }
enum CampaignStatus { draft, active, paused, completed, cancelled }
