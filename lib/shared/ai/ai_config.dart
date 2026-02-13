// ============================================
// AI CONFIGURATION
//
// Defines which models exist, what they're
// good at, and how the router picks between them.
//
// The AI in Driba is INVISIBLE — users never
// see model names. They just get the best result.
// ============================================

/// Available AI provider backends
enum AiProvider { anthropic, openai, google }

/// A specific model with its capabilities and limits
class AiModelConfig {
  final String id; // e.g. "claude-sonnet-4-20250514"
  final String name; // display: "Claude Sonnet"
  final AiProvider provider;
  final List<AiCapability> capabilities;
  final int maxInputTokens;
  final int maxOutputTokens;
  final double costPerInputToken; // USD per 1K tokens
  final double costPerOutputToken;
  final int priority; // lower = preferred (1 = first choice)
  final bool supportsVision;
  final bool supportsStreaming;

  const AiModelConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.capabilities,
    this.maxInputTokens = 200000,
    this.maxOutputTokens = 8192,
    this.costPerInputToken = 0.003,
    this.costPerOutputToken = 0.015,
    this.priority = 1,
    this.supportsVision = false,
    this.supportsStreaming = true,
  });

  bool hasCapability(AiCapability cap) => capabilities.contains(cap);
}

/// What an AI model can do
enum AiCapability {
  // Text generation
  writing, // long-form, blog posts, articles
  copywriting, // marketing copy, ads, taglines
  conversation, // chat, replies, support
  analysis, // data analysis, summaries, insights
  coding, // code generation and debugging
  translation, // multi-language

  // Structured output
  structuredData, // JSON, categories, tags
  extraction, // pull info from text/documents

  // Vision
  imageAnalysis, // describe, caption images
  imageGeneration, // create images (DALL-E, etc.)
  documentOcr, // read PDFs, documents

  // Domain-specific
  foodContent, // recipes, food descriptions
  productCopy, // product descriptions, specs
  socialMedia, // platform-optimized posts
  businessDocs, // invoices, proposals, reports
  smartReplies, // quick chat reply suggestions
}

// ============================================
// MODEL REGISTRY
// All available models and their strengths
// ============================================

class AiModels {
  AiModels._();

  // ── Anthropic ─────────────────────────────
  static const claudeSonnet = AiModelConfig(
    id: 'claude-sonnet-4-20250514',
    name: 'Claude Sonnet',
    provider: AiProvider.anthropic,
    priority: 1,
    maxInputTokens: 200000,
    maxOutputTokens: 16384,
    costPerInputToken: 0.003,
    costPerOutputToken: 0.015,
    supportsVision: true,
    capabilities: [
      AiCapability.writing,
      AiCapability.analysis,
      AiCapability.conversation,
      AiCapability.structuredData,
      AiCapability.extraction,
      AiCapability.coding,
      AiCapability.translation,
      AiCapability.imageAnalysis,
      AiCapability.documentOcr,
      AiCapability.businessDocs,
      AiCapability.smartReplies,
    ],
  );

  static const claudeHaiku = AiModelConfig(
    id: 'claude-haiku-4-5-20251001',
    name: 'Claude Haiku',
    provider: AiProvider.anthropic,
    priority: 2,
    maxInputTokens: 200000,
    maxOutputTokens: 8192,
    costPerInputToken: 0.0008,
    costPerOutputToken: 0.004,
    supportsVision: true,
    capabilities: [
      AiCapability.conversation,
      AiCapability.structuredData,
      AiCapability.extraction,
      AiCapability.translation,
      AiCapability.smartReplies,
      AiCapability.imageAnalysis,
    ],
  );

  // ── OpenAI ────────────────────────────────
  static const gpt4o = AiModelConfig(
    id: 'gpt-4o',
    name: 'GPT-4o',
    provider: AiProvider.openai,
    priority: 2,
    maxInputTokens: 128000,
    maxOutputTokens: 16384,
    costPerInputToken: 0.005,
    costPerOutputToken: 0.015,
    supportsVision: true,
    capabilities: [
      AiCapability.writing,
      AiCapability.copywriting,
      AiCapability.conversation,
      AiCapability.structuredData,
      AiCapability.imageAnalysis,
      AiCapability.socialMedia,
      AiCapability.productCopy,
      AiCapability.foodContent,
      AiCapability.coding,
    ],
  );

  static const gpt4oMini = AiModelConfig(
    id: 'gpt-4o-mini',
    name: 'GPT-4o Mini',
    provider: AiProvider.openai,
    priority: 3,
    maxInputTokens: 128000,
    maxOutputTokens: 16384,
    costPerInputToken: 0.00015,
    costPerOutputToken: 0.0006,
    supportsVision: true,
    capabilities: [
      AiCapability.conversation,
      AiCapability.structuredData,
      AiCapability.smartReplies,
      AiCapability.copywriting,
      AiCapability.socialMedia,
    ],
  );

  // ── Google ────────────────────────────────
  static const geminiPro = AiModelConfig(
    id: 'gemini-2.0-flash',
    name: 'Gemini Flash',
    provider: AiProvider.google,
    priority: 2,
    maxInputTokens: 1000000,
    maxOutputTokens: 8192,
    costPerInputToken: 0.00035,
    costPerOutputToken: 0.0015,
    supportsVision: true,
    capabilities: [
      AiCapability.conversation,
      AiCapability.imageAnalysis,
      AiCapability.documentOcr,
      AiCapability.translation,
      AiCapability.structuredData,
      AiCapability.extraction,
      AiCapability.foodContent,
      AiCapability.smartReplies,
    ],
  );

