import 'dart:async';
import 'dart:convert';
import 'ai_config.dart';
import 'ai_router.dart';

// ============================================
// AI TASKS
//
// High-level convenience methods that wrap
// the router. These are what the UI calls.
//
// Usage:
// ```dart
// final tasks = AiTasks(router: router);
// final caption = await tasks.generateCaption(
//   description: 'pasta recipe video',
//   screen: 'food',
//   style: 'casual',
// );
// ```
// ============================================

class AiTasks {
  final AiRouter router;

  const AiTasks({required this.router});

  // ============================================
  // CONTENT CREATION
  // ============================================

  /// Generate a caption for a post
  Future<AiResult> generateCaption({
    required String description,
    String screen = 'feed',
    String style = 'casual',
    String language = 'en',
    List<AiMediaInput>? media,
  }) {
    return router.execute(AiRequest(
      task: AiTaskType.writeCaption,
      prompt:
          'Write a captivating caption for this post:\n\n$description',
      context: {
        'screen': screen,
        'style': style,
        'language': language,
      },
      media: media,
      maxTokens: 200,
      temperature: 0.8,
    ));
  }

  /// Generate a product or content description
  Future<AiResult> generateDescription({
    required String title,
    String? details,
    String type = 'content', // content, product, food, service
    String style = 'professional',
    String language = 'en',
  }) {
    return router.execute(AiRequest(
      task: AiTaskType.writeDescription,
      prompt: '''Write a compelling description for:
Title: $title
Type: $type
${details != null ? 'Details: $details' : ''}

Make it engaging and informative.''',
      context: {'style': style, 'language': language},
      maxTokens: 500,
    ));
  }

  /// Generate marketing copy for a campaign
  Future<AiResult> generateMarketingCopy({
    required String product,
    required String goal, // awareness, conversion, engagement
    String? targetAudience,
    String style = 'professional',
    String language = 'en',
  }) {
    return router.execute(AiRequest(
      task: AiTaskType.writeMarketingCopy,
      prompt: '''Create marketing copy:
Product/Service: $product
Goal: $goal
${targetAudience != null ? 'Target audience: $targetAudience' : ''}

Write headline, body copy, and call-to-action.''',
      context: {'style': style, 'language': language},
      maxTokens: 600,
    ));
  }

  /// Generate a social media post optimized for a specific platform
  Future<AiResult> generateSocialPost({
    required String content,
    required String platform, // driba, linkedin, twitter, instagram, tiktok
    String style = 'casual',
    String language = 'en',
  }) {
    return router.execute(AiRequest(
      task: AiTaskType.writeSocialPost,
      prompt:
          'Adapt this content for $platform:\n\n$content',
      context: {
        'platform': platform,
        'style': style,
        'language': language,
      },
      maxTokens: 400,
    ));
  }

  /// Generate cross-platform posts (Pro mode)
  Future<Map<String, AiResult>> generateCrossPostContent({
    required String content,
    required List<String> platforms,
    String style = 'professional',
    String language = 'en',
  }) async {
    final results = <String, AiResult>{};

    // Run in parallel for speed
    final futures = platforms.map((platform) async {
      final result = await generateSocialPost(
        content: content,
        platform: platform,
        style: style,
        language: language,
      );
      return MapEntry(platform, result);
    });

    final entries = await Future.wait(futures);
    for (final entry in entries) {
      results[entry.key] = entry.value;
    }

    return results;
  }

  /// Generate a product listing description
  Future<AiResult> generateProductCopy({
    required String productName,
    String? category,
    double? price,
    List<String>? features,
    String language = 'en',
  }) {
    return router.execute(AiRequest(
      task: AiTaskType.writeProductCopy,
      prompt: '''Write a product listing for:
Name: $productName
${category != null ? 'Category: $category' : ''}
${price != null ? 'Price: \$$price' : ''}
${features != null ? 'Features: ${features.join(", ")}' : ''}

Write a title, description, and 3-5 bullet points.''',
      context: {'language': language},
      maxTokens: 500,
    ));
  }

  // ============================================
  // CHAT - Smart Replies
  // ============================================

  /// Generate smart reply suggestions for a chat
  Future<List<String>> suggestSmartReplies({
    required List<Map<String, String>> recentMessages,
    String language = 'en',
  }) async {
    // Format recent conversation
    final conversation = recentMessages
        .map((m) => '${m['sender']}: ${m['text']}')
        .join('\n');

    final result = await router.execute(AiRequest(
      task: AiTaskType.suggestSmartReplies,
      prompt: '''Recent conversation:
$conversation

Generate 3-4 natural reply suggestions for the current user.''',
      context: {'language': language},
      outputFormat: AiOutputFormat.json,
      maxTokens: 200,
      temperature: 0.8,
    ));

    if (result.success && result.jsonData != null) {
      final items = result.jsonData!['items'] as List?;
      if (items != null) {
        return items.map((e) => e.toString()).toList();
      }
    }

    // Fallback: try to parse from text
    if (result.success && result.text != null) {
      return _parseRepliesFromText(result.text!);
    }

    return ['Thanks!', 'Got it', 'Sounds good'];
  }

  List<String> _parseRepliesFromText(String text) {
    try {
      // Try JSON array
      if (text.trim().startsWith('[')) {
        final cleaned = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final list = List<dynamic>.from(jsonDecode(cleaned) as List);
        return list.map((e) => e.toString()).toList();
      }
    } catch (_) {}

    // Fallback: split by newlines, strip numbers/bullets
    return text
        .split('\n')
        .map((line) =>
            line.replaceAll(RegExp(r'^[\d\.\-\*]+\s*'), '').trim())
        .where((line) => line.isNotEmpty && line.length < 80)
        .take(4)
        .toList();
  }

