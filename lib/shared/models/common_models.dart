import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================
// COMMON TYPES - Used across all Driba models
// ============================================

/// Geographic coordinate pair
class GeoPoint2 {
  final double latitude;
  final double longitude;

  const GeoPoint2({required this.latitude, required this.longitude});

  factory GeoPoint2.fromMap(Map<String, dynamic> map) => GeoPoint2(
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
      );

  factory GeoPoint2.fromGeoPoint(GeoPoint gp) =>
      GeoPoint2(latitude: gp.latitude, longitude: gp.longitude);

  Map<String, dynamic> toMap() => {'latitude': latitude, 'longitude': longitude};
  GeoPoint toGeoPoint() => GeoPoint(latitude, longitude);
}

/// Physical address
class Address {
  final String? line1;
  final String? line2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final GeoPoint2? coordinates;

  const Address({
    this.line1,
    this.line2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.coordinates,
  });

  factory Address.fromMap(Map<String, dynamic> map) => Address(
        line1: map['line1'] as String?,
        line2: map['line2'] as String?,
        city: map['city'] as String?,
        state: map['state'] as String?,
        postalCode: map['postalCode'] as String?,
        country: map['country'] as String?,
        coordinates: map['coordinates'] != null
            ? GeoPoint2.fromMap(Map<String, dynamic>.from(map['coordinates']))
            : null,
      );

  Map<String, dynamic> toMap() => {
        if (line1 != null) 'line1': line1,
        if (line2 != null) 'line2': line2,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (postalCode != null) 'postalCode': postalCode,
        if (country != null) 'country': country,
        if (coordinates != null) 'coordinates': coordinates!.toMap(),
      };

  String get formatted =>
      [line1, line2, city, state, postalCode, country]
          .where((s) => s != null && s.isNotEmpty)
          .join(', ');
}

/// Media attachment (image, video, audio, document)
class MediaItem {
  final String url;
  final String type; // image, video, audio, document
  final String? thumbnailUrl;
  final int? width;
  final int? height;
  final int? durationMs; // for video/audio
  final int? sizeBytes;
  final String? mimeType;
  final String? blurhash; // placeholder blur hash

  const MediaItem({
    required this.url,
    required this.type,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.durationMs,
    this.sizeBytes,
    this.mimeType,
    this.blurhash,
  });

  factory MediaItem.fromMap(Map<String, dynamic> map) => MediaItem(
        url: map['url'] as String,
        type: map['type'] as String,
        thumbnailUrl: map['thumbnailUrl'] as String?,
        width: map['width'] as int?,
        height: map['height'] as int?,
        durationMs: map['durationMs'] as int?,
        sizeBytes: map['sizeBytes'] as int?,
        mimeType: map['mimeType'] as String?,
        blurhash: map['blurhash'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'url': url,
        'type': type,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (durationMs != null) 'durationMs': durationMs,
        if (sizeBytes != null) 'sizeBytes': sizeBytes,
        if (mimeType != null) 'mimeType': mimeType,
        if (blurhash != null) 'blurhash': blurhash,
      };

  bool get isVideo => type == 'video';
  bool get isImage => type == 'image';
  bool get isAudio => type == 'audio';
}

/// Price with currency
class Price {
  final double amount;
  final String currency; // ISO 4217: USD, EUR, MAD, etc.
  final double? originalAmount; // for discounts

  const Price({
    required this.amount,
    this.currency = 'USD',
    this.originalAmount,
  });

  factory Price.fromMap(Map<String, dynamic> map) => Price(
        amount: (map['amount'] as num).toDouble(),
        currency: map['currency'] as String? ?? 'USD',
        originalAmount: (map['originalAmount'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'currency': currency,
        if (originalAmount != null) 'originalAmount': originalAmount,
      };

  bool get hasDiscount => originalAmount != null && originalAmount! > amount;
  double get discountPercent =>
      hasDiscount ? ((originalAmount! - amount) / originalAmount! * 100) : 0;

  String get formatted => '\$${amount.toStringAsFixed(2)}';
}

/// Operating hours for a single day
class DayHours {
  final String day; // monday, tuesday, etc.
  final String? openTime; // "09:00"
  final String? closeTime; // "22:00"
  final bool isClosed;

  const DayHours({
    required this.day,
    this.openTime,
    this.closeTime,
    this.isClosed = false,
  });

  factory DayHours.fromMap(Map<String, dynamic> map) => DayHours(
        day: map['day'] as String,
        openTime: map['openTime'] as String?,
        closeTime: map['closeTime'] as String?,
        isClosed: map['isClosed'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'day': day,
        if (openTime != null) 'openTime': openTime,
        if (closeTime != null) 'closeTime': closeTime,
        'isClosed': isClosed,
      };
}

/// Rating aggregate
class RatingInfo {
  final double average;
  final int count;
  final Map<int, int>? distribution; // {5: 120, 4: 80, 3: 20, ...}

  const RatingInfo({
    this.average = 0,
    this.count = 0,
    this.distribution,
  });

  factory RatingInfo.fromMap(Map<String, dynamic> map) => RatingInfo(
        average: (map['average'] as num?)?.toDouble() ?? 0,
        count: map['count'] as int? ?? 0,
        distribution: map['distribution'] != null
            ? Map<int, int>.from(
                (map['distribution'] as Map).map(
                  (k, v) => MapEntry(int.parse(k.toString()), v as int),
                ),
              )
            : null,
      );

  Map<String, dynamic> toMap() => {
        'average': average,
        'count': count,
        if (distribution != null)
          'distribution': distribution!.map((k, v) => MapEntry(k.toString(), v)),
      };
}

/// Social link (LinkedIn, Twitter, website, etc.)
class SocialLink {
  final String platform; // website, twitter, instagram, linkedin, github, tiktok
  final String url;
  final String? username;

  const SocialLink({required this.platform, required this.url, this.username});

  factory SocialLink.fromMap(Map<String, dynamic> map) => SocialLink(
        platform: map['platform'] as String,
        url: map['url'] as String,
      );

  Map<String, dynamic> toMap() => {'platform': platform, 'url': url};
}

// ============================================
// SHARED ENUMS
// ============================================

/// Content visibility
enum Visibility { public, followers, private }

/// Content status
enum ContentStatus { draft, published, archived, flagged, removed }

/// Verification status
enum VerificationStatus { none, pending, verified, rejected }

/// Payment status
enum PaymentStatus { pending, processing, completed, failed, refunded }

// ============================================
// HELPERS
// ============================================

/// Safe Firestore timestamp conversion
DateTime? timestampToDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

/// Convert DateTime to Firestore Timestamp
Timestamp? dateTimeToTimestamp(DateTime? dt) {
  return dt != null ? Timestamp.fromDate(dt) : null;
}

/// Safe list cast from Firestore
List<String> toStringList(dynamic value) {
  if (value == null) return [];
  return (value as List).map((e) => e.toString()).toList();
}

/// Safe map cast from Firestore
List<T> toModelList<T>(dynamic value, T Function(Map<String, dynamic>) fromMap) {
  if (value == null) return [];
  return (value as List)
      .map((e) => fromMap(Map<String, dynamic>.from(e as Map)))
      .toList();
}
