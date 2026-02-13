import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/animations/driba_animations.dart';
import 'travel_models.dart';

/// Travel Detail Sheet — Destination details + booking
class TravelDetailSheet extends StatefulWidget {
  final Destination destination;

  const TravelDetailSheet({super.key, required this.destination});

  @override
  State<TravelDetailSheet> createState() => _TravelDetailSheetState();
}

class _TravelDetailSheetState extends State<TravelDetailSheet>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _entranceController;
  double _scrollOffset = 0;
  Hotel? _selectedHotel;
  bool _isSaved = false;

  // Booking state
  DateTime _checkIn = DateTime.now().add(const Duration(days: 14));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 17));
  int _guests = 2;

  static const Color _accent = Color(0xFF00B4D8);
  static const Color _accentLight = Color(0xFF48CAE4);

  Destination get dest => widget.destination;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _entranceController = AnimationController(
      vsync: this,
      duration: DribaDurations.slow,
    )..forward();
    if (dest.hotels.isNotEmpty) _selectedHotel = dest.hotels.first;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() => _scrollOffset = _scrollController.offset);
  }

  void _showBookingConfirmation() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(DribaSpacing.xxl),
          borderRadius: BorderRadius.circular(DribaBorderRadius.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: DribaColors.success.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: DribaColors.success, size: 32),
              ),
              const SizedBox(height: DribaSpacing.xl),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  color: DribaColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: DribaSpacing.sm),
              Text(
                '${dest.name} · ${_nights} nights\n${_selectedHotel?.name ?? ""}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DribaColors.textTertiary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: DribaSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: DribaSpacing.md),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_accent, _accentLight],
                      ),
                      borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                    ),
                    child: const Center(
                      child: Text(
                        'View Trip',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int get _nights => _checkOut.difference(_checkIn).inDays;

  double get _totalPrice {
    if (_selectedHotel == null) return 0;
    return _selectedHotel!.pricePerNight * _nights;
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final imageHeight = 300.0;
    final collapseProgress = (_scrollOffset / imageHeight).clamp(0.0, 1.0);

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: DribaColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DribaBorderRadius.xxl),
        ),
      ),
      child: Stack(
        children: [
          // Content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero image
              SliverToBoxAdapter(
                child: _buildHeroImage(imageHeight),
              ),

              // Destination info
              SliverToBoxAdapter(
                child: _buildDestInfo(),
              ),

              // Date picker
              SliverToBoxAdapter(
                child: _buildDatePicker(),
              ),

              // Hotels
              if (dest.hotels.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionTitle('Where to Stay', '🏨'),
                ),
                SliverToBoxAdapter(child: _buildHotels()),
              ],

              // Experiences
              if (dest.experiences.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionTitle('Things to Do', '✨'),
                ),
                SliverToBoxAdapter(child: _buildExperiences()),
              ],

              // Info cards
              SliverToBoxAdapter(child: _buildInfoCards()),

              // Bottom space for booking bar
              SliverToBoxAdapter(child: SizedBox(height: 100 + bottomPad)),
            ],
          ),

          // Collapsing header
          _buildCollapsingHeader(topPad, collapseProgress),

          // Bottom booking bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBookingBar(bottomPad),
          ),
        ],
      ),
    );
  }

  // ── Hero Image ──────────────────────────────
  Widget _buildHeroImage(double height) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Transform.translate(
            offset: Offset(0, _scrollOffset * 0.3),
            child: CachedNetworkImage(
              imageUrl: dest.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  DribaColors.surface,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Handle bar
          Positioned(
            top: DribaSpacing.md,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Top buttons
          Positioned(
            top: DribaSpacing.xxl,
            right: DribaSpacing.xl,
            child: Row(
              children: [
                _GlassIconButton(
                  icon: _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _isSaved = !_isSaved);
                  },
                ),
                const SizedBox(width: DribaSpacing.sm),
                _GlassIconButton(
                  icon: Icons.share_outlined,
                  onTap: () => HapticFeedback.lightImpact(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Destination Info ────────────────────────
  Widget _buildDestInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DribaSpacing.xl, 0, DribaSpacing.xl, DribaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            dest.name,
            style: const TextStyle(
              color: DribaColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          // Country + rating
          Row(
            children: [
              Icon(Icons.place, color: _accent, size: 16),
              const SizedBox(width: 3),
              Text(
                dest.country,
                style: TextStyle(
                  color: _accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: DribaSpacing.lg),
              Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
              const SizedBox(width: 3),
              Text(
                '${dest.rating}',
                style: const TextStyle(
                  color: DribaColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                ' (${dest.reviewCount} reviews)',
                style: TextStyle(
                  color: DribaColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: DribaSpacing.lg),
          // Tags
          Wrap(
            spacing: DribaSpacing.sm,
            children: dest.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: DribaSpacing.md, vertical: DribaSpacing.xs),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                ),
                child: Text(
                  tag[0].toUpperCase() + tag.substring(1),
                  style: TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: DribaSpacing.lg),
          // Description
          Text(
            dest.description,
            style: TextStyle(
              color: DribaColors.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: DribaSpacing.lg),
          // Quick info pills
          Row(
            children: [
              _InfoPill(icon: Icons.flight, text: dest.flightTime, accent: _accent),
              const SizedBox(width: DribaSpacing.sm),
              _InfoPill(icon: Icons.calendar_month, text: dest.bestSeason, accent: _accent),
              const SizedBox(width: DribaSpacing.sm),
              _InfoPill(icon: Icons.attach_money, text: dest.priceFrom, accent: _accent),
            ],
          ),
        ],
      ),
    );
  }

  // ── Date Picker ─────────────────────────────
  Widget _buildDatePicker() {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DribaSpacing.xl, DribaSpacing.md, DribaSpacing.xl, DribaSpacing.lg),
      child: GlassContainer(
        padding: const EdgeInsets.all(DribaSpacing.lg),
        borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
        child: Column(
          children: [
            Row(
              children: [
                // Check-in
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _checkIn,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _checkIn = date;
                          if (_checkOut.isBefore(_checkIn.add(const Duration(days: 1)))) {
                            _checkOut = _checkIn.add(const Duration(days: 1));
                          }
                        });
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHECK-IN',
                          style: TextStyle(
                            color: DribaColors.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${months[_checkIn.month - 1]} ${_checkIn.day}',
                          style: const TextStyle(
                            color: DribaColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Arrow
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$_nights',
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                // Check-out
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _checkOut,
                        firstDate: _checkIn.add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _checkOut = date);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'CHECK-OUT',
                          style: TextStyle(
                            color: DribaColors.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${months[_checkOut.month - 1]} ${_checkOut.day}',
                          style: const TextStyle(
                            color: DribaColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DribaSpacing.md),
            Divider(color: DribaColors.glassBorder, height: 1),
            const SizedBox(height: DribaSpacing.md),
            // Guests
            Row(
              children: [
                Icon(Icons.people_outline, color: DribaColors.textTertiary, size: 18),
                const SizedBox(width: DribaSpacing.sm),
                Text(
                  '$_guests Guest${_guests > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: DribaColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                _QtyButton(
                  icon: Icons.remove,
                  onTap: _guests > 1
                      ? () => setState(() => _guests--)
                      : null,
                  accent: _accent,
                ),
                const SizedBox(width: DribaSpacing.md),
                _QtyButton(
                  icon: Icons.add,
                  onTap: _guests < 10
                      ? () => setState(() => _guests++)
                      : null,
                  accent: _accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Hotels ──────────────────────────────────
  Widget _buildHotels() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DribaSpacing.xl, 0, DribaSpacing.xl, DribaSpacing.lg),
      child: Column(
        children: dest.hotels.map((hotel) {
          final isSelected = _selectedHotel?.id == hotel.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: DribaSpacing.md),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedHotel = hotel);
              },
              child: AnimatedContainer(
                duration: DribaDurations.fast,
                decoration: BoxDecoration(
                  color: isSelected
                      ? _accent.withOpacity(0.06)
                      : DribaColors.glassFill,
                  borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
                  border: Border.all(
                    color: isSelected ? _accent : DribaColors.glassBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(DribaBorderRadius.xl),
                      ),
                      child: SizedBox(
                        width: 110,
                        height: 110,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: hotel.imageUrl,
                              fit: BoxFit.cover,
                            ),
                            if (hotel.dealText != null)
                              Positioned(
                                top: DribaSpacing.sm,
                                left: DribaSpacing.sm,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _accent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    hotel.dealText!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Info
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(DribaSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hotel.name,
                              style: const TextStyle(
                                color: DribaColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                ...List.generate(hotel.stars, (_) =>
                                    const Icon(Icons.star, color: Color(0xFFFFD700), size: 11)),
                                const SizedBox(width: 4),
                                Text(
                                  hotel.location,
                                  style: TextStyle(
                                    color: DribaColors.textTertiary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Amenities
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: hotel.amenities.take(3).map((a) {
                                return Text(
                                  a,
                                  style: TextStyle(
                                    color: DribaColors.textTertiary,
                                    fontSize: 10,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: DribaSpacing.sm),
                            Row(
                              children: [
                                Icon(Icons.star, color: Color(0xFFFFD700), size: 13),
                                Text(
                                  ' ${hotel.rating}',
                                  style: const TextStyle(
                                    color: DribaColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  ' (${hotel.reviewCount})',
                                  style: TextStyle(
                                    color: DribaColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                                const Spacer(),
                                if (hotel.hasDiscount) ...[
                                  Text(
                                    '\$${hotel.originalPrice!.toInt()}',
                                    style: TextStyle(
                                      color: DribaColors.textDisabled,
                                      fontSize: 12,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  '\$${hotel.pricePerNight.toInt()}',
                                  style: TextStyle(
                                    color: _accent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  '/night',
                                  style: TextStyle(
                                    color: DribaColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Selection radio
                    Padding(
                      padding: const EdgeInsets.only(right: DribaSpacing.md),
                      child: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? _accent : DribaColors.textDisabled,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Experiences ─────────────────────────────
  Widget _buildExperiences() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DribaSpacing.xl, 0, DribaSpacing.xl, DribaSpacing.lg),
      child: Column(
        children: dest.experiences.map((exp) {
          return Padding(
            padding: const EdgeInsets.only(bottom: DribaSpacing.md),
            child: GlassContainer(
              borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(DribaBorderRadius.xl),
                    ),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: CachedNetworkImage(
                        imageUrl: exp.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(DribaSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exp.title,
                            style: const TextStyle(
                              color: DribaColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.schedule, color: DribaColors.textTertiary, size: 12),
                              const SizedBox(width: 3),
                              Text(exp.duration,
                                  style: TextStyle(color: DribaColors.textTertiary, fontSize: 12)),
                              const SizedBox(width: DribaSpacing.md),
                              Icon(Icons.person, color: DribaColors.textTertiary, size: 12),
                              const SizedBox(width: 3),
                              Text('by ${exp.hostName}',
                                  style: TextStyle(color: DribaColors.textTertiary, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: DribaSpacing.sm),
                          Row(
                            children: [
                              Icon(Icons.star, color: Color(0xFFFFD700), size: 13),
                              Text(
                                ' ${exp.rating} (${exp.reviewCount})',
                                style: TextStyle(
                                  color: DribaColors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '\$${exp.price.toInt()}',
                                style: TextStyle(
                                  color: _accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '/person',
                                style: TextStyle(
                                  color: DribaColors.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Info Cards ──────────────────────────────
  Widget _buildInfoCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: _InfoCard(
              icon: Icons.wb_sunny_outlined,
              title: 'Best Season',
              value: dest.bestSeason,
              accent: _accent,
            ),
          ),
          const SizedBox(width: DribaSpacing.md),
          Expanded(
            child: _InfoCard(
              icon: Icons.flight_outlined,
              title: 'Flight',
              value: dest.flightTime,
              accent: _accent,
            ),
          ),
          const SizedBox(width: DribaSpacing.md),
          Expanded(
            child: _InfoCard(
              icon: Icons.money_off,
              title: 'Fees',
              value: '0%',
              accent: DribaColors.success,
            ),
          ),
        ],
      ),
    );
  }

  // ── Collapsing Header ───────────────────────
  Widget _buildCollapsingHeader(double topPad, double progress) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: progress < 0.5,
        child: AnimatedOpacity(
          opacity: progress > 0.6 ? 1.0 : 0.0,
          duration: DribaDurations.fast,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  DribaSpacing.lg,
                  topPad + DribaSpacing.sm,
                  DribaSpacing.lg,
                  DribaSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: DribaColors.glassFill,
                  border: Border(bottom: BorderSide(color: DribaColors.glassBorder)),
                ),
                child: Row(
                  children: [
                    GlassCircleButton(
                      size: 36,
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close,
                          color: DribaColors.textPrimary, size: 18),
                    ),
                    const SizedBox(width: DribaSpacing.md),
                    Expanded(
                      child: Text(
                        dest.name,
                        style: const TextStyle(
                          color: DribaColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      dest.priceFrom,
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Booking Bar ─────────────────────────────
  Widget _buildBookingBar(double bottomPad) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            DribaSpacing.xl,
            DribaSpacing.lg,
            DribaSpacing.xl,
            bottomPad + DribaSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: DribaColors.surface.withOpacity(0.9),
            border: Border(top: BorderSide(color: DribaColors.glassBorder)),
          ),
          child: Row(
            children: [
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\$${_totalPrice.toInt()}',
                    style: const TextStyle(
                      color: DribaColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$_nights nights · $_guests guests',
                    style: TextStyle(
                      color: DribaColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Book button
              GestureDetector(
                onTap: _selectedHotel != null ? _showBookingConfirmation : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DribaSpacing.xxl, vertical: DribaSpacing.md),
                  decoration: BoxDecoration(
                    gradient: _selectedHotel != null
                        ? const LinearGradient(colors: [_accent, _accentLight])
                        : null,
                    color: _selectedHotel != null ? null : DribaColors.glassFillActive,
                    borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                    boxShadow: _selectedHotel != null
                        ? [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 12)]
                        : null,
                  ),
                  child: Text(
                    'Book Now',
                    style: TextStyle(
                      color: _selectedHotel != null
                          ? Colors.white
                          : DribaColors.textDisabled,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String emoji) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DribaSpacing.xl, DribaSpacing.lg, DribaSpacing.xl, DribaSpacing.md),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: DribaSpacing.sm),
          Text(
            title,
            style: const TextStyle(
              color: DribaColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _GlassIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accent;

  const _InfoPill({required this.icon, required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DribaSpacing.md, vertical: DribaSpacing.xs),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 13),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color accent;

  const _QtyButton({required this.icon, this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.selectionClick();
          onTap!();
        }
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null ? accent.withOpacity(0.1) : DribaColors.glassFill,
          shape: BoxShape.circle,
          border: Border.all(
            color: onTap != null ? accent.withOpacity(0.3) : DribaColors.glassBorder,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? accent : DribaColors.textDisabled,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color accent;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(DribaSpacing.md),
      borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: DribaSpacing.xs),
          Text(
            title,
            style: TextStyle(
              color: DribaColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: DribaColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
