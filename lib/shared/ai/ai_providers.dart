import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_config.dart';
import 'ai_router.dart';
import 'ai_service.dart';
import 'ai_tasks.dart';

// ============================================
// AI PROVIDERS
//
// Riverpod providers that expose AI features
// to the entire UI layer. Everything the screens
// need to call AI is here.
// ============================================

// ── Core Infrastructure ─────────────────────

/// API configuration (injected from Firebase Remote Config or env)
final aiConfigProvider = Provider<AiApiConfig>((ref) {
  // In production: load from Firebase Remote Config
  // For now: defaults (Cloud Function proxy)
  return const AiApiConfig(
    baseUrl: '', // Set from Firebase Remote Config
  );
});

/// The AI HTTP service
final aiServiceProvider = Provider<AiService>((ref) {
  final config = ref.watch(aiConfigProvider);
  return AiService(
    config: config,
    useCloudFunctions: true, // always in production
  );
});

/// The AI Router (the brain)
final aiRouterProvider = Provider<AiRouter>((ref) {
  final service = ref.watch(aiServiceProvider);
  return AiRouter(service: service);
});

/// Pre-built task helpers
final aiTasksProvider = Provider<AiTasks>((ref) {
  final router = ref.watch(aiRouterProvider);
  return AiTasks(router: router);
});

// ── Smart Replies (Chat) ────────────────────

/// Smart reply suggestions for the current chat
/// Automatically regenerates when messages change
final smartRepliesProvider = FutureProvider.family<List<String>,
    List<Map<String, String>>>((ref, recentMessages) async {
  if (recentMessages.isEmpty) return [];

  final tasks = ref.watch(aiTasksProvider);
  try {
    return await tasks.suggestSmartReplies(
      recentMessages: recentMessages,
    );
  } catch (_) {
    return ['Thanks!', 'Got it', 'Sounds good'];
  }
});

// ── Content Generation State ────────────────

/// State for AI content generation (used in Creator screen)
class AiGenerationState {
  final bool isGenerating;
  final String? generatedText;
  final String? error;
  final AiModelConfig? usedModel;
  final double? cost;
  final bool isStreaming;
  final String streamBuffer;

  const AiGenerationState({
    this.isGenerating = false,
    this.generatedText,
    this.error,
    this.usedModel,
    this.cost,
    this.isStreaming = false,
    this.streamBuffer = '',
  });

  AiGenerationState copyWith({
    bool? isGenerating,
    String? generatedText,
    String? error,
    AiModelConfig? usedModel,
    double? cost,
    bool? isStreaming,
    String? streamBuffer,
  }) {
    return AiGenerationState(
      isGenerating: isGenerating ?? this.isGenerating,
      generatedText: generatedText ?? this.generatedText,
      error: error,
      usedModel: usedModel ?? this.usedModel,
      cost: cost ?? this.cost,
      isStreaming: isStreaming ?? this.isStreaming,
      streamBuffer: streamBuffer ?? this.streamBuffer,
    );
  }
}

/// Notifier for AI content generation
class AiGenerationNotifier extends StateNotifier<AiGenerationState> {
  final AiRouter _router;
  final AiTasks _tasks;
  StreamSubscription? _streamSubscription;

  AiGenerationNotifier(this._router, this._tasks)
      : super(const AiGenerationState());

  /// Generate a caption
  Future<void> generateCaption({
    required String description,
    String screen = 'feed',
    String style = 'casual',
  }) async {
    state = const AiGenerationState(isGenerating: true);

    final result = await _tasks.generateCaption(
      description: description,
      screen: screen,
      style: style,
    );

    state = AiGenerationState(
      isGenerating: false,
      generatedText: result.success ? result.text : null,
      error: result.error,
      usedModel: result.model,
      cost: result.estimatedCost,
    );
  }

  /// Generate a description
  Future<void> generateDescription({
    required String title,
    String? details,
    String type = 'content',
  }) async {
    state = const AiGenerationState(isGenerating: true);

    final result = await _tasks.generateDescription(
      title: title,
      details: details,
      type: type,
    );

    state = AiGenerationState(
      isGenerating: false,
      generatedText: result.success ? result.text : null,
      error: result.error,
      usedModel: result.model,
      cost: result.estimatedCost,
    );
  }

