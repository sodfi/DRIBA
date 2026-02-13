import 'package:flutter/material.dart';
import '../../core/widgets/screen_shell.dart';

/// Health — Content-first wellness, nutrition, fitness posts.
/// "My Health" filter → personal dashboard, stats, records.
class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  static const Color _accent = Color(0xFF00D68F);

  @override
  Widget build(BuildContext context) {
    return DribaScreenShell(
      screenId: 'health',
      screenLabel: 'Health',
      accent: _accent,
      filters: const [
        DribaFilter('Wellness', '💚'),
        DribaFilter('Nutrition', '🥗'),
        DribaFilter('Fitness', '💪'),
        DribaFilter('Mindfulness', '🧘'),
        DribaFilter('My Health', '📊'),
      ],
      personalFilterIndex: 4,
      personalView: const _HealthDashboard(),
    );
  }
}

// ============================================
// PERSONAL HEALTH DASHBOARD
// Stats tiles, wellness score, tips
// ============================================

class _HealthDashboard extends StatelessWidget {
  const _HealthDashboard();

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00D68F);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Daily summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accent.withOpacity(0.15), accent.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.wb_sunny, color: accent, size: 24),
              const SizedBox(width: 8),
              Text('Good Morning', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 16)),
            ]),
            const SizedBox(height: 8),
            Text('Your wellness score today', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
            const SizedBox(height: 16),
            Row(children: [
              _ScoreRing(value: 78, label: 'Overall', color: accent),
              const SizedBox(width: 24),
              _ScoreRing(value: 85, label: 'Sleep', color: const Color(0xFF8B5CF6)),
              const SizedBox(width: 24),
              _ScoreRing(value: 62, label: 'Activity', color: const Color(0xFFFF6B35)),
              const SizedBox(width: 24),
              _ScoreRing(value: 90, label: 'Hydration', color: const Color(0xFF00B4D8)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // Quick stats
        Row(children: [
          Expanded(child: _StatTile(emoji: '🚶', value: '6,234', label: 'Steps')),
          const SizedBox(width: 12),
          Expanded(child: _StatTile(emoji: '🔥', value: '1,840', label: 'Cal')),
          const SizedBox(width: 12),
          Expanded(child: _StatTile(emoji: '💧', value: '5/8', label: 'Glasses')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatTile(emoji: '😴', value: '7h 23m', label: 'Sleep')),
          const SizedBox(width: 12),
          Expanded(child: _StatTile(emoji: '❤️', value: '72', label: 'BPM')),
          const SizedBox(width: 12),
          Expanded(child: _StatTile(emoji: '🧘', value: '10 min', label: 'Mindful')),
        ]),
        const SizedBox(height: 24),

        // Weekly progress
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.06))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Weekly Progress', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: ['M','T','W','T','F','S','S'].asMap().entries.map((e) {
              final filled = e.key < 4; // Mon-Thu done
              return Column(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: filled ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                    shape: BoxShape.circle,
                    border: Border.all(color: filled ? accent : Colors.white.withOpacity(0.08)),
                  ),
                  child: filled ? Icon(Icons.check, color: accent, size: 16) : null,
                ),
                const SizedBox(height: 4),
                Text(e.value, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
              ]);
            }).toList()),
          ]),
        ),
        const SizedBox(height: 16),

        // Tip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.06))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('💡 Tip of the Day', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            Text('10 minutes of morning sunlight resets your circadian rhythm and improves sleep quality by up to 40%.', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 16),

        // Health records
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.06))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.folder_outlined, color: accent, size: 18),
              const SizedBox(width: 8),
              Text('Health Records', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
            const SizedBox(height: 12),
            _RecordRow(icon: Icons.monitor_heart, label: 'Blood Pressure', value: '120/80', accent: accent),
            _RecordRow(icon: Icons.bloodtype, label: 'Blood Type', value: 'O+', accent: accent),
            _RecordRow(icon: Icons.height, label: 'BMI', value: '22.4', accent: accent),
            _RecordRow(icon: Icons.vaccines, label: 'Last Checkup', value: 'Dec 2025', accent: accent),
          ]),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _ScoreRing({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(width: 48, height: 48, child: Stack(alignment: Alignment.center, children: [
        CircularProgressIndicator(value: value / 100, strokeWidth: 3, backgroundColor: color.withOpacity(0.15), valueColor: AlwaysStoppedAnimation(color)),
        Text('$value', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
      ])),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  final String emoji, value, label;
  const _StatTile({required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
      ]),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color accent;
  const _RecordRow({required this.icon, required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, color: accent.withOpacity(0.6), size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14))),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    );
  }
}
