/// Session returned by POST /ai/sessions.
class AiSession {
  const AiSession({
    required this.id,
    required this.status,
    required this.startedAt,
    this.productId,
    this.platform,
  });

  final String id;
  final String status; // ACTIVE | COMPLETED | ABANDONED | EXPIRED
  final DateTime startedAt;
  final String? productId;
  final String? platform;

  factory AiSession.fromJson(Map<String, dynamic> json) {
    // Backend may wrap in a data envelope or return flat — handle both.
    final map = json['data'] as Map<String, dynamic>? ?? json;
    return AiSession(
      id: map['id'] as String,
      status: map['status'] as String,
      startedAt: DateTime.parse(map['startedAt'] as String),
      productId: map['productId'] as String?,
      platform: map['platform'] as String?,
    );
  }
}

/// One uploaded photo in a session.
class AiSessionPhoto {
  const AiSessionPhoto({
    required this.id,
    required this.sessionId,
    required this.cloudinaryUrl,
    required this.status,
    required this.displayOrder,
    this.deduped = false,
  });

  final String id;
  final String sessionId;
  final String cloudinaryUrl;
  final String status;
  final int displayOrder;

  /// True when the backend detected a duplicate (same SHA-256 in this session).
  final bool deduped;

  factory AiSessionPhoto.fromJson(Map<String, dynamic> json) {
    final map = (json['photo'] ??
            json['data'] ??
            json) as Map<String, dynamic>;
    return AiSessionPhoto(
      id: map['id'] as String,
      sessionId: map['sessionId'] as String,
      cloudinaryUrl: map['cloudinaryUrl'] as String,
      status: map['status'] as String,
      displayOrder: map['displayOrder'] as int? ?? 1,
      deduped: map['deduped'] as bool? ?? false,
    );
  }
}

class AiAnalysisResult {
  const AiAnalysisResult({
    required this.generationId,
    required this.sessionId,
    required this.titleSuggestion,
    required this.category,
    required this.primaryColor,
    required this.secondaryColors,
    required this.materials,
    required this.styleTags,
    required this.targetAudience,
    required this.occasionTags,
    required this.confidence,
    required this.photosAnalyzed,
    required this.generatedAt,
    this.costMillicents,
  });

  final String generationId;
  final String sessionId;
  final String titleSuggestion;
  final String category;
  final String primaryColor;
  final List<String> secondaryColors;
  final List<String> materials;
  final List<String> styleTags;
  final String targetAudience;
  final List<String> occasionTags;

  /// 'high' | 'medium' | 'low'
  final String confidence;
  final int photosAnalyzed;
  final DateTime generatedAt;
  final int? costMillicents;

  bool get isLowConfidence => confidence == 'low';
  bool get isHighConfidence => confidence == 'high';

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) {
    // Flat response — no envelope.
    // The 9 AI fields live in the nested 'analysis' sub-object (snake_case).
    final analysis = json['analysis'] as Map<String, dynamic>? ?? json;

    return AiAnalysisResult(
      generationId: json['generationId'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      titleSuggestion: analysis['title_suggestion'] as String? ?? '',
      category: analysis['category'] as String? ?? '',
      primaryColor: analysis['primary_color'] as String? ?? '',
      secondaryColors: List<String>.from(
          analysis['secondary_colors'] as List? ?? []),
      materials: List<String>.from(analysis['materials'] as List? ?? []),
      styleTags: List<String>.from(analysis['style_tags'] as List? ?? []),
      targetAudience: analysis['target_audience'] as String? ?? 'unknown',
      occasionTags: List<String>.from(
          analysis['occasion_tags'] as List? ?? []),
      confidence: analysis['confidence'] as String? ??
          json['confidence'] as String? ?? 'medium',
      photosAnalyzed: json['photosAnalyzed'] as int? ?? 1,
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : DateTime.now(),
      costMillicents: json['costMillicents'] as int?,
    );
  }
}

class CaptionVariation {
  const CaptionVariation({
    required this.style,
    required this.text,
    required this.hashtags,
    required this.emojiCount,
    required this.callToAction,
  });

  final String style; // casual_fun | professional | urgent_scarcity | educational | story_based
  final String text;
  final List<String> hashtags;
  final int emojiCount;
  final String callToAction;

