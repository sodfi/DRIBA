import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'ai_config.dart';
import 'ai_router.dart';

// ============================================
// AI SERVICE
//
// Actual API call layer. In production, ALL calls
// go through Firebase Cloud Functions (server-side)
// to keep API keys secure. The client never touches
// raw API keys.
//
// Architecture:
// Client → Cloud Function → AI Provider API
//
// For development/testing, can also call APIs
// directly (with keys from environment).
// ============================================

class AiService {
  final Dio _dio;
  final AiApiConfig config;
  final bool _useCloudFunctions;

  AiService({
    required this.config,
    bool useCloudFunctions = true,
  })  : _useCloudFunctions = useCloudFunctions,
        _dio = Dio(BaseOptions(
          connectTimeout: config.timeout,
          receiveTimeout: config.timeout,
        ));

  // ============================================
  // MAIN COMPLETION METHOD
  // ============================================

  Future<AiResult> complete(AiModelConfig model, AiRequest request) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (_useCloudFunctions) {
        return await _callViaCloudFunction(model, request, stopwatch);
      }

      // Direct API calls (dev mode)
      switch (model.provider) {
        case AiProvider.anthropic:
          return await _callAnthropic(model, request, stopwatch);
        case AiProvider.openai:
          return await _callOpenAI(model, request, stopwatch);
        case AiProvider.google:
          return await _callGoogle(model, request, stopwatch);
      }
    } on DioException catch (e) {
      stopwatch.stop();
      if (e.response?.statusCode == 429) {
        final retryAfter = e.response?.headers['retry-after']?.first;
        throw AiRateLimitException(
          retryAfter: retryAfter != null
              ? Duration(seconds: int.tryParse(retryAfter) ?? 60)
              : null,
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const AiTimeoutException();
      }
      throw AiException(
        e.response?.data?['error']?['message']?.toString() ??
            e.message ??
            'Unknown error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      stopwatch.stop();
      if (e is AiException) rethrow;
      throw AiException(e.toString());
    }
  }

  // ============================================
  // STREAMING
  // ============================================

  Stream<AiStreamChunk> streamCompletion(
    AiModelConfig model,
    AiRequest request,
  ) async* {
    if (_useCloudFunctions) {
      yield* _streamViaCloudFunction(model, request);
      return;
    }

    switch (model.provider) {
      case AiProvider.anthropic:
        yield* _streamAnthropic(model, request);
      case AiProvider.openai:
        yield* _streamOpenAI(model, request);
      case AiProvider.google:
        yield* _streamGoogle(model, request);
    }
  }

  // ============================================
  // CLOUD FUNCTION PROXY (Production)
  // ============================================

  Future<AiResult> _callViaCloudFunction(
    AiModelConfig model,
    AiRequest request,
    Stopwatch stopwatch,
  ) async {
    final response = await _dio.post(
      '${config.baseUrl}/ai/complete',
      data: {
        'model': model.id,
        'provider': model.provider.name,
        'task': request.task.name,
        'prompt': request.prompt,
        if (request.systemPrompt != null) 'systemPrompt': request.systemPrompt,
        'context': request.context,
        'maxTokens': request.maxTokens ?? model.maxOutputTokens,
        'temperature': request.temperature,
        'outputFormat': request.outputFormat.name,
        if (request.media != null)
          'media': request.media!
              .map((m) => {'url': m.url, 'type': m.type, 'mimeType': m.mimeType})
              .toList(),
      },
    );

    stopwatch.stop();
    final data = response.data as Map<String, dynamic>;

    return AiResult(
      success: true,
      text: data['text'] as String?,
      jsonData: data['json'] as Map<String, dynamic>?,
      model: model,
      task: request.task,
      inputTokens: data['usage']?['inputTokens'] as int?,
      outputTokens: data['usage']?['outputTokens'] as int?,
      latency: stopwatch.elapsed,
      estimatedCost: _estimateCost(
        model,
        data['usage']?['inputTokens'] as int? ?? 0,
        data['usage']?['outputTokens'] as int? ?? 0,
      ),
    );
  }

  Stream<AiStreamChunk> _streamViaCloudFunction(
    AiModelConfig model,
    AiRequest request,
  ) async* {
    final response = await _dio.post(
      '${config.baseUrl}/ai/stream',
      data: {
        'model': model.id,
        'provider': model.provider.name,
        'task': request.task.name,
        'prompt': request.prompt,
        if (request.systemPrompt != null) 'systemPrompt': request.systemPrompt,
        'context': request.context,
        'maxTokens': request.maxTokens ?? model.maxOutputTokens,
        'temperature': request.temperature,
        'outputFormat': request.outputFormat.name,
      },
      options: Options(responseType: ResponseType.stream),
    );

    final stream = response.data.stream as Stream<List<int>>;
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
      final lines = buffer.split('\n');
      buffer = lines.removeLast(); // keep incomplete line

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') {
            yield AiStreamChunk(text: '', isDone: true, model: model);
            return;
          }
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final text = json['text'] as String? ?? '';
            yield AiStreamChunk(text: text, model: model);
          } catch (_) {
            // skip malformed chunks
          }
        }
      }
    }

    yield AiStreamChunk(text: '', isDone: true, model: model);
  }

  // ============================================
  // ANTHROPIC (Claude) - Direct API
  // ============================================

  Future<AiResult> _callAnthropic(
    AiModelConfig model,
    AiRequest request,
    Stopwatch stopwatch,
  ) async {
    final systemPrompt = request.systemPrompt ??
        _getDefaultSystemPrompt(request.task, request.context);

    final messages = <Map<String, dynamic>>[];

    // Build content with optional media
    if (request.media != null && request.media!.isNotEmpty) {
      final content = <Map<String, dynamic>>[];
      for (final media in request.media!) {
        if (media.type == 'image') {
          content.add({
            'type': 'image',
            'source': {
              'type': 'url',
              'url': media.url,
            },
          });
        }
      }
      content.add({'type': 'text', 'text': request.prompt});
      messages.add({'role': 'user', 'content': content});
    } else {
      messages.add({'role': 'user', 'content': request.prompt});
    }

    final response = await _dio.post(
      'https://api.anthropic.com/v1/messages',
      options: Options(headers: {
        'x-api-key': config.anthropicApiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      }),
      data: {
        'model': model.id,
        'max_tokens': request.maxTokens ?? model.maxOutputTokens,
        'temperature': request.temperature,
        'system': systemPrompt,
        'messages': messages,
      },
    );

    stopwatch.stop();
    final data = response.data as Map<String, dynamic>;
    final content = data['content'] as List;
    final text = content
        .where((c) => c['type'] == 'text')
        .map((c) => c['text'] as String)
        .join('\n');

    final inputTokens = data['usage']?['input_tokens'] as int? ?? 0;
    final outputTokens = data['usage']?['output_tokens'] as int? ?? 0;

    return AiResult(
      success: true,
      text: text,
      jsonData: _tryParseJson(text, request.outputFormat),
      model: model,
      task: request.task,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      latency: stopwatch.elapsed,
      estimatedCost: _estimateCost(model, inputTokens, outputTokens),
    );
  }

  Stream<AiStreamChunk> _streamAnthropic(
    AiModelConfig model,
    AiRequest request,
  ) async* {
    final systemPrompt = request.systemPrompt ??
        _getDefaultSystemPrompt(request.task, request.context);

    final response = await _dio.post(
      'https://api.anthropic.com/v1/messages',
      options: Options(
        headers: {
          'x-api-key': config.anthropicApiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        responseType: ResponseType.stream,
      ),
      data: {
        'model': model.id,
        'max_tokens': request.maxTokens ?? model.maxOutputTokens,
        'temperature': request.temperature,
        'system': systemPrompt,
        'stream': true,
        'messages': [
          {'role': 'user', 'content': request.prompt},
        ],
      },
    );

    final stream = response.data.stream as Stream<List<int>>;
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          try {
            final json = jsonDecode(line.substring(6)) as Map<String, dynamic>;
            final type = json['type'] as String?;
            if (type == 'content_block_delta') {
              final delta = json['delta'] as Map<String, dynamic>?;
              final text = delta?['text'] as String? ?? '';
              yield AiStreamChunk(text: text, model: model);
            } else if (type == 'message_stop') {
              yield AiStreamChunk(text: '', isDone: true, model: model);
              return;
            }
          } catch (_) {}
        }
      }
    }
  }

  // ============================================
  // OPENAI (GPT) - Direct API
  // ============================================

  Future<AiResult> _callOpenAI(
    AiModelConfig model,
    AiRequest request,
    Stopwatch stopwatch,
  ) async {
    final systemPrompt = request.systemPrompt ??
        _getDefaultSystemPrompt(request.task, request.context);

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    if (request.media != null && request.media!.isNotEmpty) {
      final content = <Map<String, dynamic>>[];
      for (final media in request.media!) {
        if (media.type == 'image') {
          content.add({
            'type': 'image_url',
            'image_url': {'url': media.url},
          });
        }
      }
      content.add({'type': 'text', 'text': request.prompt});
      messages.add({'role': 'user', 'content': content});
    } else {
      messages.add({'role': 'user', 'content': request.prompt});
    }

    final response = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(headers: {
        'Authorization': 'Bearer ${config.openaiApiKey}',
        'Content-Type': 'application/json',
      }),
      data: {
        'model': model.id,
        'max_tokens': request.maxTokens ?? model.maxOutputTokens,
        'temperature': request.temperature,
        'messages': messages,
      },
    );

    stopwatch.stop();
    final data = response.data as Map<String, dynamic>;
    final text =
        data['choices']?[0]?['message']?['content'] as String? ?? '';
    final usage = data['usage'] as Map<String, dynamic>?;

    final inputTokens = usage?['prompt_tokens'] as int? ?? 0;
    final outputTokens = usage?['completion_tokens'] as int? ?? 0;

    return AiResult(
      success: true,
      text: text,
      jsonData: _tryParseJson(text, request.outputFormat),
      model: model,
      task: request.task,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      latency: stopwatch.elapsed,
      estimatedCost: _estimateCost(model, inputTokens, outputTokens),
    );
  }

  Stream<AiStreamChunk> _streamOpenAI(
    AiModelConfig model,
    AiRequest request,
  ) async* {
    final systemPrompt = request.systemPrompt ??
        _getDefaultSystemPrompt(request.task, request.context);

    final response = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.openaiApiKey}',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.stream,
      ),
      data: {
        'model': model.id,
        'max_tokens': request.maxTokens ?? model.maxOutputTokens,
        'temperature': request.temperature,
        'stream': true,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': request.prompt},
        ],
      },
    );

    final stream = response.data.stream as Stream<List<int>>;
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') {
            yield AiStreamChunk(text: '', isDone: true, model: model);
            return;
          }
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final text = json['choices']?[0]?['delta']?['content'] as String?;
            if (text != null) {
              yield AiStreamChunk(text: text, model: model);
            }
          } catch (_) {}
        }
      }
    }
  }

  // ============================================
  // GOOGLE (Gemini) - Direct API
  // ============================================

  Future<AiResult> _callGoogle(
    AiModelConfig model,
    AiRequest request,
    Stopwatch stopwatch,
  ) async {
    final systemPrompt = request.systemPrompt ??
        _getDefaultSystemPrompt(request.task, request.context);

    final parts = <Map<String, dynamic>>[];

    if (request.media != null && request.media!.isNotEmpty) {
      for (final media in request.media!) {
        if (media.type == 'image') {
          parts.add({
            'inlineData': {
              'mimeType': media.mimeType ?? 'image/jpeg',
              'data': media.url, // expects base64 for inline
            },
          });
        }
      }
    }
    parts.add({'text': request.prompt});

    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/${model.id}:generateContent?key=${config.googleApiKey}',
      data: {
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt}
          ],
        },
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {
          'maxOutputTokens': request.maxTokens ?? model.maxOutputTokens,
          'temperature': request.temperature,
        },
      },
    );

    stopwatch.stop();
    final data = response.data as Map<String, dynamic>;
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']
            as String? ??
        '';

    final usage = data['usageMetadata'] as Map<String, dynamic>?;
    final inputTokens = usage?['promptTokenCount'] as int? ?? 0;
    final outputTokens = usage?['candidatesTokenCount'] as int? ?? 0;

    return AiResult(
      success: true,
      text: text,
      jsonData: _tryParseJson(text, request.outputFormat),
      model: model,
      task: request.task,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      latency: stopwatch.elapsed,
      estimatedCost: _estimateCost(model, inputTokens, outputTokens),
    );
  }

  Stream<AiStreamChunk> _streamGoogle(
    AiModelConfig model,
    AiRequest request,
  ) async* {
    final systemPrompt = request.systemPrompt ??
        _getDefaultSystemPrompt(request.task, request.context);

    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/${model.id}:streamGenerateContent?key=${config.googleApiKey}&alt=sse',
      options: Options(responseType: ResponseType.stream),
      data: {
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt}
          ],
        },
        'contents': [
          {
            'parts': [
              {'text': request.prompt}
            ],
          },
        ],
        'generationConfig': {
          'maxOutputTokens': request.maxTokens ?? model.maxOutputTokens,
          'temperature': request.temperature,
        },
      },
    );

    final stream = response.data.stream as Stream<List<int>>;
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          try {
            final json = jsonDecode(line.substring(6)) as Map<String, dynamic>;
            final text =
                json['candidates']?[0]?['content']?['parts']?[0]?['text']
                    as String?;
            if (text != null) {
              yield AiStreamChunk(text: text, model: model);
            }
          } catch (_) {}
        }
      }
    }

    yield AiStreamChunk(text: '', isDone: true, model: model);
  }

  // ============================================
  // SYSTEM PROMPTS (per task type)
  // ============================================

  String _getDefaultSystemPrompt(
    AiTaskType task,
    Map<String, dynamic> context,
  ) {
    final style = context['style'] as String? ?? 'professional';
    final platform = context['platform'] as String? ?? 'driba';
    final language = context['language'] as String? ?? 'en';
    final screen = context['screen'] as String? ?? '';

    switch (task) {
      case AiTaskType.writeCaption:
        return '''You are a world-class social media copywriter for Driba, a premium super app.
Write engaging, authentic captions that drive interaction.
Style: $style. Language: $language.
Keep it concise (under 200 characters for maximum impact).
Include relevant emojis sparingly. Never use hashtags unless asked.
The content will appear on the "$screen" screen in Driba.''';

      case AiTaskType.writeDescription:
        return '''You are a product/content description writer for Driba.
Write compelling descriptions that inform and convert.
Style: $style. Language: $language.
Be specific about features and benefits. Use sensory language for food/travel.
Max 3 paragraphs.''';

      case AiTaskType.writeArticle:
        return '''You are an expert content writer for Driba.
Write well-structured, informative articles.
Style: $style. Language: $language.
Use clear sections, practical insights, and an engaging narrative.''';

      case AiTaskType.writeMarketingCopy:
        return '''You are a direct-response copywriter for Driba.
Write persuasive marketing copy that drives action.
Style: $style. Language: $language.
Focus on benefits over features. Use urgency and social proof.
Include a clear call-to-action.''';

      case AiTaskType.writeSocialPost:
        return '''You are a social media strategist.
Write platform-optimized posts for: $platform.
Style: $style. Language: $language.
Adapt tone and length to the platform's best practices.
For Driba: casual, authentic, visual-first.
For LinkedIn: professional, insightful, thought-leadership.
For X/Twitter: concise, punchy, conversation-starting.
For Instagram: visual storytelling, lifestyle-focused.''';

      case AiTaskType.writeProductCopy:
        return '''You are a conversion-focused e-commerce copywriter for Driba.
Write product descriptions that sell.
Style: $style. Language: $language.
Lead with the key benefit. Include specs naturally. Create desire.
Driba has 0% transaction fees — highlight this advantage for sellers.''';

      case AiTaskType.suggestSmartReplies:
        return '''You are a smart reply assistant for Driba chat.
Generate 3-4 short, natural reply suggestions.
Match the conversation's tone and context.
Language: $language.
Output as JSON array: ["reply1", "reply2", "reply3"]
Keep each under 60 characters. Be helpful, not generic.''';

      case AiTaskType.categorizeContent:
        return '''Categorize the given content into Driba screens.
Available screens: feed, food, commerce, travel, health, news, learn, movies, local, music, gaming, sports, finance, auto, pets, realestate, fashion, beauty, home, events, kids.
Output as JSON: {"categories": ["screen1", "screen2"], "tags": ["tag1", "tag2"]}
Be precise. Most content fits 1-3 screens.''';

      case AiTaskType.generateTags:
        return '''Generate relevant search tags for the given content.
Output as JSON array: ["tag1", "tag2", "tag3", ...]
Generate 5-10 tags. Include both broad and specific terms.
Language: $language.''';

      case AiTaskType.analyzeContent:
        return '''You are a content analyst for Driba.
Analyze the given content and provide insights.
Language: $language.
Be specific, data-driven, and actionable.''';

      case AiTaskType.analyzeImage:
        return '''Analyze the provided image in detail.
Describe what you see, identify key elements, and suggest how this image
could be used on the Driba platform.
Language: $language.''';

      case AiTaskType.summarize:
        return '''Summarize the given content concisely.
Language: $language.
Capture the key points in 2-3 sentences.''';

      case AiTaskType.moderateContent:
        return '''You are a content moderator for Driba.
Review the content for policy violations.
Output as JSON: {"safe": true/false, "flags": ["reason1"], "severity": "low/medium/high"}
Check for: hate speech, explicit content, spam, misinformation, scams.
Be thorough but fair. Borderline content should be flagged, not removed.''';

      case AiTaskType.translateText:
        return '''Translate the following text to $language.
Maintain the original tone and meaning.
For marketing content, adapt culturally rather than translating literally.''';

      case AiTaskType.generateBusinessDoc:
        return '''You are a business document writer for Driba.
Create professional business documents.
Style: $style. Language: $language.
Be clear, structured, and professional.''';

      case AiTaskType.transcribeDocument:
        return '''Extract all text content from the provided document/image.
Maintain the original structure and formatting where possible.
Language: $language.''';

      case AiTaskType.describeFoodImage:
        return '''Describe the food in this image for a restaurant menu on Driba.
Include: dish name (if identifiable), key ingredients visible,
cooking method, and an appetizing 1-2 sentence description.
Output as JSON: {"name": "...", "description": "...", "ingredients": [...], "cuisine": "..."}
Language: $language.''';

      // Autonomous creator prompts
      case AiTaskType.generateFoodContent:
        return '''You are a food content creator AI for Driba's Food screen.
Generate engaging food content: recipes, restaurant spotlights, food tips, trending dishes.
Include appetizing descriptions and practical info.
Output content ready to post with a catchy caption.
Language: $language. Style: warm, knowledgeable, food-lover.''';

      case AiTaskType.generateTravelContent:
        return '''You are a travel content creator AI for Driba's Travel screen.
Generate inspiring travel content: hidden gems, travel tips, destination guides, local experiences.
Be specific about locations and practical details.
Language: $language. Style: adventurous, authentic, informative.''';

      case AiTaskType.generateNewsContent:
        return '''You are a news curator AI for Driba's News screen.
Summarize and present news in an engaging, balanced way.
Always cite sources. Present multiple perspectives on controversial topics.
Language: $language. Style: factual, concise, accessible.''';

      case AiTaskType.generateLearningContent:
        return '''You are an educational content creator AI for Driba's Learn screen.
Generate clear, engaging educational content: tutorials, explainers, skill-building posts.
Break complex topics into digestible pieces.
Language: $language. Style: encouraging, clear, step-by-step.''';

      case AiTaskType.generateFitnessContent:
        return '''You are a fitness content creator AI for Driba's Health screen.
Generate motivating fitness content: workout routines, nutrition tips, wellness advice.
Be specific about exercises, reps, and form. Always include safety notes.
Language: $language. Style: motivating, practical, science-backed.''';
    }
  }

  // ============================================
  // HELPERS
  // ============================================

  Map<String, dynamic>? _tryParseJson(String text, AiOutputFormat format) {
    if (format != AiOutputFormat.json) return null;
    try {
      // Strip markdown code fences if present
      var cleaned = text.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final parsed = jsonDecode(cleaned);
      if (parsed is Map<String, dynamic>) return parsed;
      // Wrap arrays in a map
      if (parsed is List) return {'items': parsed};
      return null;
    } catch (_) {
      return null;
    }
  }

  double _estimateCost(AiModelConfig model, int inputTokens, int outputTokens) {
    return (inputTokens / 1000 * model.costPerInputToken) +
        (outputTokens / 1000 * model.costPerOutputToken);
  }
}
