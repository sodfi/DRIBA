import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/screen_shell.dart';

/// Utility — Content-first tech tips, productivity hacks, AI showcases.
/// "Toolbox" filter → grid of actual tools (QR, calc, translate, etc).
class UtilityScreen extends StatelessWidget {
  const UtilityScreen({super.key});

  static const Color _accent = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    return DribaScreenShell(
      screenId: 'utility',
      screenLabel: 'Utility',
      accent: _accent,
      filters: const [
        DribaFilter('Digital Life', '⚡'),
        DribaFilter('AI Assistant', '🤖'),
        DribaFilter('Apps', '📱'),
        DribaFilter('Toolbox', '🔧'),
      ],
      personalFilterIndex: 3,
      personalView: const _ToolboxView(),
    );
  }
}

// ============================================
// TOOLBOX — Grid of actual utility tools
// ============================================

class _ToolboxView extends StatelessWidget {
  const _ToolboxView();

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF8B5CF6);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // AI Quick Actions
        Row(children: [
          Icon(Icons.auto_awesome, color: accent, size: 18),
          const SizedBox(width: 8),
          Text('AI Quick Actions', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        const SizedBox(height: 12),
        _QuickActionBar(accent: accent),
        const SizedBox(height: 24),

        // Tools grid
        Row(children: [
          Icon(Icons.apps, color: accent, size: 18),
          const SizedBox(width: 8),
          Text('Tools', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: const [
            _ToolTile(icon: Icons.qr_code_scanner, label: 'QR Scan', color: Color(0xFF00E1FF)),
            _ToolTile(icon: Icons.calculate, label: 'Calculator', color: Color(0xFFFF6B35)),
            _ToolTile(icon: Icons.translate, label: 'Translate', color: Color(0xFF00B4D8)),
            _ToolTile(icon: Icons.cloud_queue, label: 'Weather', color: Color(0xFF00D68F)),
            _ToolTile(icon: Icons.straighten, label: 'Convert', color: Color(0xFFFFD700)),
            _ToolTile(icon: Icons.timer, label: 'Timer', color: Color(0xFFFF3D71)),
            _ToolTile(icon: Icons.text_fields, label: 'OCR Scan', color: Color(0xFF8B5CF6)),
            _ToolTile(icon: Icons.wifi_tethering, label: 'Speed Test', color: Color(0xFF00E1FF)),
            _ToolTile(icon: Icons.lock, label: 'Passwords', color: Color(0xFFFF2E93)),
          ],
        ),
        const SizedBox(height: 24),

        // Shortcuts
        Row(children: [
          Icon(Icons.bolt, color: accent, size: 18),
          const SizedBox(width: 8),
          Text('Shortcuts', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        const SizedBox(height: 12),
        _ShortcutRow(icon: Icons.flashlight_on, label: 'Flashlight', accent: accent),
        _ShortcutRow(icon: Icons.compass_calibration, label: 'Compass', accent: accent),
        _ShortcutRow(icon: Icons.volume_up, label: 'Sound Meter', accent: accent),
        _ShortcutRow(icon: Icons.color_lens, label: 'Color Picker', accent: accent),
        const SizedBox(height: 40),
      ]),
    );
  }
}

class _QuickActionBar extends StatelessWidget {
  final Color accent;
  const _QuickActionBar({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent.withOpacity(0.12), accent.withOpacity(0.04)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(children: [
            Icon(Icons.auto_awesome, color: accent.withOpacity(0.5), size: 18),
            const SizedBox(width: 12),
            Text('Ask AI anything...', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14)),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _QuickChip(label: '📝 Summarize', accent: accent),
          const SizedBox(width: 8),
          _QuickChip(label: '🌐 Translate', accent: accent),
          const SizedBox(width: 8),
          _QuickChip(label: '💡 Explain', accent: accent),
        ]),
      ]),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final Color accent;
  const _QuickChip({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Text(label, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ToolTile({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.mediumImpact(),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  const _ShortcutRow({required this.icon, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: accent, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
        Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 20),
      ]),
    );
  }
}
