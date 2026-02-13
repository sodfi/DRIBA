import 'package:flutter/material.dart';
import '../../core/widgets/screen_shell.dart';

/// Feed — The discovery layer. Shows all published posts across verticals.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DribaScreenShell(
      screenId: 'feed',
      screenLabel: 'Feed',
      accent: Color(0xFF00E1FF),
      filters: [
        DribaFilter('For You', '✨'),
        DribaFilter('Trending', '🔥'),
        DribaFilter('Following', '👥'),
        DribaFilter('AI Picks', '🤖'),
      ],
      // Feed has no personal view — it IS the discovery layer
      personalFilterIndex: -1,
    );
  }
}
