import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:utility_tools/models/tool.dart';

// ==================== CASE TRANSFORMATION TOOLS ====================

/// UPPER CASE
class UpperCaseTool extends Tool {
  UpperCaseTool()
    : super(
        name: 'Upper Case',
        description: 'Convert text to uppercase.',
        icon: Icons.text_fields_outlined,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return ToolResult(output: input.toUpperCase(), status: 'converted');
  }
}

/// lower case
class LowerCaseTool extends Tool {
  LowerCaseTool()
    : super(
        name: 'Lower Case',
        description: 'Convert text to lowercase.',
        icon: Icons.text_fields,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return ToolResult(output: input.toLowerCase(), status: 'converted');
  }
}

/// iNvErT cAsE
class InvertCaseTool extends Tool {
  InvertCaseTool()
    : super(
        name: 'Invert Case',
        description: 'Invert the case of each letter.',
        icon: Icons.swap_vert,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final result = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == char.toUpperCase()) {
        result.write(char.toLowerCase());
      } else {
        result.write(char.toUpperCase());
      }
    }
    return ToolResult(output: result.toString(), status: 'converted');
  }
}

/// camelCase
class CamelCaseTool extends Tool {
  CamelCaseTool()
    : super(
        name: 'Camel Case',
        description: 'Convert text to camelCase.',
        icon: Icons.text_format,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final words = input.split(RegExp(r'\s+'));
    if (words.isEmpty) return ToolResult(output: '', status: 'converted');

    final result = StringBuffer();
    for (int i = 0; i < words.length; i++) {
      final word = words[i].trim();
      if (word.isEmpty) continue;

      if (i == 0) {
        result.write(word.toLowerCase());
      } else {
        result.write(word[0].toUpperCase() + word.substring(1).toLowerCase());
      }
    }

    return ToolResult(output: result.toString(), status: 'converted');
  }
}

/// PascalCase
class PascalCaseTool extends Tool {
  PascalCaseTool()
    : super(
        name: 'Pascal Case',
        description: 'Convert text to PascalCase.',
        icon: Icons.text_format,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final words = input.split(RegExp(r'\s+'));
    if (words.isEmpty) return ToolResult(output: '', status: 'converted');

    final result = StringBuffer();
    for (final word in words) {
      final trimmedWord = word.trim();
      if (trimmedWord.isEmpty) continue;

      result.write(
        trimmedWord[0].toUpperCase() + trimmedWord.substring(1).toLowerCase(),
      );
    }

    return ToolResult(output: result.toString(), status: 'converted');
  }
}

/// snake_case
class SnakeCaseTool extends Tool {
  SnakeCaseTool()
    : super(
        name: 'Snake Case',
        description: 'Convert text to snake_case.',
        icon: Icons.text_format,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final words = input.split(RegExp(r'\s+'));
    if (words.isEmpty) return ToolResult(output: '', status: 'converted');

    final result = StringBuffer();
    for (int i = 0; i < words.length; i++) {
      final word = words[i].trim();
      if (word.isEmpty) continue;

      if (i > 0) result.write('_');
      result.write(word.toLowerCase());
    }

    return ToolResult(output: result.toString(), status: 'converted');
  }
}

/// kebab-case
class KebabCaseTool extends Tool {
  KebabCaseTool()
    : super(
        name: 'Kebab Case',
        description: 'Convert text to kebab-case.',
        icon: Icons.text_format,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final words = input.split(RegExp(r'\s+'));
    if (words.isEmpty) return ToolResult(output: '', status: 'converted');

    final result = StringBuffer();
    for (int i = 0; i < words.length; i++) {
      final word = words[i].trim();
      if (word.isEmpty) continue;

      if (i > 0) result.write('-');
      result.write(word.toLowerCase());
    }

    return ToolResult(output: result.toString(), status: 'converted');
  }
}

// ==================== TEXT MANIPULATION TOOLS ====================