  factory CaptionVariation.fromJson(Map<String, dynamic> json) {
    return CaptionVariation(
      style: json['style'] as String? ?? 'casual_fun',
      text: json['text'] as String? ?? '',
      hashtags: List<String>.from(json['hashtags'] as List? ?? []),
      emojiCount: json['emoji_count'] as int? ?? 0,
      callToAction: json['call_to_action'] as String? ?? '',
    );
  }

  /// Full text ready to copy — caption + hashtags joined
  String get fullText {
    if (hashtags.isEmpty) return text;
    return '$text\n\n${hashtags.map((h) => '#$h').join(' ')}';
  }
}

class CaptionsResult {
  const CaptionsResult({
    required this.generationId,
    required this.sessionId,
    required this.variations,
    required this.platform,
    required this.language,
    required this.generatedAt,
    required this.confidence,
    required this.partial,
    this.bestPostingTime,
  });

  final String generationId;
  final String sessionId;
  final List<CaptionVariation> variations;
  final String platform;
  final String language;
  final DateTime generatedAt;
  final String confidence;
  final bool partial;
  final String? bestPostingTime;

  factory CaptionsResult.fromJson(Map<String, dynamic> json) {
    final variations = json['variations'] as List? ?? [];
    return CaptionsResult(
      generationId: json['generationId'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      variations: variations
          .map((c) => CaptionVariation.fromJson(c as Map<String, dynamic>))
          .toList(),
      platform: json['platform'] as String? ?? 'INSTAGRAM',
      language: json['language'] as String? ?? 'derja',
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : DateTime.now(),
      confidence: json['confidence'] as String? ?? 'medium',
      partial: json['partial'] as bool? ?? false,
      bestPostingTime: json['bestPostingTime'] as String?,
    );
  }
}

/// Full hydration payload from GET /ai/sessions/:id/state.
/// Matches the backend SessionStateResponse. Lets Flutter rebuild the
/// AI Studio UI in one round trip on app wake or resume.
class AiSessionState {
  const AiSessionState({
    required this.session,
    required this.photos,
    this.latestAnalysis,
  });

  final AiSession session;
  final List<AiSessionPhoto> photos;

  /// Null when no ANALYZE generation exists yet for this session.
  /// Otherwise mirrors the analyze cache-hit response shape.
  final AiAnalysisResult? latestAnalysis;

  factory AiSessionState.fromJson(Map<String, dynamic> json) {
    final photos = (json['photos'] as List? ?? [])
        .map((p) => AiSessionPhoto.fromJson(p as Map<String, dynamic>))
        .toList();
    final rawAnalysis = json['latestAnalysis'];
    return AiSessionState(
      session: AiSession.fromJson(json['session'] as Map<String, dynamic>),
      photos: photos,
      latestAnalysis: rawAnalysis is Map<String, dynamic>
          ? AiAnalysisResult.fromJson(rawAnalysis)
          : null,
    );
  }
}

class AiFeatureQuota {
  const AiFeatureQuota({
    required this.used,
    required this.limit,
    required this.remaining,
  });

  final int used;
  final int limit;
  final int remaining;

  double get usedRatio => limit == 0 ? 0 : used / limit;

  factory AiFeatureQuota.fromJson(Map<String, dynamic> json) {
    return AiFeatureQuota(
      used: json['used'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
      remaining: json['remaining'] as int? ?? 0,
    );
  }
}

class AiQuotaStatus {
  const AiQuotaStatus({
    required this.tier,
    required this.analyze,
    required this.enhance,
    required this.captions,
    required this.resetsAt,
  });

  final String tier; // TRIAL | FREE | PRO
  final AiFeatureQuota analyze;
  final AiFeatureQuota enhance;
  final AiFeatureQuota captions;
  final DateTime resetsAt;

  factory AiQuotaStatus.fromJson(Map<String, dynamic> json) {
    final features = json['features'] as Map<String, dynamic>? ?? {};
    return AiQuotaStatus(
      tier: json['tier'] as String? ?? 'TRIAL',
      analyze: AiFeatureQuota.fromJson(
          features['analyze'] as Map<String, dynamic>? ?? {}),
      enhance: AiFeatureQuota.fromJson(
          features['enhance'] as Map<String, dynamic>? ?? {}),
      captions: AiFeatureQuota.fromJson(
          features['captions'] as Map<String, dynamic>? ?? {}),
      resetsAt: json['resetsAt'] != null
          ? DateTime.parse(json['resetsAt'] as String).toLocal()
          : DateTime.now(),
    );
  }
}
