import 'dart:math';
import 'package:flutter/material.dart';

enum MatchType { exact, high, medium, low }

class MatchResult {
  final String itemId;
  final String itemName;
  final double confidence;
  final MatchType matchType;

  MatchResult({
    required this.itemId,
    required this.itemName,
    required this.confidence,
    required this.matchType,
  });

  Color get confidenceColor {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.7) return Colors.orange;
    return Colors.red;
  }

  IconData get confidenceIcon {
    if (confidence >= 0.9) return Icons.check_circle;
    if (confidence >= 0.7) return Icons.check_circle_outline;
    return Icons.help_outline;
  }

  String get confidenceLabel {
    if (confidence >= 0.9) return 'Excellent Match';
    if (confidence >= 0.7) return 'Good Match';
    if (confidence >= 0.5) return 'Fair Match';
    return 'Poor Match';
  }
}

/// Fuzzy Matcher Service - Intelligent item name matching with multiple algorithms
/// Handles typos, abbreviations, and variations in Indian product names
class FuzzyMatcherService {
  static final FuzzyMatcherService instance = FuzzyMatcherService._();
  FuzzyMatcherService._();

  // Common Indian product name synonyms
  static const Map<String, List<String>> _synonyms = {
    'biryani': ['biriyani', 'briyani', 'biryaani', 'biriani'],
    'container': ['contaner', 'konteiner', 'box'],
    'aluminium': ['aluminum', 'alu'],
    'silver': ['silver', 'slver'],
    'foil': ['foil', 'foi', 'foel'],
    'milk': ['milk', 'mlk', 'doodh'],
    'laptop': ['laptop', 'leptop', 'labtop'],
    'charger': ['charger', 'charger', 'charjar'],
    'packet': ['packet', 'pkt', 'pack'],
    'bottle': ['bottle', 'bottel', 'btl'],
  };

  /// Find best matching catalog items for OCR-extracted text
  Future<List<MatchResult>> findBestMatches(
    String query,
    List<Map<String, dynamic>> catalogItems, {
    int maxResults = 3,
    double minConfidence = 0.5,
  }) async {
    if (query.trim().isEmpty) return [];

    List<MatchResult> results = [];

    for (var item in catalogItems) {
      final score = _calculateMatchScore(query, item);
      if (score >= minConfidence) {
        results.add(MatchResult(
          itemId: item['id'].toString(),
          itemName: item['name'].toString(),
          confidence: score,
          matchType: _determineMatchType(score),
        ));
      }
    }

    // Sort by confidence descending, return top matches
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results.take(maxResults).toList();
  }

  /// Multi-strategy matching algorithm combining multiple techniques
  double _calculateMatchScore(String query, Map<String, dynamic> item) {
    final itemName = item['name'].toString().toLowerCase();
    final queryLower = query.toLowerCase();

    // 1. Exact match (confidence: 1.0)
    if (itemName == queryLower) return 1.0;

    // 2. Substring match (confidence: 0.9)
    if (itemName.contains(queryLower)) return 0.9;
    if (queryLower.contains(itemName)) return 0.85;

    // 3. Levenshtein distance (edit distance)
    final levenshtein = _levenshteinDistance(queryLower, itemName);
    final maxLen = max(queryLower.length, itemName.length);
    final levenshteinScore = maxLen > 0 ? 1.0 - (levenshtein / maxLen) : 0.0;

    // 4. Jaccard similarity (token-based word matching)
    final jaccardScore = _jaccardSimilarity(queryLower, itemName);

    // 5. N-gram similarity (character-level, catches typos)
    final ngramScore = _ngramSimilarity(queryLower, itemName, n: 2);

    // 6. Phonetic similarity (for Indian names like "biryani"/"biriyani")
    final phoneticScore = _phoneticSimilarity(queryLower, itemName);

    // Weighted combination (empirically tuned for best results)
    final combinedScore = (levenshteinScore * 0.30) +
        (jaccardScore * 0.25) +
        (ngramScore * 0.25) +
        (phoneticScore * 0.20);

    return combinedScore.clamp(0.0, 1.0);
  }

  /// Determine match quality based on confidence score
  MatchType _determineMatchType(double score) {
    if (score >= 0.9) return MatchType.exact;
    if (score >= 0.7) return MatchType.high;
    if (score >= 0.5) return MatchType.medium;
    return MatchType.low;
  }

  // ALGORITHM IMPLEMENTATIONS

