// ============================================
// TRAVEL SCREEN MODELS & DEMO DATA
//
// Destinations, hotels, experiences, flights,
// and travel packages for the travel world.
// ============================================

class TravelCategory {
  final String id;
  final String name;
  final String emoji;
  const TravelCategory({required this.id, required this.name, required this.emoji});
}

class Destination {
  final String id;
  final String name;
  final String country;
  final String imageUrl;
  final String description;
  final double rating;
  final int reviewCount;
  final String priceFrom;
  final String flightTime;
  final String bestSeason;
  final List<String> tags; // trending, beach, city, mountain, cultural, adventure
  final bool isFeatured;
  final List<Hotel> hotels;
  final List<Experience> experiences;

  const Destination({
    required this.id,
    required this.name,
    required this.country,
    required this.imageUrl,
    required this.description,
    this.rating = 0,
    this.reviewCount = 0,
    this.priceFrom = '',
    this.flightTime = '',
    this.bestSeason = '',
    this.tags = const [],
    this.isFeatured = false,
    this.hotels = const [],
    this.experiences = const [],
  });
}

class Hotel {
  final String id;
  final String name;
  final String imageUrl;
  final double pricePerNight;
  final double? originalPrice;
  final double rating;
  final int reviewCount;
  final int stars;
  final String location;
  final List<String> amenities;
  final bool isAvailable;
  final String? dealText;

  const Hotel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.pricePerNight,
    this.originalPrice,
    this.rating = 0,
    this.reviewCount = 0,
    this.stars = 4,
    this.location = '',
    this.amenities = const [],
    this.isAvailable = true,
    this.dealText,
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > pricePerNight;
  double get discountPercent =>
      hasDiscount ? ((originalPrice! - pricePerNight) / originalPrice! * 100) : 0;
}

class Experience {
  final String id;
  final String title;
  final String imageUrl;
  final double price;
  final String duration;
  final double rating;
  final int reviewCount;
  final String hostName;
  final String? hostAvatar;
  final List<String> tags;
  final int maxGroupSize;

  const Experience({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.duration,
    this.rating = 0,
    this.reviewCount = 0,
    this.hostName = '',
    this.hostAvatar,
    this.tags = const [],
    this.maxGroupSize = 10,
  });
}

class TravelBooking {
  final Destination destination;
  final Hotel? hotel;
  final Experience? experience;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final double totalPrice;

  const TravelBooking({
    required this.destination,
    this.hotel,
    this.experience,
    required this.checkIn,
    required this.checkOut,
    this.guests = 2,
    required this.totalPrice,
  });

  int get nights => checkOut.difference(checkIn).inDays;
}

// ============================================
// DEMO DATA
// ============================================

class TravelDemoData {
  TravelDemoData._();

  static const List<TravelCategory> categories = [
    TravelCategory(id: 'all', name: 'Explore', emoji: '🌍'),
    TravelCategory(id: 'trending', name: 'Trending', emoji: '🔥'),
    TravelCategory(id: 'beach', name: 'Beach', emoji: '🏖️'),
    TravelCategory(id: 'city', name: 'City', emoji: '🏙️'),
    TravelCategory(id: 'mountain', name: 'Mountain', emoji: '⛰️'),
    TravelCategory(id: 'cultural', name: 'Cultural', emoji: '🕌'),
    TravelCategory(id: 'adventure', name: 'Adventure', emoji: '🧗'),
    TravelCategory(id: 'romantic', name: 'Romantic', emoji: '❤️'),
  ];