  /// All registered models
  static const List<AiModelConfig> all = [
    claudeSonnet,
    claudeHaiku,
    gpt4o,
    gpt4oMini,
    geminiPro,
  ];

  /// Get model by ID
  static AiModelConfig? byId(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ============================================
// ROUTING RULES
// Maps task types to preferred models
// ============================================

/// Preferred model order for each task type
class AiRoutingRules {
  AiRoutingRules._();

  /// Default routing: task → ordered list of model IDs to try
  static const Map<AiTaskType, List<String>> routes = {
    // Claude Sonnet excels at analysis, writing, business docs
    AiTaskType.writeCaption: ['claude-sonnet-4-20250514', 'gpt-4o', 'gemini-2.0-flash'],
    AiTaskType.writeDescription: ['claude-sonnet-4-20250514', 'gpt-4o'],
    AiTaskType.writeArticle: ['claude-sonnet-4-20250514', 'gpt-4o'],
    AiTaskType.analyzeContent: ['claude-sonnet-4-20250514', 'gpt-4o'],
    AiTaskType.generateBusinessDoc: ['claude-sonnet-4-20250514', 'gpt-4o'],
    AiTaskType.summarize: ['claude-sonnet-4-20250514', 'claude-haiku-4-5-20251001'],

    // GPT-4o excels at marketing copy and social media
    AiTaskType.writeMarketingCopy: ['gpt-4o', 'claude-sonnet-4-20250514'],
    AiTaskType.writeSocialPost: ['gpt-4o', 'claude-sonnet-4-20250514'],
    AiTaskType.writeProductCopy: ['gpt-4o', 'claude-sonnet-4-20250514'],

    // Fast models for real-time features
    AiTaskType.suggestSmartReplies: ['claude-haiku-4-5-20251001', 'gpt-4o-mini', 'gemini-2.0-flash'],
    AiTaskType.categorizeContent: ['claude-haiku-4-5-20251001', 'gpt-4o-mini'],
    AiTaskType.generateTags: ['claude-haiku-4-5-20251001', 'gpt-4o-mini'],
    AiTaskType.moderateContent: ['claude-haiku-4-5-20251001', 'gpt-4o-mini'],

    // Gemini for multimodal and long-context
    AiTaskType.analyzeImage: ['gemini-2.0-flash', 'claude-sonnet-4-20250514', 'gpt-4o'],
    AiTaskType.transcribeDocument: ['gemini-2.0-flash', 'claude-sonnet-4-20250514'],
    AiTaskType.translateText: ['gemini-2.0-flash', 'claude-haiku-4-5-20251001'],
    AiTaskType.describeFoodImage: ['gemini-2.0-flash', 'gpt-4o'],

    // Content creation (autonomous AI creators)
    AiTaskType.generateFoodContent: ['gpt-4o', 'claude-sonnet-4-20250514'],
    AiTaskType.generateTravelContent: ['claude-sonnet-4-20250514', 'gpt-4o'],
    AiTaskType.generateNewsContent: ['claude-sonnet-4-20250514', 'gpt-4o'],
    AiTaskType.generateLearningContent: ['claude-sonnet-4-20250514', 'gpt-4o'],
    AiTaskType.generateFitnessContent: ['gpt-4o', 'claude-sonnet-4-20250514'],
  };

  /// Get the best model for a task (first available)
  static AiModelConfig getBestModel(AiTaskType task) {
    final modelIds = routes[task] ?? ['claude-sonnet-4-20250514'];
    for (final id in modelIds) {
      final model = AiModels.byId(id);
      if (model != null) return model;
    }
    return AiModels.claudeSonnet; // ultimate fallback
  }
}

// ============================================
// TASK TYPES - Every AI operation in Driba
// ============================================

enum AiTaskType {
  // Content creation
  writeCaption,
  writeDescription,
  writeArticle,
  writeMarketingCopy,
  writeSocialPost,
  writeProductCopy,

  // Analysis
  analyzeContent,
  analyzeImage,
  categorizeContent,
  generateTags,
  summarize,

  // Chat
  suggestSmartReplies,
  translateText,

  // Business
  generateBusinessDoc,
  moderateContent,

  // Document
  transcribeDocument,
  describeFoodImage,

  // Autonomous creators
  generateFoodContent,
  generateTravelContent,
  generateNewsContent,
  generateLearningContent,
  generateFitnessContent,
}

// ============================================
// API KEY CONFIGURATION
// Keys are stored server-side (Cloud Functions)
// Client only passes through Firebase callable
// ============================================

class AiApiConfig {
  final String? anthropicApiKey;
  final String? openaiApiKey;
  final String? googleApiKey;
  final String baseUrl; // Cloud Function endpoint
  final Duration timeout;
  final int maxRetries;

  const AiApiConfig({
    this.anthropicApiKey,
    this.openaiApiKey,
    this.googleApiKey,
    this.baseUrl = '', // set from Firebase Remote Config
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 2,
  });
}
