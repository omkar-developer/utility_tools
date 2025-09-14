import 'package:flutter/material.dart';
import 'package:utility_tools/models/tool.dart';

class CaseTransformTool extends Tool {
  CaseTransformTool()
    : super(
        name: 'Case Transform',
        description: 'Transform text case with advanced formatting options',
        icon: Icons.text_format,
        isOutputMarkdown: true,
        canAcceptMarkdown: true,
        settings: {
          // Primary transform type
          'transform_type': 'title_case',

          // Transform options
          'preserve_acronyms': false,
          'smart_capitalization': false,
          'handle_contractions': false,
          'preserve_urls': false,
          'preserve_emails': false,

          // Word handling
          'min_word_length': 2,
          'ignore_articles': false,
          'ignore_prepositions': false,
          'ignore_conjunctions': false,

          // Special formatting
          'add_markdown_formatting': false,
          'wrap_in_quotes': false,
          'add_numbering': false,
          'bullet_style': 'none',

          // Output options
          'include_statistics': true,
          'show_before_after': true,
          'raw_output': false,
          'line_separator': '\n',
          'word_separator': null,

          // Advanced options
          'trim_whitespace': true,
          'normalize_spacing': false,
          'remove_empty_lines': false,
          'custom_exceptions': '',
          'replace_patterns': '',
        },
        settingsHints: {
          // Primary transform type
          'transform_type': {
            'type': 'dropdown',
            'label': 'Transform Type',
            'help': 'Primary text transformation to apply',
            'options': [
              {'value': 'uppercase', 'label': 'UPPERCASE'},
              {'value': 'lowercase', 'label': 'lowercase'},
              {'value': 'title_case', 'label': 'Title Case'},
              {'value': 'sentence_case', 'label': 'Sentence case'},
              {'value': 'camel_case', 'label': 'camelCase'},
              {'value': 'pascal_case', 'label': 'PascalCase'},
              {'value': 'snake_case', 'label': 'snake_case'},
              {'value': 'kebab_case', 'label': 'kebab-case'},
              {'value': 'constant_case', 'label': 'CONSTANT_CASE'},
              {'value': 'alternating', 'label': 'aLtErNaTiNg'},
              {'value': 'reverse', 'label': 'esreveR'},
              {'value': 'random_case', 'label': 'RaNdOm CaSe'},
            ],
          },

          // Transform options
          'preserve_acronyms': {
            'type': 'bool',
            'label': 'Preserve Acronyms',
            'help': 'Keep existing acronyms in UPPERCASE (e.g., NASA, API)',
          },
          'smart_capitalization': {
            'type': 'bool',
            'label': 'Smart Capitalization',
            'help': 'Apply context-aware capitalization rules',
          },
          'handle_contractions': {
            'type': 'bool',
            'label': 'Handle Contractions',
            'help': 'Properly format contractions (don\'t, won\'t, etc.)',
          },
          'preserve_urls': {
            'type': 'bool',
            'label': 'Preserve URLs',
            'help': 'Keep URLs unchanged during transformation',
          },
          'preserve_emails': {
            'type': 'bool',
            'label': 'Preserve Emails',
            'help': 'Keep email addresses unchanged',
          },

          // Word handling
          'min_word_length': {
            'type': 'spinner',
            'label': 'Min Word Length',
            'help':
                'Minimum word length to transform (shorter words may be ignored)',
            'min': 1,
            'max': 10,
            'step': 1,
          },
          'ignore_articles': {
            'type': 'bool',
            'label': 'Ignore Articles',
            'help': 'Don\'t capitalize articles (a, an, the) in title case',
          },
          'ignore_prepositions': {
            'type': 'bool',
            'label': 'Ignore Prepositions',
            'help': 'Don\'t capitalize short prepositions (of, in, on, etc.)',
          },
          'ignore_conjunctions': {
            'type': 'bool',
            'label': 'Ignore Conjunctions',
            'help': 'Don\'t capitalize conjunctions (and, but, or, etc.)',
          },

          // Special formatting
          'add_markdown_formatting': {
            'type': 'bool',
            'label': 'Add Markdown Formatting',
            'help': 'Wrap transformed text in markdown formatting',
          },
          'wrap_in_quotes': {
            'type': 'bool',
            'label': 'Wrap in Quotes',
            'help': 'Surround each line with quotation marks',
          },
          'add_numbering': {
            'type': 'bool',
            'label': 'Add Line Numbering',
            'help': 'Add sequential numbers to each line',
          },
          'bullet_style': {
            'type': 'dropdown',
            'label': 'Bullet Style',
            'help': 'Add bullet points to each line',
            'options': [
              {'value': 'none', 'label': 'None'},
              {'value': 'dash', 'label': '- Dash'},
              {'value': 'asterisk', 'label': '* Asterisk'},
              {'value': 'bullet', 'label': '• Bullet'},
              {'value': 'arrow', 'label': '→ Arrow'},
              {'value': 'check', 'label': '✓ Check'},
            ],
          },

          // Output options
          'include_statistics': {
            'type': 'bool',
            'label': 'Include Statistics',
            'help': 'Show character and word count statistics',
          },
          'show_before_after': {
            'type': 'bool',
            'label': 'Show Before/After',
            'help': 'Display original text alongside transformed result',
          },
          'line_separator': {
            'type': 'dropdown',
            'label': 'Line Separator',
            'help': 'Character(s) to separate lines in output',
            'options': [
              {'value': '\n', 'label': 'Newline (\\n)'},
              {'value': '\n\n', 'label': 'Double Newline'},
              {'value': ' | ', 'label': 'Pipe ( | )'},
              {'value': ', ', 'label': 'Comma (, )'},
              {'value': '; ', 'label': 'Semicolon (; )'},
            ],
          },
          'word_separator': {
            'type': 'text',
            'label': 'Word Separator',
            'help':
                'Character(s) to separate words (for snake_case, kebab-case, etc.)',
            'placeholder': 'Enter separator...',
          },

          // Advanced options
          'trim_whitespace': {
            'type': 'bool',
            'label': 'Trim Whitespace',
            'help': 'Remove leading and trailing whitespace',
          },
          'normalize_spacing': {
            'type': 'bool',
            'label': 'Normalize Spacing',
            'help': 'Replace multiple spaces with single spaces',
          },
          'remove_empty_lines': {
            'type': 'bool',
            'label': 'Remove Empty Lines',
            'help': 'Remove blank lines from the output',
          },
          'custom_exceptions': {
            'type': 'multiline',
            'label': 'Custom Exceptions',
            'help': 'Words to preserve exactly as written (one per line)',
            'placeholder': 'iPhone\nmacOS\nJavaScript\nAPI\netc.',
            'min_lines': 2,
            'max_lines': 6,
            'width': 300,
          },
          'replace_patterns': {
            'type': 'multiline',
            'label': 'Replace Patterns',
            'help':
                'Find and replace patterns (format: old->new, one per line)',
            'placeholder': 'colour->color\norganise->organize\netc.',
            'min_lines': 2,
            'max_lines': 5,
            'width': 300,
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.trim().isEmpty) {
      return ToolResult(
        output: '**Error:** No input text provided.',
        status: 'error',
      );
    }

    final buffer = StringBuffer();
    String processedText = input;

    // Store original for statistics
    final originalText = input;

    // Apply preprocessing
    if (settings['trim_whitespace'] == true) {
      processedText = processedText.trim();
    }

    if (settings['normalize_spacing'] == true) {
      processedText = processedText.replaceAll(RegExp(r'\s+'), ' ');
    }

    // Apply custom replacements
    if (settings['replace_patterns'].toString().isNotEmpty) {
      final patterns = settings['replace_patterns'].toString().split('\n');
      for (final pattern in patterns) {
        if (pattern.contains('->')) {
          final parts = pattern.split('->');
          if (parts.length == 2) {
            processedText = processedText.replaceAll(
              parts[0].trim(),
              parts[1].trim(),
            );
          }
        }
      }
    }

    // Apply main transformation
    final transformedText = _applyTransformation(processedText);

    // Apply post-processing formatting
    String finalText = _applyFormatting(transformedText);

    // Build output
    if (settings['raw_output'] == false) {
      buffer.writeln('# Text Case Transform Results\n');
    }

    if (settings['show_before_after'] == true &&
        settings['raw_output'] == false) {
      buffer.writeln('## Before & After\n');
      buffer.writeln('**Original:**');
      buffer.writeln('```');
      buffer.writeln(originalText);
      buffer.writeln('```\n');

      buffer.writeln('**Transformed:**');
      buffer.writeln('```');
      buffer.writeln(finalText);
      buffer.writeln('```\n');
    } else {
      if (settings['raw_output'] == false) buffer.writeln('## Result\n');
      buffer.writeln('```');
      buffer.writeln(finalText);
      buffer.writeln('```\n');
    }

    if (settings['include_statistics'] == true &&
        settings['raw_output'] == false) {
      buffer.writeln('---\n');
      buffer.writeln('## Statistics\n');
      buffer.writeln('| Metric | Original | Transformed |');
      buffer.writeln('|--------|----------|-------------|');
      buffer.writeln(
        '| Characters | ${originalText.length} | ${finalText.length} |',
      );
      buffer.writeln(
        '| Words | ${_countWords(originalText)} | ${_countWords(finalText)} |',
      );
      buffer.writeln(
        '| Lines | ${originalText.split('\n').length} | ${finalText.split('\n').length} |',
      );
      buffer.writeln('| Transform | — | **${_getTransformDisplayName()}** |');
      buffer.writeln('');
    }

    return ToolResult(output: buffer.toString(), status: 'success');
  }

  @override
  Future<String> executeGetText(String input) async {
    if (input.trim().isEmpty) {
      return 'Error: No input text provided.';
    }

    String processedText = input;

    // Apply preprocessing
    if (settings['trim_whitespace'] == true) {
      processedText = processedText.trim();
    }

    if (settings['normalize_spacing'] == true) {
      processedText = processedText.replaceAll(RegExp(r'\s+'), ' ');
    }

    // Apply custom replacements
    if (settings['replace_patterns'].toString().isNotEmpty) {
      final patterns = settings['replace_patterns'].toString().split('\n');
      for (final pattern in patterns) {
        if (pattern.contains('->')) {
          final parts = pattern.split('->');
          if (parts.length == 2) {
            processedText = processedText.replaceAll(
              parts[0].trim(),
              parts[1].trim(),
            );
          }
        }
      }
    }

    // Apply main transformation and return raw result
    final transformedText = _applyTransformation(processedText);
    return _applyFormatting(transformedText);
  }

  String _applyTransformation(String text) {
    final transformType = settings['transform_type'].toString();
    final lines = text.split('\n');

    return lines.map((line) => _transformLine(line, transformType)).join('\n');
  }

  String _transformLine(String line, String transformType) {
    if (line.trim().isEmpty) return line;

    // Preserve URLs and emails if requested
    final preservedItems = <String>[];
    String workingLine = line;

    if (settings['preserve_urls'] == true) {
      workingLine = _preservePattern(
        workingLine,
        RegExp(r'https?://[^\s]+'),
        preservedItems,
      );
    }

    if (settings['preserve_emails'] == true) {
      workingLine = _preservePattern(
        workingLine,
        RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
        preservedItems,
      );
    }

    // Apply transformation
    String transformed;
    switch (transformType) {
      case 'uppercase':
        transformed = workingLine.toUpperCase();
        break;
      case 'lowercase':
        transformed = workingLine.toLowerCase();
        break;
      case 'title_case':
        transformed = _toTitleCase(workingLine);
        break;
      case 'sentence_case':
        transformed = _toSentenceCase(workingLine);
        break;
      case 'camel_case':
        transformed = _toCamelCase(workingLine);
        break;
      case 'pascal_case':
        transformed = _toPascalCase(workingLine);
        break;
      case 'snake_case':
        transformed = _toSnakeCase(workingLine);
        break;
      case 'kebab_case':
        transformed = _toKebabCase(workingLine);
        break;
      case 'constant_case':
        transformed = _toConstantCase(workingLine);
        break;
      case 'alternating':
        transformed = _toAlternating(workingLine);
        break;
      case 'reverse':
        transformed = workingLine.split('').reversed.join('');
        break;
      case 'random_case':
        transformed = _toRandomCase(workingLine);
        break;
      default:
        transformed = workingLine;
    }

    // Restore preserved items
    for (int i = 0; i < preservedItems.length; i++) {
      transformed = transformed.replaceFirst(
        '__PRESERVED_${i}__',
        preservedItems[i],
      );
    }

    return transformed;
  }

  String _normalizeWords(String input) {
    // Break words on non-alphanumeric, collapse multiple spaces
    return input
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _toSnakeCase(String input) {
    final separator = settings['word_separator'] ?? '_';
    return input
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => w.toLowerCase())
        .join(separator);
  }

  String _toKebabCase(String input) {
    final separator = settings['word_separator'] ?? '-';
    return input
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => w.toLowerCase())
        .join(separator);
  }

