// Data models mirroring the backend JSON (see backend/app/schemas/chat.py).

class Scenario {
  final String id;
  final String title;
  final String description;
  final String expectedTopic;

  const Scenario({
    required this.id,
    required this.title,
    required this.description,
    required this.expectedTopic,
  });

  factory Scenario.fromJson(Map<String, dynamic> json) => Scenario(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        expectedTopic: json['expected_topic'] as String,
      );
}

class Correction {
  final String original;
  final String corrected;
  final String explanation;
  final String category;

  const Correction({
    required this.original,
    required this.corrected,
    required this.explanation,
    required this.category,
  });

  factory Correction.fromJson(Map<String, dynamic> json) => Correction(
        original: json['original'] as String,
        corrected: json['corrected'] as String,
        explanation: json['explanation'] as String,
        category: json['category'] as String,
      );
}

/// The tutor's structured response for one turn.
class TutorTurn {
  final String reply;
  final bool isOnTopic;
  final List<Correction> corrections;
  final String? grammarTip;
  final String? estimatedLevel;

  const TutorTurn({
    required this.reply,
    required this.isOnTopic,
    required this.corrections,
    this.grammarTip,
    this.estimatedLevel,
  });

  factory TutorTurn.fromJson(Map<String, dynamic> json) => TutorTurn(
        reply: json['reply'] as String,
        isOnTopic: json['is_on_topic'] as bool? ?? true,
        corrections: (json['corrections'] as List<dynamic>? ?? [])
            .map((c) => Correction.fromJson(c as Map<String, dynamic>))
            .toList(),
        grammarTip: json['grammar_tip'] as String?,
        estimatedLevel: json['estimated_level'] as String?,
      );
}

/// AI provider options the user can choose in Settings.
enum Provider { ollama, anthropic, openai }

extension ProviderInfo on Provider {
  String get id => switch (this) {
        Provider.ollama => 'ollama',
        Provider.anthropic => 'anthropic',
        Provider.openai => 'openai',
      };

  String get label => switch (this) {
        Provider.ollama => 'Open source (gratis)',
        Provider.anthropic => 'Claude (tu cuenta)',
        Provider.openai => 'OpenAI (tu cuenta)',
      };

  bool get needsApiKey => this != Provider.ollama;

  static Provider fromId(String? id) => switch (id) {
        'anthropic' => Provider.anthropic,
        'openai' => Provider.openai,
        _ => Provider.ollama,
      };
}

/// Per-request LLM config sent to the backend. Empty fields are omitted so the
/// backend falls back to its own defaults.
class LlmConfig {
  final Provider provider;
  final String? model;
  final String? apiKey;

  const LlmConfig({required this.provider, this.model, this.apiKey});

  Map<String, dynamic> toJson() => {
        'provider': provider.id,
        if (model != null && model!.isNotEmpty) 'model': model,
        if (apiKey != null && apiKey!.isNotEmpty) 'api_key': apiKey,
      };
}

enum Sender { user, tutor }

/// A chat bubble in the UI. Tutor messages may carry feedback (corrections + tip)
/// attached to the *preceding* user message.
class ChatMessage {
  final Sender sender;
  final String text;
  final List<Correction> corrections;
  final String? grammarTip;

  const ChatMessage({
    required this.sender,
    required this.text,
    this.corrections = const [],
    this.grammarTip,
  });

  Map<String, String> toApi() => {
        'role': sender == Sender.user ? 'user' : 'assistant',
        'content': text,
      };
}

const cefrLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
