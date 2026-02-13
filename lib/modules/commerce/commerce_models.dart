// ============================================
// COMMERCE MODELS & DEMO DATA
//
// Gold accent (#FFD700) marketplace
// Products, digital goods, services, sellers
// ============================================

class CommerceCategory {
  final String id;
  final String name;
  final String emoji;

  const CommerceCategory({required this.id, required this.name, required this.emoji});
}

class CommerceSeller {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isVerified;
  final double rating;
  final int salesCount;
  final String location;

  const CommerceSeller({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.isVerified = false,
    this.rating = 0,
    this.salesCount = 0,
    this.location = '',
  });
}

class CommerceProduct {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String currency;
  final List<String> imageUrls;
  final CommerceSeller seller;
  final List<String> categoryTags;
  final double rating;
  final int reviewCount;
  final int salesCount;
  final bool isFeatured;
  final bool isDigital;
  final bool isFreeShipping;
  final int? stockCount;
  final List<ProductVariantGroup> variants;
  final List<String> highlights; // bullet points
  final List<ProductReview> reviews;
  final String? badge; // "BESTSELLER", "NEW", "LIMITED"

  const CommerceProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    this.currency = 'USD',
    required this.imageUrls,
    required this.seller,
    required this.categoryTags,
    this.rating = 0,
    this.reviewCount = 0,
    this.salesCount = 0,
    this.isFeatured = false,
    this.isDigital = false,
    this.isFreeShipping = false,
    this.stockCount,
    this.variants = const [],
    this.highlights = const [],
    this.reviews = const [],
    this.badge,
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  double get discountPercent =>
      hasDiscount ? ((originalPrice! - price) / originalPrice! * 100) : 0;
  bool get inStock => stockCount == null || stockCount! > 0;
}

class ProductVariantGroup {
  final String name; // "Size", "Color"
  final List<ProductVariantOption> options;

  const ProductVariantGroup({required this.name, required this.options});
}

class ProductVariantOption {
  final String label;
  final double? priceAdd;
  final bool available;
  final String? colorHex; // for color swatches

  const ProductVariantOption({
    required this.label,
    this.priceAdd,
    this.available = true,
    this.colorHex,
  });
}

class ProductReview {
  final String userName;
  final String? avatarUrl;
  final double rating;
  final String text;
  final DateTime date;
  final int helpfulCount;

  const ProductReview({
    required this.userName,
    this.avatarUrl,
    required this.rating,
    required this.text,
    required this.date,
    this.helpfulCount = 0,
  });
}

class CommerceCartItem {
  final CommerceProduct product;
  final int quantity;
  final Map<String, String> selectedVariants; // group → option

  const CommerceCartItem({
    required this.product,
    this.quantity = 1,
    this.selectedVariants = const {},
  });

  double get total => product.price * quantity;

  CommerceCartItem copyWith({int? quantity, Map<String, String>? selectedVariants}) {
    return CommerceCartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      selectedVariants: selectedVariants ?? this.selectedVariants,
    );
  }
}

// ============================================
// DEMO DATA
// ============================================

class CommerceDemoData {
  CommerceDemoData._();

  static const List<CommerceCategory> categories = [
    CommerceCategory(id: 'all', name: 'All', emoji: '🛍️'),
    CommerceCategory(id: 'trending', name: 'Trending', emoji: '🔥'),
    CommerceCategory(id: 'digital', name: 'Digital', emoji: '💻'),
    CommerceCategory(id: 'fashion', name: 'Fashion', emoji: '👗'),
    CommerceCategory(id: 'tech', name: 'Tech', emoji: '📱'),
    CommerceCategory(id: 'art', name: 'Art', emoji: '🎨'),
    CommerceCategory(id: 'home', name: 'Home', emoji: '🏠'),
    CommerceCategory(id: 'beauty', name: 'Beauty', emoji: '✨'),
    CommerceCategory(id: 'handmade', name: 'Handmade', emoji: '🧶'),
    CommerceCategory(id: 'services', name: 'Services', emoji: '🔧'),
  ];

  // ── Sellers ─────────────────────────────────