  String _toConstantCase(String input) {
    final separator = settings['word_separator'] ?? '_';
    return input
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => w.toUpperCase())
        .join(separator);
  }

  String _preservePattern(String text, RegExp pattern, List<String> preserved) {
    return text.replaceAllMapped(pattern, (match) {
      final placeholder = '__PRESERVED_${preserved.length}__';
      preserved.add(match.group(0)!);
      return placeholder;
    });
  }

  List<String> _splitWords(String text) {
    // Collapse multiple spaces, split by whitespace and punctuation
    return text
        .trim()
        .split(RegExp(r'[\s\-_]+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  String _toTitleCase(String text) {
    final words = text.split(RegExp(r'\s+'));
    final articles = {'a', 'an', 'the'};
    final prepositions = {
      'of',
      'in',
      'on',
      'at',
      'by',
      'for',
      'with',
      'to',
      'from',
    };
    final conjunctions = {'and', 'but', 'or', 'nor', 'so', 'yet'};

    return words
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final word = entry.value.toLowerCase();

          if (word.length < (settings['min_word_length'] as int)) return word;

          // Always capitalize first and last word
          if (index == 0 || index == words.length - 1) {
            return _capitalizeWord(word);
          }

          // Check exceptions
          if (settings['ignore_articles'] == true && articles.contains(word)) {
            return word;
          }
          if (settings['ignore_prepositions'] == true &&
              prepositions.contains(word)) {
            return word;
          }
          if (settings['ignore_conjunctions'] == true &&
              conjunctions.contains(word)) {
            return word;
          }

          return _capitalizeWord(word);
        })
        .join(' ');
  }

  String _capitalizeWord(String word) {
    if (word.isEmpty) return word;

    if (settings['preserve_acronyms'] == true && word == word.toUpperCase()) {
      return word; // leave acronyms as is
    }

    // Check custom exceptions
    final exceptions = settings['custom_exceptions'].toString().split('\n');
    for (final exception in exceptions) {
      if (exception.trim().toLowerCase() == word.toLowerCase()) {
        return exception.trim();
      }
    }

    return word[0].toUpperCase() + word.substring(1);
  }

  String _toSentenceCase(String text) {
    if (text.isEmpty) return text;

    String lower = text.toLowerCase();
    String result = lower[0].toUpperCase() + lower.substring(1);

    if (settings['smart_capitalization'] == true) {
      result = result.replaceAllMapped(RegExp(r'(\.\s+)([a-z])'), (m) {
        return '${m.group(1)}${m.group(2)!.toUpperCase()}';
      });
    }
    return result;
  }

  String _toCamelCase(String text) {
    final words = text.split(RegExp(r'[^a-zA-Z0-9]+'));
    return words
        .asMap()
        .entries
        .map((entry) {
          final word = entry.value.toLowerCase();
          return entry.key == 0 ? word : _capitalizeWord(word);
        })
        .join('');
  }

  String _toPascalCase(String text) {
    final words = text.split(RegExp(r'[^a-zA-Z0-9]+'));
    return words.map((word) => _capitalizeWord(word.toLowerCase())).join('');
  }

  String _toAlternating(String text) {
    return text
        .split('')
        .asMap()
        .entries
        .map((entry) {
          final char = entry.value;
          return entry.key % 2 == 0 ? char.toLowerCase() : char.toUpperCase();
        })
        .join('');
  }

  String _toRandomCase(String text) {
    final random = DateTime.now().millisecondsSinceEpoch;
    return text
        .split('')
        .asMap()
        .entries
        .map((entry) {
          final char = entry.value;
          return (random + entry.key) % 2 == 0
              ? char.toLowerCase()
              : char.toUpperCase();
        })
        .join('');
  }

  String _applyFormatting(String text) {
    final lines = text.split('\n');
    final processedLines = <String>[];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      if (settings['remove_empty_lines'] == true && line.trim().isEmpty) {
        continue;
      }

      if (line.trim().isNotEmpty) {
        // Add bullet style
        final bulletStyle = settings['bullet_style'].toString();
        switch (bulletStyle) {
          case 'dash':
            line = '- $line';
            break;
          case 'asterisk':
            line = '* $line';
            break;
          case 'bullet':
            line = '• $line';
            break;
          case 'arrow':
            line = '→ $line';
            break;
          case 'check':
            line = '✓ $line';
            break;
        }

        // Add numbering
        if (settings['add_numbering'] == true) {
          line = '${i + 1}. $line';
        }

        // Wrap in quotes
        if (settings['wrap_in_quotes'] == true) {
          line = '"$line"';
        }

        // Add markdown formatting
        if (settings['add_markdown_formatting'] == true) {
          final transformType = settings['transform_type'].toString();
          switch (transformType) {
            case 'uppercase':
            case 'constant_case':
              line = '**$line**';
              break;
            case 'title_case':
              line = '## $line';
              break;
            default:
              line = '*$line*';
          }
        }
      }

      processedLines.add(line);
    }

    final separator = settings['line_separator'].toString();
    return processedLines.join(separator);
  }

  int _countWords(String text) {
    return text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
  }

  String _getTransformDisplayName() {
    final transformType = settings['transform_type'].toString();
    final displayNames = {
      'uppercase': 'UPPERCASE',
      'lowercase': 'lowercase',
      'title_case': 'Title Case',
      'sentence_case': 'Sentence case',
      'camel_case': 'camelCase',
      'pascal_case': 'PascalCase',
      'snake_case': 'snake_case',
      'kebab_case': 'kebab-case',
      'constant_case': 'CONSTANT_CASE',
      'alternating': 'aLtErNaTiNg',
      'reverse': 'esreveR',
      'random_case': 'RaNdOm CaSe',
    };
    return displayNames[transformType] ?? transformType;
  }
}

// Factory function to provide the tool
Map<String, List<Tool Function()>> getTransformTextTools() {
  return {
    'Text Conversion': [() => CaseTransformTool()],
  };
}
