/// health_profile.dart
///
/// The single source of truth for everything the app knows about a user
/// over time -- their "health diary". Every tab (PCOS, Protection, and the
/// future AI check-in chat) reads from and writes to this same model, so
/// the AI agent can reference past answers instead of re-asking, and so a
/// PCOS result or a contraception choice made today is still visible next
/// month.
///
/// This is intentionally a loose, nested JSON-friendly structure (not a
/// rigid SQL schema) because the fields here will keep growing as you add
/// features -- adding a new field just means adding it to the map, no
/// migration needed on the backend (see health_profile_api.py).
library;

class HealthProfile {
  final String userId;

  final Demographics demographics;
  final Lifestyle lifestyle;
  final ReproductiveHistory reproductiveHistory;
  final List<PcosCheckResult> pcosHistory;
  final MentalHealthFlags mentalHealth;
  final List<ConversationEntry> conversationLog;

  /// Free-standing journal entries the user writes herself (separate from
  /// AI chat turns in conversationLog) -- e.g. "Today I felt exhausted."
  /// See DiaryEntry below. Whether the AI is allowed to read these is
  /// governed by privacySettings.aiCanAccessDiary, not by this list
  /// existing or not -- the entries are always saved locally regardless
  /// of that toggle; the toggle only controls what context assembly is
  /// permitted to pull from them later.
  final List<DiaryEntry> diaryEntries;

  /// User-controlled privacy switches (section 14 of the product brief):
  /// what the AI is allowed to read, and whether it's allowed to retain
  /// memory across sessions at all. Defaults are conservative (AI access
  /// off) so a fresh profile never silently opts someone in.
  final PrivacySettings privacySettings;

  final DateTime lastUpdated;

  const HealthProfile({
    required this.userId,
    required this.demographics,
    required this.lifestyle,
    required this.reproductiveHistory,
    required this.pcosHistory,
    required this.mentalHealth,
    required this.conversationLog,
    this.diaryEntries = const [],
    this.privacySettings = const PrivacySettings(),
    required this.lastUpdated,
  });

  /// A blank profile for a brand-new user (first app launch).
  factory HealthProfile.empty(String userId) {
    return HealthProfile(
      userId: userId,
      demographics: const Demographics(),
      lifestyle: const Lifestyle(),
      reproductiveHistory: const ReproductiveHistory(),
      pcosHistory: const [],
      mentalHealth: const MentalHealthFlags(),
      conversationLog: const [],
      diaryEntries: const [],
      privacySettings: const PrivacySettings(),
      lastUpdated: DateTime.now(),
    );
  }

