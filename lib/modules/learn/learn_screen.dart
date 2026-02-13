import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/animations/driba_animations.dart';

// ============================================
// LEARN SCREEN
// Courses, AI tutor, progress — purple (#8B5CF6)
// ============================================

class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  String _selectedCategory = 'all';

  static const Color _accent = Color(0xFF8B5CF6);
  static const Color _accentLight = Color(0xFFA78BFA);

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: DribaDurations.slow,
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: DribaColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(DribaSpacing.xl, topPad + DribaSpacing.lg, DribaSpacing.xl, 0),
              child: _buildHeader(),
            ),
          ),
          SliverToBoxAdapter(child: _buildDailyProgress()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: DribaSpacing.md),
              child: _buildCategories(),
            ),
          ),
          SliverToBoxAdapter(child: _buildSectionHeader('Continue Learning', '📚')),
          SliverToBoxAdapter(child: _buildContinueLearning()),
          SliverToBoxAdapter(child: _buildAiTutorCard()),
          SliverToBoxAdapter(child: _buildSectionHeader('Popular Courses', '🔥')),
          _buildCoursesGrid(),
          SliverToBoxAdapter(child: _buildSectionHeader('5-Min Lessons', '⚡')),
          SliverToBoxAdapter(child: _buildQuickLessons()),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Learn', style: TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const Text('Level up today', style: TextStyle(color: DribaColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            ],
          ),
        ),
        GlassCircleButton(size: 42, onTap: () => HapticFeedback.lightImpact(), child: const Icon(Icons.search, color: DribaColors.textSecondary, size: 20)),
        const SizedBox(width: DribaSpacing.sm),
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.md, vertical: DribaSpacing.sm),
          borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
          borderColor: const Color(0xFFFF6B35).withOpacity(0.3),
          child: const Row(
            children: [
              Text('🔥', style: TextStyle(fontSize: 16)),
              SizedBox(width: 4),
              Text('12', style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(DribaSpacing.xl, DribaSpacing.xl, DribaSpacing.xl, 0),
      child: GlassContainer(
        padding: const EdgeInsets.all(DribaSpacing.lg),
        borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
        borderColor: _accent.withOpacity(0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Today\'s Progress', style: TextStyle(color: DribaColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                Text('2/3 goals', style: TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            const SizedBox(height: DribaSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.67,
                backgroundColor: DribaColors.glassFillActive,
                valueColor: AlwaysStoppedAnimation<Color>(_accent),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: DribaSpacing.lg),
            Row(
              children: [
                _MiniStat(icon: Icons.schedule, value: '45m', label: 'Time', color: _accent),
                const SizedBox(width: DribaSpacing.xl),
                _MiniStat(icon: Icons.check_circle_outline, value: '3', label: 'Lessons', color: DribaColors.success),
                const SizedBox(width: DribaSpacing.xl),
                _MiniStat(icon: Icons.star_outline, value: '120', label: 'XP', color: const Color(0xFFFFD700)),
                const SizedBox(width: DribaSpacing.xl),
                _MiniStat(icon: Icons.local_fire_department, value: '12', label: 'Streak', color: const Color(0xFFFF6B35)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    const categories = [
      ('all', 'All', '📖'), ('design', 'Design', '🎨'), ('coding', 'Coding', '💻'),
      ('business', 'Business', '💼'), ('language', 'Language', '🗣️'), ('ai', 'AI & ML', '🤖'),
      ('marketing', 'Marketing', '📊'), ('finance', 'Finance', '💰'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: DribaSpacing.sm),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.$1 == _selectedCategory;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedCategory = cat.$1); },
            child: AnimatedContainer(
              duration: DribaDurations.fast,
              padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.lg, vertical: DribaSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected ? _accent.withOpacity(0.15) : DribaColors.glassFill,
                borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                border: Border.all(color: isSelected ? _accent : DribaColors.glassBorder),
              ),
              child: Row(children: [
                Text(cat.$3, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: DribaSpacing.xs),
                Text(cat.$2, style: TextStyle(color: isSelected ? _accent : DribaColors.textSecondary, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContinueLearning() {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
        itemCount: _LearnData.inProgress.length,
        separatorBuilder: (_, __) => const SizedBox(width: DribaSpacing.md),
        itemBuilder: (context, index) {
          final c = _LearnData.inProgress[index];
          return GestureDetector(
            onTap: () => HapticFeedback.mediumImpact(),
            child: SizedBox(
              width: 260,
              child: GlassContainer(
                padding: const EdgeInsets.all(DribaSpacing.lg),
                borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
                borderColor: Color(c.$5).withOpacity(0.15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Color(c.$5).withOpacity(0.15), borderRadius: BorderRadius.circular(DribaBorderRadius.md)),
                        child: Center(child: Text(c.$2, style: const TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: DribaSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.$1, style: const TextStyle(color: DribaColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${c.$3}/${c.$4} lessons', style: TextStyle(color: DribaColors.textTertiary, fontSize: 12)),
                      ])),
                    ]),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(value: c.$3 / c.$4, backgroundColor: DribaColors.glassFillActive, valueColor: AlwaysStoppedAnimation(Color(c.$5)), minHeight: 6),
                    ),
                    const SizedBox(height: DribaSpacing.sm),
                    Row(children: [
                      Text('${(c.$3 / c.$4 * 100).toInt()}% complete', style: TextStyle(color: DribaColors.textTertiary, fontSize: 11)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.md, vertical: DribaSpacing.xs),
                        decoration: BoxDecoration(color: Color(c.$5), borderRadius: BorderRadius.circular(DribaBorderRadius.pill)),
                        child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAiTutorCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(DribaSpacing.xl, DribaSpacing.xl, DribaSpacing.xl, 0),
      child: GestureDetector(
        onTap: () => HapticFeedback.mediumImpact(),
        child: Container(
          padding: const EdgeInsets.all(DribaSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_accent.withOpacity(0.15), _accentLight.withOpacity(0.08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(DribaBorderRadius.xxl),
            border: Border.all(color: _accent.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [_accent, _accentLight]), borderRadius: BorderRadius.circular(DribaBorderRadius.lg), boxShadow: [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 12)]),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              ),
              const SizedBox(width: DribaSpacing.lg),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('AI Tutor', style: TextStyle(color: DribaColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 2),
                Text('Ask anything. Get personalized explanations, quizzes, and study plans.', style: TextStyle(color: DribaColors.textTertiary, fontSize: 13, height: 1.3)),
              ])),
              Icon(Icons.arrow_forward_ios, color: _accent, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  SliverPadding _buildCoursesGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: DribaSpacing.md, mainAxisSpacing: DribaSpacing.md),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final c = _LearnData.popular[index];
            return AnimatedBuilder(
              animation: _entranceController,
              builder: (_, child) {
                final delay = (index * 0.06 + 0.2).clamp(0.0, 0.6);
                final p = ((_entranceController.value - delay) / (1 - delay)).clamp(0.0, 1.0);
                return Opacity(opacity: Curves.easeOut.transform(p), child: Transform.translate(offset: Offset(0, 20 * (1 - Curves.easeOut.transform(p))), child: child));
              },
              child: GestureDetector(
                onTap: () => HapticFeedback.mediumImpact(),
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(DribaBorderRadius.xl)),
                          child: Stack(fit: StackFit.expand, children: [
                            CachedNetworkImage(imageUrl: c.imageUrl, fit: BoxFit.cover),
                            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.5)], stops: const [0.5, 1.0]))),
                            if (c.isFree) Positioned(top: DribaSpacing.sm, left: DribaSpacing.sm,
                              child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: DribaColors.success, borderRadius: BorderRadius.circular(4)),
                                child: const Text('FREE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))),
                            Positioned(bottom: DribaSpacing.sm, right: DribaSpacing.sm,
                              child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                                child: Text(c.duration, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)))),
                          ]),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(DribaSpacing.md),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.title, style: const TextStyle(color: DribaColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(c.instructor, style: TextStyle(color: DribaColors.textTertiary, fontSize: 12)),
                            const Spacer(),
                            Row(children: [
                              const Icon(Icons.star, color: Color(0xFFFFD700), size: 13),
                              Text(' ${c.rating}', style: const TextStyle(color: DribaColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
                              Text(' (${c.students})', style: TextStyle(color: DribaColors.textTertiary, fontSize: 11)),
                              const Spacer(),
                              if (!c.isFree) Text('\$${c.price.toInt()}', style: TextStyle(color: _accent, fontWeight: FontWeight.w800, fontSize: 14)),
                            ]),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: _LearnData.popular.length,
        ),
      ),
    );
  }

  Widget _buildQuickLessons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
      child: Column(
        children: _LearnData.quickLessons.map((l) {
          return Padding(
            padding: const EdgeInsets.only(bottom: DribaSpacing.sm),
            child: GestureDetector(
              onTap: () => HapticFeedback.lightImpact(),
              child: GlassContainer(
                padding: const EdgeInsets.all(DribaSpacing.md),
                borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
                child: Row(children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: _accent.withOpacity(0.1), borderRadius: BorderRadius.circular(DribaBorderRadius.md)),
                    child: Center(child: Text(l.$3, style: const TextStyle(fontSize: 20)))),
                  const SizedBox(width: DribaSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.$1, style: const TextStyle(color: DribaColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(l.$2, style: TextStyle(color: DribaColors.textTertiary, fontSize: 12)),
                  ])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _accent.withOpacity(0.1), borderRadius: BorderRadius.circular(DribaBorderRadius.pill)),
                    child: Text('5 min', style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w700))),
                  const SizedBox(width: DribaSpacing.sm),
                  Icon(Icons.play_circle_filled, color: _accent, size: 28),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String emoji) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(DribaSpacing.xl, DribaSpacing.xxl, DribaSpacing.xl, DribaSpacing.md),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: DribaSpacing.sm),
        Text(title, style: const TextStyle(color: DribaColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
        const Spacer(),
        GestureDetector(onTap: () => HapticFeedback.lightImpact(), child: Text('See all', style: TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon; final String value, label; final Color color;
  const _MiniStat({required this.icon, required this.value, required this.label, required this.color});
  @override Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: color, size: 18), const SizedBox(height: 2),
      Text(value, style: TextStyle(color: DribaColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
      Text(label, style: TextStyle(color: DribaColors.textTertiary, fontSize: 10)),
    ]);
  }
}

// ── Data ──────────────────────────────────────
class _CourseData {
  final String title, instructor, imageUrl, duration, students;
  final double rating, price; final bool isFree;
  const _CourseData({required this.title, required this.instructor, required this.imageUrl, required this.duration, this.rating = 0, this.price = 0, this.students = '', this.isFree = false});
}

class _LearnData {
  // (title, emoji, completed, total, color)
  static const inProgress = [
    ('Flutter Masterclass', '💙', 18, 32, 0xFF42A5F5),
    ('UI/UX Design System', '🎨', 7, 15, 0xFF8B5CF6),
    ('Darija for Beginners', '🇲🇦', 12, 20, 0xFFFF6B35),
  ];

  static const popular = [
    _CourseData(title: 'Building AI Apps with Claude', instructor: 'Anthropic Team', imageUrl: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=400', duration: '8h 30m', rating: 4.9, students: '12.4K', isFree: true),
    _CourseData(title: 'Advanced Figma & Design Systems', instructor: 'Sara El Amrani', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', duration: '6h 15m', rating: 4.8, price: 49, students: '8.2K'),
    _CourseData(title: 'Full-Stack with Firebase', instructor: 'Ahmed Benali', imageUrl: 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=400', duration: '12h', rating: 4.7, price: 79, students: '5.6K'),
    _CourseData(title: 'Growth Marketing Playbook', instructor: 'Leila Fassi', imageUrl: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400', duration: '4h 45m', rating: 4.6, price: 39, students: '3.1K'),
    _CourseData(title: 'Moroccan Arabic (Darija)', instructor: 'Youssef Tazi', imageUrl: 'https://images.unsplash.com/photo-1489749798305-4fea3ae63d43?w=400', duration: '10h', rating: 4.9, students: '15.8K', isFree: true),
    _CourseData(title: 'Personal Finance & Investing', instructor: 'Nadia Chraibi', imageUrl: 'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=400', duration: '5h 20m', rating: 4.5, price: 29, students: '4.2K'),
  ];

  static const quickLessons = [
    ('CSS Grid in 5 Minutes', 'Web Development', '🌐'),
    ('Intro to Prompt Engineering', 'AI & ML', '🤖'),
    ('Color Theory Basics', 'Design', '🎨'),
    ('Reading Financial Statements', 'Finance', '📊'),
    ('Arabic Greetings & Phrases', 'Language', '🗣️'),
  ];
}
