import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ai_config.dart';
import 'ai_service.dart';

// ============================================
// AI ROUTER
//
// The invisible brain. Users never choose a model.
// They describe what they want, the router picks
// the best AI, calls it, and returns the result.
//
// Features:
// - Automatic model selection by task type
// - Fallback chain (if Claude fails → try GPT → try Gemini)
// - Streaming support for real-time text generation
// - Cost tracking
// - Rate limiting awareness
// ============================================

class AiRouter {
  final AiService _service;
  final List<String> _failedModels = [];
  DateTime? _lastFailReset;

  AiRouter({required AiService service}) : _service = service;

  // ============================================
  // MAIN ENTRY POINT
  // ============================================

  /// Execute an AI task with automatic routing
  ///
  /// ```dart
  /// final result = await router.execute(AiRequest(
  ///   task: AiTaskType.writeCaption,
  ///   prompt: 'Write a caption for my pasta video',
  ///   context: {'style': 'casual', 'platform': 'driba'},
  /// ));
  /// print(result.text);
  /// ```
  Future<AiResult> execute(AiRequest request) async {
    _resetFailedModelsIfNeeded();

    // Get the routing chain for this task
    final modelChain = _getModelChain(request.task, request.preferredProvider);

    AiResult? lastError;

    for (final model in modelChain) {
      // Skip recently failed models
      if (_failedModels.contains(model.id)) continue;

      try {
        final result = await _callModel(model, request);
        return result;
      } on AiRateLimitException {
        debugPrint('[AiRouter] Rate limited on ${model.name}, trying next...');
        _failedModels.add(model.id);
        continue;
      } on AiTimeoutException {
        debugPrint('[AiRouter] Timeout on ${model.name}, trying next...');
        _failedModels.add(model.id);
        continue;
      } on AiException catch (e) {
        debugPrint('[AiRouter] Error on ${model.name}: ${e.message}');
        lastError = AiResult.error(
          model: model,
          error: e.message,
          task: request.task,
        );
        _failedModels.add(model.id);
        continue;
      }
    }

    // All models failed
    return lastError ??
        AiResult.error(
          model: AiModels.claudeSonnet,
          error: 'All AI models are temporarily unavailable. Please try again.',
          task: request.task,
        );
  }

  /// Execute with streaming (for real-time text generation)
  Stream<AiStreamChunk> executeStream(AiRequest request) async* {
    _resetFailedModelsIfNeeded();
    final modelChain = _getModelChain(request.task, request.preferredProvider);

    for (final model in modelChain) {
      if (_failedModels.contains(model.id)) continue;
      if (!model.supportsStreaming) continue;

      try {
        yield* _service.streamCompletion(model, request);
        return; // success, stop trying others
      } catch (e) {
        debugPrint('[AiRouter] Stream failed on ${model.name}: $e');
        _failedModels.add(model.id);
        continue;
      }
    }

    yield AiStreamChunk(
      text: 'AI is temporarily unavailable. Please try again.',
      isDone: true,
      isError: true,
    );
  }

  // ============================================
  // ROUTING LOGIC
  // ============================================

  /// Get ordered list of models to try for a task
  List<AiModelConfig> _getModelChain(
    AiTaskType task,
    AiProvider? preferredProvider,
  ) {
    // Start with the default route for this task
    final defaultModel = AiRoutingRules.getBestModel(task);
    final routeIds = AiRoutingRules.routes[task] ?? [defaultModel.id];

    // Convert to model configs
    var models = routeIds
        .map(AiModels.byId)
        .whereType<AiModelConfig>()
        .toList();

    // If user/config prefers a specific provider, bump it to front
    if (preferredProvider != null) {
      models.sort((a, b) {
        if (a.provider == preferredProvider && b.provider != preferredProvider) {
          return -1;
        }
        if (b.provider == preferredProvider && a.provider != preferredProvider) {
          return 1;
        }
        return a.priority.compareTo(b.priority);
      });
    }

    return models;
  }

