import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../core/theme/driba_colors.dart';

// ============================================================
// AI STUDIO SHEET
//
// The Pro-tier AI enhancement experience. User provides a photo,
// Driba offers intelligent enhancement options:
//
// 1. ENHANCE    — Improve quality, lighting, color grading
// 2. SCENE      — Place product/subject in a new scene
// 3. STYLE      — Apply artistic style transfer
// 4. VIDEO      — Generate a 6s video from the photo
// 5. BACKGROUND — Remove/replace background
//
// Each calls a Vertex AI Cloud Function (Imagen 3 or Veo 2).
// Results are uploaded to Firebase Storage.
// ============================================================

class AiStudioResult {
  final String? imageUrl;
  final String? videoUrl;
  final String actionLabel;
  const AiStudioResult({this.imageUrl, this.videoUrl, required this.actionLabel});
}

class AiStudioSheet extends StatefulWidget {
  final Uint8List mediaBytes;
  final String mediaType;
  final ValueChanged<AiStudioResult> onResult;

  const AiStudioSheet({
    super.key,
    required this.mediaBytes,
    required this.mediaType,
    required this.onResult,
  });

  @override
  State<AiStudioSheet> createState() => _AiStudioSheetState();
}

class _AiStudioSheetState extends State<AiStudioSheet> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _promptCtrl = TextEditingController();

  bool _isProcessing = false;
  String _statusText = '';
  String? _resultPreviewUrl;
  int _selectedScene = -1;
  int _selectedStyle = -1;
  String _selectedVideoMode = 'cinematic';

  // ─── Scene presets ─────────────────────────────────────
  static const _scenes = [
    _ScenePreset('🏖️', 'Beach Sunset', 'Product placed on sandy beach at golden hour, warm sunset light, ocean waves in background, soft focus bokeh'),
    _ScenePreset('🏔️', 'Mountain Peak', 'Product on dramatic mountain summit, sweeping valley view, crisp alpine air, golden hour sidelight'),
    _ScenePreset('🌿', 'Tropical Garden', 'Product nestled among lush tropical plants, monstera leaves, dappled sunlight, fresh green tones'),
    _ScenePreset('🏙️', 'City Rooftop', 'Product on modern city rooftop at twilight, skyline bokeh lights, urban sophistication, moody blue hour'),
    _ScenePreset('☕', 'Cozy Café', 'Product on marble café table, warm Edison bulb lighting, latte art nearby, morning light through window'),
    _ScenePreset('🎨', 'Art Gallery', 'Product displayed in minimalist white gallery space, museum lighting, floating shadows, premium feel'),
    _ScenePreset('🏠', 'Modern Living Room', 'Product in elegant modern living room, natural window light, neutral tones, Scandinavian design'),
    _ScenePreset('🌸', 'Spring Garden', 'Product surrounded by cherry blossoms, soft pink petals falling, ethereal natural light, dreamy atmosphere'),
    _ScenePreset('✨', 'Studio Glow', 'Product in professional studio, gradient backdrop, perfect rim lighting, commercial photography quality'),
    _ScenePreset('🪵', 'Rustic Table', 'Product on weathered oak table, dried flowers, artisan handmade feel, warm vintage tones, morning light'),
    _ScenePreset('🎄', 'Holiday', 'Product with festive holiday decorations, warm fairy lights bokeh, cozy winter atmosphere'),
    _ScenePreset('📝', 'Custom', 'Custom scene — describe your own'),
  ];

  // ─── Style presets ─────────────────────────────────────
  static const _styles = [
    _StylePreset('📸', 'Magazine Editorial', 'Professional editorial photography, high-end magazine quality, perfect exposure and composition'),
    _StylePreset('🎬', 'Cinematic Film', 'Cinematic color grade, anamorphic lens flare, film grain, dramatic contrast, movie still quality'),
    _StylePreset('🖼️', 'Oil Painting', 'Oil painting style, visible brushstrokes, rich impasto texture, classical art museum quality'),
    _StylePreset('✏️', 'Pencil Sketch', 'Detailed pencil sketch, crosshatch shading, fine art drawing, paper texture background'),
    _StylePreset('🌊', 'Watercolor', 'Delicate watercolor painting, soft washes, bleeding colors, paper grain, artistic illustration'),
    _StylePreset('🔮', 'Cyberpunk', 'Neon-lit cyberpunk aesthetic, holographic overlays, futuristic HUD elements, electric blue and pink'),
    _StylePreset('🌅', 'Golden Hour', 'Enhanced golden hour photography, warm backlight, lens flare, soft glowing skin tones'),
    _StylePreset('🖤', 'Noir B&W', 'High contrast black and white, dramatic shadows, film noir style, moody and atmospheric'),
  ];

  // ─── Video modes ───────────────────────────────────────
  static const _videoModes = {
    'cinematic': _VideoMode('🎬', 'Cinematic', 'Slow camera pull-out revealing the full scene, cinematic depth of field'),
    'orbit': _VideoMode('🔄', 'Orbit', 'Camera slowly orbits around the subject, 360-degree reveal'),
    'zoom': _VideoMode('🔍', 'Zoom In', 'Dramatic zoom into the subject, revealing fine details'),
    'timelapse': _VideoMode('⏩', 'Time-lapse', 'Scene changes around the static subject, day-to-night or seasonal'),
    'parallax': _VideoMode('↔️', 'Parallax', 'Subtle parallax movement creating 3D depth from 2D photo'),
    'morph': _VideoMode('🌀', 'Scene Morph', 'Environment morphs and transforms while subject stays anchored'),
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  // ─── Call Cloud Function ────────────────────────────────

  Future<void> _callAiFunction(String action, Map<String, dynamic> params) async {
    setState(() { _isProcessing = true; _statusText = 'Processing...'; });

    try {
      // Encode image as base64
      final b64Image = base64Encode(widget.mediaBytes);

      final callable = FirebaseFunctions.instance.httpsCallable(
        'aiMediaProcess',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
      );

      setState(() => _statusText = _getStatusText(action));

      final result = await callable.call({
        'action': action,
        'imageBase64': b64Image,
        'params': params,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final resultObj = AiStudioResult(
          imageUrl: data['imageUrl'],
          videoUrl: data['videoUrl'],
          actionLabel: data['actionLabel'] ?? action,
        );

        setState(() {
          _resultPreviewUrl = data['imageUrl'] ?? data['videoUrl'];
          _isProcessing = false;
        });

        // Send result back to CreatePostScreen
        widget.onResult(resultObj);
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception(data['error'] ?? 'Unknown error');
      }
    } catch (e) {
      setState(() { _isProcessing = false; _statusText = ''; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('AI processing failed: $e'),
          backgroundColor: DribaColors.error,
        ));
      }
    }
  }

  String _getStatusText(String action) {
    switch (action) {
      case 'enhance': return 'Enhancing your photo...';
      case 'scene': return 'Creating new scene...';
      case 'style': return 'Applying style transfer...';
      case 'video': return 'Generating video (this may take a minute)...';
      case 'background': return 'Processing background...';
      default: return 'Processing...';
    }
  }

  // ─── Actions ────────────────────────────────────────────

  void _enhance() {
    _callAiFunction('enhance', {
      'mode': 'professional',
    });
  }

  void _applyScene() {
    if (_selectedScene < 0) return;
    final scene = _scenes[_selectedScene];
    final prompt = scene.label == 'Custom' ? _promptCtrl.text : scene.prompt;
    if (prompt.isEmpty) return;

    _callAiFunction('scene', {
      'scenePrompt': prompt,
      'sceneName': scene.label,
    });
  }

  void _applyStyle() {
    if (_selectedStyle < 0) return;
    _callAiFunction('style', {
      'stylePrompt': _styles[_selectedStyle].prompt,
      'styleName': _styles[_selectedStyle].label,
    });
  }

  void _generateVideo() {
    final mode = _videoModes[_selectedVideoMode]!;
    final customPrompt = _promptCtrl.text.isNotEmpty ? _promptCtrl.text : null;

    _callAiFunction('video', {
      'mode': _selectedVideoMode,
      'modePrompt': mode.prompt,
      'customPrompt': customPrompt,
      'aspectRatio': '9:16',
    });
  }

  // ─── UI ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: mq.size.height * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xF0080E1C),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(gradient: DribaColors.premiumGradient, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Studio', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        Text('Powered by Vertex AI', style: TextStyle(color: Colors.white30, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(gradient: DribaColors.premiumGradient, borderRadius: BorderRadius.circular(6)),
                      child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                    ),
                  ],
                ),
              ),

              // Processing overlay
              if (_isProcessing) _buildProcessing(),

              // Tabs
              if (!_isProcessing) ...[
                TabBar(
                  controller: _tabCtrl,
                  indicatorColor: DribaColors.tertiary,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: '✨ Scene'),
                    Tab(text: '🎨 Style'),
                    Tab(text: '🎬 Video'),
                    Tab(text: '📸 Enhance'),
                  ],
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildSceneTab(),
                      _buildStyleTab(),
                      _buildVideoTab(),
                      _buildEnhanceTab(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessing() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview (small)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(widget.mediaBytes, width: 120, height: 120, fit: BoxFit.cover),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 40, height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(DribaColors.tertiary),
              ),
            ),
            const SizedBox(height: 16),
            Text(_statusText, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Text('This uses Google Vertex AI', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ─── Scene Tab ──────────────────────────────────────────

  Widget _buildSceneTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Place your subject in a new environment', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 4),
          Text('Driba will keep your subject and generate a new scene around it', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
          const SizedBox(height: 16),

          // Scene grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, childAspectRatio: 1.4, crossAxisSpacing: 10, mainAxisSpacing: 10,
            ),
            itemCount: _scenes.length,
            itemBuilder: (ctx, i) {
              final s = _scenes[i];
              final selected = _selectedScene == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedScene = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected ? DribaColors.tertiary.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? DribaColors.tertiary.withOpacity(0.6) : Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(s.label, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          ),

          // Custom prompt input (shows when Custom is selected)
          if (_selectedScene == _scenes.length - 1) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _promptCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe your scene...\ne.g., "Product on a marble kitchen counter, morning light, herbs in background"',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                filled: true,
                fillColor: DribaColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],

          const SizedBox(height: 20),
          _ActionButton(label: 'Generate Scene', icon: Icons.auto_awesome, enabled: _selectedScene >= 0, onTap: _applyScene),
        ],
      ),
    );
  }

  // ─── Style Tab ──────────────────────────────────────────

  Widget _buildStyleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transform your photo with an artistic style', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 2.4, crossAxisSpacing: 10, mainAxisSpacing: 10,
            ),
            itemCount: _styles.length,
            itemBuilder: (ctx, i) {
              final s = _styles[i];
              final selected = _selectedStyle == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedStyle = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: selected ? DribaColors.tertiary.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? DribaColors.tertiary.withOpacity(0.6) : Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      Text(s.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s.label, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontSize: 13, fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),
          _ActionButton(label: 'Apply Style', icon: Icons.palette, enabled: _selectedStyle >= 0, onTap: _applyStyle),
        ],
      ),
    );
  }

  // ─── Video Tab ──────────────────────────────────────────

  Widget _buildVideoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create a 6-second video from your photo', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 4),
          Text('Powered by Veo 2 — Google\'s video generation AI', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
          const SizedBox(height: 16),

          // Video mode chips
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _videoModes.entries.map((e) {
              final selected = _selectedVideoMode == e.key;
              return GestureDetector(
                onTap: () => setState(() => _selectedVideoMode = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? DribaColors.secondary.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: selected ? DribaColors.secondary.withOpacity(0.5) : Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e.value.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(e.value.label, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Description of selected mode
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white24, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  _videoModes[_selectedVideoMode]!.prompt,
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                )),
              ],
            ),
          ),

          // Optional custom direction
          const SizedBox(height: 16),
          TextField(
            controller: _promptCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Optional: add direction (e.g., "wind blowing through hair")',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              filled: true,
              fillColor: DribaColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),

          const SizedBox(height: 20),
          _ActionButton(label: 'Generate Video', icon: Icons.movie_creation, enabled: true, onTap: _generateVideo, color: DribaColors.secondary),
        ],
      ),
    );
  }

  // ─── Enhance Tab ────────────────────────────────────────

  Widget _buildEnhanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('One-tap professional enhancement', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 20),

          // Preview
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(widget.mediaBytes, width: 200, height: 200, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 24),

          // Enhancement options
          _EnhanceOption(
            icon: Icons.auto_fix_high,
            label: 'Auto Enhance',
            description: 'AI improves lighting, color, sharpness, and composition',
            onTap: _enhance,
          ),
          const SizedBox(height: 12),
          _EnhanceOption(
            icon: Icons.hdr_enhanced_select,
            label: 'HDR Effect',
            description: 'Expand dynamic range for vivid, detailed results',
            onTap: () => _callAiFunction('enhance', {'mode': 'hdr'}),
          ),
          const SizedBox(height: 12),
          _EnhanceOption(
            icon: Icons.face_retouching_natural,
            label: 'Portrait Mode',
            description: 'Blur background, enhance subject, studio-quality result',
            onTap: () => _callAiFunction('enhance', {'mode': 'portrait'}),
          ),
          const SizedBox(height: 12),
          _EnhanceOption(
            icon: Icons.crop_free,
            label: 'Expand Frame',
            description: 'AI extends the image beyond its borders',
            onTap: () => _callAiFunction('enhance', {'mode': 'outpaint'}),
          ),
        ],
      ),
    );
  }
}

// ─── Internal Models ──────────────────────────────────────

class _ScenePreset {
  final String emoji, label, prompt;
  const _ScenePreset(this.emoji, this.label, this.prompt);
}

class _StylePreset {
  final String emoji, label, prompt;
  const _StylePreset(this.emoji, this.label, this.prompt);
}

class _VideoMode {
  final String emoji, label, prompt;
  const _VideoMode(this.emoji, this.label, this.prompt);
}

// ─── Reusable Widgets ─────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({required this.label, required this.icon, required this.enabled, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? DribaColors.tertiary;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: enabled ? LinearGradient(colors: [c, c.withOpacity(0.7)]) : null,
          color: enabled ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: enabled ? Colors.white : Colors.white30, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: enabled ? Colors.white : Colors.white30, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _EnhanceOption extends StatelessWidget {
  final IconData icon;
  final String label, description;
  final VoidCallback onTap;

  const _EnhanceOption({required this.icon, required this.label, required this.description, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: DribaColors.tertiary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: DribaColors.tertiary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
              ],
            )),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}
