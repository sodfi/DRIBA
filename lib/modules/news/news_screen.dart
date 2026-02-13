import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/screen_shell.dart';

/// News — Content-first scoops and articles.
/// "My Feed" filter → personal saved topics and sources.
class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  static const Color _accent = Color(0xFFFF3D71);

  @override
  Widget build(BuildContext context) {
    return DribaScreenShell(
      screenId: 'news',
      screenLabel: 'News',
      accent: _accent,
      filters: const [
        DribaFilter('Top Stories', '📰'),
        DribaFilter('Tech', '💻'),
        DribaFilter('Business', '💼'),
        DribaFilter('Science', '🔬'),
        DribaFilter('My Feed', '📌'),
      ],
      personalFilterIndex: 4,
      personalView: const _MyNewsFeed(),
    );
  }
}

class _MyNewsFeed extends StatelessWidget {
  const _MyNewsFeed();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: Icons.topic, label: 'Followed Topics', accent: const Color(0xFFFF3D71)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['Technology', 'Climate', 'Science', 'AI', 'Startups']
                .map((t) => _TopicChip(label: t))
                .toList(),
          ),
          const SizedBox(height: 28),
          _SectionHeader(icon: Icons.source, label: 'Followed Sources', accent: const Color(0xFFFF3D71)),
          const SizedBox(height: 12),
          ...[
            _SourceRow(name: 'TechCrunch', articles: 12),
            _SourceRow(name: 'Reuters', articles: 8),
            _SourceRow(name: 'Nature', articles: 5),
            _SourceRow(name: 'Bloomberg', articles: 15),
          ],
          const SizedBox(height: 28),
          _SectionHeader(icon: Icons.bookmark, label: 'Saved Articles', accent: const Color(0xFFFF3D71)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'No saved articles yet.\nLong-press any story to save it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14, height: 1.5),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  const _SectionHeader({required this.icon, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: accent, size: 18),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 16)),
    ]);
  }
}

class _TopicChip extends StatelessWidget {
  final String label;
  const _TopicChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3D71).withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFFF3D71).withOpacity(0.25)),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFFFF3D71), fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final String name;
  final int articles;
  const _SourceRow({required this.name, required this.articles});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFFFF3D71).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(name[0], style: const TextStyle(color: Color(0xFFFF3D71), fontWeight: FontWeight.w700, fontSize: 16))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
        Text('$articles articles', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
      ]),
    );
  }
}
