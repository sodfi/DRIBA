import 'package:flutter/material.dart';
import '../../core/widgets/screen_shell.dart';

/// Travel — Content-first destinations and guides.
/// "My Trips" filter → bookings, saved places, itineraries.
class TravelScreen extends StatelessWidget {
  const TravelScreen({super.key});

  static const Color _accent = Color(0xFF00B4D8);

  @override
  Widget build(BuildContext context) {
    return DribaScreenShell(
      screenId: 'travel',
      screenLabel: 'Travel',
      accent: _accent,
      filters: const [
        DribaFilter('Discover', '🌍'),
        DribaFilter('Hotels', '🏨'),
        DribaFilter('Experiences', '🎯'),
        DribaFilter('Guides', '📍'),
        DribaFilter('My Trips', '🧳'),
      ],
      personalFilterIndex: 4,
      personalView: const _MyTripsView(),
    );
  }
}

class _MyTripsView extends StatelessWidget {
  const _MyTripsView();

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00B4D8);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.flight_takeoff, color: accent, size: 18),
          const SizedBox(width: 8),
          Text('Upcoming', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        const SizedBox(height: 12),
        _TripCard(destination: 'Marrakech', dates: 'Mar 15 – 20, 2026', hotel: 'Riad Yasmine', status: 'Confirmed', accent: accent),
        const SizedBox(height: 24),
        Row(children: [
          Icon(Icons.bookmark_outline, color: accent, size: 18),
          const SizedBox(width: 8),
          Text('Saved Places', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        const SizedBox(height: 12),
        _SavedPlace(name: 'Sahara Desert Camp', location: 'Merzouga', accent: accent),
        _SavedPlace(name: 'Essaouira Surf House', location: 'Essaouira', accent: accent),
        _SavedPlace(name: 'Atlas Mountain Trek', location: 'Imlil', accent: accent),
        _SavedPlace(name: 'Chefchaouen Blue House', location: 'Chefchaouen', accent: accent),
        const SizedBox(height: 24),
        Row(children: [
          Icon(Icons.history, color: accent, size: 18),
          const SizedBox(width: 8),
          Text('Past Trips', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        const SizedBox(height: 12),
        _TripCard(destination: 'Fez Medina', dates: 'Jan 5 – 8, 2026', hotel: 'Riad Fes', status: 'Completed', accent: accent),
        _TripCard(destination: 'Essaouira', dates: 'Nov 12 – 15, 2025', hotel: 'Wind Palace', status: 'Completed', accent: accent),
        const SizedBox(height: 40),
      ]),
    );
  }
}

class _TripCard extends StatelessWidget {
  final String destination, dates, hotel, status;
  final Color accent;
  const _TripCard({required this.destination, required this.dates, required this.hotel, required this.status, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isUpcoming = status == 'Confirmed';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isUpcoming ? LinearGradient(colors: [accent.withOpacity(0.12), accent.withOpacity(0.04)]) : null,
        color: isUpcoming ? null : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isUpcoming ? accent.withOpacity(0.3) : Colors.white.withOpacity(0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(destination, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: isUpcoming ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: TextStyle(color: isUpcoming ? accent : Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 6),
        Text(dates, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
        Text(hotel, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
      ]),
    );
  }
}

class _SavedPlace extends StatelessWidget {
  final String name, location;
  final Color accent;
  const _SavedPlace({required this.name, required this.location, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.place, color: accent, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          Text(location, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        ])),
        Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 20),
      ]),
    );
  }
}