  static const _sellerAmal = CommerceSeller(
    id: 'seller_1',
    name: 'Amal Design Studio',
    avatarUrl: 'https://i.pravatar.cc/150?img=45',
    isVerified: true,
    rating: 4.9,
    salesCount: 1247,
    location: 'London',
  );

  static const _sellerZaki = CommerceSeller(
    id: 'seller_2',
    name: 'Zaki Tech',
    avatarUrl: 'https://i.pravatar.cc/150?img=52',
    isVerified: true,
    rating: 4.7,
    salesCount: 834,
    location: 'Rabat',
  );

  static const _sellerNora = CommerceSeller(
    id: 'seller_3',
    name: 'Nora Artisan',
    avatarUrl: 'https://i.pravatar.cc/150?img=38',
    isVerified: false,
    rating: 4.8,
    salesCount: 412,
    location: 'Milan',
  );

  static const _sellerRiad = CommerceSeller(
    id: 'seller_4',
    name: 'Riad Digital',
    avatarUrl: 'https://i.pravatar.cc/150?img=60',
    isVerified: true,
    rating: 4.6,
    salesCount: 2103,
    location: 'London',
  );

  static const _sellerYasmin = CommerceSeller(
    id: 'seller_5',
    name: 'Yasmin Beauty Co.',
    avatarUrl: 'https://i.pravatar.cc/150?img=26',
    isVerified: true,
    rating: 4.9,
    salesCount: 567,
    location: 'Tangier',
  );

  // ── Products ────────────────────────────────

