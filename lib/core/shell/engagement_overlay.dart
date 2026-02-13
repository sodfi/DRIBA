import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/driba_colors.dart';
import 'shell_state.dart';

// ============================================
// ENGAGEMENT OVERLAY v6
//
// Timed bottom bar — one action at a time:
//   Like (9s) → Comment (9s) → Save (9s) → Share (9s)
//
// Smooth crossfade transitions between actions.
// Only visible when viewing a post.
// Anonymous users → sign up prompt.
// ============================================

class EngagementOverlay extends ConsumerWidget {
  const EngagementOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = ref.watch(shellProvider);
    final screen = shell.currentScreen;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    if (screen == DribaScreen.chat || !shell.isViewingPost) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0, right: 0,
      // Sit above the bottom nav bar
      bottom: bottomPad + 60,
      child: _EngagementBar(
        action: shell.engagement.activeAction,
        postId: shell.currentPostId,
      ),
    );
  }
}

class _EngagementBar extends StatefulWidget {
  final EngagementAction action;
  final String? postId;
  const _EngagementBar({required this.action, this.postId});

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
  bool _actionTaken = false;

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
    _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _anim, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));
  }

  @override
  void didUpdateWidget(_EngagementBar old) {
    super.didUpdateWidget(old);
    if (widget.action != old.action) _handleActionChange(widget.action);
  }

  void _handleActionChange(EngagementAction newAction) {
    if (newAction == EngagementAction.none) {
      _anim.reverse().then((_) {
        if (mounted) setState(() { _currentAction = EngagementAction.none; _isEditing = false; _actionTaken = false; });
      });
    } else {
      // Crossfade: slide out → swap content → slide in
      if (_anim.isCompleted || _anim.isAnimating) {
        _anim.reverse().then((_) {
          if (mounted) { _setContent(newAction); _anim.forward(); }
        });
      } else {
        _setContent(newAction);
        _anim.forward();
      }
    }
  }

  void _setContent(EngagementAction action) {
    setState(() {
      _currentAction = action;
      _isEditing = false;
      _actionTaken = false;
      switch (action) {
        case EngagementAction.like:
          _message = _likeMessages[_random.nextInt(_likeMessages.length)];
        case EngagementAction.comment:
          _message = _commentMessages[_random.nextInt(_commentMessages.length)];
          _prefill = _commentPrefills[_random.nextInt(_commentPrefills.length)];
          _textController.text = _prefill;
        case EngagementAction.save:
          _message = _saveMessages[_random.nextInt(_saveMessages.length)];
        case EngagementAction.share:
          _message = _shareMessages[_random.nextInt(_shareMessages.length)];
        default:
          _message = '';
      }
    });
  }

  @override
  void dispose() { _anim.dispose(); _textController.dispose(); super.dispose(); }

  bool _isAnonymous() {
    final user = FirebaseAuth.instance.currentUser;
    return user == null || user.isAnonymous;
  }

  void _showSignUpPrompt() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _SignUpSheet(),
    );
  }

  void _onSubmit() {
    HapticFeedback.mediumImpact();
    if (_isAnonymous()) { _showSignUpPrompt(); return; }
    final postId = widget.postId;
    if (postId == null) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    setState(() => _actionTaken = true);

    switch (_currentAction) {
      case EngagementAction.like:
        postRef.update({'likes': FieldValue.increment(1)});
      case EngagementAction.comment:
        final text = _textController.text.trim();
        if (text.isNotEmpty) {
          postRef.collection('comments').add({'userId': uid, 'text': text, 'createdAt': FieldValue.serverTimestamp()});
          postRef.update({'comments': FieldValue.increment(1)});
        }
      case EngagementAction.save:
        postRef.update({'saves': FieldValue.increment(1)});
      case EngagementAction.share:
        postRef.update({'shares': FieldValue.increment(1)});
      default: break;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _anim.reverse();
    });
  }

  IconData _icon() {
    if (_actionTaken) return Icons.check_rounded;
    switch (_currentAction) {
      case EngagementAction.like: return Icons.favorite_rounded;
      case EngagementAction.comment: return Icons.arrow_upward_rounded;
      case EngagementAction.save: return Icons.bookmark_rounded;
      case EngagementAction.share: return Icons.send_rounded;
      default: return Icons.circle;
    }
  }

  Color _color() {
    if (_actionTaken) return const Color(0xFF00D68F);
    switch (_currentAction) {
      case EngagementAction.like: return const Color(0xFFFF2D55);
      case EngagementAction.comment: return DribaColors.primary;
      case EngagementAction.save: return const Color(0xFFFFD700);
      case EngagementAction.share: return const Color(0xFF00D68F);
      default: return DribaColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF050B14).withOpacity(0.82),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _color().withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    // Message or tappable comment preview
                    Expanded(
                      child: _currentAction == EngagementAction.comment && !_isEditing
                          ? GestureDetector(
                              onTap: () {
                                if (_isAnonymous()) { _showSignUpPrompt(); return; }
                                setState(() => _isEditing = true);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                                ),
                                child: Text(
                                  _prefill.isNotEmpty ? _prefill : _message,
                                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                          : _currentAction == EngagementAction.comment && _isEditing
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _color().withOpacity(0.15)),
                                  ),
                                  child: TextField(
                                    controller: _textController, autofocus: true,
                                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: _message,
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    onSubmitted: (_) => _onSubmit(),
                                  ),
                                )
                              : Text(
                                  _actionTaken ? 'Done! ✓' : _message,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(_actionTaken ? 0.7 : 0.45),
                                    fontSize: 14, fontWeight: _actionTaken ? FontWeight.w600 : FontWeight.w400, height: 1.4),
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                ),
                    ),
                    const SizedBox(width: 12),
                    // Action button
                    GestureDetector(
                      onTap: _actionTaken ? null : _onSubmit,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _actionTaken ? _color().withOpacity(0.2) : _color().withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: _color().withOpacity(_actionTaken ? 0.5 : 0.25), width: 1.5),
                        ),
                        child: Icon(_icon(), color: _color(), size: 20),
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
}

// ── Sign Up Sheet ──
class _SignUpSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1628).withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: DribaColors.primary.withOpacity(0.15)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    gradient: DribaColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 20),
                const Text('Join Driba', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text('Create a free account to like, comment, save, and interact.', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15, height: 1.5)),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(gradient: DribaColors.primaryGradient, borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text('Maybe later', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