  HealthProfile copyWith({
    Demographics? demographics,
    Lifestyle? lifestyle,
    ReproductiveHistory? reproductiveHistory,
    List<PcosCheckResult>? pcosHistory,
    MentalHealthFlags? mentalHealth,
    List<ConversationEntry>? conversationLog,
    List<DiaryEntry>? diaryEntries,
    PrivacySettings? privacySettings,
  }) {
    return HealthProfile(
      userId: userId,
      demographics: demographics ?? this.demographics,
      lifestyle: lifestyle ?? this.lifestyle,
      reproductiveHistory: reproductiveHistory ?? this.reproductiveHistory,
      pcosHistory: pcosHistory ?? this.pcosHistory,
      mentalHealth: mentalHealth ?? this.mentalHealth,
      conversationLog: conversationLog ?? this.conversationLog,
      diaryEntries: diaryEntries ?? this.diaryEntries,
      privacySettings: privacySettings ?? this.privacySettings,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'demographics': demographics.toJson(),
    'lifestyle': lifestyle.toJson(),
    'reproductive_history': reproductiveHistory.toJson(),
    'pcos_history': pcosHistory.map((e) => e.toJson()).toList(),
    'mental_health': mentalHealth.toJson(),
    'conversation_log': conversationLog.map((e) => e.toJson()).toList(),
    'diary_entries': diaryEntries.map((e) => e.toJson()).toList(),
    'privacy_settings': privacySettings.toJson(),
    'last_updated': lastUpdated.toIso8601String(),
  };

  factory HealthProfile.fromJson(Map<String, dynamic> json) {
    return HealthProfile(
      userId: json['user_id'] as String,
      demographics: Demographics.fromJson(
        json['demographics'] as Map<String, dynamic>? ?? {},
      ),
      lifestyle: Lifestyle.fromJson(
        json['lifestyle'] as Map<String, dynamic>? ?? {},
      ),
      reproductiveHistory: ReproductiveHistory.fromJson(
        json['reproductive_history'] as Map<String, dynamic>? ?? {},
      ),
      pcosHistory: (json['pcos_history'] as List<dynamic>? ?? [])
          .map((e) => PcosCheckResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      mentalHealth: MentalHealthFlags.fromJson(
        json['mental_health'] as Map<String, dynamic>? ?? {},
      ),
      conversationLog: (json['conversation_log'] as List<dynamic>? ?? [])
          .map((e) => ConversationEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      // Both default to empty/conservative if absent, so loading an
      // OLDER saved profile (written before these fields existed) never
      // throws -- it just comes back with no diary entries and AI access
      // off, which is the safe default anyway.
      diaryEntries: (json['diary_entries'] as List<dynamic>? ?? [])
          .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      privacySettings: PrivacySettings.fromJson(
        json['privacy_settings'] as Map<String, dynamic>? ?? {},
      ),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
    );
  }
}

/// ---------------------------------------------------------------
/// Demographics -- who the user is. Kept separate from lifestyle so
/// the PCOS/Protection forms can pull just this section without
/// pulling everything else.
/// ---------------------------------------------------------------
class Demographics {
  final int? ageYrs;
  final double? weightKg;
  final double? heightCm;

  /// 'Single', 'Married', 'Divorced', 'Widowed', or null if not provided.
  /// Relevant because some contraception/PCOS guidance differs by this
  /// (e.g. fertility planning conversations, some WHO MEC categories).
  final String? maritalStatus;

  const Demographics({
    this.ageYrs,
    this.weightKg,
    this.heightCm,
    this.maritalStatus,
  });

  Demographics copyWith({
    int? ageYrs,
    double? weightKg,
    double? heightCm,
    String? maritalStatus,
  }) {
    return Demographics(
      ageYrs: ageYrs ?? this.ageYrs,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      maritalStatus: maritalStatus ?? this.maritalStatus,
    );
  }

  Map<String, dynamic> toJson() => {
    'age_yrs': ageYrs,
    'weight_kg': weightKg,
    'height_cm': heightCm,
    'marital_status': maritalStatus,
  };

  factory Demographics.fromJson(Map<String, dynamic> json) {
    return Demographics(
      ageYrs: json['age_yrs'] as int?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      maritalStatus: json['marital_status'] as String?,
    );
  }
}

/// ---------------------------------------------------------------
/// Lifestyle -- the day-to-day habits the AI check-in asks about
/// (exercise, diet, fast food, sleep) and uses to drive
/// recommendations.
/// ---------------------------------------------------------------
class Lifestyle {
  final bool? regularExercise;
  final String? exerciseFrequency; // e.g. 'Never', '1-2x/week', '3+/week'
  final String? dietQuality; // e.g. 'Poor', 'Average', 'Good'
  final bool? fastFoodFrequent;
  final double? averageSleepHours;

  /// Free-text notes captured verbatim from the AI chat, in case the
  /// structured fields above don't capture everything the user said.
  final String? notes;

  const Lifestyle({
    this.regularExercise,
    this.exerciseFrequency,
    this.dietQuality,
    this.fastFoodFrequent,
    this.averageSleepHours,
    this.notes,
  });

  Lifestyle copyWith({
    bool? regularExercise,
    String? exerciseFrequency,
    String? dietQuality,
    bool? fastFoodFrequent,
    double? averageSleepHours,
    String? notes,
  }) {
    return Lifestyle(
      regularExercise: regularExercise ?? this.regularExercise,
      exerciseFrequency: exerciseFrequency ?? this.exerciseFrequency,
      dietQuality: dietQuality ?? this.dietQuality,
      fastFoodFrequent: fastFoodFrequent ?? this.fastFoodFrequent,
      averageSleepHours: averageSleepHours ?? this.averageSleepHours,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'regular_exercise': regularExercise,
    'exercise_frequency': exerciseFrequency,
    'diet_quality': dietQuality,
    'fast_food_frequent': fastFoodFrequent,
    'average_sleep_hours': averageSleepHours,
    'notes': notes,
  };

  factory Lifestyle.fromJson(Map<String, dynamic> json) {
    return Lifestyle(
      regularExercise: json['regular_exercise'] as bool?,
      exerciseFrequency: json['exercise_frequency'] as String?,
      dietQuality: json['diet_quality'] as String?,
      fastFoodFrequent: json['fast_food_frequent'] as bool?,
      averageSleepHours: (json['average_sleep_hours'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

/// ---------------------------------------------------------------
/// Reproductive history -- cycle info and contraception choices over
/// time, feeding both the Protection tab and future PCOS pre-fill.
/// ---------------------------------------------------------------
class ReproductiveHistory {
  final String? cycleRegularity; // 'Regular' or 'Irregular'
  final int? cycleLengthDays;

  /// The contraception method currently in use, if any (matches the
  /// method names used in protection_screen.dart's _methods list).
  final String? currentContraceptionMethod;

  /// Every eligibility check or method chosen over time, most recent
  /// last -- lets "My Plan" show a real history instead of only the
  /// latest result.
  final List<ContraceptionLogEntry> contraceptionHistory;

  const ReproductiveHistory({
    this.cycleRegularity,
    this.cycleLengthDays,
    this.currentContraceptionMethod,
    this.contraceptionHistory = const [],
  });

  ReproductiveHistory copyWith({
    String? cycleRegularity,
    int? cycleLengthDays,
    String? currentContraceptionMethod,
    List<ContraceptionLogEntry>? contraceptionHistory,
  }) {
    return ReproductiveHistory(
      cycleRegularity: cycleRegularity ?? this.cycleRegularity,
      cycleLengthDays: cycleLengthDays ?? this.cycleLengthDays,
      currentContraceptionMethod:
          currentContraceptionMethod ?? this.currentContraceptionMethod,
      contraceptionHistory: contraceptionHistory ?? this.contraceptionHistory,
    );
  }

  Map<String, dynamic> toJson() => {
    'cycle_regularity': cycleRegularity,
    'cycle_length_days': cycleLengthDays,
    'current_contraception_method': currentContraceptionMethod,
    'contraception_history': contraceptionHistory
        .map((e) => e.toJson())
        .toList(),
  };

  factory ReproductiveHistory.fromJson(Map<String, dynamic> json) {
    return ReproductiveHistory(
      cycleRegularity: json['cycle_regularity'] as String?,
      cycleLengthDays: json['cycle_length_days'] as int?,
      currentContraceptionMethod:
          json['current_contraception_method'] as String?,
      contraceptionHistory:
          (json['contraception_history'] as List<dynamic>? ?? [])
              .map(
                (e) =>
                    ContraceptionLogEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

class ContraceptionLogEntry {
  final DateTime date;
  final String method;
  final String? note;

  const ContraceptionLogEntry({
    required this.date,
    required this.method,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'method': method,
    'note': note,
  };

  factory ContraceptionLogEntry.fromJson(Map<String, dynamic> json) {
    return ContraceptionLogEntry(
      date: DateTime.parse(json['date'] as String),
      method: json['method'] as String,
      note: json['note'] as String?,
    );
  }
}

/// ---------------------------------------------------------------
/// PCOS check history -- every result the user has ever gotten from
/// the Detection tab, so trends over time are possible later (e.g.
/// "your estimated likelihood has gone from 40% to 65% over 3
/// months" -- a much more useful signal than a single snapshot).
/// ---------------------------------------------------------------
class PcosCheckResult {
  final DateTime date;
  final String prediction; // 'PCOS Detected' / 'No PCOS Detected'
  final double pcosProbability;
  final String modelUsed;

  const PcosCheckResult({
    required this.date,
    required this.prediction,
    required this.pcosProbability,
    required this.modelUsed,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'prediction': prediction,
    'pcos_probability': pcosProbability,
    'model_used': modelUsed,
  };

  factory PcosCheckResult.fromJson(Map<String, dynamic> json) {
    return PcosCheckResult(
      date: DateTime.parse(json['date'] as String),
      prediction: json['prediction'] as String,
      pcosProbability: (json['pcos_probability'] as num).toDouble(),
      modelUsed: json['model_used'] as String,
    );
  }
}

/// ---------------------------------------------------------------
/// Mental health flags -- deliberately lightweight and NON-diagnostic.
/// This app must never claim to diagnose anxiety, depression, or any
/// mental health condition. These fields exist only to let the AI
/// check-in be gentler/more relevant on a return visit (e.g. "last
/// time you mentioned feeling stressed about work -- how's that
/// going?") and to decide when to show a "please consider talking to
/// someone" prompt with real crisis resources, never a label.
/// ---------------------------------------------------------------
class MentalHealthFlags {
  /// Self-reported 1-5 scale, set by the user/AI chat, never inferred
  /// or asserted by the app on its own.
  final int? selfReportedStressLevel;
  final String? notes;
  final DateTime? lastCheckIn;

  const MentalHealthFlags({
    this.selfReportedStressLevel,
    this.notes,
    this.lastCheckIn,
  });

  MentalHealthFlags copyWith({
    int? selfReportedStressLevel,
    String? notes,
    DateTime? lastCheckIn,
  }) {
    return MentalHealthFlags(
      selfReportedStressLevel:
          selfReportedStressLevel ?? this.selfReportedStressLevel,
      notes: notes ?? this.notes,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
    );
  }

  Map<String, dynamic> toJson() => {
    'self_reported_stress_level': selfReportedStressLevel,
    'notes': notes,
    'last_check_in': lastCheckIn?.toIso8601String(),
  };

  factory MentalHealthFlags.fromJson(Map<String, dynamic> json) {
    return MentalHealthFlags(
      selfReportedStressLevel: json['self_reported_stress_level'] as int?,
      notes: json['notes'] as String?,
      lastCheckIn: json['last_check_in'] != null
          ? DateTime.parse(json['last_check_in'] as String)
          : null,
    );
  }
}

/// ---------------------------------------------------------------
/// Conversation log -- the raw AI check-in chat history, so the AI
/// agent (built in the next phase) has memory of past conversations
/// instead of starting fresh every time.
/// ---------------------------------------------------------------
class ConversationEntry {
  final DateTime timestamp;
  final String role; // 'user' or 'assistant'
  final String message;

  const ConversationEntry({
    required this.timestamp,
    required this.role,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'role': role,
    'message': message,
  };

  factory ConversationEntry.fromJson(Map<String, dynamic> json) {
    return ConversationEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      role: json['role'] as String,
      message: json['message'] as String,
    );
  }
}

/// ---------------------------------------------------------------
/// Diary entries -- free-text journal entries the user writes
/// herself (section 13 of the product brief). Distinct from
/// ConversationEntry: a diary entry is not part of a chat turn, it's
/// a standalone note ("Today I felt exhausted and didn't want to
/// talk to anyone") that may optionally carry a mood, symptom tags,
/// or free-form tags.
///
/// Whether the AI context-assembly layer is allowed to read these at
/// all is controlled by PrivacySettings.aiCanAccessDiary below -- this
/// class itself has no opinion on that; it's just storage.
/// ---------------------------------------------------------------
class DiaryEntry {
  final String id;
  final DateTime date;
  final String text;

  /// Optional single mood label, free-form to match whatever picker UI
  /// ends up being used (e.g. '😊 Happy', '😰 Anxious') -- kept as a
  /// plain string rather than an enum so it can share vocabulary with
  /// CycleProvider's existing mood logging without a hard dependency.
  final String? mood;

  /// Optional symptom tags the user attaches to this entry, e.g.
  /// ['Cramps', 'Fatigue'] -- free-form strings for the same reason.
  final List<String> symptomTags;

  /// Optional free-form tags for anything else the user wants to mark
  /// this entry with (e.g. 'stress', 'family', 'breakup') -- these are
  /// what let the AI later notice a pattern like "stress mentioned in
  /// 4 of the last 5 entries before your period", presented only as an
  /// observation per the product brief, never a diagnosis.
  final List<String> tags;

  const DiaryEntry({
    required this.id,
    required this.date,
    required this.text,
    this.mood,
    this.symptomTags = const [],
    this.tags = const [],
  });

  DiaryEntry copyWith({
    DateTime? date,
    String? text,
    String? mood,
    List<String>? symptomTags,
    List<String>? tags,
  }) {
    return DiaryEntry(
      id: id,
      date: date ?? this.date,
      text: text ?? this.text,
      mood: mood ?? this.mood,
      symptomTags: symptomTags ?? this.symptomTags,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'text': text,
    'mood': mood,
    'symptom_tags': symptomTags,
    'tags': tags,
  };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      text: json['text'] as String,
      mood: json['mood'] as String?,
      symptomTags:
          (json['symptom_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
    );
  }
}

/// ---------------------------------------------------------------
/// Privacy settings -- user-controlled switches for what the AI is
/// permitted to read and remember (section 14 of the product brief).
/// Deliberately defaults to conservative/off values so a brand-new
/// profile never silently grants AI access to anything -- the user
/// has to explicitly opt in, and can revoke at any time.
///
/// This object controls PERMISSION only. It does not delete data --
/// deleting diary entries, clearing AI memory, etc. are separate
/// explicit actions (to be built in the Settings/privacy screen) that
/// mutate diaryEntries / conversationLog directly. Turning
/// aiCanAccessDiary off, for example, does not erase diaryEntries; it
/// just means the context-assembly layer must skip them.
/// ---------------------------------------------------------------
class PrivacySettings {
  /// Whether the AI context-assembly layer may read diaryEntries when
  /// building context for a chat turn. Off by default.
  final bool aiCanAccessDiary;

  /// Whether the AI is allowed to retain conversation memory across
  /// sessions at all (i.e. read conversationLog / build any
  /// cross-session context). If false, every chat should be treated
  /// as a fresh conversation with no prior history included. On by
  /// default since without it the "AI remembers your journey" feature
  /// in the brief can't function -- but the user can turn it off.
  final bool aiMemoryEnabled;

  const PrivacySettings({
    this.aiCanAccessDiary = false,
    this.aiMemoryEnabled = true,
  });

  PrivacySettings copyWith({bool? aiCanAccessDiary, bool? aiMemoryEnabled}) {
    return PrivacySettings(
      aiCanAccessDiary: aiCanAccessDiary ?? this.aiCanAccessDiary,
      aiMemoryEnabled: aiMemoryEnabled ?? this.aiMemoryEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'ai_can_access_diary': aiCanAccessDiary,
    'ai_memory_enabled': aiMemoryEnabled,
  };

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      aiCanAccessDiary: json['ai_can_access_diary'] as bool? ?? false,
      aiMemoryEnabled: json['ai_memory_enabled'] as bool? ?? true,
    );
  }
}
