import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/driba_colors.dart';
import 'shell_state.dart';

// ============================================
// ENGAGEMENT OVERLAY — v3
//
// Single bottom bar that morphs per action.
// Slides up from bottom with heavy blur.
// Each action has unique messaging + submit icon.
// Hidden on Chat screen.
//
// Flow (one at a time, slow):
//   Like → Comment → Save → Share → gone
// ============================================

class EngagementOverlay extends ConsumerWidget {
  const EngagementOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engagement = ref.watch(engagementProvider);
    final screen = ref.watch(currentScreenProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // Hide on Chat — it has its own input
    if (screen == DribaScreen.chat) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: _EngagementBar(
        action: engagement.activeAction,
        bottomPad: bottomPad,
      ),
    );
  }
}

/// Bottom action bar — morphs per engagement action
class _EngagementBar extends StatefulWidget {
  final EngagementAction action;
  final double bottomPad;

  const _EngagementBar({required this.action, required this.bottomPad});

  @override
  State<_EngagementBar> createState() => _EngagementBarState();
}

class _EngagementBarState extends State<_EngagementBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  final _textController = TextEditingController();
  bool _isEditing = false;

  // Varied messages per action so user doesn't get bored
  static final _random = math.Random();

  static const _likeMessages = [
    'Tap the heart if this resonates ✨',
    'Show some love if you vibe with this 💫',
    'Double-tap energy — hit the heart ❤️',
    'Feel this? Let them know 🤍',
    'One tap to make their day 💜',
  ];

  static const _commentMessages = [
    'Drop your thoughts here...',
    'What comes to mind? Share it...',
    'Say something — they\'re listening...',
    'Your take on this?',
    'Add your perspective...',
  ];

  static const _commentPrefills = [
    'This is incredible 🔥',
    'Love everything about this ✨',
    'Needed to see this today 🙌',
    'So good. More of this please 💯',
    'Saving this for later 🔖',
  ];

  static const _saveMessages = [
    'Worth saving? Bookmark it 📌',
    'Come back to this later — save it 🔖',
    'Don\'t lose this one — tap to keep 💾',
    'Your future self will thank you 📚',
    'Add this to your collection ⭐',
  ];

  static const _shareMessages = [
    'Know someone who needs this? 📤',
    'Share the good stuff — pass it on 💌',
    'Send this to a friend who\'d love it 🫶',
    'Too good to keep to yourself 🌟',
    'Spread the word — share it 📣',
  ];

  EngagementAction _currentAction = EngagementAction.none;
  String _message = '';
  String _prefill = '';

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 500),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_EngagementBar old) {
    super.didUpdateWidget(old);
    if (widget.action != old.action) {
      _handleActionChange(widget.action);
    }
  }

  void _handleActionChange(EngagementAction newAction) {
    if (newAction == EngagementAction.none) {
      _anim.reverse().then((_) {
        if (mounted) setState(() {
          _currentAction = EngagementAction.none;
          _isEditing = false;
        });
      });
    } else {
      // If already showing, cross-fade by reversing then forwarding
      if (_anim.isCompleted || _anim.isAnimating) {
        _anim.reverse().then((_) {
          if (mounted) {
            _setActionContent(newAction);
            _anim.forward();
          }
        });
      } else {
        _setActionContent(newAction);
        _anim.forward();
      }
    }
  }

  void _setActionContent(EngagementAction action) {
    setState(() {
      _currentAction = action;
      _isEditing = false;
      switch (action) {
        case EngagementAction.like:
          _message = _likeMessages[_random.nextInt(_likeMessages.length)];
          _prefill = '';
        case EngagementAction.comment:
          _message = _commentMessages[_random.nextInt(_commentMessages.length)];
          _prefill = _commentPrefills[_random.nextInt(_commentPrefills.length)];
          _textController.text = _prefill;
        case EngagementAction.save:
          _message = _saveMessages[_random.nextInt(_saveMessages.length)];
          _prefill = '';
        case EngagementAction.share:
          _message = _shareMessages[_random.nextInt(_shareMessages.length)];
          _prefill = '';
        default:
          _message = '';
          _prefill = '';
      }
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _textController.dispose();
    super.dispose();
  }

  IconData _actionIcon() {
    switch (_currentAction) {
      case EngagementAction.like:
        return Icons.favorite_rounded;
      case EngagementAction.comment:
        return Icons.arrow_upward_rounded;
      case EngagementAction.save:
        return Icons.bookmark_rounded;
      case EngagementAction.share:
        return Icons.send_rounded;
      default:
        return Icons.circle;
    }
  }

  Color _actionColor() {
    switch (_currentAction) {
      case EngagementAction.like:
        return const Color(0xFFFF2D55);
      case EngagementAction.comment:
        return DribaColors.primary;
      case EngagementAction.save:
        return const Color(0xFFFFD700);
      case EngagementAction.share:
        return const Color(0xFF00D68F);
      default:
        return DribaColors.primary;
    }
  }

  void _onSubmit() {
    HapticFeedback.mediumImpact();
    // TODO: wire to Firestore actions
    // For now, dismiss
    _anim.reverse();
  }

  void _onTextFieldTap() {
    if (_currentAction == EngagementAction.comment && !_isEditing) {
      setState(() => _isEditing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: _buildBar(),
      ),
    );
  }

  Widget _buildBar() {
    final color = _actionColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Expanded comment editor (slides up when tapped)
        if (_isEditing && _currentAction == EngagementAction.comment)
          _buildExpandedEditor(color),

        // Main bar
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 14, 12, widget.bottomPad + 14),
              decoration: BoxDecoration(
                color: const Color(0xFF050B14).withOpacity(0.85),
                border: Border(
                  top: BorderSide(color: color.withOpacity(0.15), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  // Message text or editable field
                  Expanded(
                    child: _currentAction == EngagementAction.comment && !_isEditing
                        ? GestureDetector(
                            onTap: _onTextFieldTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Text(
                                _prefill.isNotEmpty ? _prefill : _message,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                        : Text(
                            _message,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),

                  const SizedBox(width: 12),

                  // Action button
                  GestureDetector(
                    onTap: _onSubmit,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                      ),
                      child: Icon(_actionIcon(), color: color, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedEditor(Color color) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF050B14).withOpacity(0.9),
            border: Border(
              top: BorderSide(color: color.withOpacity(0.1), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: TextField(
                    controller: _textController,
                    autofocus: true,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15),
                    decoration: InputDecoration(
                      hintText: _message,
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (_) => _onSubmit(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _onSubmit,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
