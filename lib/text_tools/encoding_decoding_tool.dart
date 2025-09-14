import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:utility_tools/models/tool.dart';
import 'package:crypto/crypto.dart';

class EncodingHubTool extends Tool {
  EncodingHubTool()
    : super(
        name: 'Encoding Hub',
        description:
            'Unified encode/decode/transform for URL, HTML entities, Base64, Hex, Binary, Octal, Decimal, Morse, ROT13/47, Slashes, Slugify',
        icon: Icons.code,
        isOutputMarkdown: false,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'operation': 'encode',
          'codec': 'url',
          'output_format': 'text',
          'ignore_invalid': true,
          'separator': 'space',
          'case_format': 'auto',
          'show_statistics': false,
        },
        settingsHints: {
          'operation': {
            'type': 'dropdown',
            'label': 'Operation',
            'help': 'Choose to encode or decode the input',
            'options': [
              {'value': 'encode', 'label': 'Encode'},
              {'value': 'decode', 'label': 'Decode'},
            ],
          },
          'codec': {
            'type': 'dropdown',
            'label': 'Codec',
            'help': 'Choose the encoding/decoding method',
            'options': [
              {'value': 'url', 'label': 'URL Encoding'},
              {'value': 'html', 'label': 'HTML Entities'},
              {'value': 'base64', 'label': 'Base64'},
              {'value': 'hex', 'label': 'Hexadecimal'},
              {'value': 'binary', 'label': 'Binary'},
              {'value': 'octal', 'label': 'Octal'},
              {'value': 'decimal', 'label': 'Decimal (ASCII)'},
              {'value': 'morse', 'label': 'Morse Code'},
              {'value': 'rot13', 'label': 'ROT13'},
              {'value': 'rot47', 'label': 'ROT47'},
              {'value': 'slash', 'label': 'Slash Escaping'},
              {'value': 'slug', 'label': 'URL Slug'},
              {'value': 'unicode', 'label': 'Unicode Escape'},
              {'value': 'jwt', 'label': 'JWT'}, // Remove "(decode only)"
            ],
          },
          'output_format': {
            'type': 'dropdown',
            'label': 'Output Format',
            'help': 'Format the final output',
            'options': [
              {'value': 'text', 'label': 'Plain Text'},
              {'value': 'hex', 'label': 'Hexadecimal'},
              {'value': 'base64', 'label': 'Base64'},
              {'value': 'json', 'label': 'JSON'},
            ],
          },
          'separator': {
            'type': 'dropdown',
            'label': 'Separator',
            'help': 'Separator for multi-byte encodings',
            'options': [
              {'value': 'space', 'label': 'Space'},
              {'value': 'comma', 'label': 'Comma'},
              {'value': 'none', 'label': 'None'},
            ],
          },
          'case_format': {
            'type': 'dropdown',
            'label': 'Case Format',
            'help': 'Case formatting for hex output',
            'options': [
              {'value': 'auto', 'label': 'Auto'},
              {'value': 'upper', 'label': 'UPPERCASE'},
              {'value': 'lower', 'label': 'lowercase'},
            ],
          },
          'ignore_invalid': {
            'type': 'bool',
            'label': 'Ignore Invalid Characters',
            'help': 'Skip invalid characters instead of throwing errors',
          },
          'show_statistics': {
            'type': 'bool',
            'label': 'Show Statistics',
            'help': 'Display encoding statistics and metadata',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    final operation = settings['operation'] as String;
    final codec = settings['codec'] as String;
    final outputFormat = settings['output_format'] as String;
    final ignoreInvalid = settings['ignore_invalid'] as bool;
    final separator = settings['separator'] as String;
    final caseFormat = settings['case_format'] as String;
    final showStats = settings['show_statistics'] as bool;

    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success');
    }

    try {
      String result;
      Map<String, dynamic> stats = {};

      switch (codec) {
        case 'url':
          result = operation == 'encode'
              ? _urlEncode(input, ignoreInvalid)
              : _urlDecode(input, ignoreInvalid);
          stats = _getBasicStats(input, result);
          break;

        case 'html':
          result = operation == 'encode'
              ? _htmlEncode(input)
              : _htmlDecode(input, ignoreInvalid);
          stats = _getBasicStats(input, result);
          break;

        case 'base64':
          result = operation == 'encode'
              ? _base64Encode(input)
              : _base64Decode(input, ignoreInvalid);
          stats = _getBase64Stats(input, result, operation);
          break;

        case 'hex':
          result = operation == 'encode'
              ? _hexEncode(input, separator, caseFormat)
              : _hexDecode(input, separator, ignoreInvalid);
          stats = _getHexStats(input, result, operation);
          break;

        case 'binary':
          result = operation == 'encode'
              ? _binaryEncode(input, separator)
              : _binaryDecode(input, separator, ignoreInvalid);
          stats = _getBinaryStats(input, result, operation);
          break;

        case 'octal':
          result = operation == 'encode'
              ? _octalEncode(input, separator)
              : _octalDecode(input, separator, ignoreInvalid);
          stats = _getBasicStats(input, result);
          break;

        case 'decimal':
          result = operation == 'encode'
              ? _decimalEncode(input, separator)
              : _decimalDecode(input, separator, ignoreInvalid);
          stats = _getBasicStats(input, result);
          break;

        case 'morse':
          result = operation == 'encode'
              ? _morseEncode(input, ignoreInvalid)
              : _morseDecode(input, ignoreInvalid);
          stats = _getMorseStats(input, result, operation);
          break;

        case 'rot13':
          result = _rot13(input);
          stats = _getBasicStats(input, result);
          break;

        case 'rot47':
          result = _rot47(input);
          stats = _getBasicStats(input, result);
          break;

        case 'slash':
          result = operation == 'encode'
              ? _slashEncode(input)
              : _slashDecode(input, ignoreInvalid);
          stats = _getBasicStats(input, result);
          break;

        case 'slug':
          result = operation == 'encode' ? _slugify(input) : _deslugify(input);
          stats = _getBasicStats(input, result);
          break;

        case 'unicode':
          result = operation == 'encode'
              ? _unicodeEncode(input)
              : _unicodeDecode(input, ignoreInvalid);
          stats = _getBasicStats(input, result);
          break;

        case 'jwt':
          result = operation == 'encode'
              ? _jwtEncode(input)
              : _jwtDecode(input, ignoreInvalid);
          stats = _getJwtStats(result, input);
          break;

        default:
          return ToolResult(
            output: 'Unsupported codec: $codec',
            status: 'error',
          );
      }

      // Apply output format transformation
      result = _applyOutputFormat(result, outputFormat, codec);

      // Add statistics if requested
      if (showStats && stats.isNotEmpty) {
        final statsText = _formatStats(stats);
        result = '$result\n\n--- Statistics ---\n$statsText';
      }

      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(
        output: ignoreInvalid ? input : 'Error: ${e.toString()}',
        status: ignoreInvalid ? 'warning' : 'error',
      );
    }
  }

