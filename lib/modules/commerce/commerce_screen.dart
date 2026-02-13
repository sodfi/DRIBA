import 'package:flutter/material.dart';
import '../../core/widgets/screen_shell.dart';

/// Shop — Content-first product showcases and drops.
/// "Wishlist" filter → saved items, cart, order tracking.
class CommerceScreen extends StatelessWidget {
  const CommerceScreen({super.key});

  static const Color _accent = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return DribaScreenShell(
      screenId: 'commerce',
      screenLabel: 'Shop',
      accent: _accent,
      filters: const [
        DribaFilter('Featured', '⭐'),
        DribaFilter('Fashion', '👗'),
        DribaFilter('Home', '🏠'),
        DribaFilter('Beauty', '💄'),
        DribaFilter('Wishlist', '💛'),
      ],
      personalFilterIndex: 4,
      personalView: const _WishlistView(),
    );
  }
}

class _WishlistView extends StatelessWidget {
  const _WishlistView();

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFFD700);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Cart summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accent.withOpacity(0.12), accent.withOpacity(0.04)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.25)),
          ),
          child: Row(children: [
            Icon(Icons.shopping_cart, color: accent, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              Text('2 items · \$344', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
              child: const Text('Checkout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Icon(Icons.favorite_outline, color: accent, size: 18),
          const SizedBox(width: 8),
          Text('Wishlist', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        const SizedBox(height: 12),
        _WishlistItem(name: 'Handwoven Berber Rug', price: 299, accent: accent),
        _WishlistItem(name: 'Argan Oil Gift Set', price: 45, accent: accent),
        _WishlistItem(name: 'Brass Lantern', price: 65, accent: accent),
        _WishlistItem(name: 'Leather Messenger Bag', price: 179, accent: accent),
        const SizedBox(height: 24),
        Row(children: [
          Icon(Icons.local_shipping_outlined, color: accent, size: 18),
          const SizedBox(width: 8),
          Text('Active Orders', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        const SizedBox(height: 12),
        _OrderTrack(name: 'Moroccan Ceramic Set', status: 'In Transit', eta: 'Feb 15', accent: accent),
        _OrderTrack(name: 'Rose Water Spray', status: 'Delivered', eta: 'Feb 10', accent: accent),
        const SizedBox(height: 40),
      ]),
    );
  }
}

class _WishlistItem extends StatelessWidget {
  final String name;
  final double price;
  final Color accent;
  const _WishlistItem({required this.name, required this.price, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.shopping_bag, color: accent, size: 16)),
        const SizedBox(width: 12),
        Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
        Text('\$${price.toStringAsFixed(0)}', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 15)),
      ]),
    );
  }
}

class _OrderTrack extends StatelessWidget {
  final String name, status, eta;
  final Color accent;
  const _OrderTrack({required this.name, required this.status, required this.eta, required this.accent});

  @override
  Widget build(BuildContext context) {
    final delivered = status == 'Delivered';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Row(children: [
        Icon(delivered ? Icons.check_circle : Icons.local_shipping, color: delivered ? const Color(0xFF00D68F) : accent, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          Text('$status · $eta', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        ])),
      ]),
    );
  }
}
