import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================
// ENGAGEMENT OVERLAY v5 — Disabled
//
// Actions now live permanently on post cards
// (TikTok-style right-side buttons).
// This overlay is kept as empty for compatibility.
// ============================================

class EngagementOverlay extends ConsumerWidget {
  const EngagementOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }
}