  // ============================================
  // CONTENT ANALYSIS
  // ============================================

  /// Auto-categorize content into Driba screens
  Future<Map<String, dynamic>> categorizeContent({
    required String text,
    List<AiMediaInput>? media,
  }) async {
    final result = await router.execute(AiRequest(
      task: AiTaskType.categorizeContent,
      prompt: 'Categorize this content:\n\n$text',
      media: media,
      outputFormat: AiOutputFormat.json,
      maxTokens: 200,
      temperature: 0.3,
    ));

    if (result.success && result.jsonData != null) {
      return result.jsonData!;
    }

    return {'categories': ['feed'], 'tags': []};
  }

  /// Generate search tags for content
  Future<List<String>> generateTags({
    required String content,
    String language = 'en',
  }) async {
    final result = await router.execute(AiRequest(
      task: AiTaskType.generateTags,
      prompt: 'Generate search tags for:\n\n$content',
      context: {'language': language},
      outputFormat: AiOutputFormat.json,
      maxTokens: 150,
      temperature: 0.4,
    ));

    if (result.success && result.jsonData != null) {
      final items = result.jsonData!['items'] as List?;
      if (items != null) return items.map((e) => e.toString()).toList();
    }

    return [];
  }

  /// Moderate content for policy violations
  Future<Map<String, dynamic>> moderateContent({
    required String content,
    List<AiMediaInput>? media,
  }) async {
    final result = await router.execute(AiRequest(
      task: AiTaskType.moderateContent,
      prompt: 'Review this content for policy compliance:\n\n$content',
      media: media,
      outputFormat: AiOutputFormat.json,
      maxTokens: 200,
      temperature: 0.1,
    ));

    if (result.success && result.jsonData != null) {
      return result.jsonData!;
    }

    return {'safe': true, 'flags': [], 'severity': 'low'};
  }

  /// Summarize long content
  Future<AiResult> summarize({
    required String content,
    int? maxLength,
    String language = 'en',
  }) {
    return router.execute(AiRequest(
      task: AiTaskType.summarize,
      prompt:
          'Summarize this${maxLength != null ? ' in under $maxLength words' : ''}:\n\n$content',
      context: {'language': language},
      maxTokens: maxLength ?? 200,
      temperature: 0.3,
    ));
  }

  // ============================================
  // VISION / MEDIA
  // ============================================

  /// Analyze an image and suggest how to use it
  Future<AiResult> analyzeImage({
    required String imageUrl,
    String language = 'en',
  }) {
    return router.execute(AiRequest(
      task: AiTaskType.analyzeImage,
      prompt: 'Analyze this image for use on Driba.',
      media: [AiMediaInput(url: imageUrl, type: 'image')],
      context: {'language': language},
      maxTokens: 400,
    ));
  }

  /// Describe a food image for a menu
  Future<Map<String, dynamic>> describeFoodImage({
    required String imageUrl,
    String language = 'en',
  }) async {
    final result = await router.execute(AiRequest(
      task: AiTaskType.describeFoodImage,
      prompt: 'Describe this food for a restaurant menu.',
      media: [AiMediaInput(url: imageUrl, type: 'image')],
      context: {'language': language},
      outputFormat: AiOutputFormat.json,
      maxTokens: 300,
    ));

    if (result.success && result.jsonData != null) {
      return result.jsonData!;
    }

    return {
      'name': 'Dish',
      'description': result.text ?? '',
      'ingredients': [],
      'cuisine': 'unknown',
    };
  }

  // ============================================
  // TRANSLATION
  // ============================================

  /// Translate text to a target language
  Future<AiResult> translate({
    required String text,
    required String targetLanguage,
    bool preserveFormatting = true,
  }) {
    return router.execute(AiRequest(
      task: AiTaskType.translateText,
      prompt: '''Translate to $targetLanguage${preserveFormatting ? ' (preserve formatting)' : ''}:

$text''',
      context: {'language': targetLanguage},
      maxTokens: text.length * 2, // rough estimate
      temperature: 0.3,
    ));
  }

  // ============================================
  // BUSINESS DOCUMENTS
  // ============================================

  /// Generate a business document
  Future<AiResult> generateBusinessDoc({
    required String type, // invoice_note, proposal, email, report
    required String details,
    String style = 'professional',
    String language = 'en',
  }) {
    return router.execute(AiRequest(
      task: AiTaskType.generateBusinessDoc,
      prompt: '''Generate a $type:

$details''',
      context: {'style': style, 'language': language},
      maxTokens: 1000,
    ));
  }

  // ============================================
  // STREAMING WRAPPERS
  // ============================================

  /// Stream a caption being generated (for live preview)
  Stream<AiStreamChunk> streamCaption({
    required String description,
    String screen = 'feed',
    String style = 'casual',
    String language = 'en',
  }) {
    return router.executeStream(AiRequest(
      task: AiTaskType.writeCaption,
      prompt:
          'Write a captivating caption for this post:\n\n$description',
      context: {
        'screen': screen,
        'style': style,
        'language': language,
      },
      maxTokens: 200,
      temperature: 0.8,
    ));
  }

  /// Stream article generation
  Stream<AiStreamChunk> streamArticle({
    required String topic,
    String style = 'professional',
    String language = 'en',
  }) {
    return router.executeStream(AiRequest(
      task: AiTaskType.writeArticle,
      prompt: 'Write an engaging article about:\n\n$topic',
      context: {'style': style, 'language': language},
      maxTokens: 2000,
    ));
  }
}