/// Reverse Text (entire text or per line)
class ReverseTextTool extends Tool {
  ReverseTextTool()
    : super(
        name: 'Reverse Text',
        description: 'Reverse the order of characters in text.',
        icon: Icons.rotate_right,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return ToolResult(
      output: input.split('').reversed.join(''),
      status: 'reversed',
    );
  }
}

/// Remove Extra Spaces
class RemoveExtraSpacesTool extends Tool {
  RemoveExtraSpacesTool()
    : super(
        name: 'Remove Extra Spaces',
        description: 'Remove extra spaces between words.',
        icon: Icons.remove_red_eye,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return ToolResult(
      output: input.trim().replaceAll(RegExp(r'\s+'), ' '),
      status: 'cleaned',
    );
  }
}

/// Remove All Spaces
class RemoveAllSpacesTool extends Tool {
  RemoveAllSpacesTool()
    : super(
        name: 'Remove All Spaces',
        description: 'Remove all spaces from text.',
        icon: Icons.remove,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return ToolResult(output: input.replaceAll(' ', ''), status: 'cleaned');
  }
}

/// Trim Whitespace
class TrimWhitespaceTool extends Tool {
  TrimWhitespaceTool()
    : super(
        name: 'Trim Whitespace',
        description: 'Remove leading and trailing whitespace.',
        icon: Icons.border_clear,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return ToolResult(output: input.trim(), status: 'trimmed');
  }
}

/// Remove Line Breaks
class RemoveLineBreaksTool extends Tool {
  RemoveLineBreaksTool()
    : super(
        name: 'Remove Line Breaks',
        description: 'Remove all line breaks from text.',
        icon: Icons.linear_scale,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return ToolResult(
      output: input.replaceAll('\n', ' ').replaceAll('\r', ' '),
      status: 'cleaned',
    );
  }
}

/// Add Line Numbers
class AddLineNumbersTool extends Tool {
  AddLineNumbersTool()
    : super(
        name: 'Add Line Numbers',
        description: 'Add line numbers to each line of text.',
        icon: Icons.format_list_numbered,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final lines = input.split('\n');
    final result = StringBuffer();
    for (int i = 0; i < lines.length; i++) {
      result.write('${i + 1}: ${lines[i]}\n');
    }
    return ToolResult(output: result.toString().trim(), status: 'numbered');
  }
}

// ==================== TEXT ANALYSIS TOOLS ====================

/// Count Characters
class CountCharactersTool extends Tool {
  CountCharactersTool()
    : super(
        name: 'Count Characters',
        description: 'Count characters, words, and lines in text.',
        icon: Icons.calculate,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final charCount = input.length;
    final wordCount = input.trim().isEmpty
        ? 0
        : input.trim().split(RegExp(r'\s+')).length;
    final lineCount = input.isEmpty ? 0 : input.split('\n').length;

    return ToolResult(
      output: 'Characters: $charCount\nWords: $wordCount\nLines: $lineCount',
      status: 'counted',
    );
  }
}

/// Find and Replace
class FindAndReplaceTool extends Tool {
  FindAndReplaceTool()
    : super(
        name: 'Find and Replace',
        description: 'Find and replace text patterns.',
        icon: Icons.find_replace,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    // This tool would typically use settings for find/replace values
    return ToolResult(output: input, status: 'processed');
  }
}

// ==================== ENCODING/FORMATTING TOOLS ====================

/// URL Encode
class UrlEncodeTool extends Tool {
  UrlEncodeTool()
    : super(
        name: 'URL Encode',
        description: 'Encode text for use in URLs.',
        icon: Icons.link,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    // Simple URL encoding implementation
    return ToolResult(output: Uri.encodeComponent(input), status: 'encoded');
  }
}