  /// Levenshtein Distance - Edit distance between two strings
  /// Counts minimum number of single-character edits (insertions, deletions, substitutions)
  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> dp = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    // Initialize first row and column
    for (int i = 0; i <= s1.length; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      dp[0][j] = j;
    }

    // Fill the matrix
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        if (s1[i - 1] == s2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1]; // No operation needed
        } else {
          dp[i][j] = 1 +
              min(
                dp[i - 1][j], // Deletion
                min(
                  dp[i][j - 1], // Insertion
                  dp[i - 1][j - 1], // Substitution
                ),
              );
        }
      }
    }

    return dp[s1.length][s2.length];
  }

  /// Jaccard Similarity - Token-based word matching
  /// Measures similarity between two sets of words
  double _jaccardSimilarity(String s1, String s2) {
    final words1 = s1.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
    final words2 = s2.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();

    if (words1.isEmpty && words2.isEmpty) return 1.0;
    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;

    return union > 0 ? intersection / union : 0.0;
  }

  /// N-gram Similarity - Character-level matching
  /// Catches typos and spelling variations
  double _ngramSimilarity(String s1, String s2, {int n = 2}) {
    final ngrams1 = _getNgrams(s1, n);
    final ngrams2 = _getNgrams(s2, n);

    if (ngrams1.isEmpty && ngrams2.isEmpty) return 1.0;
    if (ngrams1.isEmpty || ngrams2.isEmpty) return 0.0;

    final intersection = ngrams1.intersection(ngrams2).length;
    final union = ngrams1.union(ngrams2).length;

    return union > 0 ? intersection / union : 0.0;
  }

  /// Generate n-grams from a string
  Set<String> _getNgrams(String s, int n) {
    if (s.length < n) return {s};

    Set<String> ngrams = {};
    for (int i = 0; i <= s.length - n; i++) {
      ngrams.add(s.substring(i, i + n));
    }
    return ngrams;
  }

  /// Phonetic Similarity - Handle pronunciation variations
  /// Especially useful for Indian product names
  double _phoneticSimilarity(String s1, String s2) {
    // Check for known synonyms
    for (var entry in _synonyms.entries) {
      final baseWord = entry.key;
      final variations = entry.value;

      final s1HasBase = s1.contains(baseWord);
      final s2HasBase = s2.contains(baseWord);

      final s1HasVariation = variations.any((v) => s1.contains(v));
      final s2HasVariation = variations.any((v) => s2.contains(v));

      // If one has base word and other has variation, they're phonetically similar
      if ((s1HasBase && s2HasVariation) || (s2HasBase && s1HasVariation)) {
        return 0.85;
      }

      // If both have variations of same word
      if (s1HasVariation && s2HasVariation) {
        return 0.80;
      }
    }

    // Simple phonetic matching: remove vowels and compare
    final consonants1 = _getConsonants(s1);
    final consonants2 = _getConsonants(s2);

    if (consonants1.isEmpty || consonants2.isEmpty) return 0.0;

    // Use Levenshtein on consonants
    final distance = _levenshteinDistance(consonants1, consonants2);
    final maxLen = max(consonants1.length, consonants2.length);

    return maxLen > 0 ? 1.0 - (distance / maxLen) * 0.5 : 0.0;
  }

  /// Extract consonants from string (remove vowels for phonetic matching)
  String _getConsonants(String s) {
    return s.replaceAll(RegExp(r'[aeiou]'), '');
  }

  /// Get detailed match explanation for debugging/UI display
  String getMatchExplanation(String query, String itemName, double confidence) {
    if (confidence >= 0.9) {
      return 'Excellent match! Very confident this is the right item.';
    } else if (confidence >= 0.7) {
      return 'Good match. Small differences detected but likely correct.';
    } else if (confidence >= 0.5) {
      return 'Fair match. Please verify this is the correct item.';
    } else {
      return 'Low confidence. Consider manual selection.';
    }
  }

  /// Calculate match statistics for analysis
  Map<String, dynamic> getMatchStatistics(
    String query,
    Map<String, dynamic> item,
  ) {
    final itemName = item['name'].toString().toLowerCase();
    final queryLower = query.toLowerCase();

    return {
      'levenshtein_distance': _levenshteinDistance(queryLower, itemName),
      'jaccard_similarity': _jaccardSimilarity(queryLower, itemName),
      'ngram_similarity': _ngramSimilarity(queryLower, itemName),
      'phonetic_similarity': _phoneticSimilarity(queryLower, itemName),
      'overall_score': _calculateMatchScore(query, item),
    };
  }
}