  /// Generate marketing copy
  Future<void> generateMarketingCopy({
    required String product,
    required String goal,
    String? targetAudience,
  }) async {
    state = const AiGenerationState(isGenerating: true);

    final result = await _tasks.generateMarketingCopy(
      product: product,
      goal: goal,
      targetAudience: targetAudience,
    );

    state = AiGenerationState(
      isGenerating: false,
      generatedText: result.success ? result.text : null,
      error: result.error,
      usedModel: result.model,
      cost: result.estimatedCost,
    );
  }

  /// Stream content generation (live typing effect)
  void streamCaption({
    required String description,
    String screen = 'feed',
    String style = 'casual',
  }) {
    _streamSubscription?.cancel();
    state = const AiGenerationState(isGenerating: true, isStreaming: true);

    final stream = _tasks.streamCaption(
      description: description,
      screen: screen,
      style: style,
    );

    _streamSubscription = stream.listen(
      (chunk) {
        if (chunk.isDone) {
          state = state.copyWith(
            isGenerating: false,
            isStreaming: false,
            generatedText: state.streamBuffer,
          );
        } else if (chunk.isError) {
          state = AiGenerationState(
            isGenerating: false,
            isStreaming: false,
            error: chunk.text,
          );
        } else {
          state = state.copyWith(
            streamBuffer: state.streamBuffer + chunk.text,
            usedModel: chunk.model,
          );
        }
      },
      onError: (e) {
        state = AiGenerationState(
          isGenerating: false,
          isStreaming: false,
          error: e.toString(),
        );
      },
    );
  }

  /// Generate cross-platform content
  Future<Map<String, String>> generateCrossPost({
    required String content,
    required List<String> platforms,
    String style = 'professional',
  }) async {
    state = const AiGenerationState(isGenerating: true);

    final results = await _tasks.generateCrossPostContent(
      content: content,
      platforms: platforms,
      style: style,
    );

    final textMap = <String, String>{};
    for (final entry in results.entries) {
      if (entry.value.success && entry.value.text != null) {
        textMap[entry.key] = entry.value.text!;
      }
    }

    state = AiGenerationState(
      isGenerating: false,
      generatedText: textMap.values.firstOrNull,
    );

    return textMap;
  }

  /// Clear state
  void clear() {
    _streamSubscription?.cancel();
    state = const AiGenerationState();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for the generation state notifier
final aiGenerationProvider =
    StateNotifierProvider<AiGenerationNotifier, AiGenerationState>((ref) {
  final router = ref.watch(aiRouterProvider);
  final tasks = ref.watch(aiTasksProvider);
  return AiGenerationNotifier(router, tasks);
});

// ── Content Analysis ────────────────────────

/// Auto-categorize content
final contentCategoriesProvider = FutureProvider.family<Map<String, dynamic>,
    String>((ref, text) async {
  final tasks = ref.watch(aiTasksProvider);
  return tasks.categorizeContent(text: text);
});

/// Generate tags for content
final contentTagsProvider =
    FutureProvider.family<List<String>, String>((ref, content) async {
  final tasks = ref.watch(aiTasksProvider);
  return tasks.generateTags(content: content);
});

/// Moderate content
final contentModerationProvider = FutureProvider.family<Map<String, dynamic>,
    String>((ref, content) async {
  final tasks = ref.watch(aiTasksProvider);
  return tasks.moderateContent(content: content);
});

// ── Image Analysis ──────────────────────────

/// Describe a food image
final foodImageDescriptionProvider = FutureProvider.family<
    Map<String, dynamic>, String>((ref, imageUrl) async {
  final tasks = ref.watch(aiTasksProvider);
  return tasks.describeFoodImage(imageUrl: imageUrl);
});

// ── Translation ─────────────────────────────

/// Translate text
final translationProvider = FutureProvider.family<AiResult,
    ({String text, String language})>((ref, params) async {
  final tasks = ref.watch(aiTasksProvider);
  return tasks.translate(
    text: params.text,
    targetLanguage: params.language,
  );
});
