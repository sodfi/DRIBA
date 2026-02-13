import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/driba_colors.dart';
import 'ai_studio_sheet.dart';

// ============================================================
// CREATE POST SCREEN
//
// Full post creation flow:
//   1. Pick image/video (camera or gallery)
//   2. Write caption with smart suggestions
//   3. Select categories (multi-select)
//   4. Toggle AI Studio (Pro) for enhancements
//   5. Preview → Publish
//
// Dual aspect ratio: user uploads are auto-cropped to both
// 9:16 (mobile) and 16:9 (desktop) on the backend.
// ============================================================

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  final _captionCtrl = TextEditingController();
  final _picker = ImagePicker();
  late AnimationController _publishAnim;

  // State
  Uint8List? _selectedMedia;
  String? _selectedMediaPath;
  String _mediaType = 'image'; // 'image' or 'video'
  final Set<String> _categories = {'feed'};
  bool _isPublishing = false;
  bool _aiEnhanced = false;
  String? _aiMediaUrl; // URL after AI enhancement
  String? _aiVideoUrl; // URL if AI video was generated
  String _aiAction = ''; // what AI did

  // AI Studio Pro toggle
  bool _showAiStudio = false;

  static const _maxCaption = 500;

  @override
  void initState() {
    super.initState();
    _publishAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _publishAnim.dispose();
    super.dispose();
  }

  // ─── Media Picking ──────────────────────────────────────

  Future<void> _pickMedia(ImageSource source, {bool video = false}) async {
    try {
      XFile? file;
      if (video) {
        file = await _picker.pickVideo(source: source, maxDuration: const Duration(seconds: 60));
        if (file != null) _mediaType = 'video';
      } else {
        file = await _picker.pickImage(source: source, maxWidth: 2048, maxHeight: 2048, imageQuality: 85);
        if (file != null) _mediaType = 'image';
      }

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedMedia = bytes;
          _selectedMediaPath = file!.path;
          _aiEnhanced = false;
          _aiMediaUrl = null;
          _aiVideoUrl = null;
          _aiAction = '';
        });
      }
    } catch (e) {
      _showSnack('Could not access media: $e');
    }
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DribaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Add Media', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              _MediaOption(
                icon: Icons.camera_alt_rounded,
                label: 'Take Photo',
                color: DribaColors.primary,
                onTap: () { Navigator.pop(ctx); _pickMedia(ImageSource.camera); },
              ),
              const SizedBox(height: 12),
              _MediaOption(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                color: DribaColors.tertiary,
                onTap: () { Navigator.pop(ctx); _pickMedia(ImageSource.gallery); },
              ),
              const SizedBox(height: 12),
              _MediaOption(
                icon: Icons.videocam_rounded,
                label: 'Record Video',
                color: DribaColors.secondary,
                onTap: () { Navigator.pop(ctx); _pickMedia(ImageSource.camera, video: true); },
              ),
              const SizedBox(height: 12),
              _MediaOption(
                icon: Icons.video_library_rounded,
                label: 'Video from Gallery',
                color: const Color(0xFFFF6B35),
                onTap: () { Navigator.pop(ctx); _pickMedia(ImageSource.gallery, video: true); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── AI Studio ──────────────────────────────────────────

  void _openAiStudio() {
    if (_selectedMedia == null) {
      _showSnack('Add a photo first to use AI Studio');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiStudioSheet(
        mediaBytes: _selectedMedia!,
        mediaType: _mediaType,
        onResult: (result) {
          setState(() {
            _aiEnhanced = true;
            _aiMediaUrl = result.imageUrl;
            _aiVideoUrl = result.videoUrl;
            _aiAction = result.actionLabel;
            if (result.videoUrl != null) _mediaType = 'video';
          });
        },
      ),
    );
  }

  // ─── Publish ────────────────────────────────────────────

  Future<void> _publish() async {
    if (_selectedMedia == null && _aiMediaUrl == null) {
      _showSnack('Add a photo or video');
      return;
    }
    if (_captionCtrl.text.trim().isEmpty) {
      _showSnack('Write a caption');
      return;
    }

    setState(() => _isPublishing = true);
    _publishAnim.repeat();

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'anonymous';
      final displayName = user?.displayName ?? 'Driba User';
      final avatarUrl = user?.photoURL ?? 'https://ui-avatars.com/api/?name=User&background=1a1a2e&color=00e1ff&size=150&bold=true';

      String mediaUrl = _aiMediaUrl ?? '';

      // Upload original media if not AI-processed
      if (mediaUrl.isEmpty && _selectedMedia != null) {
        final postId = FirebaseFirestore.instance.collection('posts').doc().id;
        final ext = _mediaType == 'video' ? 'mp4' : 'png';
        final ref = FirebaseStorage.instance.ref('user-content/$uid/$postId.$ext');
        await ref.putData(
          _selectedMedia!,
          SettableMetadata(contentType: _mediaType == 'video' ? 'video/mp4' : 'image/png'),
        );
        mediaUrl = await ref.getDownloadURL();
      }

      // Extract hashtags from caption
      final hashtagRegex = RegExp(r'#(\w+)');
      final hashtags = hashtagRegex.allMatches(_captionCtrl.text).map((m) => m.group(1)!).toList();

      // Build post document
      final postDoc = {
        'author': uid,
        'authorName': displayName,
        'authorAvatar': avatarUrl,
        'description': _captionCtrl.text.trim(),
        'hashtags': hashtags,
        'categories': _categories.toList(),

        // Media — primary URL (original or AI-enhanced)
        'mediaUrl': mediaUrl,
        'mediaType': _aiVideoUrl != null ? 'video' : _mediaType,

        // If AI generated a video from the photo
        if (_aiVideoUrl != null) 'videoUrl': _aiVideoUrl,

        // AI enhancement metadata
        'isAIGenerated': false,
        'isAIEnhanced': _aiEnhanced,
        if (_aiEnhanced) 'aiEnhancement': {
          'action': _aiAction,
          'originalMediaType': 'image',
          'enhancedAt': FieldValue.serverTimestamp(),
        },

        // Engagement counters
        'likes': 0, 'comments': 0, 'shares': 0, 'saves': 0, 'views': 0,
        'engagementScore': 0,

        // Moderation
        'status': 'pending_review', // user content goes through moderation

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('posts').add(postDoc);

      _publishAnim.stop();
      if (mounted) {
        Navigator.pop(context);
        _showSnack('Post published!', success: true);
      }
    } catch (e) {
      _publishAnim.stop();
      setState(() => _isPublishing = false);
      _showSnack('Failed to publish: $e');
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? DribaColors.success : DribaColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── UI ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 700;

    return Scaffold(
      backgroundColor: DribaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 16, vertical: 16),
                child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DribaColors.background,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white70, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text('Create Post', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          _PublishButton(
            onTap: _publish,
            isPublishing: _isPublishing,
            enabled: _selectedMedia != null || _aiMediaUrl != null,
            animation: _publishAnim,
          ),
        ],
      ),
    );
  }

  // Desktop/tablet layout: side by side
  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: media preview
        Expanded(flex: 5, child: _buildMediaSection()),
        const SizedBox(width: 24),
        // Right: caption + options
        Expanded(flex: 4, child: Column(
          children: [
            _buildCaptionSection(),
            const SizedBox(height: 20),
            _buildCategorySection(),
            const SizedBox(height: 20),
            _buildAiStudioToggle(),
          ],
        )),
      ],
    );
  }

  // Mobile layout: stacked
  Widget _buildNarrowLayout() {
    return Column(
      children: [
        _buildMediaSection(),
        const SizedBox(height: 20),
        _buildCaptionSection(),
        const SizedBox(height: 20),
        _buildCategorySection(),
        const SizedBox(height: 20),
        _buildAiStudioToggle(),
        const SizedBox(height: 60),
      ],
    );
  }

  // ─── Media Section ──────────────────────────────────────

  Widget _buildMediaSection() {
    return GestureDetector(
      onTap: _showMediaPicker,
      child: AspectRatio(
        aspectRatio: _selectedMedia != null ? 4 / 5 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: DribaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          clipBehavior: Clip.antiAlias,
          child: _selectedMedia != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image preview
                    if (_mediaType == 'image')
                      Image.memory(_selectedMedia!, fit: BoxFit.cover)
                    else
                      Container(
                        color: Colors.black,
                        child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white54, size: 64)),
                      ),

                    // AI enhanced badge
                    if (_aiEnhanced)
                      Positioned(
                        top: 12, left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: DribaColors.premiumGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(_aiAction.isEmpty ? 'AI Enhanced' : _aiAction,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),

                    // Change photo button
                    Positioned(
                      bottom: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_horiz, color: Colors.white70, size: 16),
                            SizedBox(width: 4),
                            Text('Change', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        gradient: DribaColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text('Add Photo or Video', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Tap to choose from camera or gallery', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── Caption Section ────────────────────────────────────

  Widget _buildCaptionSection() {
    final charCount = _captionCtrl.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Caption', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: DribaColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: _captionCtrl,
            maxLength: _maxCaption,
            maxLines: 5,
            minLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
            decoration: InputDecoration(
              hintText: "What's on your mind?",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('$charCount / $_maxCaption',
              style: TextStyle(
                color: charCount > _maxCaption * 0.9 ? DribaColors.warning : Colors.white24,
                fontSize: 12,
              )),
            const Spacer(),
            Text('Use #hashtags for discovery', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12)),
          ],
        ),
      ],
    );
  }

  // ─── Category Selector ──────────────────────────────────

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Categories', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Choose where your post appears', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            _CategoryChip('🍽️ Food', 'food'),
            _CategoryChip('🌍 Travel', 'travel'),
            _CategoryChip('📰 News', 'news'),
            _CategoryChip('💚 Health', 'health'),
            _CategoryChip('⭐ Shop', 'commerce'),
            _CategoryChip('⚡ Digital Life', 'utility'),
            _CategoryChip('✨ Feed', 'feed'),
          ].map((c) => _buildCategoryChip(c.label, c.value)).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _categories.contains(value);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected && value != 'feed') {
            _categories.remove(value);
          } else {
            _categories.add(value);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? DribaColors.primary.withOpacity(0.15) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? DribaColors.primary.withOpacity(0.5) : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(label, style: TextStyle(
          color: isSelected ? DribaColors.primary : Colors.white54,
          fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        )),
      ),
    );
  }

  // ─── AI Studio Toggle ───────────────────────────────────

  Widget _buildAiStudioToggle() {
    return GestureDetector(
      onTap: _openAiStudio,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: _selectedMedia != null
              ? const LinearGradient(colors: [Color(0xFF1a0a2e), Color(0xFF0a1628)])
              : null,
          color: _selectedMedia == null ? DribaColors.surface : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedMedia != null ? DribaColors.tertiary.withOpacity(0.3) : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: DribaColors.premiumGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('AI Studio', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: DribaColors.premiumGradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedMedia == null
                        ? 'Add a photo to unlock AI enhancements'
                        : 'Enhance photo, change scene, or create video',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────

class _CategoryChip {
  final String label;
  final String value;
  const _CategoryChip(this.label, this.value);
}

class _MediaOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaOption({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _PublishButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isPublishing;
  final bool enabled;
  final AnimationController animation;

  const _PublishButton({required this.onTap, required this.isPublishing, required this.enabled, required this.animation});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled && !isPublishing ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: enabled ? DribaColors.primaryGradient : null,
          color: enabled ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(100),
        ),
        child: isPublishing
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text('Publish', style: TextStyle(
                color: enabled ? Colors.white : Colors.white30,
                fontWeight: FontWeight.w600, fontSize: 14,
              )),
      ),
    );
  }
}