/// URL Decode
class UrlDecodeTool extends Tool {
  UrlDecodeTool()
    : super(
        name: 'URL Decode',
        description: 'Decode URL-encoded text.',
        icon: Icons.link_off,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    // Simple URL decoding implementation
    return ToolResult(output: Uri.decodeComponent(input), status: 'decoded');
  }
}

/// HTML Encode
class HtmlEncodeTool extends Tool {
  HtmlEncodeTool()
    : super(
        name: 'HTML Encode',
        description: 'Encode HTML special characters.',
        icon: Icons.code,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final result = input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');

    return ToolResult(output: result, status: 'encoded');
  }
}

/// HTML Decode
class HtmlDecodeTool extends Tool {
  HtmlDecodeTool()
    : super(
        name: 'HTML Decode',
        description: 'Decode HTML entities.',
        icon: Icons.code,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final result = input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    return ToolResult(output: result, status: 'decoded');
  }
}

/// Base64 Encode
class Base64EncodeTool extends Tool {
  Base64EncodeTool()
    : super(
        name: 'Base64 Encode',
        description: 'Encode text using Base64.',
        icon: Icons.lock,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final bytes = utf8.encode(input);
    return ToolResult(output: base64Encode(bytes), status: 'encoded');
  }
}

/// Base64 Decode
class Base64DecodeTool extends Tool {
  Base64DecodeTool()
    : super(
        name: 'Base64 Decode',
        description: 'Decode Base64-encoded text.',
        icon: Icons.lock_open,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      final bytes = base64Decode(input);
      return ToolResult(output: utf8.decode(bytes), status: 'decoded');
    } catch (e) {
      return ToolResult(output: 'Error decoding Base64: $e', status: 'error');
    }
  }
}

// ==================== FORMATTING TOOLS ====================

/// Sort Lines
class SortLinesTool extends Tool {
  SortLinesTool()
    : super(
        name: 'Sort Lines',
        description: 'Sort lines alphabetically.',
        icon: Icons.sort,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final lines = input.split('\n');
    lines.sort();
    return ToolResult(output: lines.join('\n'), status: 'sorted');
  }
}

/// Extract Emails
class ExtractEmailsTool extends Tool {
  ExtractEmailsTool()
    : super(
        name: 'Extract Emails',
        description: 'Find and extract email addresses from text.',
        icon: Icons.email,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final RegExp emailRegex = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    );
    final matches = emailRegex.allMatches(input);
    final emails = <String>{};

    for (final match in matches) {
      emails.add(match.group(0)!);
    }

    return ToolResult(output: emails.join('\n'), status: 'extracted');
  }
}

/// Extract URLs
class ExtractUrlsTool extends Tool {
  ExtractUrlsTool()
    : super(
        name: 'Extract URLs',
        description: 'Find and extract URLs from text.',
        icon: Icons.link,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final RegExp urlRegex = RegExp(
      r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+',
    );
    final matches = urlRegex.allMatches(input);
    final urls = <String>{};

    for (final match in matches) {
      urls.add(match.group(0)!);
    }

    return ToolResult(output: urls.join('\n'), status: 'extracted');
  }
}

/// Generate Lorem Ipsum
class LoremIpsumTool extends Tool {
  LoremIpsumTool()
    : super(
        name: 'Lorem Ipsum',
        description: 'Generate Lorem Ipsum placeholder text.',
        icon: Icons.text_snippet,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    // Implementation would generate Lorem Ipsum text based on settings
    return ToolResult(
      output: 'Lorem ipsum dolor sit amet...',
      status: 'generated',
    );
  }
}

// ==================== ADDITIONAL USEFUL TOOLS ====================

/// Word Wrap
class WordWrapTool extends Tool {
  WordWrapTool()
    : super(
        name: 'Word Wrap',
        description: 'Wrap text at specified line length.',
        icon: Icons.format_align_left,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    // Implementation would wrap text based on settings
    return ToolResult(output: input, status: 'wrapped');
  }
}