  /// Actually call a model through the service layer
  Future<AiResult> _callModel(AiModelConfig model, AiRequest request) async {
    final response = await _service.complete(model, request);
    return response;
  }

  /// Reset failed models list every 5 minutes
  void _resetFailedModelsIfNeeded() {
    final now = DateTime.now();
    if (_lastFailReset == null ||
        now.difference(_lastFailReset!) > const Duration(minutes: 5)) {
      _failedModels.clear();
      _lastFailReset = now;
    }
  }

  /// Force reset (e.g., user presses retry)
  void resetFailures() {
    _failedModels.clear();
    _lastFailReset = DateTime.now();
  }
}

// ============================================
// REQUEST / RESPONSE MODELS
// ============================================

/// A request to the AI system
class AiRequest {
  final AiTaskType task;
  final String prompt;
  final String? systemPrompt; // override default system prompt
  final Map<String, dynamic> context; // additional context
  final AiProvider? preferredProvider; // user preference
  final int? maxTokens;
  final double temperature;
  final List<AiMediaInput>? media; // images, documents to analyze
  final AiOutputFormat outputFormat;

  const AiRequest({
    required this.task,
    required this.prompt,
    this.systemPrompt,
    this.context = const {},
    this.preferredProvider,
    this.maxTokens,
    this.temperature = 0.7,
    this.media,
    this.outputFormat = AiOutputFormat.text,
  });

  AiRequest copyWith({
    AiTaskType? task,
    String? prompt,
    String? systemPrompt,
    Map<String, dynamic>? context,
    AiProvider? preferredProvider,
    int? maxTokens,
    double? temperature,
    List<AiMediaInput>? media,
    AiOutputFormat? outputFormat,
  }) {
    return AiRequest(
      task: task ?? this.task,
      prompt: prompt ?? this.prompt,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      context: context ?? this.context,
      preferredProvider: preferredProvider ?? this.preferredProvider,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      media: media ?? this.media,
      outputFormat: outputFormat ?? this.outputFormat,
    );
  }
}

/// Media attached to a request (for vision models)
class AiMediaInput {
  final String url; // url or base64
  final String type; // image, document, pdf
  final String? mimeType;

  const AiMediaInput({
    required this.url,
    required this.type,
    this.mimeType,
  });
}

/// Output format
enum AiOutputFormat { text, json, markdown, html }

/// Result from an AI call
class AiResult {
  final bool success;
  final String? text;
  final Map<String, dynamic>? jsonData; // for structured output
  final AiModelConfig model;
  final AiTaskType task;
  final String? error;
  final int? inputTokens;
  final int? outputTokens;
  final Duration? latency;
  final double? estimatedCost;

  const AiResult({
    required this.success,
    this.text,
    this.jsonData,
    required this.model,
    required this.task,
    this.error,
    this.inputTokens,
    this.outputTokens,
    this.latency,
    this.estimatedCost,
  });

  factory AiResult.error({
    required AiModelConfig model,
    required String error,
    required AiTaskType task,
  }) {
    return AiResult(
      success: false,
      model: model,
      task: task,
      error: error,
    );
  }
}

/// Streaming chunk
class AiStreamChunk {
  final String text;
  final bool isDone;
  final bool isError;
  final AiModelConfig? model;

  const AiStreamChunk({
    required this.text,
    this.isDone = false,
    this.isError = false,
    this.model,
  });
}

// ============================================
// EXCEPTIONS
// ============================================

class AiException implements Exception {
  final String message;
  final int? statusCode;
  const AiException(this.message, {this.statusCode});
  @override
  String toString() => 'AiException: $message';
}

class AiRateLimitException extends AiException {
  final Duration? retryAfter;
  const AiRateLimitException({this.retryAfter})
      : super('Rate limited', statusCode: 429);
}

class AiTimeoutException extends AiException {
  const AiTimeoutException() : super('Request timed out');
}
