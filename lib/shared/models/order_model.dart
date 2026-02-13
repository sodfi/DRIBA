import 'package:cloud_firestore/cloud_firestore.dart';
import 'common_models.dart';
import 'user_model.dart';

// ============================================
// ORDER MODEL
// Firestore: /orders/{orderId}
//
// Unified order for everything:
// - Product purchase
// - Food delivery
// - Service booking
// - Travel/accommodation booking
// - Event ticket
//
// 0% transaction fees - users keep 100%
// ============================================

class Order {
  final String id;
  final String orderNumber; // human-readable: DRB-2026-001234

  // Parties
  final UserRef buyer;
  final UserRef seller;
  final String? chatId; // linked chat for this order

  // Type
  final OrderType type;
  final OrderStatus status;

  // Items
  final List<OrderItem> items;
  final OrderPricing pricing;

  // Delivery / Fulfillment
  final FulfillmentInfo fulfillment;

  // Payment
  final PaymentInfo payment;

  // Booking (for services/travel/events)
  final BookingInfo? booking;

  // Delivery tracking (for food/products)
  final DeliveryTracking? delivery;

  // Review
  final String? reviewId; // link to review after completion
  final bool buyerReviewed;
  final bool sellerReviewed;

  // Notes
  final String? buyerNote;
  final String? sellerNote;
  final String? cancellationReason;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.buyer,
    required this.seller,
    this.chatId,
    required this.type,
    this.status = OrderStatus.pending,
    required this.items,
    required this.pricing,
    required this.fulfillment,
    required this.payment,
    this.booking,
    this.delivery,
    this.reviewId,
    this.buyerReviewed = false,
    this.sellerReviewed = false,
    this.buyerNote,
    this.sellerNote,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.cancelledAt,
  });

  factory Order.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order.fromMap(data, doc.id);
  }

  factory Order.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Order(
      id: docId ?? map['id'] as String,
      orderNumber: map['orderNumber'] as String? ?? '',
      buyer: UserRef.fromMap(Map<String, dynamic>.from(map['buyer'] as Map)),
      seller: UserRef.fromMap(Map<String, dynamic>.from(map['seller'] as Map)),
      chatId: map['chatId'] as String?,
      type: OrderType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'product'),
        orElse: () => OrderType.product,
      ),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      items: toModelList(map['items'], OrderItem.fromMap),
      pricing: map['pricing'] != null
          ? OrderPricing.fromMap(Map<String, dynamic>.from(map['pricing'] as Map))
          : const OrderPricing(),
      fulfillment: map['fulfillment'] != null
          ? FulfillmentInfo.fromMap(
              Map<String, dynamic>.from(map['fulfillment'] as Map))
          : const FulfillmentInfo(),
      payment: map['payment'] != null
          ? PaymentInfo.fromMap(Map<String, dynamic>.from(map['payment'] as Map))
          : const PaymentInfo(),
      booking: map['booking'] != null
          ? BookingInfo.fromMap(Map<String, dynamic>.from(map['booking'] as Map))
          : null,
      delivery: map['delivery'] != null
          ? DeliveryTracking.fromMap(
              Map<String, dynamic>.from(map['delivery'] as Map))
          : null,
      reviewId: map['reviewId'] as String?,
      buyerReviewed: map['buyerReviewed'] as bool? ?? false,
      sellerReviewed: map['sellerReviewed'] as bool? ?? false,
      buyerNote: map['buyerNote'] as String?,
      sellerNote: map['sellerNote'] as String?,
      cancellationReason: map['cancellationReason'] as String?,
      createdAt: timestampToDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: timestampToDateTime(map['updatedAt']) ?? DateTime.now(),
      completedAt: timestampToDateTime(map['completedAt']),
      cancelledAt: timestampToDateTime(map['cancelledAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'orderNumber': orderNumber,
        'buyer': buyer.toMap(),
        'seller': seller.toMap(),
        if (chatId != null) 'chatId': chatId,
        'type': type.name,
        'status': status.name,
        'items': items.map((e) => e.toMap()).toList(),
        'pricing': pricing.toMap(),
        'fulfillment': fulfillment.toMap(),
        'payment': payment.toMap(),
        if (booking != null) 'booking': booking!.toMap(),
        if (delivery != null) 'delivery': delivery!.toMap(),
        if (reviewId != null) 'reviewId': reviewId,
        'buyerReviewed': buyerReviewed,
        'sellerReviewed': sellerReviewed,
        if (buyerNote != null) 'buyerNote': buyerNote,
        if (sellerNote != null) 'sellerNote': sellerNote,
        if (cancellationReason != null) 'cancellationReason': cancellationReason,
        'createdAt': dateTimeToTimestamp(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
        if (completedAt != null) 'completedAt': dateTimeToTimestamp(completedAt),
        if (cancelledAt != null) 'cancelledAt': dateTimeToTimestamp(cancelledAt),
      };

  bool get isActive =>
      status != OrderStatus.completed &&
      status != OrderStatus.cancelled &&
      status != OrderStatus.refunded;
}

enum OrderType { product, food, service, booking, event, rental }

enum OrderStatus {
  pending,     // just created
  confirmed,   // seller accepted
  preparing,   // being prepared (food) or packaged (product)
  inTransit,   // on the way
  delivered,   // arrived
  completed,   // both parties confirmed
  cancelled,
  refunded,
  disputed,
}

// ============================================
// ORDER ITEM
// ============================================

class OrderItem {
  final String postId; // reference to the post
  final String name;
  final String? imageUrl;
  final int quantity;
  final Price unitPrice;
  final String? variantId;
  final String? variantName;
  final String? specialInstructions;

  const OrderItem({
    required this.postId,
    required this.name,
    this.imageUrl,
    this.quantity = 1,
    required this.unitPrice,
    this.variantId,
    this.variantName,
    this.specialInstructions,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        postId: map['postId'] as String,
        name: map['name'] as String,
        imageUrl: map['imageUrl'] as String?,
        quantity: map['quantity'] as int? ?? 1,
        unitPrice: Price.fromMap(Map<String, dynamic>.from(map['unitPrice'] as Map)),
        variantId: map['variantId'] as String?,
        variantName: map['variantName'] as String?,
        specialInstructions: map['specialInstructions'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'name': name,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'quantity': quantity,
        'unitPrice': unitPrice.toMap(),
        if (variantId != null) 'variantId': variantId,
        if (variantName != null) 'variantName': variantName,
        if (specialInstructions != null) 'specialInstructions': specialInstructions,
      };

  double get total => unitPrice.amount * quantity;
}

// ============================================
// ORDER PRICING - Breakdown of costs
// 0% platform fee!
// ============================================

class OrderPricing {
  final double subtotal;
  final double deliveryFee;
  final double serviceFee; // always 0 — Driba's promise
  final double tax;
  final double discount;
  final double tip;
  final double total;
  final String currency;

  const OrderPricing({
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.serviceFee = 0, // 0% forever
    this.tax = 0,
    this.discount = 0,
    this.tip = 0,
    this.total = 0,
    this.currency = 'USD',
  });

  factory OrderPricing.fromMap(Map<String, dynamic> map) => OrderPricing(
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
        deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0,
        serviceFee: (map['serviceFee'] as num?)?.toDouble() ?? 0,
        tax: (map['tax'] as num?)?.toDouble() ?? 0,
        discount: (map['discount'] as num?)?.toDouble() ?? 0,
        tip: (map['tip'] as num?)?.toDouble() ?? 0,
        total: (map['total'] as num?)?.toDouble() ?? 0,
        currency: map['currency'] as String? ?? 'USD',
      );

  Map<String, dynamic> toMap() => {
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'serviceFee': serviceFee,
        'tax': tax,
        'discount': discount,
        'tip': tip,
        'total': total,
        'currency': currency,
      };

  /// Calculate total from components
  factory OrderPricing.calculate({
    required List<OrderItem> items,
    double deliveryFee = 0,
    double tax = 0,
    double discount = 0,
    double tip = 0,
    String currency = 'USD',
  }) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    return OrderPricing(
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: 0, // 0% always
      tax: tax,
      discount: discount,
      tip: tip,
      total: subtotal + deliveryFee + tax - discount + tip,
      currency: currency,
    );
  }
}

// ============================================
// FULFILLMENT INFO
// ============================================

class FulfillmentInfo {
  final String method; // delivery, pickup, digital, onsite, remote
  final Address? deliveryAddress;
  final Address? pickupAddress;
  final String? estimatedTime; // "30-45 min", "2-3 days"
  final String? trackingNumber;
  final String? trackingUrl;

  const FulfillmentInfo({
    this.method = 'delivery',
    this.deliveryAddress,
    this.pickupAddress,
    this.estimatedTime,
    this.trackingNumber,
    this.trackingUrl,
  });

  factory FulfillmentInfo.fromMap(Map<String, dynamic> map) => FulfillmentInfo(
        method: map['method'] as String? ?? 'delivery',
        deliveryAddress: map['deliveryAddress'] != null
            ? Address.fromMap(
                Map<String, dynamic>.from(map['deliveryAddress'] as Map))
            : null,
        pickupAddress: map['pickupAddress'] != null
            ? Address.fromMap(
                Map<String, dynamic>.from(map['pickupAddress'] as Map))
            : null,
        estimatedTime: map['estimatedTime'] as String?,
        trackingNumber: map['trackingNumber'] as String?,
        trackingUrl: map['trackingUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'method': method,
        if (deliveryAddress != null) 'deliveryAddress': deliveryAddress!.toMap(),
        if (pickupAddress != null) 'pickupAddress': pickupAddress!.toMap(),
        if (estimatedTime != null) 'estimatedTime': estimatedTime,
        if (trackingNumber != null) 'trackingNumber': trackingNumber,
        if (trackingUrl != null) 'trackingUrl': trackingUrl,
      };
}

// ============================================
// PAYMENT INFO
// ============================================

class PaymentInfo {
  final PaymentStatus status;
  final String method; // card, apple_pay, google_pay, cash
  final String? stripePaymentIntentId;
  final String? stripeTransferId; // payout to seller
  final double? paidAmount;
  final DateTime? paidAt;

  const PaymentInfo({
    this.status = PaymentStatus.pending,
    this.method = 'card',
    this.stripePaymentIntentId,
    this.stripeTransferId,
    this.paidAmount,
    this.paidAt,
  });

  factory PaymentInfo.fromMap(Map<String, dynamic> map) => PaymentInfo(
        status: PaymentStatus.values.firstWhere(
          (e) => e.name == (map['status'] as String? ?? 'pending'),
          orElse: () => PaymentStatus.pending,
        ),
        method: map['method'] as String? ?? 'card',
        stripePaymentIntentId: map['stripePaymentIntentId'] as String?,
        stripeTransferId: map['stripeTransferId'] as String?,
        paidAmount: (map['paidAmount'] as num?)?.toDouble(),
        paidAt: timestampToDateTime(map['paidAt']),
      );

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'method': method,
        if (stripePaymentIntentId != null)
          'stripePaymentIntentId': stripePaymentIntentId,
        if (stripeTransferId != null) 'stripeTransferId': stripeTransferId,
        if (paidAmount != null) 'paidAmount': paidAmount,
        if (paidAt != null) 'paidAt': dateTimeToTimestamp(paidAt),
      };
}

// ============================================
// BOOKING INFO - For services, travel, events
// ============================================

class BookingInfo {
  final DateTime startAt;
  final DateTime? endAt;
  final int? durationMinutes;
  final int? guestCount;
  final String? timezone;
  final List<String>? addOns; // extra services selected
  final String? confirmationCode;

  const BookingInfo({
    required this.startAt,
    this.endAt,
    this.durationMinutes,
    this.guestCount,
    this.timezone,
    this.addOns,
    this.confirmationCode,
  });

  factory BookingInfo.fromMap(Map<String, dynamic> map) => BookingInfo(
        startAt: timestampToDateTime(map['startAt']) ?? DateTime.now(),
        endAt: timestampToDateTime(map['endAt']),
        durationMinutes: map['durationMinutes'] as int?,
        guestCount: map['guestCount'] as int?,
        timezone: map['timezone'] as String?,
        addOns: map['addOns'] != null ? toStringList(map['addOns']) : null,
        confirmationCode: map['confirmationCode'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'startAt': dateTimeToTimestamp(startAt),
        if (endAt != null) 'endAt': dateTimeToTimestamp(endAt),
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (guestCount != null) 'guestCount': guestCount,
        if (timezone != null) 'timezone': timezone,
        if (addOns != null) 'addOns': addOns,
        if (confirmationCode != null) 'confirmationCode': confirmationCode,
      };
}

// ============================================
// DELIVERY TRACKING - Real-time food/product delivery
// ============================================

class DeliveryTracking {
  final String? driverName;
  final String? driverPhone;
  final String? driverAvatarUrl;
  final GeoPoint2? driverLocation; // real-time
  final List<TrackingEvent> events;
  final int? estimatedMinutes;

  const DeliveryTracking({
    this.driverName,
    this.driverPhone,
    this.driverAvatarUrl,
    this.driverLocation,
    this.events = const [],
    this.estimatedMinutes,
  });

  factory DeliveryTracking.fromMap(Map<String, dynamic> map) => DeliveryTracking(
        driverName: map['driverName'] as String?,
        driverPhone: map['driverPhone'] as String?,
        driverAvatarUrl: map['driverAvatarUrl'] as String?,
        driverLocation: map['driverLocation'] != null
            ? GeoPoint2.fromMap(
                Map<String, dynamic>.from(map['driverLocation'] as Map))
            : null,
        events: toModelList(map['events'], TrackingEvent.fromMap),
        estimatedMinutes: map['estimatedMinutes'] as int?,
      );

  Map<String, dynamic> toMap() => {
        if (driverName != null) 'driverName': driverName,
        if (driverPhone != null) 'driverPhone': driverPhone,
        if (driverAvatarUrl != null) 'driverAvatarUrl': driverAvatarUrl,
        if (driverLocation != null) 'driverLocation': driverLocation!.toMap(),
        'events': events.map((e) => e.toMap()).toList(),
        if (estimatedMinutes != null) 'estimatedMinutes': estimatedMinutes,
      };

  TrackingEvent? get latestEvent => events.isNotEmpty ? events.last : null;
}

class TrackingEvent {
  final String status; // confirmed, preparing, picked_up, on_the_way, delivered
  final String description;
  final DateTime timestamp;

  const TrackingEvent({
    required this.status,
    required this.description,
    required this.timestamp,
  });

  factory TrackingEvent.fromMap(Map<String, dynamic> map) => TrackingEvent(
        status: map['status'] as String,
        description: map['description'] as String? ?? '',
        timestamp: timestampToDateTime(map['timestamp']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'status': status,
        'description': description,
        'timestamp': dateTimeToTimestamp(timestamp),
      };
}

// ============================================
// REVIEW
// Firestore: /reviews/{reviewId}
// ============================================

class Review {
  final String id;
  final String orderId;
  final String postId;
  final UserRef reviewer;
  final UserRef reviewee;
  final int rating; // 1-5
  final String? text;
  final List<MediaItem> media; // review photos
  final String? sellerResponse;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.orderId,
    required this.postId,
    required this.reviewer,
    required this.reviewee,
    required this.rating,
    this.text,
    this.media = const [],
    this.sellerResponse,
    required this.createdAt,
  });

  factory Review.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      orderId: data['orderId'] as String,
      postId: data['postId'] as String,
      reviewer: UserRef.fromMap(
          Map<String, dynamic>.from(data['reviewer'] as Map)),
      reviewee: UserRef.fromMap(
          Map<String, dynamic>.from(data['reviewee'] as Map)),
      rating: data['rating'] as int,
      text: data['text'] as String?,
      media: toModelList(data['media'], MediaItem.fromMap),
      sellerResponse: data['sellerResponse'] as String?,
      createdAt: timestampToDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'postId': postId,
        'reviewer': reviewer.toMap(),
        'reviewee': reviewee.toMap(),
        'rating': rating,
        if (text != null) 'text': text,
        'media': media.map((e) => e.toMap()).toList(),
        if (sellerResponse != null) 'sellerResponse': sellerResponse,
        'createdAt': dateTimeToTimestamp(createdAt),
      };
}