/// Remove Duplicates
class RemoveDuplicatesTool extends Tool {
  RemoveDuplicatesTool()
    : super(
        name: 'Remove Duplicates',
        description: 'Remove duplicate lines or words.',
        icon: Icons.filter_list,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    // Implementation would remove duplicates based on settings
    return ToolResult(output: input, status: 'cleaned');
  }
}

/// Capitalize Each Word
class CapitalizeEachWordTool extends Tool {
  CapitalizeEachWordTool()
    : super(
        name: 'Capitalize Each Word',
        description: 'Convert each word\'s first letter to uppercase.',
        icon: Icons.text_decrease,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    // Preserve spacing while capitalizing the first non-space char after a boundary
    final result = input.replaceAllMapped(
      RegExp(r'(^|\s)(\S)', multiLine: true),
      (m) => '${m.group(1)!}${m.group(2)!.toUpperCase()}',
    );
    return ToolResult(output: result, status: 'capitalized');
  }
}

/// Sentence Case
class SentenceCaseTool extends Tool {
  SentenceCaseTool()
    : super(
        name: 'Sentence Case',
        description: 'Capitalize the first letter of each sentence.',
        icon: Icons.hiking_rounded,
      );

  @override
  Future<ToolResult> execute(String input) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final lowercaseRest = settings['lowercase_rest'] == true;
    final base = lowercaseRest ? input.toLowerCase() : input;

    final result = base.replaceAllMapped(
      // Start of string OR punctuation + space(s) followed by a letter
      RegExp(r'(^|[.!?]\s+)([a-z])', multiLine: true),
      (m) => '${m.group(1)!}${m.group(2)!.toUpperCase()}',
    );

    return ToolResult(output: result, status: 'converted to sentence case');
  }
}