  static final List<CommerceProduct> products = [
    CommerceProduct(
      id: 'prod_1',
      name: 'Handcrafted Italian Leather Bag',
      description:
          'Authentic handcrafted leather bag from the workshops of Florence. Each piece is unique, made by master artisans using traditional techniques passed down through generations. Premium vegetable-tanned leather with brass hardware.',
      price: 89.99,
      originalPrice: 129.99,
      imageUrls: [
        'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=600',
        'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=600',
      ],
      seller: _sellerNora,
      categoryTags: ['fashion', 'handmade', 'trending'],
      rating: 4.8,
      reviewCount: 156,
      salesCount: 342,
      isFeatured: true,
      isFreeShipping: true,
      badge: 'BESTSELLER',
      variants: [
        ProductVariantGroup(name: 'Color', options: [
          ProductVariantOption(label: 'Tan', colorHex: '#C4956A'),
          ProductVariantOption(label: 'Dark Brown', colorHex: '#5C3317'),
          ProductVariantOption(label: 'Black', colorHex: '#1A1A1A'),
        ]),
        ProductVariantGroup(name: 'Size', options: [
          ProductVariantOption(label: 'Medium'),
          ProductVariantOption(label: 'Large', priceAdd: 15.00),
        ]),
      ],
      highlights: [
        '100% genuine Italian leather',
        'Handcrafted by master artisans in Tuscany',
        'Brass hardware with antique finish',
        'Interior zip pocket + phone slot',
        'Ships from Florence within 3-5 days',
      ],
      reviews: _bagReviews,
    ),
    CommerceProduct(
      id: 'prod_2',
      name: 'Premium UI Design Kit — 500+ Components',
      description:
          'Complete Figma design system with 500+ production-ready components, dark mode, responsive layouts, and design tokens. Perfect for SaaS, mobile apps, and dashboards. Free lifetime updates included.',
      price: 49.00,
      originalPrice: 79.00,
      imageUrls: [
        'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=600',
        'https://images.unsplash.com/photo-1586717791821-3f44a563fa4c?w=600',
      ],
      seller: _sellerRiad,
      categoryTags: ['digital', 'tech', 'trending'],
      rating: 4.9,
      reviewCount: 89,
      salesCount: 1203,
      isFeatured: true,
      isDigital: true,
      badge: 'TOP RATED',
      highlights: [
        '500+ production-ready Figma components',
        'Dark + Light mode included',
        'Auto-layout & responsive',
        'Design tokens for developers',
        'Free lifetime updates',
      ],
      reviews: _digitalReviews,
    ),
    CommerceProduct(
      id: 'prod_3',
      name: 'Wireless Noise-Cancelling Earbuds Pro',
      description:
          'Crystal-clear audio with adaptive noise cancellation. 36-hour battery life with case, IPX5 water resistance, spatial audio, and ultra-low latency mode for gaming. USB-C fast charging.',
      price: 79.99,
      originalPrice: 119.99,
      imageUrls: [
        'https://images.unsplash.com/photo-1590658268037-6bf12f032f55?w=600',
        'https://images.unsplash.com/photo-1606220588913-b3aacb4d2f46?w=600',
      ],
      seller: _sellerZaki,
      categoryTags: ['tech', 'trending'],
      rating: 4.6,
      reviewCount: 234,
      salesCount: 567,
      isFeatured: true,
      isFreeShipping: true,
      badge: 'NEW',
      variants: [
        ProductVariantGroup(name: 'Color', options: [
          ProductVariantOption(label: 'Midnight Black', colorHex: '#1A1A2E'),
          ProductVariantOption(label: 'Pearl White', colorHex: '#F5F5F5'),
          ProductVariantOption(label: 'Ocean Blue', colorHex: '#1E90FF'),
        ]),
      ],
      highlights: [
        'Adaptive noise cancellation (ANC)',
        '36-hour total battery life',
        'IPX5 water resistant',
        'Spatial audio with head tracking',
        'USB-C fast charge: 10min = 2hrs',
      ],
      reviews: _techReviews,
    ),
    CommerceProduct(
      id: 'prod_4',
      name: 'Abstract Geometric Wall Art — Set of 3',
      description:
          'Museum-quality giclée prints on premium cotton canvas. Modern abstract geometric designs inspired by geometric patterns. Includes hanging hardware. Each canvas is 40x60cm.',
      price: 129.00,
      imageUrls: [
        'https://images.unsplash.com/photo-1549490349-8643362247b5?w=600',
      ],
      seller: _sellerAmal,
      categoryTags: ['art', 'home'],
      rating: 4.7,
      reviewCount: 45,
      salesCount: 189,
      isFreeShipping: true,
      highlights: [
        'Set of 3 canvases (40x60cm each)',
        'Museum-quality giclée prints',
        'Premium 350gsm cotton canvas',
        'Inspired by geometric art',
        'Hanging hardware included',
      ],
    ),
    CommerceProduct(
      id: 'prod_5',
      name: 'Argan Oil — Pure Organic Cold-Pressed',
      description:
          'Certified organic argan oil sourced directly from women\'s cooperatives in the Souss Valley. Cold-pressed, unrefined, multi-purpose: hair, skin, nails. Glass dropper bottle, 50ml.',
      price: 24.99,
      originalPrice: 34.99,
      imageUrls: [
        'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=600',
      ],
      seller: _sellerYasmin,
      categoryTags: ['beauty', 'handmade', 'trending'],
      rating: 4.9,
      reviewCount: 312,
      salesCount: 890,
      badge: 'BESTSELLER',
      variants: [
        ProductVariantGroup(name: 'Size', options: [
          ProductVariantOption(label: '30ml'),
          ProductVariantOption(label: '50ml', priceAdd: 10.00),
          ProductVariantOption(label: '100ml', priceAdd: 25.00),
        ]),
      ],
      highlights: [
        'Certified organic & cold-pressed',
        'Sourced from women\'s cooperatives',
        'Multi-use: hair, skin, nails',
        'Glass dropper bottle',
        'Ethically produced in Souss Valley',
      ],
    ),
    CommerceProduct(
      id: 'prod_6',
      name: 'Smart Home Automation Hub',
      description:
          'Control your entire home from one device. Compatible with Zigbee, Z-Wave, WiFi, and Thread. Works with 10,000+ smart devices. Local processing for privacy. Built-in Matter support.',
      price: 149.99,
      imageUrls: [
        'https://images.unsplash.com/photo-1558089687-f282ffcbc126?w=600',
      ],
      seller: _sellerZaki,
      categoryTags: ['tech', 'home'],
      rating: 4.5,
      reviewCount: 78,
      salesCount: 234,
      stockCount: 12,
      isFreeShipping: true,
      highlights: [
        'Zigbee, Z-Wave, WiFi, Thread, Matter',
        '10,000+ compatible devices',
        'Local processing — no cloud required',
        'Voice assistant integration',
        'Free Driba smart home app',
      ],
    ),
    CommerceProduct(
      id: 'prod_7',
      name: 'Brand Identity Design Package',
      description:
          'Complete brand identity designed by our award-winning team. Includes logo (5 concepts, 3 revisions), brand guidelines, color palette, typography, social media kit, and business card design.',
      price: 299.00,
      originalPrice: 499.00,
      imageUrls: [
        'https://images.unsplash.com/photo-1626785774573-4b799315345d?w=600',
      ],
      seller: _sellerAmal,
      categoryTags: ['services', 'digital'],
      rating: 5.0,
      reviewCount: 23,
      salesCount: 67,
      isDigital: true,
      badge: 'TOP RATED',
      highlights: [
        '5 logo concepts, 3 revision rounds',
        'Complete brand style guide (PDF)',
        'Color palette + typography system',
        'Social media template kit',
        'Business card design included',
        'Delivered in 7-10 business days',
      ],
    ),
    CommerceProduct(
      id: 'prod_8',
      name: 'Handwoven Turkish Kilim Rug — Atlas Mountains',
      description:
          'Authentic kilim rug handwoven by master artisans in Cappadocia. Each rug tells a story through its unique symbols and patterns. 100% virgin wool, natural dyes.',
      price: 349.00,
      imageUrls: [
        'https://images.unsplash.com/photo-1600166898405-da9535204843?w=600',
      ],
      seller: _sellerNora,
      categoryTags: ['home', 'handmade', 'art'],
      rating: 4.8,
      reviewCount: 34,
      salesCount: 78,
      isFreeShipping: true,
      variants: [
        ProductVariantGroup(name: 'Size', options: [
          ProductVariantOption(label: '120×180cm'),
          ProductVariantOption(label: '160×230cm', priceAdd: 150.00),
          ProductVariantOption(label: '200×300cm', priceAdd: 350.00, available: false),
        ]),
      ],
      highlights: [
        'Handwoven in Middle Atlas Mountains',
        '100% virgin wool, natural dyes',
        'Each piece is one-of-a-kind',
        'Certificate of authenticity included',
        'Takes 2-4 weeks to weave',
      ],
    ),
  ];

