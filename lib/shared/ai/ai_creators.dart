import 'ai_config.dart';

// ============================================
// AUTONOMOUS AI CREATORS
//
// These are AI "personalities" that auto-generate
// content for Driba screens. They run as Cloud
// Functions on a schedule, creating fresh content
// so screens always have something interesting.
//
// Each creator has a personality, topic areas,
// posting schedule, and quality rules.
//
// They are NOT chatbots — users never interact
// with them directly. They're invisible content
// engines that keep the platform alive.
// ============================================

/// Configuration for an autonomous AI creator agent
class AiCreatorConfig {
  final String id;
  final String name; // internal name
  final String displayName; // shows as post author: "Driba Food"
  final String avatarUrl; // generated avatar
  final String screen; // which screen they post to
  final AiTaskType taskType;

  // Content rules
  final List<String> topics; // what they write about
  final List<String> contentTypes; // article, tip, recipe, list, review
  final String style; // writing style
  final String defaultLanguage;
  final List<String> supportedLanguages;

  // Posting schedule
  final int postsPerDay;
  final List<int> postingHoursUtc; // e.g. [8, 12, 18]

  // Quality
  final double minConfidence; // 0-1, reject below this
  final bool requiresReview; // human review before publishing
  final List<String> forbiddenTopics;

  // Categories & tags
  final List<String> categories; // Driba screen IDs
  final List<String> defaultTags;

  const AiCreatorConfig({
    required this.id,
    required this.name,
    required this.displayName,
    required this.avatarUrl,
    required this.screen,
    required this.taskType,
    required this.topics,
    this.contentTypes = const ['article'],
    this.style = 'professional',
    this.defaultLanguage = 'en',
    this.supportedLanguages = const ['en'],
    this.postsPerDay = 3,
    this.postingHoursUtc = const [8, 14, 20],
    this.minConfidence = 0.7,
    this.requiresReview = false,
    this.forbiddenTopics = const [],
    required this.categories,
    this.defaultTags = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'screen': screen,
        'taskType': taskType.name,
        'topics': topics,
        'contentTypes': contentTypes,
        'style': style,
        'defaultLanguage': defaultLanguage,
        'supportedLanguages': supportedLanguages,
        'postsPerDay': postsPerDay,
        'postingHoursUtc': postingHoursUtc,
        'minConfidence': minConfidence,
        'requiresReview': requiresReview,
        'forbiddenTopics': forbiddenTopics,
        'categories': categories,
        'defaultTags': defaultTags,
      };
}

// ============================================
// BUILT-IN CREATORS
// ============================================

class AiCreators {
  AiCreators._();

  // ── Food Creator ──────────────────────────
  static const food = AiCreatorConfig(
    id: 'driba_food',
    name: 'food_creator',
    displayName: 'Driba Food',
    avatarUrl: 'assets/images/ai_creators/food.png',
    screen: 'food',
    taskType: AiTaskType.generateFoodContent,
    topics: [
      'trending recipes',
      'cooking techniques',
      'restaurant spotlights',
      'street food around the world',
      'healthy meal prep',
      'seasonal ingredients',
      'food science',
      'kitchen hacks',
      'dessert recipes',
      'cuisine deep dives',
    ],
    contentTypes: ['recipe', 'tip', 'spotlight', 'list', 'article'],
    style: 'warm, knowledgeable, food-passionate',
    postsPerDay: 4,
    postingHoursUtc: [7, 11, 16, 20],
    categories: ['food', 'learn'],
    defaultTags: ['food', 'cooking', 'recipe'],
    forbiddenTopics: ['alcohol promotion to minors', 'extreme diets'],
  );

  // ── Travel Creator ────────────────────────
  static const travel = AiCreatorConfig(
    id: 'driba_travel',
    name: 'travel_creator',
    displayName: 'Driba Travel',
    avatarUrl: 'assets/images/ai_creators/travel.png',
    screen: 'travel',
    taskType: AiTaskType.generateTravelContent,
    topics: [
      'hidden gem destinations',
      'budget travel tips',
      'luxury getaways',
      'solo travel guides',
      'cultural experiences',
      'adventure activities',
      'digital nomad spots',
      'road trip itineraries',
      'seasonal travel guides',
      'local food and travel',
    ],
    contentTypes: ['guide', 'tip', 'itinerary', 'spotlight', 'article'],
    style: 'adventurous, authentic, practical',
    postsPerDay: 3,
    postingHoursUtc: [9, 14, 19],
    categories: ['travel'],
    defaultTags: ['travel', 'explore', 'wanderlust'],
  );

