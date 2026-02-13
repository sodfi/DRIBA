// ============================================
// FOOD SCREEN MODELS & DEMO DATA
// ============================================

class FoodCategory {
  final String id;
  final String name;
  final String emoji;

  const FoodCategory({required this.id, required this.name, required this.emoji});
}

class FoodRestaurant {
  final String id;
  final String name;
  final String coverUrl;
  final String? logoUrl;
  final double rating;
  final int reviewCount;
  final int deliveryTimeMin; // minutes
  final int deliveryTimeMax;
  final double deliveryFee;
  final double minimumOrder;
  final double distance; // km
  final List<String> cuisineTags;
  final bool isFeatured;
  final bool isOpen;
  final String? promoText;
  final List<String> dietaryOptions; // halal, vegan, gluten-free
  final List<FoodMenuSection> menu;

  const FoodRestaurant({
    required this.id,
    required this.name,
    required this.coverUrl,
    this.logoUrl,
    required this.rating,
    this.reviewCount = 0,
    required this.deliveryTimeMin,
    required this.deliveryTimeMax,
    this.deliveryFee = 0,
    this.minimumOrder = 0,
    this.distance = 0,
    required this.cuisineTags,
    this.isFeatured = false,
    this.isOpen = true,
    this.promoText,
    this.dietaryOptions = const [],
    this.menu = const [],
  });

  String get deliveryTimeRange => '$deliveryTimeMin-$deliveryTimeMax min';
  String get distanceFormatted =>
      distance < 1 ? '${(distance * 1000).toInt()}m' : '${distance.toStringAsFixed(1)}km';
}

class FoodMenuSection {
  final String name;
  final List<FoodMenuItem> items;

  const FoodMenuSection({required this.name, required this.items});
}

class FoodMenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice; // for discounts
  final String? imageUrl;
  final List<String> tags; // popular, new, spicy
  final int calories;
  final bool isAvailable;
  final List<MenuOption>? options; // size, extras, etc.

  const FoodMenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    this.imageUrl,
    this.tags = const [],
    this.calories = 0,
    this.isAvailable = true,
    this.options,
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  double get discountPercent =>
      hasDiscount ? ((originalPrice! - price) / originalPrice! * 100) : 0;
}

class MenuOption {
  final String name;
  final List<MenuOptionChoice> choices;
  final bool isRequired;

  const MenuOption({
    required this.name,
    required this.choices,
    this.isRequired = false,
  });
}

class MenuOptionChoice {
  final String name;
  final double priceAdd;

  const MenuOptionChoice({required this.name, this.priceAdd = 0});
}

class CartItem {
  final FoodMenuItem menuItem;
  final FoodRestaurant restaurant;
  final int quantity;
  final String? specialInstructions;

  const CartItem({
    required this.menuItem,
    required this.restaurant,
    this.quantity = 1,
    this.specialInstructions,
  });

  double get total => menuItem.price * quantity;

