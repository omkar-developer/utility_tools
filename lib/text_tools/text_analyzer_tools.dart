import 'package:utility_tools/models/tool.dart';
import 'package:flutter/material.dart';

class TextStatisticsTool extends Tool {
  TextStatisticsTool()
    : super(
        name: 'Text Statistics',
        description:
            'Comprehensive text analysis with counts, readability scores, and advanced metrics.',
        icon: Icons.analytics_outlined,
        isOutputMarkdown: true,
        isInputMarkdown: false,
        canAcceptMarkdown: true,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'countCharacters': true,
          'countCharactersNoSpaces': true,
          'countWords': true,
          'countLines': true,
          'countParagraphs': true,
          'countSentences': false,
          'showReadability': false,
          'readabilityType': 'Flesch-Kincaid Grade',
          'showAdvancedMetrics': false,
          'showEstimatedReadingTime': false,
          'wordsPerMinute': 200,
          'outputFormat': 'detailed',
        },
        settingsHints: {
          'countCharacters': {
            'type': 'bool',
            'label': 'Character Count (with spaces)',
            'help': 'Include spaces and punctuation in character count',
          },
          'countCharactersNoSpaces': {
            'type': 'bool',
            'label': 'Character Count (no spaces)',
            'help': 'Exclude spaces from character count',
          },
          'countWords': {
            'type': 'bool',
            'label': 'Word Count',
            'help': 'Count the number of words',
          },
          'countLines': {
            'type': 'bool',
            'label': 'Line Count',
            'help': 'Count the number of lines',
          },
          'countParagraphs': {
            'type': 'bool',
            'label': 'Paragraph Count',
            'help': 'Count paragraphs (separated by blank lines)',
          },
          'countSentences': {
            'type': 'bool',
            'label': 'Sentence Count',
            'help': 'Count the number of sentences',
          },
          'showReadability': {
            'type': 'bool',
            'label': 'Show Readability Scores',
            'help': 'Calculate readability metrics (Flesch scores, etc.)',
          },
          'readabilityType': {
            'type': 'dropdown',
            'label': 'Readability Score Type',
            'help': 'Choose which readability scores to show',
            'options': [
              {
                'value': 'Flesch-Kincaid Grade',
                'label': 'Flesch-Kincaid Grade Level',
              },
              {'value': 'Flesch Reading Ease', 'label': 'Flesch Reading Ease'},
              {'value': 'Both', 'label': 'Both Flesch Scores'},
              {'value': 'All', 'label': 'All Available Scores'},
            ],
          },
          'showAdvancedMetrics': {
            'type': 'bool',
            'label': 'Advanced Metrics',
            'help': 'Show word frequency, avg word/sentence length, etc.',
          },
          'showEstimatedReadingTime': {
            'type': 'bool',
            'label': 'Estimated Reading Time',
            'help': 'Calculate estimated reading time',
          },
          'wordsPerMinute': {
            'type': 'number',
            'label': 'Reading Speed (WPM)',
            'help': 'Words per minute for reading time calculation',
            'min': 100,
            'max': 500,
          },
          'outputFormat': {
            'type': 'dropdown',
            'label': 'Output Format',
            'help': 'Choose how to display the statistics',
            'options': [
              {'value': 'detailed', 'label': 'Detailed (with descriptions)'},
              {'value': 'compact', 'label': 'Compact (numbers only)'},
              {'value': 'table', 'label': 'Table format'},
            ],
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    // Clean input for markdown processing if needed
    final String cleanInput = _stripMarkdownIfNeeded(input);

    final Map<String, dynamic> stats = _analyzeText(cleanInput);
    final String output = _formatOutput(stats);

    return ToolResult(output: output, status: 'success');
  }

  String _stripMarkdownIfNeeded(String input) {
    // Basic markdown stripping for more accurate text analysis
    return input
        .replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '') // Images
        .replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '') // Links (keep text)
        .replaceAll(RegExp(r'`{1,3}[^`]*`{1,3}'), '') // Code
        .replaceAll(RegExp(r'[*_]{1,2}([^*_]+)[*_]{1,2}'), r'$1') // Bold/italic
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '') // Headers
        .replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '') // Lists
        .replaceAll(
          RegExp(r'^\s*\d+\.\s+', multiLine: true),
          '',
        ) // Numbered lists
        .replaceAll(RegExp(r'^>\s*', multiLine: true), ''); // Blockquotes
  }

  Map<String, dynamic> _analyzeText(String input) {
    final Map<String, dynamic> stats = {};

    // Basic counts
    if (settings['countCharacters'] as bool) {
      stats['characters'] = input.length;
    }

    if (settings['countCharactersNoSpaces'] as bool) {
      stats['charactersNoSpaces'] = input.replaceAll(RegExp(r'\s'), '').length;
    }

    List<String> words = [];
    if (settings['countWords'] as bool ||
        settings['showAdvancedMetrics'] as bool ||
        settings['showReadability'] as bool ||
        settings['showEstimatedReadingTime'] as bool) {
      words = _extractWords(input);
      stats['words'] = words.length;
    }

    if (settings['countLines'] as bool) {
      final List<String> lines = input.split(RegExp(r'\r?\n'));
      stats['lines'] = lines.length;
      stats['nonEmptyLines'] = lines
          .where((line) => line.trim().isNotEmpty)
          .length;
    }

    if (settings['countParagraphs'] as bool) {
      stats['paragraphs'] = _countParagraphs(input);
    }

    List<String> sentences = [];
    if (settings['countSentences'] as bool ||
        settings['showReadability'] as bool) {
      sentences = _extractSentences(input);
      stats['sentences'] = sentences.length;
    }

    // Advanced metrics
    if (settings['showAdvancedMetrics'] as bool && words.isNotEmpty) {
      stats['avgWordsPerSentence'] = sentences.isNotEmpty
          ? words.length / sentences.length
          : 0;
      stats['avgCharsPerWord'] =
          words.map((w) => w.length).reduce((a, b) => a + b) / words.length;
      stats['longestWord'] = words.reduce(
        (a, b) => a.length > b.length ? a : b,
      );
      stats['shortestWord'] = words.reduce(
        (a, b) => a.length < b.length ? a : b,
      );

      // Word frequency (top 5)
      final Map<String, int> frequency = {};
      for (String word in words) {
        final String normalizedWord = word.toLowerCase();
        if (normalizedWord.length > 2) {
          // Skip very short words
          frequency[normalizedWord] = (frequency[normalizedWord] ?? 0) + 1;
        }
      }
      final List<MapEntry<String, int>> topWords = frequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      stats['topWords'] = topWords.take(5).toList();
    }

    // Reading time
    if (settings['showEstimatedReadingTime'] as bool && words.isNotEmpty) {
      final int wpm = settings['wordsPerMinute'] as int;
      final double minutes = words.length / wpm;
      stats['readingTimeMinutes'] = minutes;
      stats['readingTimeFormatted'] = _formatReadingTime(minutes);
    }

    // Readability scores
    if (settings['showReadability'] as bool &&
        words.isNotEmpty &&
        sentences.isNotEmpty) {
      final int syllableCount = _estimateTotalSyllables(words);
      stats['syllables'] = syllableCount;

      final String readabilityType = settings['readabilityType'] as String;

      if (readabilityType == 'Flesch-Kincaid Grade' ||
          readabilityType == 'Both' ||
          readabilityType == 'All') {
        stats['fleschKincaidGrade'] = _calculateFleschKincaidGrade(
          words.length,
          sentences.length,
          syllableCount,
        );
      }

      if (readabilityType == 'Flesch Reading Ease' ||
          readabilityType == 'Both' ||
          readabilityType == 'All') {
        stats['fleschReadingEase'] = _calculateFleschReadingEase(
          words.length,
          sentences.length,
          syllableCount,
        );
      }

      if (readabilityType == 'All') {
        stats['automatedReadabilityIndex'] =
            _calculateAutomatedReadabilityIndex(
              words.length,
              sentences.length,
              stats['characters'] as int,
            );
        stats['colemanLiauIndex'] = _calculateColemanLiauIndex(
          words.length,
          sentences.length,
          stats['characters'] as int,
        );
      }
    }

    return stats;
  }

  String _formatOutput(Map<String, dynamic> stats) {
    final String format = settings['outputFormat'] as String;

    switch (format) {
      case 'compact':
        return _formatCompact(stats);
      case 'table':
        return _formatTable(stats);
      default:
        return _formatDetailed(stats);
    }
  }

  String _formatDetailed(Map<String, dynamic> stats) {
    final StringBuffer output = StringBuffer();
    output.writeln("## 📊 Text Statistics\n");

    // Basic counts
    if (stats.containsKey('characters')) {
      output.writeln("**Characters (with spaces):** ${stats['characters']}");
    }
    if (stats.containsKey('charactersNoSpaces')) {
      output.writeln(
        "**Characters (no spaces):** ${stats['charactersNoSpaces']}",
      );
    }
    if (stats.containsKey('words')) {
      output.writeln("**Words:** ${stats['words']}");
    }
    if (stats.containsKey('sentences')) {
      output.writeln("**Sentences:** ${stats['sentences']}");
    }
    if (stats.containsKey('lines')) {
      output.writeln(
        "**Lines:** ${stats['lines']} (${stats['nonEmptyLines']} non-empty)",
      );
    }
    if (stats.containsKey('paragraphs')) {
      output.writeln("**Paragraphs:** ${stats['paragraphs']}");
    }

    // Reading time
    if (stats.containsKey('readingTimeFormatted')) {
      output.writeln("\n### ⏱️ Reading Time");
      output.writeln(
        "**Estimated reading time:** ${stats['readingTimeFormatted']}",
      );
      final int wpm = settings['wordsPerMinute'] as int;
      output.writeln("*(Based on $wpm words per minute)*");
    }

    // Advanced metrics
    if (stats.containsKey('avgWordsPerSentence')) {
      output.writeln("\n### 📈 Advanced Metrics");
      output.writeln(
        "**Average words per sentence:** ${(stats['avgWordsPerSentence'] as double).toStringAsFixed(1)}",
      );
      output.writeln(
        "**Average characters per word:** ${(stats['avgCharsPerWord'] as double).toStringAsFixed(1)}",
      );
      output.writeln(
        "**Longest word:** \"${stats['longestWord']}\" (${(stats['longestWord'] as String).length} chars)",
      );
      output.writeln(
        "**Shortest word:** \"${stats['shortestWord']}\" (${(stats['shortestWord'] as String).length} chars)",
      );

      if (stats.containsKey('topWords')) {
        output.writeln("\n**Most frequent words:**");
        final List<MapEntry<String, int>> topWords =
            stats['topWords'] as List<MapEntry<String, int>>;
        for (int i = 0; i < topWords.length; i++) {
          output.writeln(
            "${i + 1}. \"${topWords[i].key}\" (${topWords[i].value} times)",
          );
        }
      }
    }

    // Readability scores
    if (stats.containsKey('fleschKincaidGrade') ||
        stats.containsKey('fleschReadingEase')) {
      output.writeln("\n### 🎯 Readability Scores");

      if (stats.containsKey('syllables')) {
        output.writeln("**Total syllables:** ${stats['syllables']}");
      }

      if (stats.containsKey('fleschKincaidGrade')) {
        final double grade = stats['fleschKincaidGrade'];
        output.writeln(
          "**Flesch-Kincaid Grade Level:** ${grade.toStringAsFixed(1)}",
        );
        output.writeln("  *${_interpretFleschKincaidGrade(grade)}*");
      }

      if (stats.containsKey('fleschReadingEase')) {
        final double ease = stats['fleschReadingEase'];
        output.writeln("**Flesch Reading Ease:** ${ease.toStringAsFixed(1)}");
        output.writeln("  *${_interpretFleschReadingEase(ease)}*");
      }

      if (stats.containsKey('automatedReadabilityIndex')) {
        output.writeln(
          "**Automated Readability Index:** ${(stats['automatedReadabilityIndex'] as double).toStringAsFixed(1)}",
        );
      }

      if (stats.containsKey('colemanLiauIndex')) {
        output.writeln(
          "**Coleman-Liau Index:** ${(stats['colemanLiauIndex'] as double).toStringAsFixed(1)}",
        );
      }
    }

    return output.toString();
  }

  String _formatCompact(Map<String, dynamic> stats) {
    final List<String> items = [];

    if (stats.containsKey('characters')) {
      items.add("${stats['characters']} chars");
    }
    if (stats.containsKey('charactersNoSpaces')) {
      items.add("${stats['charactersNoSpaces']} chars (no spaces)");
    }
    if (stats.containsKey('words')) items.add("${stats['words']} words");
    if (stats.containsKey('sentences')) {
      items.add("${stats['sentences']} sentences");
    }
    if (stats.containsKey('lines')) items.add("${stats['lines']} lines");
    if (stats.containsKey('paragraphs')) {
      items.add("${stats['paragraphs']} paragraphs");
    }
    if (stats.containsKey('readingTimeFormatted')) {
      items.add("~${stats['readingTimeFormatted']} reading time");
    }
    if (stats.containsKey('fleschKincaidGrade')) {
      items.add(
        "FK Grade ${(stats['fleschKincaidGrade'] as double).toStringAsFixed(1)}",
      );
    }
    if (stats.containsKey('fleschReadingEase')) {
      items.add(
        "F-Ease ${(stats['fleschReadingEase'] as double).toStringAsFixed(1)}",
      );
    }

    return "**Text Stats:** ${items.join(' • ')}";
  }

  String _formatTable(Map<String, dynamic> stats) {
    final StringBuffer output = StringBuffer();
    output.writeln("## Text Statistics\n");
    output.writeln("| Metric | Value |");
    output.writeln("|--------|-------|");

    if (stats.containsKey('characters')) {
      output.writeln("| Characters (with spaces) | ${stats['characters']} |");
    }
    if (stats.containsKey('charactersNoSpaces')) {
      output.writeln(
        "| Characters (no spaces) | ${stats['charactersNoSpaces']} |",
      );
    }
    if (stats.containsKey('words')) {
      output.writeln("| Words | ${stats['words']} |");
    }
    if (stats.containsKey('sentences')) {
      output.writeln("| Sentences | ${stats['sentences']} |");
    }
    if (stats.containsKey('lines')) {
      output.writeln("| Lines | ${stats['lines']} |");
    }
    if (stats.containsKey('paragraphs')) {
      output.writeln("| Paragraphs | ${stats['paragraphs']} |");
    }
    if (stats.containsKey('readingTimeFormatted')) {
      output.writeln("| Reading Time | ${stats['readingTimeFormatted']} |");
    }
    if (stats.containsKey('fleschKincaidGrade')) {
      output.writeln(
        "| Flesch-Kincaid Grade | ${(stats['fleschKincaidGrade'] as double).toStringAsFixed(1)} |",
      );
    }
    if (stats.containsKey('fleschReadingEase')) {
      output.writeln(
        "| Flesch Reading Ease | ${(stats['fleschReadingEase'] as double).toStringAsFixed(1)} |",
      );
    }

    return output.toString();
  }

  // Utility methods
  List<String> _extractWords(String text) {
    return RegExp(r'\b\w+\b')
        .allMatches(text)
        .map((match) => match.group(0)!)
        .where((word) => word.isNotEmpty)
        .toList();
  }

  List<String> _extractSentences(String text) {
    return text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  int _countParagraphs(String text) {
    if (text.trim().isEmpty) return 0;
    final List<String> paragraphs = text
        .split(RegExp(r'(\r?\n\s*){2,}'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return paragraphs.isEmpty
        ? (text.trim().isNotEmpty ? 1 : 0)
        : paragraphs.length;
  }

  String _formatReadingTime(double minutes) {
    if (minutes < 1) {
      return "${(minutes * 60).round()} seconds";
    } else if (minutes < 60) {
      final int mins = minutes.floor();
      final int secs = ((minutes - mins) * 60).round();
      return secs > 0 ? "${mins}m ${secs}s" : "${mins}m";
    } else {
      final int hours = (minutes / 60).floor();
      final int remainingMins = (minutes % 60).round();
      return remainingMins > 0 ? "${hours}h ${remainingMins}m" : "${hours}h";
    }
  }

  int _estimateTotalSyllables(List<String> words) {
    return words.map(_estimateWordSyllables).reduce((a, b) => a + b);
  }

  int _estimateWordSyllables(String word) {
    final String cleanWord = word.toLowerCase().replaceAll(
      RegExp(r'[^a-z]'),
      '',
    );
    if (cleanWord.isEmpty) return 1;

    int syllables = 0;
    bool prevWasVowel = false;

    for (int i = 0; i < cleanWord.length; i++) {
      final bool isVowel = 'aeiouy'.contains(cleanWord[i]);
      if (isVowel && !prevWasVowel) {
        syllables++;
      }
      prevWasVowel = isVowel;
    }

    // Adjust for silent 'e'
    if (cleanWord.endsWith('e') && syllables > 1) {
      syllables--;
    }

    // Handle 'le' ending
    if (cleanWord.endsWith('le') &&
        cleanWord.length > 2 &&
        !'aeiouy'.contains(cleanWord[cleanWord.length - 3])) {
      syllables++;
    }

    return syllables > 0 ? syllables : 1;
  }

  // Readability calculations
  double _calculateFleschKincaidGrade(
    int wordCount,
    int sentenceCount,
    int syllableCount,
  ) {
    if (sentenceCount == 0 || wordCount == 0) return 0.0;
    return 0.39 * (wordCount / sentenceCount) +
        11.8 * (syllableCount / wordCount) -
        15.59;
  }

  double _calculateFleschReadingEase(
    int wordCount,
    int sentenceCount,
    int syllableCount,
  ) {
    if (sentenceCount == 0 || wordCount == 0) return 100.0;
    return 206.835 -
        1.015 * (wordCount / sentenceCount) -
        84.6 * (syllableCount / wordCount);
  }

  double _calculateAutomatedReadabilityIndex(
    int wordCount,
    int sentenceCount,
    int characterCount,
  ) {
    if (sentenceCount == 0 || wordCount == 0) return 0.0;
    return 4.71 * (characterCount / wordCount) +
        0.5 * (wordCount / sentenceCount) -
        21.43;
  }

  double _calculateColemanLiauIndex(
    int wordCount,
    int sentenceCount,
    int characterCount,
  ) {
    if (wordCount == 0) return 0.0;
    final double l = (characterCount / wordCount) * 100;
    final double s = (sentenceCount / wordCount) * 100;
    return 0.0588 * l - 0.296 * s - 15.8;
  }

  // Interpretation helpers
  String _interpretFleschKincaidGrade(double grade) {
    if (grade <= 6) return "Elementary school level";
    if (grade <= 8) return "Middle school level";
    if (grade <= 13) return "High school level";
    if (grade <= 16) return "College level";
    return "Graduate level";
  }

  String _interpretFleschReadingEase(double ease) {
    if (ease >= 90) return "Very easy to read";
    if (ease >= 80) return "Easy to read";
    if (ease >= 70) return "Fairly easy to read";
    if (ease >= 60) return "Standard reading level";
    if (ease >= 50) return "Fairly difficult to read";
    if (ease >= 30) return "Difficult to read";
    return "Very difficult to read";
  }
}

Map<String, List<Tool Function()>> getTextAnalyzerTools() {
  return {
    'Text Analysis': [() => TextStatisticsTool()],
  };
}