  static final List<Destination> destinations = [
    Destination(
      id: 'd1',
      name: 'Marrakech',
      country: 'Morocco',
      imageUrl: 'https://images.unsplash.com/photo-1597212618440-806262de4f6b?w=600',
      description: 'The Red City — a sensory feast of spice markets, riads, and the Atlas Mountains. Explore the medina, relax in hidden gardens, and experience Moroccan hospitality at its finest.',
      rating: 4.8,
      reviewCount: 2340,
      priceFrom: '\$89/night',
      flightTime: '1h from Casa',
      bestSeason: 'Oct – Apr',
      tags: ['trending', 'cultural', 'city'],
      isFeatured: true,
      hotels: [
        Hotel(
          id: 'h1', name: 'Riad Jardin Secret', stars: 5,
          imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=500',
          pricePerNight: 189, originalPrice: 249, rating: 4.9, reviewCount: 412,
          location: 'Medina', amenities: ['Pool', 'Spa', 'Rooftop', 'WiFi', 'Breakfast'],
          dealText: '24% OFF',
        ),
        Hotel(
          id: 'h2', name: 'La Mamounia Palace', stars: 5,
          imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=500',
          pricePerNight: 420, rating: 4.8, reviewCount: 890,
          location: 'Hivernage', amenities: ['Pool', 'Spa', 'Garden', 'Restaurant', 'Bar'],
        ),
        Hotel(
          id: 'h3', name: 'Dar El Maa Boutique', stars: 4,
          imageUrl: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=500',
          pricePerNight: 89, rating: 4.6, reviewCount: 234,
          location: 'Mellah', amenities: ['Terrace', 'WiFi', 'Breakfast'],
          dealText: 'Best Value',
        ),
      ],
      experiences: [
        Experience(
          id: 'e1', title: 'Sunset Camel Ride in the Palmeraie',
          imageUrl: 'https://images.unsplash.com/photo-1548824005-c9e7f4dfee7e?w=500',
          price: 45, duration: '2.5 hours', rating: 4.9, reviewCount: 567,
          hostName: 'Hassan', tags: ['adventure', 'sunset'],
        ),
        Experience(
          id: 'e2', title: 'Moroccan Cooking Class & Market Tour',
          imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=500',
          price: 65, duration: '4 hours', rating: 4.8, reviewCount: 321,
          hostName: 'Fatima', tags: ['cultural', 'food'],
        ),
      ],
    ),
    Destination(
      id: 'd2',
      name: 'Santorini',
      country: 'Greece',
      imageUrl: 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=600',
      description: 'White-washed villages perched on volcanic cliffs overlooking the deepest blue of the Aegean Sea. Santorini is where sunsets become spiritual experiences.',
      rating: 4.9,
      reviewCount: 4120,
      priceFrom: '\$159/night',
      flightTime: '4h from Casa',
      bestSeason: 'May – Oct',
      tags: ['trending', 'beach', 'romantic'],
      isFeatured: true,
      hotels: [
        Hotel(
          id: 'h4', name: 'Oia Sunset Villas', stars: 5,
          imageUrl: 'https://images.unsplash.com/photo-1602343168117-bb8ffe3e2e9f?w=500',
          pricePerNight: 320, originalPrice: 410, rating: 4.9, reviewCount: 678,
          location: 'Oia', amenities: ['Infinity Pool', 'Caldera View', 'Spa', 'WiFi'],
          dealText: '22% OFF',
        ),
      ],
      experiences: [
        Experience(
          id: 'e3', title: 'Catamaran Sunset Cruise with Dinner',
          imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=500',
          price: 120, duration: '5 hours', rating: 4.9, reviewCount: 892,
          hostName: 'Nikos', tags: ['romantic', 'sunset'],
        ),
      ],
    ),
    Destination(
      id: 'd3',
      name: 'Chefchaouen',
      country: 'Morocco',
      imageUrl: 'https://images.unsplash.com/photo-1553540017-f2956d979f39?w=600',
      description: 'The Blue Pearl of Morocco — a dreamlike village painted in every shade of blue. Tucked in the Rif Mountains, it\'s the perfect escape from the world.',
      rating: 4.7,
      reviewCount: 1560,
      priceFrom: '\$45/night',
      flightTime: '5h drive from Casa',
      bestSeason: 'Mar – Jun, Sep – Nov',
      tags: ['cultural', 'mountain'],
      hotels: [
        Hotel(
          id: 'h5', name: 'Casa Perleta', stars: 3,
          imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=500',
          pricePerNight: 55, rating: 4.7, reviewCount: 189,
          location: 'Old Medina', amenities: ['Terrace', 'WiFi', 'Breakfast'],
        ),
      ],
      experiences: [
        Experience(
          id: 'e4', title: 'Rif Mountains Hiking & Waterfall Trek',
          imageUrl: 'https://images.unsplash.com/photo-1551632811-561732d1e306?w=500',
          price: 35, duration: '6 hours', rating: 4.8, reviewCount: 234,
          hostName: 'Youssef', tags: ['adventure', 'mountain'],
        ),
      ],
    ),
    Destination(
      id: 'd4',
      name: 'Bali',
      country: 'Indonesia',
      imageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600',
      description: 'Island of the Gods — lush rice terraces, ancient temples, world-class surf, and a wellness culture that soothes the soul. Bali is where adventure meets tranquility.',
      rating: 4.8,
      reviewCount: 5670,
      priceFrom: '\$69/night',
      flightTime: '16h from Casa',
      bestSeason: 'Apr – Oct',
      tags: ['trending', 'beach', 'adventure', 'cultural'],
      isFeatured: true,
      hotels: [
        Hotel(
          id: 'h6', name: 'Ubud Bamboo Retreat', stars: 4,
          imageUrl: 'https://images.unsplash.com/photo-1540541338287-41700207dee6?w=500',
          pricePerNight: 120, originalPrice: 180, rating: 4.8, reviewCount: 456,
          location: 'Ubud', amenities: ['Pool', 'Yoga', 'Spa', 'Restaurant', 'WiFi'],
          dealText: '33% OFF',
        ),
      ],
      experiences: [
        Experience(
          id: 'e5', title: 'Sunrise Trek to Mount Batur',
          imageUrl: 'https://images.unsplash.com/photo-1555400038-63f5ba517a47?w=500',
          price: 55, duration: '8 hours', rating: 4.7, reviewCount: 1234,
          hostName: 'Wayan', tags: ['adventure', 'mountain'],
        ),
      ],
    ),
    Destination(
      id: 'd5',
      name: 'Essaouira',
      country: 'Morocco',
      imageUrl: 'https://images.unsplash.com/photo-1569383746724-6f1b882b8f46?w=600',
      description: 'Wind City on the Atlantic — a bohemian coastal town with Portuguese fortifications, world-class kitesurfing, and the freshest seafood you\'ll ever taste.',
      rating: 4.6,
      reviewCount: 980,
      priceFrom: '\$55/night',
      flightTime: '3h drive from Casa',
      bestSeason: 'Jun – Sep',
      tags: ['beach', 'adventure'],
      hotels: [
        Hotel(
          id: 'h7', name: 'L\'Heure Bleue Palais', stars: 5,
          imageUrl: 'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=500',
          pricePerNight: 175, rating: 4.7, reviewCount: 312,
          location: 'Medina', amenities: ['Pool', 'Cinema', 'Spa', 'Rooftop'],
        ),
      ],
      experiences: [
        Experience(
          id: 'e6', title: 'Kitesurfing Lesson for Beginners',
          imageUrl: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=500',
          price: 75, duration: '3 hours', rating: 4.6, reviewCount: 178,
          hostName: 'Mehdi', tags: ['adventure', 'beach'],
        ),
      ],
    ),
    Destination(
      id: 'd6',
      name: 'Tokyo',
      country: 'Japan',
      imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=600',
      description: 'Where ancient tradition collides with neon-lit futurism. Tokyo is temples at dawn, robot restaurants at night, and the best food on earth in between.',
      rating: 4.9,
      reviewCount: 8900,
      priceFrom: '\$110/night',
      flightTime: '14h from Casa',
      bestSeason: 'Mar – May, Oct – Nov',
      tags: ['trending', 'city', 'cultural'],
      isFeatured: true,
      hotels: [
        Hotel(
          id: 'h8', name: 'Shinjuku Capsule Zen', stars: 3,
          imageUrl: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=500',
          pricePerNight: 65, rating: 4.5, reviewCount: 567,
          location: 'Shinjuku', amenities: ['WiFi', 'Onsen', 'Lounge'],
          dealText: 'Unique Stay',
        ),
      ],
      experiences: [
        Experience(
          id: 'e7', title: 'Tsukiji Fish Market & Sushi Masterclass',
          imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=500',
          price: 95, duration: '4 hours', rating: 4.9, reviewCount: 2100,
          hostName: 'Kenji', tags: ['cultural', 'food'],
        ),
      ],
    ),
  ];

  static List<Destination> get featured =>
      destinations.where((d) => d.isFeatured).toList();
}
