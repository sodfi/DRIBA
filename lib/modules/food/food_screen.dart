import 'package:flutter/material.dart';
import '../../core/widgets/screen_shell.dart';

/// Food — Content-first recipes and restaurant spotlights.
/// "Orders" filter → order history, saved restaurants, reorder.
class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key});

  static const Color _accent = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context) {
    return DribaScreenShell(
      screenId: 'food',
      screenLabel: 'Food',
      accent: _accent,
      filters: const [
        DribaFilter('All', '🍽️'),
        DribaFilter('Recipes', '👨‍🍳'),
        DribaFilter('Restaurants', '🏪'),
        DribaFilter('Healthy', '🥗'),
        DribaFilter('Orders', '🛒'),
      ],
      personalFilterIndex: 4,
      personalView: const _OrdersView(),
    );
  }
}

class _OrdersView extends StatelessWidget {
  const _OrdersView();

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF6B35);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.receipt_long, color: accent, size: 18),
          const SizedBox(width: 8),
          Text('Recent Orders', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        const SizedBox(height: 16),
        _OrderCard(name: 'Golden Dragon', items: 'Pad Thai, Spring Rolls, Mango Sticky Rice', time: '2 days ago', status: 'Delivered', accent: accent),
        _OrderCard(name: 'Nomad', items: 'Modern Mezze Platter', time: '5 days ago', status: 'Delivered', accent: accent),
        _OrderCard(name: 'Casa Bella Pizza', items: 'Margherita, Garlic Bread', time: '1 week ago', status: 'Delivered', accent: accent),
        const SizedBox(height: 24),
        Row(children: [
          Icon(Icons.favorite_outline, color: accent, size: 18),
          const SizedBox(width: 8),
          Text('Saved Restaurants', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        const SizedBox(height: 12),
        _SavedRestaurant(name: 'Nobu Downtown', cuisine: 'Japanese', rating: 4.8, accent: accent),
        _SavedRestaurant(name: 'Café Clock', cuisine: 'Fusion', rating: 4.6, accent: accent),
        _SavedRestaurant(name: 'Dishoom', cuisine: 'Japanese-Peruvian', rating: 4.7, accent: accent),
        const SizedBox(height: 40),
      ]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String name, items, time, status;
  final Color accent;
  const _OrderCard({required this.name, required this.items, required this.time, required this.status, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(items, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
        const SizedBox(height: 4),
        Row(children: [
          Text(time, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
          const Spacer(),
          Text('Reorder', style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

class _SavedRestaurant extends StatelessWidget {
  final String name, cuisine;
  final double rating;
  final Color accent;
  const _SavedRestaurant({required this.name, required this.cuisine, required this.rating, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(name[0], style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 16)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          Text(cuisine, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        ])),
        Text('⭐ $rating', style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