  // Enhanced URL encoding with better error handling
  String _urlEncode(String input, bool ignoreInvalid) {
    try {
      return Uri.encodeComponent(input);
    } catch (e) {
      if (ignoreInvalid) {
        return input.runes.map((r) {
          try {
            return Uri.encodeComponent(String.fromCharCode(r));
          } catch (_) {
            return String.fromCharCode(r);
          }
        }).join();
      }
      rethrow;
    }
  }

  String _urlDecode(String input, bool ignoreInvalid) {
    try {
      return Uri.decodeComponent(input);
    } catch (e) {
      if (ignoreInvalid) {
        // Try to decode parts that are valid
        return input.replaceAllMapped(RegExp(r'%[0-9A-Fa-f]{2}'), (match) {
          try {
            return Uri.decodeComponent(match.group(0)!);
          } catch (_) {
            return match.group(0)!;
          }
        });
      }
      rethrow;
    }
  }

  // Enhanced HTML encoding with more entities
  String _htmlEncode(String input) {
    const entities = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;',
      ' ': '&nbsp;',
      '©': '&copy;',
      '®': '&reg;',
      '™': '&trade;',
    };

    String result = input;
    for (final entry in entities.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  String _htmlDecode(String input, bool ignoreInvalid) {
    const entities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
      '&nbsp;': ' ',
      '&copy;': '©',
      '&reg;': '®',
      '&trade;': '™',
    };

    String result = input;

    // Decode named entities
    for (final entry in entities.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    // Decode numeric entities &#123; and &#x7B;
    result = result.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      try {
        final code = int.parse(match.group(1)!);
        return String.fromCharCode(code);
      } catch (e) {
        return ignoreInvalid ? match.group(0)! : throw e;
      }
    });

    result = result.replaceAllMapped(RegExp(r'&#x([0-9A-Fa-f]+);'), (match) {
      try {
        final code = int.parse(match.group(1)!, radix: 16);
        return String.fromCharCode(code);
      } catch (e) {
        return ignoreInvalid ? match.group(0)! : throw e;
      }
    });