class SettingsDemoTool extends Tool {
  SettingsDemoTool()
    : super(
        name: 'Settings Demo',
        description: 'Comprehensive demo of all settings types and hints',
        icon: Icons.settings_applications,
        isOutputMarkdown: true,
        settings: {
          // Boolean settings
          'enable_feature': true,
          'debug_mode': false,

          // Text settings
          'username': 'john_doe',
          'api_key': 'sk-1234567890abcdef',
          'description': 'This is a multi-line\ndescription field\nfor testing',

          // Number settings
          'max_items': 100,
          'timeout_seconds': 30.5,
          'quality_level': 75,

          // Dropdown settings
          'theme': 'dark',
          'language': 'en',
          'output_format': 'json',

          // Slider settings
          'volume': 80.0,
          'brightness': 65.0,
          'contrast': 50.0,

          // Spinner settings
          'spinner_count': 5,
          'spinner_decimal': 25.5,
        },
        settingsHints: {
          // Boolean hints - Tests: bool type, labels, help tooltips
          'enable_feature': {
            'type': 'bool',
            'label': 'Enable Advanced Feature',
            'help': 'Toggle the advanced feature on/off [Tests: bool control]',
          },
          'debug_mode': {
            'type': 'bool',
            'label': 'Debug Mode',
            'help':
                'Enable detailed logging for troubleshooting [Tests: bool control]',
          },

          // Text hints - Tests: text type, placeholders, obscured input, custom width
          'username': {
            'type': 'text',
            'label': 'Username',
            'help': 'Your account username [Tests: text control, placeholder]',
            'placeholder': 'Enter username...',
          },
          'api_key': {
            'type': 'text',
            'label': 'API Key',
            'help': 'Your secret API key [Tests: obscured text, custom width]',
            'placeholder': 'Enter API key...',
            'obscure': true,
            'width': 350, // Custom width test
          },
          'description': {
            'type': 'multiline',
            'label': 'Description',
            'help':
                'Detailed description [Tests: multiline, min/max lines, custom size]',
            'placeholder': 'Enter detailed description...',
            'min_lines': 3,
            'max_lines': 6,
            'width': 400, // Custom width test
            'height': 120, // Custom height test
          },

          // Number hints - Tests: number type, min/max, decimal support
          'max_items': {
            'type': 'number',
            'label': 'Max Items',
            'help':
                'Maximum items to process [Tests: integer number, min/max validation]',
            'min': 1,
            'max': 1000,
          },
          'timeout_seconds': {
            'type': 'number',
            'label': 'Timeout (seconds)',
            'help': 'Connection timeout [Tests: decimal number, validation]',
            'min': 0.1,
            'max': 300.0,
            'decimal': true,
          },
          'quality_level': {
            'type': 'number',
            'label': 'Quality Level',
            'help':
                'Image quality percentage [Tests: integer number with range]',
            'min': 0,
            'max': 100,
            'width': 150, // Custom width test
          },

          // Dropdown hints - Tests: dropdown type, option formats
          'theme': {
            'type': 'dropdown',
            'label': 'Theme',
            'help': 'Application theme [Tests: dropdown with labeled options]',
            'options': [
              {'value': 'light', 'label': 'Light Theme'},
              {'value': 'dark', 'label': 'Dark Theme'},
              {'value': 'auto', 'label': 'Auto (System)'},
            ],
          },
          'language': {
            'type': 'dropdown',
            'label': 'Language',
            'help': 'Interface language [Tests: simple string options]',
            'options': ['en', 'es', 'fr', 'de', 'ja'],
          },
          'output_format': {
            'type': 'dropdown',
            'label': 'Output Format',
            'help': 'Data output format [Tests: dropdown with custom width]',
            'options': ['json', 'xml', 'csv', 'yaml'],
            'width': 180, // Custom width test
          },

          // Slider hints - Tests: slider type, various display options
          'volume': {
            'type': 'slider',
            'label': 'Volume',
            'help': 'Audio volume level [Tests: slider with value display]',
            'min': 0.0,
            'max': 100.0,
            'divisions': 100,
            'show_value': true,
          },
          'brightness': {
            'type': 'slider',
            'label': 'Brightness',
            'help': 'Display brightness [Tests: slider with divisions]',
            'min': 0.0,
            'max': 100.0,
            'divisions': 50,
            'show_value': true,
            'width': 300, // Custom width test
          },
          'contrast': {
            'type': 'slider',
            'label': 'Contrast',
            'help': 'Display contrast level [Tests: slider with range display]',
            'min': 0.0,
            'max': 100.0,
            'show_range': true,
          },

          // Spinner hints - Tests: spinner type, step values, decimal support
          'spinner_count': {
            'type': 'spinner',
            'label': 'Item Count',
            'help': 'Number of items [Tests: spinner control, integer steps]',
            'min': 0,
            'max': 100,
            'step': 1,
          },
          'spinner_decimal': {
            'type': 'spinner',
            'label': 'Decimal Value',
            'help':
                'Decimal value with spinner [Tests: decimal spinner, custom step]',
            'min': 0.0,
            'max': 100.0,
            'step': 0.5,
            'decimal': true,
            'decimals': 1,
            'width': 200, // Custom width test
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    final buffer = StringBuffer();

    buffer.writeln('# Settings Demo Results\n');

    // Boolean settings
    buffer.writeln('## Boolean Settings');
    buffer.writeln('- Enable Feature: ${settings['enable_feature']}');
    buffer.writeln('- Debug Mode: ${settings['debug_mode']}\n');

    // Text settings
    buffer.writeln('## Text Settings');
    buffer.writeln('- Username: "${settings['username']}"');
    buffer.writeln('- API Key: "${settings['api_key']}"');
    buffer.writeln(
      '- Description: "${settings['description'].toString().replaceAll('\n', ' ')}"\n',
    );

    // Number settings
    buffer.writeln('## Number Settings');
    buffer.writeln('- Max Items: ${settings['max_items']}');
    buffer.writeln('- Timeout: ${settings['timeout_seconds']} seconds');
    buffer.writeln('- Quality: ${settings['quality_level']}\n');

    // Dropdown settings
    buffer.writeln('## Dropdown Settings');
    buffer.writeln('- Theme: ${settings['theme']}');
    buffer.writeln('- Language: ${settings['language']}');
    buffer.writeln('- Output Format: ${settings['output_format']}\n');

    // Slider settings
    buffer.writeln('## Slider Settings');
    buffer.writeln('- Volume: ${settings['volume']}%');
    buffer.writeln('- Brightness: ${settings['brightness']}%');
    buffer.writeln('- Contrast: ${settings['contrast']}%\n');

    // Spinner settings
    buffer.writeln('## Spinner Settings');
    buffer.writeln('- Item Count: ${settings['spinner_count']}');
    buffer.writeln('- Decimal Value: ${settings['spinner_decimal']}\n');

    buffer.writeln('---\n');
    buffer.writeln('**Input:** "$input"');

    return ToolResult(output: buffer.toString(), status: 'success');
  }

  @override
  Future<String> executeGetText(String input) async {
    // Custom plain text output only override if tool needs to output custom text
    // as markdown is auto converted to plain if not overriden
    final buffer = StringBuffer();

    buffer.writeln('SETTINGS DEMO RESULTS');
    buffer.writeln('=' * 30);

    buffer.writeln('Boolean:');
    buffer.writeln('  Enable Feature: ${settings['enable_feature']}');
    buffer.writeln('  Debug Mode: ${settings['debug_mode']}');

    buffer.writeln('\nText:');
    buffer.writeln('  Username: ${settings['username']}');
    buffer.writeln('  API Key: ${settings['api_key']}');
    buffer.writeln(
      '  Description: ${settings['description'].toString().replaceAll('\n', ' ')}',
    );

    buffer.writeln('\nNumbers:');
    buffer.writeln('  Max Items: ${settings['max_items']}');
    buffer.writeln('  Timeout: ${settings['timeout_seconds']}s');
    buffer.writeln('  Quality: ${settings['quality_level']}');

    buffer.writeln('\nDropdowns:');
    buffer.writeln('  Theme: ${settings['theme']}');
    buffer.writeln('  Language: ${settings['language']}');
    buffer.writeln('  Format: ${settings['output_format']}');

    buffer.writeln('\nSliders:');
    buffer.writeln('  Volume: ${settings['volume']}%');
    buffer.writeln('  Brightness: ${settings['brightness']}%');
    buffer.writeln('  Contrast: ${settings['contrast']}%');

    buffer.writeln('\nSpinners:');
    buffer.writeln('  Count: ${settings['spinner_count']}');
    buffer.writeln('  Decimal: ${settings['spinner_decimal']}');

    buffer.writeln('\nInput: "$input"');

    return buffer.toString();
  }
}

Map<String, List<Tool Function()>> getTextToolCategories() {
  return {
    'Text Manipulation': [
      () => ReverseTextTool(),
      () => RemoveExtraSpacesTool(),
      () => RemoveAllSpacesTool(),
      () => TrimWhitespaceTool(),
      () => RemoveLineBreaksTool(),
      () => AddLineNumbersTool(),
      () => WordWrapTool(),
      () => RemoveDuplicatesTool(),
    ],
    'Text Analysis': [() => CountCharactersTool(), () => FindAndReplaceTool()],
    'Encoding/Decoding': [
      () => UrlEncodeTool(),
      () => UrlDecodeTool(),
      () => HtmlEncodeTool(),
      () => HtmlDecodeTool(),
      () => Base64EncodeTool(),
      () => Base64DecodeTool(),
    ],
    'Formatting': [() => SortLinesTool()],
    'Extraction': [() => ExtractEmailsTool(), () => ExtractUrlsTool()],
    'Generators': [() => LoremIpsumTool()],
    'Other': [() => SettingsDemoTool()],
  };
}
