import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/driba_colors.dart';
import 'shell_state.dart';

// ============================================
// CONTENT CHROME v2 — Minimal
//
// With iOS bottom nav now permanent, chrome is
// simplified to just show screen indicator dots
// on tap. No more duplicate category labels.
// ============================================

class ContentChrome extends ConsumerWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onCreateTap;
  final PageController pageController;

  const ContentChrome({
    super.key,
    required this.onProfileTap,
    required this.onCreateTap,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Chrome is now handled by the bottom nav bar
    // This widget is kept for backwards compatibility but renders nothing
    return const SizedBox.shrink();
  }
}
