import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'catches_provider.dart';
import '../models/catch.dart';

/// AI-powered features using Google Gemini.
///
/// Features:
/// 1. 🐟 AI Fish ID — identify species from a photo
/// 2. 🎤 Smart Voice — parse natural language into catch data
/// 3. 🗺️ Lake Insights — answer questions from your catch data
/// 4. 🎣 Smart Tackle Picks — recommend lures based on conditions
class AIService extends ChangeNotifier {
  static final AIService instance = AIService._();
  AIService._();

  GenerativeModel? _model;
  bool _initialized = false;
  bool _isLoading = false;
  String? _lastError;

  bool get isAvailable => _initialized && _model != null;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  /// Initialize the Gemini model with the API key.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final apiKey = ApiConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      _lastError = 'Gemini API key not configured. Set GEMINI_API_KEY.';
      return;
    }

    try {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash', // Fast & free tier
        apiKey: apiKey,
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
        ],
      );
      debugPrint('AIService: Gemini initialized successfully');
    } catch (e) {
      _lastError = 'Failed to initialize AI: $e';
      debugPrint('AIService: $e');
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  //  1. 🐟 AI Fish ID — identify species from a photo
  // ─────────────────────────────────────────────────────────

  /// Identifies the fish species from an image file.
  /// Returns the species name and confidence, or null if unsure.
  Future<FishIdResult?> identifyFish(File image) async {
    if (!_ensureReady()) return null;

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final imageBytes = await image.readAsBytes();
      final content = [
        Content.multi([
          TextPart(
              'Identify the fish in this photo. Return ONLY a JSON object with keys: '
              '"species" (common name), "scientificName", "confidence" (0-1), '
              '"description" (1 sentence). If you cannot identify it, set species to null.'),
          DataPart('image/png', imageBytes),
        ]),
      ];

      final response = await _model!.generateContent(content);
      final text = response.text ?? '';

      // Parse JSON from response
      final jsonStr = _extractJson(text);
      if (jsonStr != null) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        if (data['species'] != null) {
          return FishIdResult(
            species: data['species'] as String,
            scientificName: data['scientificName'] as String? ?? '',
            confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
            description: data['description'] as String? ?? '',
          );
        }
      }
      return null;
    } catch (e) {
      _lastError = 'Fish ID failed: $e';
      debugPrint('AIService: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Identifies fish from base64-encoded image bytes (for in-app camera).
  Future<FishIdResult?> identifyFishFromBytes(Uint8List imageBytes) async {
    if (!_ensureReady()) return null;

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final content = [
        Content.multi([
          TextPart(
              'Identify the fish in this photo. Return ONLY a JSON object with keys: '
              '"species" (common name), "scientificName", "confidence" (0-1), '
              '"description" (1 sentence). If you cannot identify it, set species to null.'),
          DataPart('image/png', imageBytes),
        ]),
      ];

      final response = await _model!.generateContent(content);
      final text = response.text ?? '';

      final jsonStr = _extractJson(text);
      if (jsonStr != null) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        if (data['species'] != null) {
          return FishIdResult(
            species: data['species'] as String,
            scientificName: data['scientificName'] as String? ?? '',
            confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
            description: data['description'] as String? ?? '',
          );
        }
      }
      return null;
    } catch (e) {
      _lastError = 'Fish ID failed: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────
  //  2. 🎤 Smart Voice — parse natural language into catch data
  // ─────────────────────────────────────────────────────────

  /// Parses a natural language voice command into catch form data.
  /// Example: "caught a 5lb largemouth bass at the dock using a spinner"
  Future<VoiceParsedCatch?> parseVoice(String text) async {
    if (!_ensureReady()) return null;

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final prompt = '''
Parse this fishing catch description into structured data.
Return ONLY a JSON object with these keys (all optional, null if not mentioned):
{
  "species": "common fish name or null",
  "weight": number or null,
  "weightUnit": "lb" or "kg" or null,
  "length": number or null,
  "lengthUnit": "inches" or "cm" or null,
  "location": "location name or null",
  "lure": "lure/bait name or null",
  "angler": "person name or null",
  "notes": "any extra details or null"
}

Text to parse: "$text"
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final jsonStr = _extractJson(response.text ?? '');
      if (jsonStr == null) return null;

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return VoiceParsedCatch(
        species: data['species'] as String?,
        weight: (data['weight'] as num?)?.toDouble(),
        weightUnit: data['weightUnit'] as String?,
        length: (data['length'] as num?)?.toDouble(),
        lengthUnit: data['lengthUnit'] as String?,
        location: data['location'] as String?,
        lure: data['lure'] as String?,
        angler: data['angler'] as String?,
        notes: data['notes'] as String?,
      );
    } catch (e) {
      _lastError = 'Voice parse failed: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────
  //  3. 🗺️ Lake Insights — answer questions from catch data
  // ─────────────────────────────────────────────────────────

  /// Answers a question based on the user's catch history.
  /// Example: "what's the best lure for pike at lake erie?"
  Future<String?> askInsight(String question, List<Catch> catches) async {
    if (!_ensureReady()) return null;
    if (catches.isEmpty) return 'No catch data to analyze yet. Start fishing! 🎣';

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // Summarize catch data for the prompt
      final summary = _summarizeCatches(catches);

      final prompt = '''
You are a fishing expert assistant for the CatchTales app. Answer the user's question based on their fishing data below.

USER DATA:
$summary

USER QUESTION: "$question"

Provide a helpful, concise answer (2-4 sentences). Be specific to their data. If the data doesn't contain enough info, say so and give general advice.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No insights available.';
    } catch (e) {
      _lastError = 'Insights failed: $e';
      return 'Sorry, I couldn\'t process that question.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────
  //  4. 🎣 Smart Tackle Picks — recommend lures based on conditions
  // ─────────────────────────────────────────────────────────

  /// Gets AI-powered tackle recommendations for target species and conditions.
  Future<String?> recommendTackle({
    required String species,
    double? temperature,
    String? weatherCondition,
    String? season,
    String? waterType,
    double? waterTemp,
  }) async {
    if (!_ensureReady()) return null;

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final prompt = '''
You are a fishing tackle expert. Recommend the best lures/tackle for:

TARGET SPECIES: $species
${temperature != null ? 'TEMPERATURE: ${temperature}°F' : ''}
${weatherCondition != null ? 'WEATHER: $weatherCondition' : ''}
${season != null ? 'SEASON: $season' : ''}
${waterType != null ? 'WATER TYPE: $waterType' : ''}
${waterTemp != null ? 'WATER TEMP: ${waterTemp}°F' : ''}

Return ONLY a JSON array of 3 recommendations:
[
  {
    "name": "lure name",
    "type": "type (e.g. Spinnerbait, Crankbait, Soft Plastic)",
    "reason": "why it's good for these conditions (1 sentence)",
    "confidence": 0.0-1.0
  }
]
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No recommendations available.';
    } catch (e) {
      _lastError = 'Tackle recommendation failed: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────

  bool _ensureReady() {
    if (!_initialized) init();
    if (_model == null) {
      _lastError = 'AI not available. Check your API key.';
      return false;
    }
    return true;
  }

  /// Extract JSON from AI response (handles markdown code blocks).
  String? _extractJson(String text) {
    // Try to find a JSON block in markdown
    final blockMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(text);
    if (blockMatch != null) return blockMatch.group(1)!.trim();

    // Try direct JSON parse
    try {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start >= 0 && end > start) {
        final candidate = text.substring(start, end + 1);
        jsonDecode(candidate); // validate
        return candidate;
      }
    } catch (_) {}
    return null;
  }

  /// Summarize catch list for the AI prompt.
  String _summarizeCatches(List<Catch> catches) {
    final total = catches.length;
    final speciesCount = <String, int>{};
    final lureCount = <String, int>{};
    final locationCount = <String, int>{};
    double totalWeight = 0;
    int weightCount = 0;
    String? biggest;

    for (final c in catches) {
      speciesCount[c.species] = (speciesCount[c.species] ?? 0) + 1;
      if (c.lure.isNotEmpty) lureCount[c.lure] = (lureCount[c.lure] ?? 0) + 1;
      if (c.location.isNotEmpty) locationCount[c.location] = (locationCount[c.location] ?? 0) + 1;
      if (c.weight != null && c.weight! > 0) {
        totalWeight += c.weight!;
        weightCount++;
        if (biggest == null || c.weight! > double.parse(biggest.split(' ')[0])) {
          biggest = '${c.weight} ${c.weightUnit}';
        }
      }
    }

    final topSpecies = speciesCount.entries
        .toList()..sort((a, b) => b.value.compareTo(a.value));
    final topLures = lureCount.entries
        .toList()..sort((a, b) => b.value.compareTo(a.value));
    final topLocations = locationCount.entries
        .toList()..sort((a, b) => b.value.compareTo(a.value));

    return '''
Total catches: $total
Species caught: ${speciesCount.length}
Top species: ${topSpecies.take(5).map((e) => '${e.key} (${e.value})').join(', ')}
Top lures: ${topLures.take(5).map((e) => '${e.key} (${e.value})').join(', ')}
Top locations: ${topLocations.take(5).map((e) => '${e.key} (${e.value})').join(', ')}
Average weight: ${weightCount > 0 ? (totalWeight / weightCount).toStringAsFixed(1) : 'N/A'}
Biggest catch: ${biggest ?? 'N/A'}
''';
  }
}

// ─── Result Models ──────────────────────────────────────────

class FishIdResult {
  final String species;
  final String scientificName;
  final double confidence;
  final String description;

  FishIdResult({
    required this.species,
    required this.scientificName,
    required this.confidence,
    required this.description,
  });
}

class VoiceParsedCatch {
  final String? species;
  final double? weight;
  final String? weightUnit;
  final double? length;
  final String? lengthUnit;
  final String? location;
  final String? lure;
  final String? angler;
  final String? notes;

  VoiceParsedCatch({
    this.species,
    this.weight,
    this.weightUnit,
    this.length,
    this.lengthUnit,
    this.location,
    this.lure,
    this.angler,
    this.notes,
  });
}