  // ── Reviews ─────────────────────────────────

  static final _bagReviews = [
    ProductReview(
      userName: 'Leila M.',
      avatarUrl: 'https://i.pravatar.cc/100?img=31',
      rating: 5.0,
      text: 'Absolutely stunning! The leather quality is incredible and the craftsmanship is top notch. Gets more beautiful with use.',
      date: DateTime.now().subtract(const Duration(days: 3)),
      helpfulCount: 24,
    ),
    ProductReview(
      userName: 'Ahmed K.',
      avatarUrl: 'https://i.pravatar.cc/100?img=14',
      rating: 4.5,
      text: 'Great bag, very well made. The smell of real leather is amazing. Shipping was fast too.',
      date: DateTime.now().subtract(const Duration(days: 12)),
      helpfulCount: 11,
    ),
  ];

  static final _digitalReviews = [
    ProductReview(
      userName: 'Carlos R.',
      avatarUrl: 'https://i.pravatar.cc/100?img=53',
      rating: 5.0,
      text: 'This kit saved me weeks of work. Components are beautifully designed and well-organized. Auto-layout works perfectly.',
      date: DateTime.now().subtract(const Duration(days: 7)),
      helpfulCount: 42,
    ),
  ];

  static final _techReviews = [
    ProductReview(
      userName: 'Sofia B.',
      avatarUrl: 'https://i.pravatar.cc/100?img=44',
      rating: 4.5,
      text: 'Sound quality is impressive for the price. ANC works great on the bus. Battery easily lasts 2 days.',
      date: DateTime.now().subtract(const Duration(days: 5)),
      helpfulCount: 18,
    ),
  ];
}