    return result;
  }

  // Base64 with padding validation
  String _base64Encode(String input) {
    return base64Encode(utf8.encode(input));
  }

  String _base64Decode(String input, bool ignoreInvalid) {
    try {
      // Clean input
      String cleaned = input.replaceAll(RegExp(r'\s'), '');

      // Add padding if needed
      while (cleaned.length % 4 != 0) {
        cleaned += '=';
      }

      return utf8.decode(base64Decode(cleaned));
    } catch (e) {
      if (ignoreInvalid) return input;
      rethrow;
    }
  }

  // Enhanced hex with configurable separator and case
  String _hexEncode(String input, String separator, String caseFormat) {
    final sep = _getSeparator(separator);
    String hex = input.runes
        .map((r) => r.toRadixString(16).padLeft(2, '0'))
        .join(sep);

    return _applyCase(hex, caseFormat);
  }

  String _hexDecode(String input, String separator, bool ignoreInvalid) {
    try {
      String cleaned = input.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');

      if (cleaned.length % 2 != 0) {
        if (ignoreInvalid) {
          cleaned = cleaned.substring(0, cleaned.length - 1);
        } else {
          throw FormatException('Invalid hex length');
        }
      }

      final hexBytes = <int>[];
      for (int i = 0; i < cleaned.length; i += 2) {
        hexBytes.add(int.parse(cleaned.substring(i, i + 2), radix: 16));
      }

      return utf8.decode(hexBytes);
    } catch (e) {
      if (ignoreInvalid) return input;
      rethrow;
    }
  }

  // Enhanced binary with configurable separator
  String _binaryEncode(String input, String separator) {
    final sep = _getSeparator(separator);
    return input.runes.map((r) => r.toRadixString(2).padLeft(8, '0')).join(sep);
  }

  String _binaryDecode(String input, String separator, bool ignoreInvalid) {
    try {
      String cleaned = input.replaceAll(RegExp(r'[^01]'), '');

      // Pad to multiple of 8
      while (cleaned.length % 8 != 0) {
        cleaned = '0$cleaned';
      }

      final bytes = <int>[];
      for (int i = 0; i < cleaned.length; i += 8) {
        bytes.add(int.parse(cleaned.substring(i, i + 8), radix: 2));
      }

      return utf8.decode(bytes);
    } catch (e) {
      if (ignoreInvalid) return input;
      rethrow;
    }
  }

  // Octal encoding with separator support
  String _octalEncode(String input, String separator) {
    final sep = _getSeparator(separator);
    return input.runes.map((r) => r.toRadixString(8).padLeft(3, '0')).join(sep);
  }

  String _octalDecode(String input, String separator, bool ignoreInvalid) {
    try {
      String cleaned = input.replaceAll(RegExp(r'[^0-7]'), '');

      // Group into 3s
      final groups = <String>[];
      for (int i = 0; i < cleaned.length; i += 3) {
        final end = math.min(i + 3, cleaned.length);
        groups.add(cleaned.substring(i, end).padLeft(3, '0'));
      }

      final bytes = groups.map((g) => int.parse(g, radix: 8)).toList();
      return utf8.decode(bytes);
    } catch (e) {
      if (ignoreInvalid) return input;
      rethrow;
    }
  }

  // Decimal ASCII encoding
  String _decimalEncode(String input, String separator) {
    final sep = _getSeparator(separator);
    return input.runes.map((r) => r.toString()).join(sep);
  }

  String _decimalDecode(String input, String separator, bool ignoreInvalid) {
    try {
      final numbers = input
          .split(RegExp(r'[^0-9]+'))
          .where((s) => s.isNotEmpty)
          .map((s) => int.parse(s))
          .toList();

      return utf8.decode(numbers);
    } catch (e) {
      if (ignoreInvalid) return input;
      rethrow;
    }
  }

  // Enhanced Morse code with punctuation support
  static const Map<String, String> _morseEncodeMap = {
    'A': '.-',
    'B': '-...',
    'C': '-.-.',
    'D': '-..',
    'E': '.',
    'F': '..-.',
    'G': '--.',
    'H': '....',
    'I': '..',
    'J': '.---',
    'K': '-.-',
    'L': '.-..',
    'M': '--',
    'N': '-.',
    'O': '---',
    'P': '.--.',
    'Q': '--.-',
    'R': '.-.',
    'S': '...',
    'T': '-',
    'U': '..-',
    'V': '...-',
    'W': '.--',
    'X': '-..-',
    'Y': '-.--',
    'Z': '--..',
    '0': '-----',
    '1': '.----',
    '2': '..---',
    '3': '...--',
    '4': '....-',
    '5': '.....',
    '6': '-....',
    '7': '--...',
    '8': '---..',
    '9': '----.',
    ' ': '/',
    '.': '.-.-.-',
    ',': '--..--',
    '?': '..--..',
    "'": '.----.',
    '!': '-.-.--',
    '/': '-..-.',
    '(': '-.--.',
    ')': '-.--.-',
    '&': '.-...',
    ':': '---...',
    ';': '-.-.-.',
    '=': '-...-',
    '+': '.-.-.',
    '-': '-....-',
    '_': '..--.-',
    '"': '.-..-.',
    '\$': '...-..-',
    '@': '.--.-.',
  };

  static final Map<String, String> _morseDecodeMap = {
    for (final entry in _morseEncodeMap.entries) entry.value: entry.key,
  };

  String _morseEncode(String input, bool ignoreInvalid) {
    return input
        .toUpperCase()
        .runes
        .map((r) {
          final char = String.fromCharCode(r);
          final morse = _morseEncodeMap[char];
          if (morse == null && !ignoreInvalid) {
            throw FormatException('Unsupported character: $char');
          }
          return morse ?? (ignoreInvalid ? char : '');
        })
        .where((s) => s.isNotEmpty)
        .join(' ');
  }

  String _morseDecode(String input, bool ignoreInvalid) {
    return input
        .split(' ')
        .map((code) {
          final char = _morseDecodeMap[code];
          if (char == null && !ignoreInvalid) {
            throw FormatException('Invalid morse code: $code');
          }
          return char ?? (ignoreInvalid ? code : '');
        })
        .join('');
  }

  // ROT13 - letters only
  String _rot13(String input) {
    return input.runes.map((r) {
      if (r >= 65 && r <= 90) {
        // A-Z
        return String.fromCharCode(((r - 65 + 13) % 26) + 65);
      } else if (r >= 97 && r <= 122) {
        // a-z
        return String.fromCharCode(((r - 97 + 13) % 26) + 97);
      }
      return String.fromCharCode(r);
    }).join();
  }

  // ROT47 - ASCII printable characters
  String _rot47(String input) {
    return input.runes.map((r) {
      if (r >= 33 && r <= 126) {
        return String.fromCharCode(((r - 33 + 47) % 94) + 33);
      }
      return String.fromCharCode(r);
    }).join();
  }

  // Enhanced slash encoding
  String _slashEncode(String input) {
    const escapes = {
      '\\': '\\\\',
      '/': '\\/',
      '"': '\\"',
      '\n': '\\n',
      '\r': '\\r',
      '\t': '\\t',
      '\b': '\\b',
      '\f': '\\f',
    };

    String result = input;
    for (final entry in escapes.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  String _slashDecode(String input, bool ignoreInvalid) {
    const escapes = {
      '\\\\': '\\',
      '\\/': '/',
      '\\"': '"',
      '\\n': '\n',
      '\\r': '\r',
      '\\t': '\t',
      '\\b': '\b',
      '\\f': '\f',
    };

    String result = input;
    for (final entry in escapes.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  // Enhanced slugify
  String _slugify(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâäæãåā]'), 'a')
        .replaceAll(RegExp(r'[çćč]'), 'c')
        .replaceAll(RegExp(r'[èéêëēėę]'), 'e')
        .replaceAll(RegExp(r'[îïíīįì]'), 'i')
        .replaceAll(RegExp(r'[ôöòóœøōõ]'), 'o')
        .replaceAll(RegExp(r'[ûüùúū]'), 'u')
        .replaceAll(RegExp(r'[ÿỳýū]'), 'y')
        .replaceAll(RegExp(r'[ñń]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'[\s_-]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  String _deslugify(String input) {
    return input.replaceAll(RegExp(r'[-_]+'), ' ').trim();
  }

  // Unicode escape sequences
  String _unicodeEncode(String input) {
    return input.runes
        .map(
          (r) => r > 127
              ? '\\u${r.toRadixString(16).padLeft(4, '0')}'
              : String.fromCharCode(r),
        )
        .join();
  }

  String _unicodeDecode(String input, bool ignoreInvalid) {
    return input.replaceAllMapped(RegExp(r'\\u([0-9A-Fa-f]{4})'), (match) {
      try {
        final code = int.parse(match.group(1)!, radix: 16);
        return String.fromCharCode(code);
      } catch (e) {
        return ignoreInvalid ? match.group(0)! : throw e;
      }
    });
  }

  // JWT decoder (header and payload only)
  String _jwtDecode(String input, bool ignoreInvalid) {
    try {
      final parts = input.split('.');
      if (parts.length != 3) {
        throw FormatException('Invalid JWT format');
      }

      final header = _base64Decode(parts[0], ignoreInvalid);
      final payload = _base64Decode(parts[1], ignoreInvalid);

      return 'Header:\n$header\n\nPayload:\n$payload';
    } catch (e) {
      if (ignoreInvalid) return input;
      rethrow;
    }
  }

  String _jwtEncode(String input) {
    try {
      // Parse input as JSON
      final payload = jsonDecode(input);
      final header = {'alg': 'HS256', 'typ': 'JWT'};

      // Encode header and payload
      final headerBase64 = base64UrlEncode(
        utf8.encode(jsonEncode(header)),
      ).replaceAll('=', '');
      final payloadBase64 = base64UrlEncode(
        utf8.encode(jsonEncode(payload)),
      ).replaceAll('=', '');

      // Create signature
      final secret = settings['jwt_secret'] as String;
      final message = '$headerBase64.$payloadBase64';
      final hmac = Hmac(sha256, utf8.encode(secret));
      final signature = hmac.convert(utf8.encode(message));
      final signatureBase64 = base64UrlEncode(
        signature.bytes,
      ).replaceAll('=', '');

      return '$headerBase64.$payloadBase64.$signatureBase64';
    } catch (e) {
      throw FormatException('Invalid JSON payload: ${e.toString()}');
    }
  }

  // Helper methods
  String _getSeparator(String separator) {
    switch (separator) {
      case 'space':
        return ' ';
      case 'comma':
        return ',';
      case 'none':
        return '';
      default:
        return ' ';
    }
  }

  String _applyCase(String input, String caseFormat) {
    switch (caseFormat) {
      case 'upper':
        return input.toUpperCase();
      case 'lower':
        return input.toLowerCase();
      default:
        return input;
    }
  }

  String _applyOutputFormat(String result, String format, String codec) {
    if (format == codec) return result;

    switch (format) {
      case 'hex':
        return result.runes
            .map((r) => r.toRadixString(16).padLeft(2, '0'))
            .join(' ');
      case 'base64':
        return base64Encode(utf8.encode(result));
      case 'json':
        return '{"result": ${jsonEncode(result)}}';
      default:
        return result;
    }
  }

  // Statistics methods
  Map<String, dynamic> _getBasicStats(String input, String output) {
    return {
      'input_length': input.length,
      'output_length': output.length,
      'size_change':
          '${((output.length - input.length) / input.length * 100).toStringAsFixed(1)}%',
    };
  }

  Map<String, dynamic> _getBase64Stats(
    String input,
    String output,
    String operation,
  ) {
    final basic = _getBasicStats(input, output);
    if (operation == 'encode') {
      basic['padding'] = output.endsWith('==')
          ? 2
          : output.endsWith('=')
          ? 1
          : 0;
    }
    return basic;
  }

  Map<String, dynamic> _getHexStats(
    String input,
    String output,
    String operation,
  ) {
    final basic = _getBasicStats(input, output);
    if (operation == 'encode') {
      basic['hex_bytes'] = input.length;
      basic['hex_chars'] = output.length;
    }
    return basic;
  }

  Map<String, dynamic> _getBinaryStats(
    String input,
    String output,
    String operation,
  ) {
    final basic = _getBasicStats(input, output);
    if (operation == 'encode') {
      basic['bits'] = input.length * 8;
    }
    return basic;
  }

  Map<String, dynamic> _getMorseStats(
    String input,
    String output,
    String operation,
  ) {
    final basic = _getBasicStats(input, output);
    if (operation == 'encode') {
      basic['morse_groups'] = output.split(' ').length;
    }
    return basic;
  }

  Map<String, dynamic> _getJwtStats(String input, String output) {
    final parts = input.split('.');
    return {
      'jwt_parts': parts.length,
      'header_length': parts.isNotEmpty ? parts[0].length : 0,
      'payload_length': parts.length > 1 ? parts[1].length : 0,
      'signature_length': parts.length > 2 ? parts[2].length : 0,
    };
  }

  String _formatStats(Map<String, dynamic> stats) {
    return stats.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }
}

Map<String, List<Tool Function()>> getEncodingDecodingTools() {
  return {
    'Coding': [() => EncodingHubTool()],
  };
}