  CartItem copyWith({int? quantity, String? specialInstructions}) {
    return CartItem(
      menuItem: menuItem,
      restaurant: restaurant,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}

// ============================================
// DEMO DATA
// ============================================

class FoodDemoData {
  FoodDemoData._();

  static const List<FoodCategory> categories = [
    FoodCategory(id: 'all', name: 'All', emoji: '🍽️'),
    FoodCategory(id: 'nearby', name: 'Nearby', emoji: '📍'),
    FoodCategory(id: 'asian', name: 'Asian', emoji: '🍜'),
    FoodCategory(id: 'pizza', name: 'Pizza', emoji: '🍕'),
    FoodCategory(id: 'sushi', name: 'Sushi', emoji: '🍣'),
    FoodCategory(id: 'burger', name: 'Burgers', emoji: '🍔'),
    FoodCategory(id: 'asian', name: 'Asian', emoji: '🥢'),
    FoodCategory(id: 'healthy', name: 'Healthy', emoji: '🥗'),
    FoodCategory(id: 'dessert', name: 'Dessert', emoji: '🍰'),
    FoodCategory(id: 'coffee', name: 'Coffee', emoji: '☕'),
    FoodCategory(id: 'halal', name: 'Halal', emoji: '🌙'),
  ];

  static final List<FoodRestaurant> restaurants = [
    FoodRestaurant(
      id: 'r1',
      name: 'The Golden Dragon',
      coverUrl: 'https://images.unsplash.com/photo-1540914124281-342587941389?w=600',
      rating: 4.8,
      reviewCount: 342,
      deliveryTimeMin: 25,
      deliveryTimeMax: 35,
      deliveryFee: 0,
      minimumOrder: 15,
      distance: 1.2,
      cuisineTags: ['asian', 'popular', 'nearby'],
      isFeatured: true,
      promoText: 'FREE DELIVERY',
      dietaryOptions: ['halal', 'vegetarian-options'],
      menu: _asianMenu,
    ),
    FoodRestaurant(
      id: 'r2',
      name: 'Sakura Ramen House',
      coverUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600',
      rating: 4.6,
      reviewCount: 218,
      deliveryTimeMin: 30,
      deliveryTimeMax: 45,
      deliveryFee: 2.99,
      distance: 2.5,
      cuisineTags: ['asian', 'sushi', 'nearby'],
      isFeatured: true,
      promoText: '20% OFF FIRST ORDER',
      menu: _asianMenu,
    ),
    FoodRestaurant(
      id: 'r3',
      name: 'Casa Bella Pizza',
      coverUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600',
      rating: 4.7,
      reviewCount: 567,
      deliveryTimeMin: 20,
      deliveryTimeMax: 30,
      deliveryFee: 0,
      distance: 0.8,
      cuisineTags: ['pizza', 'nearby'],
      isFeatured: true,
      dietaryOptions: ['vegetarian-options'],
      menu: _pizzaMenu,
    ),
    FoodRestaurant(
      id: 'r4',
      name: 'Green Bowl Co.',
      coverUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600',
      rating: 4.5,
      reviewCount: 189,
      deliveryTimeMin: 15,
      deliveryTimeMax: 25,
      deliveryFee: 1.50,
      distance: 0.5,
      cuisineTags: ['healthy', 'nearby'],
      dietaryOptions: ['vegan', 'gluten-free'],
      menu: _healthyMenu,
    ),
    FoodRestaurant(
      id: 'r5',
      name: 'Burger Artisan',
      coverUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600',
      rating: 4.4,
      reviewCount: 423,
      deliveryTimeMin: 25,
      deliveryTimeMax: 35,
      deliveryFee: 0,
      distance: 1.8,
      cuisineTags: ['burger', 'nearby'],
      promoText: 'BUY 1 GET 1',
      menu: _burgerMenu,
    ),
    FoodRestaurant(
      id: 'r6',
      name: 'Pâtisserie Royale',
      coverUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=600',
      rating: 4.9,
      reviewCount: 156,
      deliveryTimeMin: 20,
      deliveryTimeMax: 30,
      deliveryFee: 2.00,
      distance: 3.1,
      cuisineTags: ['dessert', 'coffee'],
      menu: _dessertMenu,
    ),
  ];

  // ── Menus ─────────────────────────────────

  static const _asianMenu = [
    FoodMenuSection(name: 'Signature Dishes', items: [
      FoodMenuItem(
        id: 'm1', name: 'Royal Couscous', price: 16.99,
        description: 'Fluffy semolina with seven vegetables, tender lamb, and aromatic broth',
        imageUrl: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400',
        tags: ['popular'], calories: 680,
      ),
      FoodMenuItem(
        id: 'm2', name: 'Chicken Teriyaki', price: 14.99,
        description: 'Grilled chicken glazed with homemade teriyaki sauce and sesame seeds',
        imageUrl: 'https://images.unsplash.com/photo-1541518763669-27fef04b14ea?w=400',
        tags: ['popular', 'spicy'], calories: 520,
      ),
      FoodMenuItem(
        id: 'm3', name: 'Lamb Mechoui', price: 22.99, originalPrice: 28.99,
        description: 'Slow-roasted lamb shoulder with cumin, served with flatbread',
        tags: ['new'], calories: 750,
      ),
    ]),
    FoodMenuSection(name: 'Starters', items: [
      FoodMenuItem(
        id: 'm4', name: 'Harira Soup', price: 7.99,
        description: 'Traditional tomato-lentil soup with fresh herbs and lemon',
        calories: 220,
      ),
      FoodMenuItem(
        id: 'm5', name: 'Briouats', price: 8.99,
        description: 'Crispy phyllo triangles filled with spiced beef and almonds',
        tags: ['popular'], calories: 340,
      ),
    ]),
    FoodMenuSection(name: 'Drinks', items: [
      FoodMenuItem(
        id: 'm6', name: 'Japanese Matcha Latte', price: 3.99,
        description: 'Fresh mint, gunpowder green tea, poured from height',
        calories: 60,
      ),
      FoodMenuItem(
        id: 'm7', name: 'Avocado Smoothie', price: 5.99,
        description: 'Blended with almonds, dates, and a touch of orange blossom',
        calories: 280,
      ),
    ]),
  ];

  static const _asianMenu = [
    FoodMenuSection(name: 'Ramen', items: [
      FoodMenuItem(
        id: 'a1', name: 'Tonkotsu Ramen', price: 15.99,
        description: 'Rich pork bone broth, chashu, soft egg, nori, bamboo shoots',
        imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400',
        tags: ['popular'], calories: 620,
      ),
      FoodMenuItem(
        id: 'a2', name: 'Spicy Miso Ramen', price: 14.99,
        description: 'Fermented soybean broth with chili oil, corn, ground pork',
        tags: ['spicy'], calories: 580,
      ),
    ]),
    FoodMenuSection(name: 'Sushi Rolls', items: [
      FoodMenuItem(
        id: 'a3', name: 'Dragon Roll', price: 13.99,
        description: 'Shrimp tempura, avocado, eel, tobiko, unagi sauce',
        tags: ['popular'], calories: 420,
      ),
      FoodMenuItem(
        id: 'a4', name: 'Salmon Lover', price: 12.99,
        description: 'Triple salmon: sashimi, smoked, and torched with truffle mayo',
        tags: ['new'], calories: 380,
      ),
    ]),
  ];

  static const _pizzaMenu = [
    FoodMenuSection(name: 'Classic Pizzas', items: [
      FoodMenuItem(
        id: 'p1', name: 'Margherita DOP', price: 12.99,
        description: 'San Marzano tomato, fior di latte, fresh basil, EVOO',
        imageUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400',
        tags: ['popular'], calories: 850,
      ),
      FoodMenuItem(
        id: 'p2', name: 'Truffle Funghi', price: 16.99,
        description: 'Wild mushroom medley, truffle cream, fontina, fresh thyme',
        tags: ['new'], calories: 920,
      ),
    ]),
    FoodMenuSection(name: 'Sides', items: [
      FoodMenuItem(
        id: 'p3', name: 'Garlic Knots', price: 5.99,
        description: 'Fresh-baked with garlic butter and parmesan, marinara dip',
        calories: 320,
      ),
    ]),
  ];

  static const _healthyMenu = [
    FoodMenuSection(name: 'Bowls', items: [
      FoodMenuItem(
        id: 'h1', name: 'Açaí Power Bowl', price: 11.99,
        description: 'Açaí, banana, granola, chia seeds, fresh berries, honey drizzle',
        imageUrl: 'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=400',
        tags: ['popular'], calories: 380,
      ),
      FoodMenuItem(
        id: 'h2', name: 'Mediterranean Bowl', price: 13.99,
        description: 'Quinoa, grilled chicken, hummus, feta, cherry tomato, tahini',
        calories: 520,
      ),
    ]),
  ];

  static const _burgerMenu = [
    FoodMenuSection(name: 'Burgers', items: [
      FoodMenuItem(
        id: 'b1', name: 'Smash Classic', price: 11.99,
        description: 'Double smashed patty, American cheese, secret sauce, pickles',
        imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
        tags: ['popular'], calories: 780,
      ),
      FoodMenuItem(
        id: 'b2', name: 'Truffle Wagyu', price: 18.99,
        description: 'A5 wagyu beef, truffle aioli, gruyère, caramelized onions',
        tags: ['new'], calories: 920,
      ),
    ]),
    FoodMenuSection(name: 'Sides', items: [
      FoodMenuItem(
        id: 'b3', name: 'Loaded Fries', price: 6.99,
        description: 'Crispy fries with cheese sauce, bacon bits, jalapeños, ranch',
        tags: ['popular'], calories: 580,
      ),
    ]),
  ];

  static const _dessertMenu = [
    FoodMenuSection(name: 'Pastries', items: [
      FoodMenuItem(
        id: 'd1', name: 'Chocolate Fondant', price: 9.99,
        description: 'Warm molten chocolate cake with vanilla bean ice cream',
        imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400',
        tags: ['popular'], calories: 480,
      ),
      FoodMenuItem(
        id: 'd2', name: 'Pistachio Croissant', price: 5.99,
        description: 'Buttery laminated dough filled with pistachio frangipane',
        tags: ['new'], calories: 340,
      ),
    ]),
  ];
}