  // ── Learn Creator ─────────────────────────
  static const learn = AiCreatorConfig(
    id: 'driba_learn',
    name: 'learn_creator',
    displayName: 'Driba Learn',
    avatarUrl: 'assets/images/ai_creators/learn.png',
    screen: 'learn',
    taskType: AiTaskType.generateLearningContent,
    topics: [
      'productivity techniques',
      'tech tutorials',
      'business skills',
      'creative skills',
      'language learning tips',
      'science explainers',
      'money management',
      'communication skills',
      'mental models',
      'career development',
    ],
    contentTypes: ['tutorial', 'explainer', 'tip', 'list', 'article'],
    style: 'encouraging, clear, accessible',
    postsPerDay: 3,
    postingHoursUtc: [8, 13, 18],
    categories: ['learn'],
    defaultTags: ['learn', 'skills', 'growth'],
  );

  // ── Fitness Creator ───────────────────────
  static const fitness = AiCreatorConfig(
    id: 'driba_fitness',
    name: 'fitness_creator',
    displayName: 'Driba Fitness',
    avatarUrl: 'assets/images/ai_creators/fitness.png',
    screen: 'health',
    taskType: AiTaskType.generateFitnessContent,
    topics: [
      'home workouts',
      'gym routines',
      'yoga and flexibility',
      'running and cardio',
      'nutrition for athletes',
      'recovery and rest',
      'mental health and exercise',
      'beginner fitness guides',
      'workout challenges',
      'sports-specific training',
    ],
    contentTypes: ['workout', 'tip', 'routine', 'article', 'challenge'],
    style: 'motivating, science-backed, inclusive',
    postsPerDay: 3,
    postingHoursUtc: [6, 12, 17],
    categories: ['health'],
    defaultTags: ['fitness', 'health', 'workout'],
    forbiddenTopics: [
      'extreme weight loss',
      'unverified supplements',
      'dangerous exercises without proper form guidance',
    ],
  );

  // ── News Creator ──────────────────────────
  static const news = AiCreatorConfig(
    id: 'driba_news',
    name: 'news_creator',
    displayName: 'Driba News',
    avatarUrl: 'assets/images/ai_creators/news.png',
    screen: 'news',
    taskType: AiTaskType.generateNewsContent,
    topics: [
      'technology and AI',
      'business and startups',
      'science discoveries',
      'climate and environment',
      'culture and society',
      'innovation',
      'global economy',
      'space exploration',
    ],
    contentTypes: ['summary', 'analysis', 'roundup', 'explainer'],
    style: 'factual, balanced, accessible',
    postsPerDay: 5,
    postingHoursUtc: [7, 10, 13, 16, 20],
    requiresReview: true, // news needs human review
    categories: ['news'],
    defaultTags: ['news', 'current events'],
    forbiddenTopics: [
      'misinformation',
      'unverified rumors',
      'partisan political takes',
    ],
  );

  /// All built-in creators
  static const List<AiCreatorConfig> all = [
    food,
    travel,
    learn,
    fitness,
    news,
  ];

  /// Get creator by screen
  static AiCreatorConfig? forScreen(String screenId) {
    try {
      return all.firstWhere((c) => c.screen == screenId);
    } catch (_) {
      return null;
    }
  }
}

// ============================================
// CONTENT GENERATION PROMPT BUILDER
// Used by Cloud Functions to generate posts
// ============================================

class CreatorPromptBuilder {
  CreatorPromptBuilder._();

  /// Build a generation prompt for a creator
  static String buildPrompt(AiCreatorConfig creator, {String? specificTopic}) {
    final topic = specificTopic ??
        '${creator.topics[DateTime.now().millisecond % creator.topics.length]}';

    return '''You are "${creator.displayName}", a content creator for Driba's ${creator.screen} screen.

Your personality: ${creator.style}

Generate a post about: $topic

Requirements:
- Content type: ${creator.contentTypes[DateTime.now().second % creator.contentTypes.length]}
- Language: ${creator.defaultLanguage}
- Must be original and engaging
- Include practical, actionable information
- Write for a mobile-first audience (concise, scannable)
${creator.forbiddenTopics.isNotEmpty ? '- NEVER discuss: ${creator.forbiddenTopics.join(", ")}' : ''}

Output as JSON:
{
  "title": "Short catchy title",
  "description": "The main post text (150-300 words)",
  "tags": ["tag1", "tag2", "tag3"],
  "confidence": 0.0-1.0 (how confident you are in the quality)
}''';
  }
}
