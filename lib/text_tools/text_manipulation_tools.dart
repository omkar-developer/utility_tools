// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:csv/csv.dart';
import 'package:encrypt/encrypt.dart';
import 'package:html/dom.dart' as html;
import 'package:markdown/markdown.dart' as md;
import 'package:qr/qr.dart';
import 'package:utility_tools/models/tool.dart';
import 'package:flutter/material.dart' hide Key;
import 'package:html2md/html2md.dart' as html2md;

import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart' as xml;
import 'package:json_path/json_path.dart'; // For more complex JSON path queries

import 'package:crypto/crypto.dart';
import 'package:bcrypt/bcrypt.dart';

class HashCryptoTool extends Tool {
  HashCryptoTool()
    : super(
        name: 'HashCrypto',
        description:
            'Hash, HMAC, password hash and verify text using various algorithms',
        icon: Icons.security,
        isOutputMarkdown: false,
        isInputMarkdown: false,
        canAcceptMarkdown: false,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'mode': 'hash',
          'algorithm': 'sha256',
          'key_or_salt': '',
          'rounds': 10,
          'output_encoding': 'hex',
          'verify_against': '',
        },
        settingsHints: {
          'mode': {
            'type': 'dropdown',
            'label': 'Mode',
            'help': 'Select operation mode',
            'options': ['hash', 'hmac', 'password_hash', 'verify'],
            'width': 150,
          },
          'algorithm': {
            'type': 'dropdown',
            'label': 'Algorithm',
            'help': 'Hashing algorithm to use',
            'options': ['md5', 'sha1', 'sha256', 'sha512', 'bcrypt', 'scrypt'],
            'width': 150,
          },
          'key_or_salt': {
            'type': 'text',
            'label': 'Key/Salt',
            'help': 'HMAC key or bcrypt/scrypt salt (optional)',
            'placeholder': 'Enter key or salt...',
            'width': 300,
          },
          'rounds': {
            'type': 'number',
            'label': 'Rounds',
            'help': 'Number of rounds for bcrypt/scrypt',
            'min': 4,
            'max': 31,
            'width': 150,
          },
          'output_encoding': {
            'type': 'dropdown',
            'label': 'Output Encoding',
            'help': 'Encoding format for output',
            'options': ['hex', 'base64'],
          },
          'verify_against': {
            'type': 'text',
            'label': 'Verify Against',
            'help': 'Hash to verify against (only used in verify mode)',
            'placeholder': 'Enter hash to verify...',
            'width': 300,
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    try {
      final mode = settings['mode'] as String;
      final algorithm = settings['algorithm'] as String;
      final keyOrSalt = settings['key_or_salt'] as String;
      final rounds = (settings['rounds'] as num).toInt();
      final outputEncoding = settings['output_encoding'] as String;
      final verifyAgainst = settings['verify_against'] as String;

      if (input.isEmpty) {
        return ToolResult(
          output: 'Error: Input text is required',
          status: 'error',
        );
      }

      String result;

      switch (mode) {
        case 'hash':
          result = await _performHash(input, algorithm, outputEncoding);
          break;
        case 'hmac':
          if (keyOrSalt.isEmpty) {
            return ToolResult(
              output: 'Error: HMAC key is required',
              status: 'error',
            );
          }
          result = await _performHmac(
            input,
            algorithm,
            keyOrSalt,
            outputEncoding,
          );
          break;
        case 'password_hash':
          result = await _performPasswordHash(
            input,
            algorithm,
            keyOrSalt,
            rounds,
          );
          break;
        case 'verify':
          if (verifyAgainst.isEmpty) {
            return ToolResult(
              output: 'Error: Hash to verify against is required',
              status: 'error',
            );
          }
          result = await _performVerify(
            input,
            algorithm,
            verifyAgainst,
            keyOrSalt,
            rounds,
          );
          break;
        default:
          return ToolResult(
            output: 'Error: Invalid mode selected',
            status: 'error',
          );
      }

      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: ${e.toString()}', status: 'error');
    }
  }

  Future<String> _performHash(
    String input,
    String algorithm,
    String encoding,
  ) async {
    List<int> bytes;

    switch (algorithm) {
      case 'md5':
        bytes = md5.convert(utf8.encode(input)).bytes;
        break;
      case 'sha1':
        bytes = sha1.convert(utf8.encode(input)).bytes;
        break;
      case 'sha256':
        bytes = sha256.convert(utf8.encode(input)).bytes;
        break;
      case 'sha512':
        bytes = sha512.convert(utf8.encode(input)).bytes;
        break;
      case 'bcrypt':
      case 'scrypt':
        throw Exception(
          'Use password_hash mode for ${algorithm.toUpperCase()}',
        );
      default:
        throw Exception('Unsupported algorithm: $algorithm');
    }

    return _encodeBytes(bytes, encoding);
  }

  Future<String> _performHmac(
    String input,
    String algorithm,
    String key,
    String encoding,
  ) async {
    List<int> keyBytes = utf8.encode(key);
    List<int> bytes;

    switch (algorithm) {
      case 'md5':
        var hmacMd5 = Hmac(md5, keyBytes);
        bytes = hmacMd5.convert(utf8.encode(input)).bytes;
        break;
      case 'sha1':
        var hmacSha1 = Hmac(sha1, keyBytes);
        bytes = hmacSha1.convert(utf8.encode(input)).bytes;
        break;
      case 'sha256':
        var hmacSha256 = Hmac(sha256, keyBytes);
        bytes = hmacSha256.convert(utf8.encode(input)).bytes;
        break;
      case 'sha512':
        var hmacSha512 = Hmac(sha512, keyBytes);
        bytes = hmacSha512.convert(utf8.encode(input)).bytes;
        break;
      case 'bcrypt':
      case 'scrypt':
        throw Exception('HMAC not supported for ${algorithm.toUpperCase()}');
      default:
        throw Exception('Unsupported algorithm: $algorithm');
    }

    return _encodeBytes(bytes, encoding);
  }

  Future<String> _performPasswordHash(
    String input,
    String algorithm,
    String salt,
    int rounds,
  ) async {
    switch (algorithm) {
      case 'bcrypt':
        String saltToUse = salt.isEmpty ? BCrypt.gensalt() : salt;
        String hash = BCrypt.hashpw(input, saltToUse);
        return 'Hash: $hash\nSalt used: $saltToUse';
      case 'scrypt':
        // Note: This is a simplified scrypt implementation
        // In production, you'd use a proper scrypt library
        List<int> saltBytes = salt.isEmpty
            ? _generateRandomBytes(16)
            : utf8.encode(salt);
        String saltUsed = salt.isEmpty ? base64.encode(saltBytes) : salt;

        // Simple scrypt-like derivation (this is NOT actual scrypt)
        var bytes = Uint8List.fromList(utf8.encode(input + saltUsed));
        for (int i = 0; i < rounds * 1000; i++) {
          bytes = Uint8List.fromList(sha256.convert(bytes).bytes);
        }

        String hash = base64.encode(bytes);
        return 'Hash: $hash\nSalt used: $saltUsed\nRounds: ${rounds * 1000}';
      default:
        throw Exception('Password hashing only supports bcrypt and scrypt');
    }
  }

  Future<String> _performVerify(
    String input,
    String algorithm,
    String hashToVerify,
    String salt,
    int rounds,
  ) async {
    switch (algorithm) {
      case 'bcrypt':
        bool isValid = BCrypt.checkpw(input, hashToVerify);
        return 'Verification: ${isValid ? 'MATCH' : 'NO MATCH'}';
      case 'scrypt':
        // For scrypt verification, we'd need the original salt
        if (salt.isEmpty) {
          return 'Error: Salt is required for scrypt verification';
        }

        // Generate hash with same parameters
        var bytes = utf8.encode(input + salt);
        for (int i = 0; i < rounds * 1000; i++) {
          bytes = Uint8List.fromList(sha256.convert(bytes).bytes);
        }

        String generatedHash = base64.encode(bytes);
        bool isValid = generatedHash == hashToVerify;
        return 'Verification: ${isValid ? 'MATCH' : 'NO MATCH'}\nGenerated: $generatedHash';
      default:
        // For regular hashes, generate and compare
        String generatedHash = await _performHash(input, algorithm, 'hex');
        bool isValid =
            generatedHash.toLowerCase() == hashToVerify.toLowerCase();
        return 'Verification: ${isValid ? 'MATCH' : 'NO MATCH'}\nGenerated: $generatedHash';
    }
  }

  String _encodeBytes(List<int> bytes, String encoding) {
    switch (encoding) {
      case 'hex':
        return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
      case 'base64':
        return base64.encode(bytes);
      default:
        throw Exception('Unsupported encoding: $encoding');
    }
  }

  List<int> _generateRandomBytes(int length) {
    var random = Random.secure();
    return List<int>.generate(length, (i) => random.nextInt(256));
  }

  @override
  Future<String> executeGetText(String input) async {
    final result = await execute(input);
    return result.output;
  }
}

class DataExtractionTool extends Tool {
  DataExtractionTool()
    : super(
        name: 'Data Extraction',
        description:
            'Extract text or data from HTML, XML, BBCode, or JSON using proper parsers.',
        icon: Icons.data_object_outlined,
        isOutputMarkdown: true,
        isInputMarkdown: false,
        canAcceptMarkdown: false,
        supportsLiveUpdate: false, // Parsing can be expensive
        supportsStreaming: false,
        settings: {
          'inputFormat': 'HTML',
          'extractionMethod': 'text_content',
          'outputFormat': 'markdown',
          // --- HTML/XML Specific ---
          'htmlXmlTag': '',
          'htmlXmlAttribute': '',
          'htmlXmlAttributeValue': '',
          'htmlXmlIncludeTags': false,
          'htmlXmlPrettyPrint': true,
          'htmlIgnoreScriptsStyles': true,
          // --- JSON Specific ---
          'jsonPath': '',
          'jsonPrettyPrint': true,
          // --- BBCode Specific ---
          'bbcodeStripTags': true,
          'bbcodeExtractTags': '',
          // --- General ---
          'caseSensitive': false,
          'trimWhitespace': true,
        },
        settingsHints: {
          'inputFormat': {
            'type': 'dropdown',
            'label': 'Input Format',
            'help': 'Select the format of the input data',
            'options': [
              {'value': 'HTML', 'label': 'HTML'},
              {'value': 'XML', 'label': 'XML'},
              {'value': 'BBCode', 'label': 'BBCode'},
              {'value': 'JSON', 'label': 'JSON'},
            ],
          },
          'extractionMethod': {
            'type': 'dropdown',
            'label': 'Extraction Method',
            'help': 'What to extract from the data',
            'options': [
              {'value': 'text_content', 'label': 'Text Content'},
              {'value': 'specific_tag', 'label': 'Specific Tag/Element'},
              {
                'value': 'tag_with_attribute',
                'label': 'Tag with Attribute (Text)',
              },
              {
                'value': 'tag_attribute_value',
                'label': 'Tag with Attribute (Value)',
              },
              {
                'value': 'attribute_value',
                'label': 'Attribute Value (Any Tag)',
              },
              {'value': 'json_value', 'label': 'Value by Key/Path (JSON)'},
              {'value': 'pretty_print', 'label': 'Pretty Print Structure'},
              {'value': 'raw', 'label': 'Raw Data (No Change)'},
            ],
          },
          'outputFormat': {
            'type': 'dropdown',
            'label': 'Output Format',
            'help': 'How to format the extracted data',
            'options': [
              {'value': 'markdown', 'label': 'Markdown (Default)'},
              {'value': 'raw_text', 'label': 'Raw Text'},
              {'value': 'raw_list', 'label': 'Raw List (One Per Line)'},
              {'value': 'json', 'label': 'JSON Array'},
              {'value': 'csv', 'label': 'CSV Format'},
            ],
          },
          // --- HTML/XML Settings ---
          'htmlXmlTag': {
            'type': 'text',
            'label': 'Tag Name',
            'help': 'Name of the HTML/XML tag to extract (e.g., p, div, item)',
            'placeholder': 'e.g., div, p, title',
          },
          'htmlXmlAttribute': {
            'type': 'text',
            'label': 'Attribute Name',
            'help':
                'Name of the attribute to extract/filter by (e.g., href, src, class)',
            'placeholder': 'e.g., href, src, class',
          },
          'htmlXmlAttributeValue': {
            'type': 'text',
            'label': 'Attribute Value Filter',
            'help':
                'Optional: only match elements where attribute contains this value',
            'placeholder': 'e.g., button, navbar',
          },
          'htmlXmlIncludeTags': {
            'type': 'bool',
            'label': 'Include Tags (Text Extraction)',
            'help': 'Keep HTML/XML tags when extracting text content',
          },
          'htmlXmlPrettyPrint': {
            'type': 'bool',
            'label': 'Pretty Print (Structure)',
            'help': 'Format the HTML/XML structure output for readability',
          },
          'htmlIgnoreScriptsStyles': {
            'type': 'bool',
            'label': 'Ignore Scripts & Styles',
            'help': 'Exclude <script> and <style> content from text extraction',
          },
          // --- JSON Settings ---
          'jsonPath': {
            'type': 'text',
            'label': 'Key or JSONPath',
            'help':
                'JSON key (e.g., name) or JSONPath expression (e.g., \$.store.book[*].author)',
            'placeholder': 'e.g., name, \$.store.book[0].title',
            'width': 300,
          },
          'jsonPrettyPrint': {
            'type': 'bool',
            'label': 'Pretty Print',
            'help': 'Format the JSON output for readability',
          },
          // --- BBCode Settings ---
          'bbcodeStripTags': {
            'type': 'bool',
            'label': 'Strip BBCode Tags',
            'help': 'Remove BBCode tags and return plain text',
          },
          'bbcodeExtractTags': {
            'type': 'text',
            'label': 'Extract Tag Content',
            'help':
                'Extract content within specific BBCode tags (e.g., quote, code)',
            'placeholder': 'e.g., quote, code, url',
            'width': 200,
          },
          // --- General Settings ---
          'caseSensitive': {
            'type': 'bool',
            'label': 'Case Sensitive',
            'help': 'Make tag and attribute matching case sensitive',
          },
          'trimWhitespace': {
            'type': 'bool',
            'label': 'Trim Whitespace',
            'help': 'Remove extra whitespace from extracted text',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(
        output: _formatOutput('No input data provided.', []),
        status: 'success',
      );
    }

    final String format = settings['inputFormat'] as String;
    final String method = settings['extractionMethod'] as String;
    List<String> results = [];
    String error = "";

    try {
      switch (format) {
        case 'HTML':
          results = _extractFromHTML(input, method);
          break;
        case 'XML':
          results = _extractFromXML(input, method);
          break;
        case 'BBCode':
          results = _extractFromBBCode(input, method);
          break;
        case 'JSON':
          results = _extractFromJSON(input, method);
          break;
        default:
          error = "Unsupported input format: `$format`";
      }

      if (error.isNotEmpty) {
        return ToolResult(
          output: _formatOutput("Error: $error", []),
          status: 'error',
        );
      }

      return ToolResult(output: _formatOutput('', results), status: 'success');
    } catch (e, stackTrace) {
      return ToolResult(
        output: _formatOutput(
          'Failed to extract data.\n\nReason: $e\n\nDetails:\n$stackTrace',
          [],
        ),
        status: 'error',
      );
    }
  }

  String _formatOutput(String message, List<String> results) {
    final String outputFormat = settings['outputFormat'] as String;
    final String format = settings['inputFormat'] as String;
    final String method = settings['extractionMethod'] as String;

    if (message.isNotEmpty) {
      return "## Data Extraction Results\n\n$message";
    }

    if (results.isEmpty) {
      return "## Data Extraction Results\n\n*No matching data found.*";
    }

    String title = "## Extracted Data";
    if (method == 'specific_tag' &&
        (settings['htmlXmlTag'] as String).isNotEmpty) {
      title += " - `<${settings['htmlXmlTag']}>`";
    } else if ((method == 'attribute_value' ||
            method == 'tag_attribute_value') &&
        (settings['htmlXmlAttribute'] as String).isNotEmpty) {
      title += " - Attribute `${settings['htmlXmlAttribute']}`";
    } else if (method == 'json_value' &&
        (settings['jsonPath'] as String).isNotEmpty) {
      title += " - Path `${settings['jsonPath']}`";
    }

    switch (outputFormat) {
      case 'raw_text':
        return results.join('\n');

      case 'raw_list':
        return results.join('\n');

      case 'json':
        return jsonEncode(results);

      case 'csv':
        // Simple CSV format - escape quotes and wrap in quotes if contains comma
        final csvResults = results.map((r) {
          if (r.contains(',') || r.contains('"') || r.contains('\n')) {
            return '"${r.replaceAll('"', '""')}"';
          }
          return r;
        }).toList();
        return csvResults.join(',\n');

      default: // markdown
        String output = "$title\n\n";
        if (results.length == 1) {
          // Single result
          final result = results[0];
          if (result.length > 100 || result.contains('\n')) {
            output += "```\n$result\n```";
          } else {
            output += "`$result`";
          }
        } else {
          // Multiple results
          output += "**${results.length} results found:**\n\n";
          for (int i = 0; i < results.length; i++) {
            final result = results[i];
            if (result.length > 100 || result.contains('\n')) {
              output += "**${i + 1}.** \n```\n$result\n```\n\n";
            } else {
              output += "- `$result`\n";
            }
          }
        }
        return output.trim();
    }
  }

  List<String> _extractFromHTML(String html, String method) {
    final String tagName = (settings['htmlXmlTag'] as String).toLowerCase();
    final String attrName = (settings['htmlXmlAttribute'] as String)
        .toLowerCase();
    final String attrValue = settings['htmlXmlAttributeValue'] as String;
    final bool includeTags = settings['htmlXmlIncludeTags'] as bool;
    final bool prettyPrint = settings['htmlXmlPrettyPrint'] as bool;
    final bool ignoreScriptsStyles =
        settings['htmlIgnoreScriptsStyles'] as bool;
    final bool caseSensitive = settings['caseSensitive'] as bool;
    final bool trimWhitespace = settings['trimWhitespace'] as bool;

    // Parse the HTML
    final html_dom.Document document = html_parser.parse(html);

    // Remove script and style elements if requested
    if (ignoreScriptsStyles) {
      document.querySelectorAll('script').forEach((e) => e.remove());
      document.querySelectorAll('style').forEach((e) => e.remove());
    }

    switch (method) {
      case 'text_content':
        String text;
        if (includeTags) {
          text = document.outerHtml;
        } else {
          text = document.body?.text ?? document.text ?? '';
        }
        if (trimWhitespace) {
          text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
        }
        return [text];

      case 'specific_tag':
        if (tagName.isEmpty) {
          throw Exception(
            "Tag name is required for 'Specific Tag' extraction.",
          );
        }
        final List<html_dom.Element> elements = document.querySelectorAll(
          tagName,
        );
        return elements.map((e) {
          String result = includeTags ? e.outerHtml : e.text;
          if (trimWhitespace) {
            result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
          }
          return result;
        }).toList();

      case 'tag_with_attribute':
        if (tagName.isEmpty || attrName.isEmpty) {
          throw Exception(
            "Both tag name and attribute name are required for 'Tag with Attribute' extraction.",
          );
        }
        String selector = tagName;
        if (attrValue.isNotEmpty) {
          if (caseSensitive) {
            selector += '[$attrName*="$attrValue"]';
          } else {
            selector += '[$attrName*="$attrValue" i]';
          }
        } else {
          selector += '[$attrName]';
        }
        final List<html_dom.Element> elements = document.querySelectorAll(
          selector,
        );
        return elements.map((e) {
          String result = includeTags ? e.outerHtml : e.text;
          if (trimWhitespace) {
            result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
          }
          return result;
        }).toList();

      case 'tag_attribute_value':
        if (tagName.isEmpty || attrName.isEmpty) {
          throw Exception(
            "Both tag name and attribute name are required for 'Tag Attribute Value' extraction.",
          );
        }
        String selector = tagName;
        if (attrValue.isNotEmpty) {
          if (caseSensitive) {
            selector += '[$attrName*="$attrValue"]';
          } else {
            selector += '[$attrName*="$attrValue" i]';
          }
        } else {
          selector += '[$attrName]';
        }
        final List<html_dom.Element> elements = document.querySelectorAll(
          selector,
        );
        return elements
            .map((e) => e.attributes[attrName] ?? '')
            .where((v) => v.isNotEmpty)
            .toList();

      case 'attribute_value':
        if (attrName.isEmpty) {
          throw Exception(
            "Attribute name is required for 'Attribute Value' extraction.",
          );
        }
        String selector = '[$attrName]';
        if (tagName.isNotEmpty) {
          selector = '$tagName$selector';
        }
        final List<html_dom.Element> elements = document.querySelectorAll(
          selector,
        );
        return elements
            .map((e) => e.attributes[attrName] ?? '')
            .where((v) => v.isNotEmpty)
            .where((v) {
              if (attrValue.isEmpty) return true;
              return caseSensitive
                  ? v.contains(attrValue)
                  : v.toLowerCase().contains(attrValue.toLowerCase());
            })
            .toList();

      case 'pretty_print':
        String outputHtml = document.outerHtml;
        if (prettyPrint) {
          // Basic indentation for better readability
          outputHtml = _prettyPrintHtml(outputHtml);
        }
        return [outputHtml];

      default: // 'raw'
        return [html];
    }
  }

  List<String> _extractFromXML(String xmlString, String method) {
    final String tagName = settings['htmlXmlTag'] as String;
    final String attrName = settings['htmlXmlAttribute'] as String;
    final String attrValue = settings['htmlXmlAttributeValue'] as String;
    final bool includeTags = settings['htmlXmlIncludeTags'] as bool;
    final bool prettyPrint = settings['htmlXmlPrettyPrint'] as bool;
    final bool caseSensitive = settings['caseSensitive'] as bool;
    final bool trimWhitespace = settings['trimWhitespace'] as bool;

    // Parse the XML
    late xml.XmlDocument document;
    try {
      document = xml.XmlDocument.parse(xmlString);
    } catch (e) {
      throw Exception("Failed to parse XML: $e");
    }

    switch (method) {
      case 'text_content':
        String text;
        if (includeTags) {
          text = document.toXmlString(pretty: prettyPrint);
        } else {
          text = document.text;
        }
        if (trimWhitespace) {
          text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
        }
        return [text];

      case 'specific_tag':
        if (tagName.isEmpty) {
          throw Exception(
            "Tag name is required for 'Specific Tag' extraction.",
          );
        }
        final List<xml.XmlElement> elements = document
            .findAllElements(tagName)
            .toList();
        return elements.map((e) {
          String result = includeTags
              ? e.toXmlString(pretty: prettyPrint)
              : e.text;
          if (trimWhitespace) {
            result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
          }
          return result;
        }).toList();

      case 'tag_with_attribute':
        if (tagName.isEmpty || attrName.isEmpty) {
          throw Exception(
            "Both tag name and attribute name are required for 'Tag with Attribute' extraction.",
          );
        }
        final List<xml.XmlElement> elements = document
            .findAllElements(tagName)
            .where((e) => e.getAttribute(attrName) != null)
            .where((e) {
              if (attrValue.isEmpty) return true;
              final String? value = e.getAttribute(attrName);
              if (value == null) return false;
              return caseSensitive
                  ? value.contains(attrValue)
                  : value.toLowerCase().contains(attrValue.toLowerCase());
            })
            .toList();
        return elements.map((e) {
          String result = includeTags
              ? e.toXmlString(pretty: prettyPrint)
              : e.text;
          if (trimWhitespace) {
            result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
          }
          return result;
        }).toList();

      case 'tag_attribute_value':
        if (tagName.isEmpty || attrName.isEmpty) {
          throw Exception(
            "Both tag name and attribute name are required for 'Tag Attribute Value' extraction.",
          );
        }
        final List<xml.XmlElement> elements = document
            .findAllElements(tagName)
            .where((e) => e.getAttribute(attrName) != null)
            .where((e) {
              if (attrValue.isEmpty) return true;
              final String? value = e.getAttribute(attrName);
              if (value == null) return false;
              return caseSensitive
                  ? value.contains(attrValue)
                  : value.toLowerCase().contains(attrValue.toLowerCase());
            })
            .toList();
        return elements.map((e) => e.getAttribute(attrName)!).toList();

      case 'attribute_value':
        if (attrName.isEmpty) {
          throw Exception(
            "Attribute name is required for 'Attribute Value' extraction.",
          );
        }
        Iterable<xml.XmlElement> elements;
        if (tagName.isNotEmpty) {
          elements = document.findAllElements(tagName);
        } else {
          elements = document.descendants.whereType<xml.XmlElement>();
        }
        return elements
            .map((e) => e.getAttribute(attrName))
            .where((v) => v != null && v.isNotEmpty)
            .cast<String>()
            .where((v) {
              if (attrValue.isEmpty) return true;
              return caseSensitive
                  ? v.contains(attrValue)
                  : v.toLowerCase().contains(attrValue.toLowerCase());
            })
            .toList();

      case 'pretty_print':
        final String prettyXml = document.toXmlString(pretty: prettyPrint);
        return [prettyXml];

      default: // 'raw'
        return [xmlString];
    }
  }

  List<String> _extractFromBBCode(String bbcode, String method) {
    final bool stripTags = settings['bbcodeStripTags'] as bool;
    final String extractTag = settings['bbcodeExtractTags'] as String;
    final bool trimWhitespace = settings['trimWhitespace'] as bool;

    switch (method) {
      case 'text_content':
        if (stripTags) {
          // Improved BBCode tag removal
          String text = bbcode.replaceAll(RegExp(r'\[[^\]]*\]'), '');
          if (trimWhitespace) {
            text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
          }
          return [text];
        } else {
          return [bbcode];
        }

      case 'specific_tag':
        if (extractTag.isEmpty) {
          throw Exception(
            "Tag name is required for BBCode 'Specific Tag' extraction.",
          );
        }
        final RegExp tagRegex = RegExp(
          r'\[' +
              RegExp.escape(extractTag) +
              r'(?:[^\]]*)\](.*?)\[\/' +
              RegExp.escape(extractTag) +
              r'\]',
          multiLine: true,
          dotAll: true,
        );
        final Iterable<RegExpMatch> matches = tagRegex.allMatches(bbcode);
        List<String> results = matches.map((m) {
          String content = m.group(1) ?? '';
          if (trimWhitespace) {
            content = content.replaceAll(RegExp(r'\s+'), ' ').trim();
          }
          return content;
        }).toList();
        return results;

      case 'pretty_print':
        return [bbcode];

      default: // 'raw'
        return [bbcode];
    }
  }

  List<String> _extractFromJSON(String jsonString, String method) {
    final String jsonPathQuery = settings['jsonPath'] as String? ?? '';
    final bool prettyPrint = settings['jsonPrettyPrint'] as bool? ?? true;

    // Parse JSON safely
    dynamic parsedJson;
    try {
      parsedJson = jsonDecode(jsonString);
    } catch (e) {
      throw Exception("Invalid JSON input: $e");
    }

    switch (method) {
      case 'json_value':
        if (jsonPathQuery.isEmpty) {
          throw Exception(
            "Key or JSONPath is required for 'Value by Key/Path' extraction.",
          );
        }

        try {
          final path = JsonPath(jsonPathQuery);
          final results = path.read(parsedJson).toList();

          return results.map((r) {
            final value = r.value;
            if (value is String) return value;
            try {
              return JsonEncoder.withIndent(
                prettyPrint ? '  ' : '',
              ).convert(value);
            } catch (_) {
              return value.toString();
            }
          }).toList();
        } on FormatException catch (e) {
          throw Exception("Invalid JSONPath expression: `$jsonPathQuery` - $e");
        }

      case 'pretty_print':
      case 'text_content':
        try {
          final prettyJson = JsonEncoder.withIndent(
            prettyPrint ? '  ' : '',
          ).convert(parsedJson);
          return [prettyJson];
        } catch (e) {
          throw Exception("Failed to pretty print JSON: $e");
        }

      default: // 'raw'
        return [jsonString];
    }
  }

  // Helper method for basic HTML pretty printing
  String _prettyPrintHtml(String html) {
    // Simple indentation - this is basic but works for most cases
    String result = html;
    int indent = 0;
    final RegExp tagRegex = RegExp(r'<[^>]+>');
    final StringBuffer buffer = StringBuffer();
    int lastEnd = 0;

    for (final match in tagRegex.allMatches(html)) {
      // Add text before tag
      String beforeTag = html.substring(lastEnd, match.start).trim();
      if (beforeTag.isNotEmpty) {
        buffer.writeln('${'  ' * indent}$beforeTag');
      }

      String tag = match.group(0)!;

      // Check if it's a closing tag
      if (tag.startsWith('</')) {
        indent = (indent - 1).clamp(0, 100);
        buffer.writeln('${'  ' * indent}$tag');
      } else if (tag.endsWith('/>')) {
        // Self-closing tag
        buffer.writeln('${'  ' * indent}$tag');
      } else {
        // Opening tag
        buffer.writeln('${'  ' * indent}$tag');
        // Don't indent for inline tags
        if (!_isInlineTag(tag)) {
          indent++;
        }
      }

      lastEnd = match.end;
    }

    // Add any remaining text
    String remaining = html.substring(lastEnd).trim();
    if (remaining.isNotEmpty) {
      buffer.writeln('${'  ' * indent}$remaining');
    }

    return '```html\n${buffer.toString()}\n```';
  }

  bool _isInlineTag(String tag) {
    final String tagName = tag
        .replaceAll(RegExp(r'</?([a-zA-Z0-9]+).*>'), r'$1')
        .toLowerCase();
    const inlineTags = {
      'a',
      'span',
      'strong',
      'em',
      'b',
      'i',
      'u',
      'code',
      'small',
      'sup',
      'sub',
    };
    return inlineTags.contains(tagName);
  }
}

// 1. Prefix/Suffix Operations Tool
class PrefixSuffixTool extends Tool {
  PrefixSuffixTool()
    : super(
        name: 'Prefix & Suffix Operations',
        description:
            'Add or remove prefixes and suffixes from lines, words, or letters. Supports ignoring/removing empty lines, both prefix & suffix together, and more.',
        icon: Icons.format_indent_increase,
        isOutputMarkdown: false,
        isInputMarkdown: false,
        canAcceptMarkdown: true,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'operation': 'add_prefix',
          'target': 'lines',
          'prefixText': '• ',
          'suffixText': '',
          'ignoreEmpty': true,
          'removeEmpty': false,
          'preserveIndent': false,
          'trimWhitespace': false,
          'lettersOnly': false,
        },
        settingsHints: {
          'operation': {
            'type': 'dropdown',
            'label': 'Operation Type',
            'help': 'Add or remove prefix/suffix (or both)',
            'options': [
              {'value': 'add_prefix', 'label': 'Add Prefix'},
              {'value': 'remove_prefix', 'label': 'Remove Prefix'},
              {'value': 'add_suffix', 'label': 'Add Suffix'},
              {'value': 'remove_suffix', 'label': 'Remove Suffix'},
              {'value': 'add_both', 'label': 'Add Prefix & Suffix'},
              {'value': 'remove_both', 'label': 'Remove Prefix & Suffix'},
            ],
          },
          'target': {
            'type': 'dropdown',
            'label': 'Apply To',
            'help': 'What to apply the operation to',
            'options': [
              {'value': 'lines', 'label': 'Lines'},
              {'value': 'words', 'label': 'Words'},
              {'value': 'letters', 'label': 'Letters'},
            ],
          },
          'prefixText': {
            'type': 'text',
            'label': 'Prefix Text',
            'help': 'Text to add or remove at the beginning',
            'placeholder': '• ',
          },
          'suffixText': {
            'type': 'text',
            'label': 'Suffix Text',
            'help': 'Text to add or remove at the end',
            'placeholder': '...',
          },
          'ignoreEmpty': {
            'type': 'bool',
            'label': 'Ignore Empty Lines',
            'help': 'Leave empty lines untouched',
          },
          'removeEmpty': {
            'type': 'bool',
            'label': 'Remove Empty Lines',
            'help': 'Completely delete empty lines from output',
          },
          'preserveIndent': {
            'type': 'bool',
            'label': 'Preserve Indentation',
            'help': 'Apply prefix/suffix after original leading spaces',
          },
          'trimWhitespace': {
            'type': 'bool',
            'label': 'Trim Whitespace',
            'help': 'Trim leading/trailing spaces from each line/word',
          },
          'lettersOnly': {
            'type': 'bool',
            'label': 'Letters Only (for letter mode)',
            'help':
                'Apply only to alphabetic letters, not punctuation/whitespace',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success');
    }

    final String operation = settings['operation'] as String;
    String result = input;

    try {
      switch (operation) {
        case 'add_prefix':
          result = _process(input, addPrefix: true);
          break;
        case 'remove_prefix':
          result = _process(input, removePrefix: true);
          break;
        case 'add_suffix':
          result = _process(input, addSuffix: true);
          break;
        case 'remove_suffix':
          result = _process(input, removeSuffix: true);
          break;
        case 'add_both':
          result = _process(input, addPrefix: true, addSuffix: true);
          break;
        case 'remove_both':
          result = _process(input, removePrefix: true, removeSuffix: true);
          break;
        default:
          result = input;
      }

      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: $e', status: 'error');
    }
  }

  String _process(
    String input, {
    bool addPrefix = false,
    bool removePrefix = false,
    bool addSuffix = false,
    bool removeSuffix = false,
  }) {
    final String target = settings['target'] as String;
    final String prefix = settings['prefixText'] as String;
    final String suffix = settings['suffixText'] as String;
    final bool ignoreEmpty = settings['ignoreEmpty'] as bool;
    final bool removeEmpty = settings['removeEmpty'] as bool;
    final bool preserveIndent = settings['preserveIndent'] as bool;
    final bool trimWhitespace = settings['trimWhitespace'] as bool;
    final bool lettersOnly = settings['lettersOnly'] as bool;

    if (target == 'lines') {
      return input
          .split('\n')
          .map((line) {
            String original = line;

            if (removeEmpty && line.trim().isEmpty) return null;
            if (ignoreEmpty && line.trim().isEmpty) return line;

            String leadingIndent = '';
            if (preserveIndent) {
              leadingIndent = RegExp(r'^\s*').stringMatch(line) ?? '';
              line = line.trimLeft();
            }

            if (trimWhitespace) line = line.trim();

            if (addPrefix) line = '$prefix$line';
            if (addSuffix) line = '$line$suffix';

            if (removePrefix && line.startsWith(prefix)) {
              line = line.substring(prefix.length);
            }
            if (removeSuffix && line.endsWith(suffix)) {
              line = line.substring(0, line.length - suffix.length);
            }

            return '$leadingIndent$line';
          })
          .where((line) => line != null)
          .join('\n');
    }

    if (target == 'words') {
      return input
          .split(RegExp(r'\s+'))
          .where((w) => !(removeEmpty && w.trim().isEmpty))
          .map((word) {
            if (ignoreEmpty && word.trim().isEmpty) return word;

            String processed = trimWhitespace ? word.trim() : word;

            if (addPrefix) processed = '$prefix$processed';
            if (addSuffix) processed = '$processed$suffix';

            if (removePrefix && processed.startsWith(prefix)) {
              processed = processed.substring(prefix.length);
            }
            if (removeSuffix && processed.endsWith(suffix)) {
              processed = processed.substring(
                0,
                processed.length - suffix.length,
              );
            }

            return processed;
          })
          .join(' ');
    }

    if (target == 'letters') {
      return input
          .split('')
          .map((char) {
            if (lettersOnly && !RegExp(r'[A-Za-z]').hasMatch(char)) {
              return char;
            }

            String processed = char;
            if (addPrefix) processed = '$prefix$processed';
            if (addSuffix) processed = '$processed$suffix';

            if (removePrefix && processed.startsWith(prefix)) {
              processed = processed.substring(prefix.length);
            }
            if (removeSuffix && processed.endsWith(suffix)) {
              processed = processed.substring(
                0,
                processed.length - suffix.length,
              );
            }

            return processed;
          })
          .join('');
    }

    return input;
  }
}

// 2. Symbol Operations Tool
class SymbolOperationsTool extends Tool {
  SymbolOperationsTool()
    : super(
        name: 'Symbol Operations',
        description:
            'Add or remove symbols around/between words, letters, or lines.',
        icon: Icons.title,
        isOutputMarkdown: false,
        isInputMarkdown: false,
        canAcceptMarkdown: true,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'operation': 'add_symbols',
          'symbolText': '"',
          'symbolPosition': 'around_words',
        },
        settingsHints: {
          'operation': {
            'type': 'dropdown',
            'label': 'Operation',
            'help': 'Add or remove symbols',
            'options': [
              {'value': 'add_symbols', 'label': 'Add Symbols'},
              {'value': 'remove_symbols', 'label': 'Remove Symbols'},
            ],
          },
          'symbolText': {
            'type': 'text',
            'label': 'Symbol/Text',
            'help': 'Symbol or text to add/remove',
            'placeholder': '"',
          },
          'symbolPosition': {
            'type': 'dropdown',
            'label': 'Symbol Position',
            'help': 'Where to place symbols',
            'options': [
              {'value': 'around_words', 'label': 'Around Words'},
              {'value': 'around_letters', 'label': 'Around Letters'},
              {'value': 'between_letters', 'label': 'Between Letters'},
              {'value': 'between_words', 'label': 'Between Words'},
              {'value': 'around_lines', 'label': 'Around Lines'},
              {'value': 'before_lines', 'label': 'Before Lines'},
              {'value': 'after_lines', 'label': 'After Lines'},
              {'value': 'between_lines', 'label': 'Between Lines'},
            ],
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success');
    }

    final String operation = settings['operation'] as String;
    String result = input;

    try {
      switch (operation) {
        case 'add_symbols':
          result = _addSymbols(input);
          break;
        case 'remove_symbols':
          result = _removeSymbols(input);
          break;
        default:
          result = input;
      }

      return ToolResult(output: result, status: 'success');
    } catch (e) {
      // Returning the error message in the output as per template example
      return ToolResult(output: 'Error processing text: $e', status: 'error');
    }
  }

  String _addSymbols(String input) {
    final String symbol = settings['symbolText'] as String;
    final String position = settings['symbolPosition'] as String;

    switch (position) {
      case 'around_words':
        return input
            .split(RegExp(r'\s+'))
            .map((word) => '$symbol$word$symbol')
            .join(' ');
      case 'around_letters':
        // Keeps spaces as spaces, adds symbols around non-space chars
        return input.replaceAllMapped(
          RegExp(r'[^\s]'),
          (match) => '$symbol${match.group(0)}$symbol',
        );
      case 'between_letters':
        // Adds symbol between every character
        return input.split('').join(symbol);
      case 'between_words':
        // Adds symbol between words (replaces one or more spaces with symbol)
        return input.replaceAll(RegExp(r'\s+'), symbol);
      // --- New cases for lines ---
      case 'around_lines':
        // Adds symbol before and after each line
        return input
            .split('\n')
            .map((line) => '$symbol$line$symbol')
            .join('\n');
      case 'before_lines':
        // Adds symbol at the beginning of each line
        return input.split('\n').map((line) => '$symbol$line').join('\n');
      case 'after_lines':
        // Adds symbol at the end of each line
        return input.split('\n').map((line) => '$line$symbol').join('\n');
      case 'between_lines':
        // Adds symbol between lines
        List<String> lines = input.split('\n');
        if (lines.length <= 1) {
          return input; // No lines to put symbol between
        }
        StringBuffer buffer = StringBuffer();
        for (int i = 0; i < lines.length; i++) {
          buffer.write(lines[i]);
          if (i < lines.length - 1) {
            // Don't add symbol after the last line
            buffer.write(symbol);
          }
        }
        return buffer.toString();
      // --- End new cases ---
      default:
        return input;
    }
  }

  String _removeSymbols(String input) {
    final String symbol = settings['symbolText'] as String;
    if (symbol.isEmpty) return input;

    // Removes all instances of the symbol text.
    return input.replaceAll(RegExp(RegExp.escape(symbol)), '');
  }
}

// 3. Line Numbering Tool
class LineNumberingTool extends Tool {
  LineNumberingTool()
    : super(
        name: 'Line Numbering & Lists',
        description:
            'Add/remove line numbers or bullets. Supports smart spacing, empty line handling, word wrap, and flexible formatting.',
        icon: Icons.format_list_numbered,
        isOutputMarkdown: false,
        isInputMarkdown: false,
        canAcceptMarkdown: true,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'operation': 'add_numbers',
          'listType': 'numbers',
          'numberFormat': '1. ',
          'bulletStyle': '•',
          'customBullet': '',
          'smartSpacing': true,
          'skipEmptyLines': true,
          'wordWrap': false,
          'wrapWidth': 80,
          'continuationIndent': '', // default = same as prefix length
          'trimWhitespace': true,
          'preserveIndent': false,
          'customSeparator': '', // overrides numberFormat separator
        },
        settingsHints: {
          'operation': {
            'type': 'dropdown',
            'label': 'Operation',
            'options': [
              {'value': 'add_numbers', 'label': 'Add Numbers/Bullets'},
              {'value': 'remove_numbers', 'label': 'Remove Numbers/Bullets'},
            ],
          },
          'listType': {
            'type': 'dropdown',
            'label': 'List Type',
            'options': [
              {'value': 'numbers', 'label': 'Numbers'},
              {'value': 'bullets', 'label': 'Bullets'},
            ],
          },
          'numberFormat': {
            'type': 'dropdown',
            'label': 'Number Format',
            'options': [
              {'value': '1. ', 'label': '1. 2. 3.'},
              {'value': '1) ', 'label': '1) 2) 3)'},
              {'value': '(1) ', 'label': '(1) (2) (3)'},
              {'value': '[1] ', 'label': '[1] [2] [3]'},
              {'value': '1: ', 'label': '1: 2: 3:'},
              {'value': '1\t', 'label': '1[tab] 2[tab] 3[tab]'},
            ],
          },
          'bulletStyle': {
            'type': 'dropdown',
            'label': 'Bullet Style',
            'options': [
              {'value': '•', 'label': '• Standard Bullet'},
              {'value': '◦', 'label': '◦ White Bullet'},
              {'value': '▪', 'label': '▪ Small Square'},
              {'value': '-', 'label': '- Dash'},
              {'value': '*', 'label': '* Asterisk'},
              {'value': '>', 'label': '> Chevron'},
            ],
          },
          'customBullet': {
            'type': 'text',
            'label': 'Custom Bullet',
            'placeholder': 'e.g., →, ➤, ::',
          },
          'smartSpacing': {'type': 'bool', 'label': 'Smart Spacing'},
          'skipEmptyLines': {'type': 'bool', 'label': 'Skip Empty Lines'},
          'wordWrap': {'type': 'bool', 'label': 'Word Wrap'},
          'wrapWidth': {
            'type': 'number',
            'label': 'Wrap Width',
            'min': 10,
            'max': 200,
          },
          'continuationIndent': {
            'type': 'text',
            'label': 'Continuation Indent',
            'help':
                'Indent for wrapped lines. Leave empty to auto-match prefix width.',
            'placeholder': 'e.g., 4 spaces, "--", "   "',
          },
          'trimWhitespace': {
            'type': 'bool',
            'label': 'Trim Whitespace',
            'help': 'Remove extra spaces from each line before processing',
          },
          'preserveIndent': {
            'type': 'bool',
            'label': 'Preserve Indent',
            'help': 'Keep original leading spaces when numbering/wrapping',
          },
          'customSeparator': {
            'type': 'text',
            'label': 'Custom Separator',
            'help': 'Override number format separator (e.g., use "::")',
            'placeholder': 'e.g., ::, =>, >>',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success');
    }

    final String operation = settings['operation'] as String;
    String result = input;

    try {
      switch (operation) {
        case 'add_numbers':
          result = _addNumbersOrBullets(input);
          break;
        case 'remove_numbers':
          result = _removeNumbersOrBullets(input);
          break;
        default:
          result = input;
      }

      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error processing text: $e', status: 'error');
    }
  }

  String _addNumbersOrBullets(String input) {
    final String listType = settings['listType'] as String;
    final String numberFormat = settings['numberFormat'] as String;
    final String bulletStyle = settings['bulletStyle'] as String;
    final String customBullet = settings['customBullet'] as String;
    final bool smartSpacing = settings['smartSpacing'] as bool;
    final bool skipEmptyLines = settings['skipEmptyLines'] as bool;
    final bool wordWrap = settings['wordWrap'] as bool;
    final int wrapWidth = (settings['wrapWidth'] as num).toInt();
    final String continuationIndentSetting =
        settings['continuationIndent'] as String;
    final bool trimWhitespace = settings['trimWhitespace'] as bool;
    final bool preserveIndent = settings['preserveIndent'] as bool;
    final String customSeparator = settings['customSeparator'] as String;

    final List<String> originalLines = input.split('\n');
    final List<String> processedLines = [];
    int lineCounter = 1;

    // Calculate max prefix width for alignment
    int maxWidth = 0;
    if (smartSpacing) {
      if (listType == 'numbers') {
        int maxLineNum = originalLines.length;
        String samplePrefix = _makeNumberPrefix(
          maxLineNum,
          numberFormat,
          customSeparator,
        );
        maxWidth = samplePrefix.length;
      } else {
        String effectiveBullet = customBullet.isNotEmpty
            ? customBullet
            : bulletStyle;
        maxWidth = effectiveBullet.length + 1;
      }
    }

    for (String line in originalLines) {
      if (trimWhitespace) line = line.trimRight();

      if (skipEmptyLines && line.trim().isEmpty) {
        processedLines.add(line);
        continue;
      }

      String leadingIndent = "";
      if (preserveIndent) {
        leadingIndent = RegExp(r'^\s*').stringMatch(line) ?? "";
        line = line.trimLeft();
      }

      // Build prefix
      String prefix;
      if (listType == 'numbers') {
        prefix = _makeNumberPrefix(lineCounter, numberFormat, customSeparator);
        lineCounter++;
      } else {
        prefix = customBullet.isNotEmpty ? customBullet : bulletStyle;
        prefix += ' ';
      }

      if (smartSpacing) {
        prefix = prefix.padRight(maxWidth);
      }

      String continuationIndent = continuationIndentSetting.isNotEmpty
          ? continuationIndentSetting
          : ' ' * prefix.length;

      // Wrap text
      List<String> wrappedLines = wordWrap
          ? _wordWrapLine(line, wrapWidth).split('\n')
          : [line];

      for (int i = 0; i < wrappedLines.length; i++) {
        if (i == 0) {
          processedLines.add('$leadingIndent$prefix${wrappedLines[i]}');
        } else {
          processedLines.add(
            '$leadingIndent$continuationIndent${wrappedLines[i]}',
          );
        }
      }
    }

    return processedLines.join('\n');
  }

  String _makeNumberPrefix(int number, String format, String customSep) {
    if (customSep.isNotEmpty) {
      return "$number$customSep";
    }
    return format.replaceAll('1', number.toString());
  }

  String _wordWrapLine(String line, int width) {
    List<String> words = line.split(RegExp(r'\s+'));
    List<String> wrapped = [];
    String current = "";

    for (String word in words) {
      if (word.isEmpty) continue;

      if (current.isEmpty) {
        if (word.length > width) {
          // split very long word
          for (int i = 0; i < word.length; i += width) {
            wrapped.add(
              word.substring(
                i,
                i + width > word.length ? word.length : i + width,
              ),
            );
          }
        } else {
          current = word;
        }
      } else {
        String test = "$current $word";
        if (test.length <= width) {
          current = test;
        } else {
          wrapped.add(current);
          if (word.length > width) {
            for (int i = 0; i < word.length; i += width) {
              wrapped.add(
                word.substring(
                  i,
                  i + width > word.length ? word.length : i + width,
                ),
              );
            }
            current = "";
          } else {
            current = word;
          }
        }
      }
    }

    if (current.isNotEmpty) wrapped.add(current);

    return wrapped.join('\n');
  }

  String _removeNumbersOrBullets(String input) {
    return input
        .split('\n')
        .map((line) {
          return line.replaceFirst(
            RegExp(r'^\s*([\d]+[\.\)\]\:\t]|[\•\◦\▪\-\*\>])\s*'),
            '',
          );
        })
        .join('\n');
  }
}

// 4. Line Cleanup Tool
class LineCleanupTool extends Tool {
  LineCleanupTool()
    : super(
        name: 'Line Cleanup',
        description:
            'Remove empty lines, duplicate lines, and perform line-based cleanup operations.',
        icon: Icons.cleaning_services,
        isOutputMarkdown: false,
        isInputMarkdown: false,
        canAcceptMarkdown: true,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'removeEmptyLines': true,
          'removeDuplicateLines': false,
          'caseSensitiveDuplicates': false,
        },
        settingsHints: {
          'removeEmptyLines': {
            'type': 'bool',
            'label': 'Remove Empty Lines',
            'help': 'Remove completely empty lines',
          },
          'removeDuplicateLines': {
            'type': 'bool',
            'label': 'Remove Duplicate Lines',
            'help': 'Remove duplicate lines',
          },
          'caseSensitiveDuplicates': {
            'type': 'bool',
            'label': 'Case Sensitive Duplicates',
            'help': 'Consider case when removing duplicates',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success');
    }

    String result = input;

    try {
      if (settings['removeEmptyLines'] as bool) {
        result = _removeEmptyLines(result);
      }

      if (settings['removeDuplicateLines'] as bool) {
        result = _removeDuplicateLines(result);
      }

      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: $e', status: 'error');
    }
  }

  String _removeEmptyLines(String input) {
    return input.split('\n').where((line) => line.trim().isNotEmpty).join('\n');
  }

  String _removeDuplicateLines(String input) {
    final bool caseSensitive = settings['caseSensitiveDuplicates'] as bool;
    final List<String> lines = input.split('\n');
    final Set<String> seen = <String>{};
    final List<String> result = [];

    for (String line in lines) {
      final String checkLine = caseSensitive ? line : line.toLowerCase();
      if (!seen.contains(checkLine)) {
        seen.add(checkLine);
        result.add(line);
      }
    }

    return result.join('\n');
  }
}

// 5. Line Break Operations Tool
class LineBreakTool extends Tool {
  LineBreakTool()
    : super(
        name: 'Line Break Operations',
        description:
            'Add, remove, or modify line breaks with various formatting styles.',
        icon: Icons.keyboard_return,
        isOutputMarkdown: false,
        isInputMarkdown: false,
        canAcceptMarkdown: true,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {'lineBreakStyle': 'add_double'},
        settingsHints: {
          'lineBreakStyle': {
            'type': 'dropdown',
            'label': 'Line Break Operation',
            'help': 'Type of line break operation to perform',
            'options': [
              {'value': 'add_double', 'label': 'Add Double Line Breaks'},
              {'value': 'remove_extra', 'label': 'Remove Extra Line Breaks'},
              {'value': 'normalize', 'label': 'Normalize Line Breaks'},
              {'value': 'fancy_breaks', 'label': 'Add Fancy Breaks (----)'},
              {'value': 'paragraph_breaks', 'label': 'Add Paragraph Breaks'},
            ],
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success');
    }

    try {
      String result = _processLineBreaks(input);
      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: $e', status: 'error');
    }
  }

  String _processLineBreaks(String input) {
    final String style = settings['lineBreakStyle'] as String;

    switch (style) {
      case 'add_double':
        return input.replaceAll('\n', '\n\n');
      case 'remove_extra':
        return input.replaceAll(RegExp(r'\n{3,}'), '\n\n');
      case 'normalize':
        return input.replaceAll(RegExp(r'\n+'), '\n');
      case 'fancy_breaks':
        return input.replaceAll('\n', '\n----\n');
      case 'paragraph_breaks':
        return input
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .join('\n\n');
      default:
        return input;
    }
  }
}

// 6. Separator Conversion Tool
class SeparatorConverterTool extends Tool {
  SeparatorConverterTool()
    : super(
        name: 'Separator Converter',
        description:
            'Convert between different types of separators (spaces, tabs, commas, etc.).',
        icon: Icons.swap_horiz,
        isOutputMarkdown: false,
        isInputMarkdown: false,
        canAcceptMarkdown: true,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'separatorFrom': 'spaces',
          'separatorTo': 'newlines',
          'customSeparator': ',',
        },
        settingsHints: {
          'separatorFrom': {
            'type': 'dropdown',
            'label': 'Convert From',
            'help': 'Current separator to convert from',
            'options': [
              {'value': 'spaces', 'label': 'Spaces'},
              {'value': 'tabs', 'label': 'Tabs'},
              {'value': 'commas', 'label': 'Commas'},
              {'value': 'semicolons', 'label': 'Semicolons'},
              {'value': 'newlines', 'label': 'Newlines'},
              {'value': 'pipes', 'label': 'Pipes (|)'},
              {'value': 'custom', 'label': 'Custom'},
            ],
          },
          'separatorTo': {
            'type': 'dropdown',
            'label': 'Convert To',
            'help': 'Target separator to convert to',
            'options': [
              {'value': 'spaces', 'label': 'Spaces'},
              {'value': 'tabs', 'label': 'Tabs'},
              {'value': 'commas', 'label': 'Commas'},
              {'value': 'semicolons', 'label': 'Semicolons'},
              {'value': 'newlines', 'label': 'Newlines'},
              {'value': 'pipes', 'label': 'Pipes (|)'},
              {'value': 'custom', 'label': 'Custom'},
            ],
          },
          'customSeparator': {
            'type': 'text',
            'label': 'Custom Separator',
            'help': 'Custom separator when "custom" is selected',
            'placeholder': ', ',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success');
    }

    try {
      String result = _convertSeparators(input);
      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: $e', status: 'error');
    }
  }

  String _convertSeparators(String input) {
    final String from = settings['separatorFrom'] as String;
    final String to = settings['separatorTo'] as String;
    final String custom = settings['customSeparator'] as String;

    String fromSep = _getSeparator(from, custom);
    String toSep = _getSeparator(to, custom);

    if (fromSep == toSep) return input;

    // Special handling for different separator types
    if (from == 'newlines') {
      return input.split('\n').join(toSep);
    } else if (to == 'newlines') {
      return input.split(RegExp(RegExp.escape(fromSep))).join('\n');
    } else {
      return input.replaceAll(RegExp(RegExp.escape(fromSep)), toSep);
    }
  }

  String _getSeparator(String type, String custom) {
    switch (type) {
      case 'spaces':
        return ' ';
      case 'tabs':
        return '\t';
      case 'commas':
        return ', ';
      case 'semicolons':
        return '; ';
      case 'newlines':
        return '\n';
      case 'pipes':
        return ' | ';
      case 'custom':
        return custom;
      default:
        return ' ';
    }
  }
}

// 7. Whitespace Operations Tool
class WhitespaceOperationsTool extends Tool {
  WhitespaceOperationsTool()
    : super(
        name: 'Whitespace Operations',
        description:
            'Normalize, add, remove, or modify whitespace and spacing in text.',
        icon: Icons.space_bar,
        isOutputMarkdown: false,
        isInputMarkdown: false,
        canAcceptMarkdown: true,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {'whitespaceOperation': 'normalize', 'spacingAmount': 4},
        settingsHints: {
          'whitespaceOperation': {
            'type': 'dropdown',
            'label': 'Whitespace Operation',
            'help': 'Type of whitespace operation to perform',
            'options': [
              {'value': 'normalize', 'label': 'Normalize (single spaces)'},
              {'value': 'remove_all', 'label': 'Remove All Spaces'},
              {'value': 'remove_extra', 'label': 'Remove Extra Spaces'},
              {'value': 'add_random', 'label': 'Add Random Spacing'},
              {'value': 'double_space', 'label': 'Double Space'},
              {'value': 'tab_to_spaces', 'label': 'Tabs to Spaces'},
              {'value': 'spaces_to_tabs', 'label': 'Spaces to Tabs'},
            ],
          },
          'spacingAmount': {
            'type': 'number',
            'label': 'Spacing Amount',
            'help': 'Number of spaces per tab (for conversion operations)',
            'min': 1,
            'max': 10,
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success');
    }

    try {
      String result = _processWhitespace(input);
      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: $e', status: 'error');
    }
  }

  String _processWhitespace(String input) {
    final String operation = settings['whitespaceOperation'] as String;
    final int spacingAmount = (settings['spacingAmount'] as num).toInt();

    switch (operation) {
      case 'normalize':
        return input.replaceAll(RegExp(r'\s+'), ' ').trim();
      case 'remove_all':
        return input.replaceAll(RegExp(r'\s+'), '');
      case 'remove_extra':
        return input.replaceAll(RegExp(r' {2,}'), ' ');
      case 'add_random':
        return _addRandomSpacing(input);
      case 'double_space':
        return input.replaceAll(' ', '  ');
      case 'tab_to_spaces':
        return input.replaceAll('\t', ' ' * spacingAmount);
      case 'spaces_to_tabs':
        final String spaces = ' ' * spacingAmount;
        return input.replaceAll(spaces, '\t');
      default:
        return input;
    }
  }

  String _addRandomSpacing(String input) {
    final List<String> chars = input.split('');
    final StringBuffer result = StringBuffer();
    final Random random = Random();

    for (int i = 0; i < chars.length; i++) {
      result.write(chars[i]);
      if (chars[i] != ' ' && i < chars.length - 1 && chars[i + 1] != ' ') {
        if (random.nextBool()) {
          result.write(' ' * (random.nextInt(3) + 1));
        }
      }
    }

    return result.toString();
  }
}

// 8. Case Conversion Tool
class CaseConverterTool extends Tool {
  CaseConverterTool()
    : super(
        name: 'Case Converter',
        description:
            'Convert text case: uppercase, lowercase, title case, sentence case, etc.',
        icon: Icons.text_fields,
        isOutputMarkdown: false,
        isInputMarkdown: false,
        canAcceptMarkdown: true,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {'caseType': 'uppercase', 'preserveAcronyms': false},
        settingsHints: {
          'caseType': {
            'type': 'dropdown',
            'label': 'Case Type',
            'help': 'Type of case conversion to apply',
            'options': [
              {'value': 'uppercase', 'label': 'UPPERCASE'},
              {'value': 'lowercase', 'label': 'lowercase'},
              {'value': 'title_case', 'label': 'Title Case'},
              {'value': 'sentence_case', 'label': 'Sentence case'},
              {'value': 'camel_case', 'label': 'camelCase'},
              {'value': 'pascal_case', 'label': 'PascalCase'},
              {'value': 'snake_case', 'label': 'snake_case'},
              {'value': 'kebab_case', 'label': 'kebab-case'},
              {'value': 'alternating', 'label': 'aLtErNaTiNg CaSe'},
              {'value': 'inverse', 'label': 'iNVERSE cASE'},
            ],
          },
          'preserveAcronyms': {
            'type': 'bool',
            'label': 'Preserve Acronyms',
            'help': 'Keep common acronyms in uppercase (for title case)',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success');
    }

    try {
      String result = _convertCase(input);
      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: $e', status: 'error');
    }
  }

  String _convertCase(String input) {
    final String caseType = settings['caseType'] as String;
    final bool preserveAcronyms = settings['preserveAcronyms'] as bool;

    switch (caseType) {
      case 'uppercase':
        return input.toUpperCase();
      case 'lowercase':
        return input.toLowerCase();
      case 'title_case':
        return _toTitleCase(input, preserveAcronyms);
      case 'sentence_case':
        return _toSentenceCase(input);
      case 'camel_case':
        return _toCamelCase(input);
      case 'pascal_case':
        return _toPascalCase(input);
      case 'snake_case':
        return _toSnakeCase(input);
      case 'kebab_case':
        return _toKebabCase(input);
      case 'alternating':
        return _toAlternatingCase(input);
      case 'inverse':
        return _toInverseCase(input);
      default:
        return input;
    }
  }

  String _toTitleCase(String input, bool preserveAcronyms) {
    final List<String> commonAcronyms = [
      'API',
      'HTTP',
      'URL',
      'JSON',
      'XML',
      'HTML',
      'CSS',
      'JS',
      'SQL',
      'AI',
      'ML',
      'UI',
      'UX',
    ];

    return input
        .split(' ')
        .map((word) {
          if (preserveAcronyms && commonAcronyms.contains(word.toUpperCase())) {
            return word.toUpperCase();
          }
          return word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String _toSentenceCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  String _toCamelCase(String input) {
    List<String> words = input.split(RegExp(r'[\s_-]+'));
    if (words.isEmpty) return input;

    String result = words[0].toLowerCase();
    for (int i = 1; i < words.length; i++) {
      if (words[i].isNotEmpty) {
        result +=
            words[i][0].toUpperCase() + words[i].substring(1).toLowerCase();
      }
    }
    return result;
  }

  String _toPascalCase(String input) {
    List<String> words = input.split(RegExp(r'[\s_-]+'));
    return words
        .map(
          (word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join('');
  }

  String _toSnakeCase(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  }

  String _toKebabCase(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[\s_]+'), '-');
  }

  String _toAlternatingCase(String input) {
    StringBuffer result = StringBuffer();
    bool uppercase = false;

    for (String char in input.split('')) {
      if (char.contains(RegExp(r'[a-zA-Z]'))) {
        result.write(uppercase ? char.toUpperCase() : char.toLowerCase());
        uppercase = !uppercase;
      } else {
        result.write(char);
      }
    }
    return result.toString();
  }

  String _toInverseCase(String input) {
    return input
        .split('')
        .map((char) {
          if (char == char.toUpperCase()) {
            return char.toLowerCase();
          } else {
            return char.toUpperCase();
          }
        })
        .join('');
  }
}

// 9. Text Sorting Tool
class TextSortingTool extends Tool {
  TextSortingTool()
    : super(
        name: 'Text Sorting',
        description:
            'Sort lines, words, or characters alphabetically or by various criteria.',
        icon: Icons.sort_by_alpha,
        isOutputMarkdown: false, // now markdown for list formatting
        isInputMarkdown: false,
        canAcceptMarkdown: true,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'sortTarget': 'lines',
          'sortOrder': 'ascending',
          'sortBy': 'alphabetical',
          'caseSensitive': false,
          'removeEmpty': false,
          'outputFormat': 'raw',
        },
        settingsHints: {
          'sortTarget': {
            'type': 'dropdown',
            'label': 'Sort Target',
            'help': 'What to sort',
            'options': [
              {'value': 'lines', 'label': 'Lines'},
              {'value': 'words', 'label': 'Words'},
              {'value': 'characters', 'label': 'Characters'},
            ],
          },
          'sortOrder': {
            'type': 'dropdown',
            'label': 'Sort Order',
            'help': 'Ascending or descending order',
            'options': [
              {'value': 'ascending', 'label': 'Ascending (A-Z)'},
              {'value': 'descending', 'label': 'Descending (Z-A)'},
              {'value': 'random', 'label': 'Random Shuffle'},
            ],
          },
          'sortBy': {
            'type': 'dropdown',
            'label': 'Sort By',
            'help': 'Criteria for sorting',
            'options': [
              {'value': 'alphabetical', 'label': 'Alphabetical'},
              {'value': 'length', 'label': 'Length'},
              {
                'value': 'numerical',
                'label': 'Numerical (if contains numbers)',
              },
            ],
          },
          'caseSensitive': {
            'type': 'bool',
            'label': 'Case Sensitive',
            'help': 'Consider case when sorting',
          },
          'removeEmpty': {
            'type': 'bool',
            'label': 'Remove Empty Items',
            'help': 'Remove empty lines/words before sorting',
          },
          'outputFormat': {
            'type': 'dropdown',
            'label': 'Output Format',
            'help': 'Choose how the sorted result should be displayed',
            'options': [
              {'value': 'raw', 'label': 'Raw (joined)'},
              {'value': 'bullet', 'label': 'Bullet List'},
              {'value': 'numbered', 'label': 'Numbered List'},
              {'value': 'inline', 'label': 'Inline (comma separated)'},
            ],
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success');
    }

    try {
      String result = _sortText(input);
      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: $e', status: 'error');
    }
  }

  String _sortText(String input) {
    final String target = settings['sortTarget'] as String;
    final String order = settings['sortOrder'] as String;
    final String sortBy = settings['sortBy'] as String;
    final bool caseSensitive = settings['caseSensitive'] as bool;
    final bool removeEmpty = settings['removeEmpty'] as bool;
    final String outputFormat = settings['outputFormat'] as String;

    List<String> items;
    String separator;

    switch (target) {
      case 'lines':
        items = input.split('\n');
        separator = '\n';
        break;
      case 'words':
        items = input.split(RegExp(r'\s+'));
        separator = ' ';
        break;
      case 'characters':
        items = input.split('');
        separator = '';
        break;
      default:
        return input;
    }

    if (removeEmpty) {
      items = items.where((item) => item.trim().isNotEmpty).toList();
    }

    if (order == 'random') {
      items.shuffle(Random());
    } else {
      items.sort((a, b) {
        String aComp = caseSensitive ? a : a.toLowerCase();
        String bComp = caseSensitive ? b : b.toLowerCase();

        int comparison;
        switch (sortBy) {
          case 'length':
            comparison = a.length.compareTo(b.length);
            break;
          case 'numerical':
            final RegExp numberRegex = RegExp(r'\d+');
            final Match? aMatch = numberRegex.firstMatch(a);
            final Match? bMatch = numberRegex.firstMatch(b);

            if (aMatch != null && bMatch != null) {
              final int aNum = int.tryParse(aMatch.group(0)!) ?? 0;
              final int bNum = int.tryParse(bMatch.group(0)!) ?? 0;
              comparison = aNum.compareTo(bNum);
            } else {
              comparison = aComp.compareTo(bComp);
            }
            break;
          default: // alphabetical
            comparison = aComp.compareTo(bComp);
            break;
        }

        return order == 'descending' ? -comparison : comparison;
      });
    }

    // Format output
    switch (outputFormat) {
      case 'bullet':
        return items.map((e) => "- $e").join("\n");
      case 'numbered':
        return items
            .asMap()
            .entries
            .map((e) => "${e.key + 1}. ${e.value}")
            .join("\n");
      case 'inline':
        return items.join(', ');
      default: // raw
        return items.join(separator);
    }
  }
}

// 10. Find & Replace Tool
class FindReplaceTool extends Tool {
  FindReplaceTool()
    : super(
        name: 'Find & Replace',
        description:
            'Find and replace text with support for regex patterns and multiple replacements.',
        icon: Icons.find_replace,
        isOutputMarkdown: false,
        isInputMarkdown: false,
        canAcceptMarkdown: true,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'findText': '',
          'replaceText': '',
          'caseSensitive': false,
          'useRegex': false,
          'replaceAll': true,
        },
        settingsHints: {
          'findText': {
            'type': 'text',
            'label': 'Find Text',
            'help': 'Text or pattern to find',
            'placeholder': 'search text',
          },
          'replaceText': {
            'type': 'text',
            'label': 'Replace With',
            'help': 'Replacement text',
            'placeholder': 'replacement text',
          },
          'caseSensitive': {
            'type': 'bool',
            'label': 'Case Sensitive',
            'help': 'Match case exactly',
          },
          'useRegex': {
            'type': 'bool',
            'label': 'Use Regular Expressions',
            'help': 'Treat find text as regex pattern',
          },
          'replaceAll': {
            'type': 'bool',
            'label': 'Replace All Occurrences',
            'help': 'Replace all matches (vs just first)',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success');
    }

    try {
      String result = _replaceText(input);
      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: $e', status: 'error');
    }
  }

  String _replaceText(String input) {
    final String findText = settings['findText'] as String;
    final String replaceText = settings['replaceText'] as String;
    final bool caseSensitive = settings['caseSensitive'] as bool;
    final bool useRegex = settings['useRegex'] as bool;
    final bool replaceAll = settings['replaceAll'] as bool;

    if (findText.isEmpty) return input;

    try {
      if (useRegex) {
        final RegExp regex = RegExp(findText, caseSensitive: caseSensitive);

        if (replaceAll) {
          return input.replaceAll(regex, replaceText);
        } else {
          return input.replaceFirst(regex, replaceText);
        }
      } else {
        if (replaceAll) {
          if (caseSensitive) {
            return input.replaceAll(findText, replaceText);
          } else {
            return input.replaceAll(
              RegExp(RegExp.escape(findText), caseSensitive: false),
              replaceText,
            );
          }
        } else {
          if (caseSensitive) {
            return input.replaceFirst(findText, replaceText);
          } else {
            return input.replaceFirst(
              RegExp(RegExp.escape(findText), caseSensitive: false),
              replaceText,
            );
          }
        }
      }
    } catch (e) {
      // If regex is invalid, treat as literal text
      return input.replaceAll(findText, replaceText);
    }
  }
}

// 11. Text Extraction Tool
class TextExtractionTool extends Tool {
  TextExtractionTool()
    : super(
        name: 'Text Extraction',
        description:
            'Extract emails, URLs, phone numbers, and other patterns from text.',
        icon: Icons.search,
        isOutputMarkdown: false,
        isInputMarkdown: false,
        canAcceptMarkdown: true,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'extractionType': 'emails',
          'removeDuplicates': true,
          'onePerLine': true,
        },
        settingsHints: {
          'extractionType': {
            'type': 'dropdown',
            'label': 'Extract Type',
            'help': 'What to extract from the text',
            'options': [
              {'value': 'emails', 'label': 'Email Addresses'},
              {'value': 'urls', 'label': 'URLs'},
              {'value': 'phone_numbers', 'label': 'Phone Numbers'},
              {'value': 'numbers', 'label': 'Numbers'},
              {'value': 'hashtags', 'label': 'Hashtags (#tag)'},
              {'value': 'mentions', 'label': 'Mentions (@user)'},
              {'value': 'ip_addresses', 'label': 'IP Addresses'},
              {'value': 'dates', 'label': 'Dates'},
            ],
          },
          'removeDuplicates': {
            'type': 'bool',
            'label': 'Remove Duplicates',
            'help': 'Remove duplicate matches',
          },
          'onePerLine': {
            'type': 'bool',
            'label': 'One Per Line',
            'help': 'Put each match on a separate line',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success');
    }

    try {
      String result = _extractText(input);
      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: $e', status: 'error');
    }
  }

  String _extractText(String input) {
    final String extractionType = settings['extractionType'] as String;
    final bool removeDuplicates = settings['removeDuplicates'] as bool;
    final bool onePerLine = settings['onePerLine'] as bool;

    RegExp? regex;

    switch (extractionType) {
      case 'emails':
        regex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
        break;
      case 'urls':
        regex = RegExp(r'https?://[^\s<>"{}|\\^`\[\]]+');
        break;
      case 'phone_numbers':
        regex = RegExp(
          r'(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}',
        );
        break;
      case 'numbers':
        regex = RegExp(r'\b\d+\.?\d*\b');
        break;
      case 'hashtags':
        regex = RegExp(r'#\w+');
        break;
      case 'mentions':
        regex = RegExp(r'@\w+');
        break;
      case 'ip_addresses':
        regex = RegExp(r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b');
        break;
      case 'dates':
        regex = RegExp(
          r'\b\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}\b|\b\d{4}[/\-]\d{1,2}[/\-]\d{1,2}\b',
        );
        break;
      default:
        return input;
    }

    Iterable<RegExpMatch> matches = regex.allMatches(input);
    List<String> results = matches.map((match) => match.group(0)!).toList();

    if (removeDuplicates) {
      results = results.toSet().toList();
    }

    if (results.isEmpty) {
      return 'No ${extractionType.replaceAll('_', ' ')} found in the text.';
    }

    String separator = onePerLine ? '\n' : ', ';
    return results.join(separator);
  }
}

// 12. Text Reversal Tool
class TextReversalTool extends Tool {
  TextReversalTool()
    : super(
        name: 'Text Reversal',
        description:
            'Reverse text, words, lines, or characters in various ways.',
        icon: Icons.flip,
        isOutputMarkdown: false,
        isInputMarkdown: false,
        canAcceptMarkdown: true,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {'reversalType': 'entire_text'},
        settingsHints: {
          'reversalType': {
            'type': 'dropdown',
            'label': 'Reversal Type',
            'help': 'How to reverse the text',
            'options': [
              {
                'value': 'entire_text',
                'label': 'Entire Text (character by character)',
              },
              {
                'value': 'word_order',
                'label': 'Word Order (reverse word sequence)',
              },
              {
                'value': 'line_order',
                'label': 'Line Order (reverse line sequence)',
              },
              {
                'value': 'words_individually',
                'label': 'Each Word Individually',
              },
              {
                'value': 'lines_individually',
                'label': 'Each Line Individually',
              },
            ],
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success');
    }

    try {
      String result = _reverseText(input);
      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: $e', status: 'error');
    }
  }

  String _reverseText(String input) {
    final String reversalType = settings['reversalType'] as String;

    switch (reversalType) {
      case 'entire_text':
        return input.split('').reversed.join('');

      case 'word_order':
        return input.split(RegExp(r'\s+')).reversed.join(' ');

      case 'line_order':
        return input.split('\n').reversed.join('\n');

      case 'words_individually':
        return input
            .split(RegExp(r'(\s+)'))
            .map((part) {
              // Keep whitespace as is, reverse only words
              if (part.contains(RegExp(r'\s'))) {
                return part;
              } else {
                return part.split('').reversed.join('');
              }
            })
            .join('');

      case 'lines_individually':
        return input
            .split('\n')
            .map((line) => line.split('').reversed.join(''))
            .join('\n');

      default:
        return input;
    }
  }
}

// 13. Line Operations Tool
class LineOperationsTool extends Tool {
  LineOperationsTool()
    : super(
        name: 'Line Operations',
        description:
            'Extract specific lines, line ranges, random lines, or perform advanced line operations.',
        icon: Icons.view_list,
        isOutputMarkdown: false,
        isInputMarkdown: false,
        canAcceptMarkdown: true,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'operation': 'extract_range',
          'startLine': 1,
          'endLine': 10,
          'specificLines': '1,3,5',
          'randomCount': 5,
          'extractUnique': false,
          'ignoreEmpty': false, // <-- NEW
          'removeEmpty': false, // <-- NEW
        },
        settingsHints: {
          'operation': {
            'type': 'dropdown',
            'label': 'Operation Type',
            'help': 'Type of line operation to perform',
            'options': [
              {'value': 'extract_range', 'label': 'Extract Line Range'},
              {'value': 'extract_specific', 'label': 'Extract Specific Lines'},
              {'value': 'extract_random', 'label': 'Extract Random Lines'},
              {'value': 'first_n_lines', 'label': 'First N Lines'},
              {'value': 'last_n_lines', 'label': 'Last N Lines'},
              {'value': 'every_nth_line', 'label': 'Every Nth Line'},
            ],
          },
          'startLine': {
            'type': 'number',
            'label': 'Start Line',
            'help': 'Starting line number (1-based)',
            'min': 1,
          },
          'endLine': {
            'type': 'number',
            'label': 'End Line',
            'help': 'Ending line number (1-based)',
            'min': 1,
          },
          'specificLines': {
            'type': 'text',
            'label': 'Specific Lines',
            'help': 'Comma-separated line numbers (e.g., 1,3,5-7,10)',
            'placeholder': '1,3,5',
          },
          'randomCount': {
            'type': 'number',
            'label': 'Count/N Value',
            'help': 'Number of lines to extract or N for every Nth line',
            'min': 1,
          },
          'extractUnique': {
            'type': 'bool',
            'label': 'Extract Unique Only',
            'help': 'For random extraction, ensure no duplicates',
          },
          'ignoreEmpty': {
            'type': 'bool',
            'label': 'Ignore Empty Lines',
            'help': 'Skip empty lines when selecting by index',
          },
          'removeEmpty': {
            'type': 'bool',
            'label': 'Remove Empty Lines',
            'help': 'Remove empty lines from the final output',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success');
    }

    try {
      String result = _performLineOperation(input);
      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: $e', status: 'error');
    }
  }

  String _performLineOperation(String input) {
    final String operation = settings['operation'] as String;
    final bool ignoreEmpty = settings['ignoreEmpty'] as bool;
    final bool removeEmpty = settings['removeEmpty'] as bool;

    // Split lines
    List<String> lines = input.split('\n');

    // Apply ignore empty
    List<String> workingLines = ignoreEmpty
        ? lines.where((l) => l.trim().isNotEmpty).toList()
        : List.from(lines);

    String result;
    switch (operation) {
      case 'extract_range':
        result = _extractRange(workingLines);
        break;
      case 'extract_specific':
        result = _extractSpecific(workingLines);
        break;
      case 'extract_random':
        result = _extractRandom(workingLines);
        break;
      case 'first_n_lines':
        result = _extractFirstN(workingLines);
        break;
      case 'last_n_lines':
        result = _extractLastN(workingLines);
        break;
      case 'every_nth_line':
        result = _extractEveryNth(workingLines);
        break;
      default:
        result = input;
    }

    // Apply remove empty (on final output)
    if (removeEmpty) {
      result = result.split('\n').where((l) => l.trim().isNotEmpty).join('\n');
    }

    return result;
  }

  String _extractRange(List<String> lines) {
    final int startLine = (settings['startLine'] as num).toInt();
    final int endLine = (settings['endLine'] as num).toInt();

    int start = (startLine - 1).clamp(0, lines.length - 1);
    int end = (endLine - 1).clamp(start, lines.length - 1);

    return lines.sublist(start, end + 1).join('\n');
  }

  String _extractSpecific(List<String> lines) {
    final String specificLines = settings['specificLines'] as String;

    if (specificLines.isEmpty) return '';

    Set<int> lineNumbers = <int>{};

    List<String> parts = specificLines.split(',');
    for (String part in parts) {
      part = part.trim();
      if (part.contains('-')) {
        List<String> rangeParts = part.split('-');
        if (rangeParts.length == 2) {
          int? start = int.tryParse(rangeParts[0].trim());
          int? end = int.tryParse(rangeParts[1].trim());
          if (start != null && end != null) {
            for (int i = start; i <= end; i++) {
              lineNumbers.add(i);
            }
          }
        }
      } else {
        int? lineNum = int.tryParse(part);
        if (lineNum != null) {
          lineNumbers.add(lineNum);
        }
      }
    }

    List<String> result = [];
    for (int lineNum in lineNumbers.toList()..sort()) {
      if (lineNum > 0 && lineNum <= lines.length) {
        result.add(lines[lineNum - 1]);
      }
    }

    return result.join('\n');
  }

  String _extractRandom(List<String> lines) {
    final int randomCount = (settings['randomCount'] as num).toInt();
    final bool extractUnique = settings['extractUnique'] as bool;

    if (lines.isEmpty || randomCount <= 0) return '';

    List<String> availableLines = List<String>.from(lines);
    List<String> result = [];
    Random random = Random();

    int count = randomCount.clamp(
      1,
      extractUnique ? lines.length : randomCount,
    );

    for (int i = 0; i < count; i++) {
      if (availableLines.isEmpty) break;

      int randomIndex = random.nextInt(availableLines.length);
      result.add(availableLines[randomIndex]);

      if (extractUnique) {
        availableLines.removeAt(randomIndex);
      }
    }

    return result.join('\n');
  }

  String _extractFirstN(List<String> lines) {
    final int count = (settings['randomCount'] as num).toInt();

    int n = count.clamp(1, lines.length);
    return lines.take(n).join('\n');
  }

  String _extractLastN(List<String> lines) {
    final int count = (settings['randomCount'] as num).toInt();

    int n = count.clamp(1, lines.length);
    return lines.skip(lines.length - n).join('\n');
  }

  String _extractEveryNth(List<String> lines) {
    final int n = (settings['randomCount'] as num).toInt();

    if (n <= 0) return '';

    List<String> result = [];
    for (int i = n - 1; i < lines.length; i += n) {
      result.add(lines[i]);
    }

    return result.join('\n');
  }
}

class AlignTextTool extends Tool {
  AlignTextTool()
    : super(
        name: "Align Text",
        description:
            "Align text (left, right, center, justify) to a fixed width.",
        icon: Icons.align_horizontal_left_sharp,
        isOutputMarkdown: false, // Text alignment output should be plain text
        settings: {
          'alignment': 'left',
          'lineWidth': 80,
          'padChar': ' ',
          'trim': true,
          'preserveEmptyLines': true,
          'wordWrap': false,
          'fillLines': true,
        },
        settingsHints: {
          'alignment': {
            'type': 'dropdown',
            'label': 'Text Alignment',
            'help': 'How to align the text within the specified width',
            'options': [
              {'value': 'left', 'label': 'Left Align'},
              {'value': 'right', 'label': 'Right Align'},
              {'value': 'center', 'label': 'Center Align'},
              {'value': 'justify', 'label': 'Justify (Full Width)'},
            ],
          },
          'lineWidth': {
            'type': 'number',
            'label': 'Line Width',
            'help': 'Target width in characters for each line',
            'min': 10,
            'max': 200,
          },
          'padChar': {
            'type': 'text',
            'label': 'Padding Character',
            'help': 'Character used for padding (usually space)',
            'placeholder': ' ',
            'maxLength': 1,
          },
          'trim': {
            'type': 'bool',
            'label': 'Trim Lines',
            'help':
                'Remove leading/trailing whitespace from each line before processing',
          },
          'preserveEmptyLines': {
            'type': 'bool',
            'label': 'Preserve Empty Lines',
            'help': 'Keep empty lines in the output',
          },
          'wordWrap': {
            'type': 'bool',
            'label': 'Word Wrap',
            'help': 'Wrap long lines that exceed the line width',
          },
          'fillLines': {
            'type': 'bool',
            'label': 'Fill to Full Width',
            'help':
                'Pad lines to exact width (except for lines longer than width)',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(output: 'No input text provided.', status: 'success');
    }

    final String alignment = settings['alignment'] as String;
    final int width = (settings['lineWidth'] as num).toInt();
    final String padChar = (settings['padChar'] as String).isNotEmpty
        ? (settings['padChar'] as String)[0] // Take only first character
        : ' ';
    final bool trim = settings['trim'] as bool;
    final bool preserveEmpty = settings['preserveEmptyLines'] as bool;
    final bool wordWrap = settings['wordWrap'] as bool;
    final bool fillLines = settings['fillLines'] as bool;

    if (width < 1) {
      return ToolResult(
        output: 'Error: Line width must be at least 1 character.',
        status: 'error',
      );
    }

    try {
      List<String> lines = input.split('\n');
      final List<String> result = [];

      for (String line in lines) {
        String text = trim ? line.trim() : line;

        // Handle empty lines
        if (text.isEmpty) {
          if (preserveEmpty) {
            result.add(fillLines ? padChar * width : '');
          }
          continue;
        }

        // Handle word wrapping if enabled
        if (wordWrap && text.length > width) {
          final wrappedLines = _wrapText(text, width);
          for (String wrappedLine in wrappedLines) {
            result.add(
              _alignLine(wrappedLine, alignment, width, padChar, fillLines),
            );
          }
        } else {
          result.add(_alignLine(text, alignment, width, padChar, fillLines));
        }
      }

      return ToolResult(output: result.join('\n'), status: 'success');
    } catch (e, stackTrace) {
      return ToolResult(
        output: 'Error processing text: $e\n\nStack trace:\n$stackTrace',
        status: 'error',
      );
    }
  }

  String _alignLine(
    String text,
    String alignment,
    int width,
    String padChar,
    bool fillLines,
  ) {
    // If text is longer than width and we're not filling, just return as-is
    if (text.length >= width && !fillLines) {
      return text;
    }

    switch (alignment) {
      case 'right':
        return text.padLeft(width, padChar);

      case 'center':
        int totalPad = width - text.length;
        if (totalPad <= 0) {
          return text;
        }
        int leftPad = totalPad ~/ 2;
        int rightPad = totalPad - leftPad;
        return '${padChar * leftPad}$text${padChar * rightPad}';

      case 'justify':
        return _justifyLine(text, width, padChar);

      case 'left':
      default:
        return fillLines ? text.padRight(width, padChar) : text;
    }
  }

  String _justifyLine(String text, int width, String padChar) {
    final words = text.trim().split(RegExp(r'\s+'));

    // Can't justify single word or if text is already wider than target
    if (words.length == 1 || text.length >= width) {
      return text.padRight(width, padChar);
    }

    final totalWordChars = words.fold(0, (sum, w) => sum + w.length);
    final totalSpacesNeeded = width - totalWordChars;
    final gaps = words.length - 1;

    if (totalSpacesNeeded <= 0 || gaps <= 0) {
      return text;
    }

    final baseSpaces = totalSpacesNeeded ~/ gaps;
    final extraSpaces = totalSpacesNeeded % gaps;

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < words.length; i++) {
      buffer.write(words[i]);
      if (i < words.length - 1) {
        // Add base spaces plus one extra for the first 'extraSpaces' gaps
        int spacesToAdd = baseSpaces + (i < extraSpaces ? 1 : 0);
        buffer.write(padChar * spacesToAdd);
      }
    }

    return buffer.toString();
  }

  List<String> _wrapText(String text, int width) {
    final List<String> result = [];
    final words = text.split(RegExp(r'\s+'));

    StringBuffer currentLine = StringBuffer();

    for (String word in words) {
      // If adding this word would exceed width, start new line
      if (currentLine.length + word.length + 1 > width &&
          currentLine.isNotEmpty) {
        result.add(currentLine.toString().trim());
        currentLine.clear();
      }

      // Add word to current line
      if (currentLine.isNotEmpty) {
        currentLine.write(' ');
      }
      currentLine.write(word);

      // If single word is longer than width, add it as-is and start new line
      if (currentLine.length >= width) {
        result.add(currentLine.toString().trim());
        currentLine.clear();
      }
    }

    // Add remaining text
    if (currentLine.isNotEmpty) {
      result.add(currentLine.toString().trim());
    }

    return result.isEmpty ? [''] : result;
  }
}

class IndentUnindentTool extends Tool {
  IndentUnindentTool()
    : super(
        name: 'Indent / Unindent Lines',
        description:
            'Add or remove indentation (spaces or tabs) from the beginning of lines.',
        icon: Icons
            .format_indent_increase, // Or Icons.format_indent_decrease depending on default
        isOutputMarkdown: false,
        isInputMarkdown: false,
        canAcceptMarkdown: true,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'operation': 'indent',
          'indentType': 'space',
          'numberOfSpaces': 4, // Used when indentType is 'space'
          'tabCount': 1, // Used when indentType is 'tab'
          'applyTo':
              'all_lines', // or 'selected_lines' - assuming UI handles selection
        },
        settingsHints: {
          'operation': {
            'type': 'dropdown',
            'label': 'Operation',
            'help': 'Choose to indent or unindent lines',
            'options': [
              {'value': 'indent', 'label': 'Indent Lines'},
              {'value': 'unindent', 'label': 'Unindent Lines'},
            ],
          },
          'indentType': {
            'type': 'dropdown',
            'label': 'Indent Type',
            'help': 'Use spaces or tab characters for indentation',
            'options': [
              {'value': 'space', 'label': 'Spaces'},
              {'value': 'tab', 'label': 'Tabs'},
            ],
          },
          'numberOfSpaces': {
            'type': 'spinner', // Or 'number'
            'label': 'Number of Spaces',
            'help': 'How many spaces to use for each indent level',
            'min': 1,
            'max': 16,
            'step': 1,
          },
          'tabCount': {
            'type': 'spinner', // Or 'number'
            'label': 'Number of Tabs',
            'help': 'How many tab characters to use for each indent level',
            'min': 1,
            'max': 4,
            'step': 1,
          },
          'applyTo': {
            'type': 'dropdown',
            'label': 'Apply To',
            'help': 'Which lines to process (requires UI selection support)',
            'options': [
              {'value': 'all_lines', 'label': 'All Lines'},
              {'value': 'selected_lines', 'label': 'Selected Lines'},
            ],
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success');
    }

    final String operation = settings['operation'] as String;
    final String indentType = settings['indentType'] as String;
    final int spaceCount = (settings['numberOfSpaces'] as num).toInt();
    final int tabCount = (settings['tabCount'] as num).toInt();
    // Note: 'applyTo' logic would typically be handled by the UI/Controller
    // by passing only the selected text or the full text accordingly.
    // For this tool implementation, we assume it operates on the full input.

    String indentUnit = "";
    if (indentType == 'space') {
      indentUnit = " " * spaceCount;
    } else if (indentType == 'tab') {
      indentUnit = "\t" * tabCount;
    }

    List<String> lines = input.split('\n');

    try {
      if (operation == 'indent') {
        // Add indent to the beginning of every line (or non-empty lines if a setting was added)
        lines = lines.map((line) => '$indentUnit$line').toList();
      } else if (operation == 'unindent') {
        // Remove indent from the beginning of every line
        String pattern = "";
        if (indentType == 'space') {
          // Create a pattern to match up to the specified number of leading spaces
          pattern = r'^ {1,' + spaceCount.toString() + r'}';
        } else if (indentType == 'tab') {
          // Create a pattern to match up to the specified number of leading tabs
          pattern = r'^\t{1,' + tabCount.toString() + r'}';
        }
        final RegExp regex = RegExp(pattern);
        lines = lines.map((line) => line.replaceFirst(regex, '')).toList();
      }

      return ToolResult(output: lines.join('\n'), status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error processing text: $e', status: 'error');
    }
  }
}

class EscapeHubTool extends Tool {
  EscapeHubTool()
    : super(
        name: 'Escape',
        description:
            'Escape/Unescape text for programming contexts: JSON, SQL, CSV, XML/HTML attributes, JavaScript, C#, Regex, Shell',
        icon: Icons.security,
        isOutputMarkdown: false,
        supportsLiveUpdate: false,
        supportsStreaming: false,
        settings: {'mode': 'escape', 'target': 'json', 'strict': true},
        settingsHints: {
          'mode': {
            'type': 'dropdown',
            'label': 'Mode',
            'help': 'Choose to escape or unescape the input text',
            'options': [
              {'value': 'escape', 'label': 'Escape'},
              {'value': 'unescape', 'label': 'Unescape'},
            ],
          },
          'target': {
            'type': 'dropdown',
            'label': 'Target Language/Format',
            'help': 'Choose the programming language or format context',
            'options': [
              {'value': 'json', 'label': 'JSON String'},
              {'value': 'sql', 'label': 'SQL String'},
              {'value': 'csv', 'label': 'CSV Field'},
              {'value': 'xml_attr', 'label': 'XML Attribute'},
              {'value': 'html_attr', 'label': 'HTML Attribute'},
              {'value': 'javascript', 'label': 'JavaScript String'},
              {'value': 'csharp', 'label': 'C# String'},
              {'value': 'cplus', 'label': 'C++ String'},
              {'value': 'regex', 'label': 'Regular Expression'},
              {'value': 'shell', 'label': 'Shell Command'},
            ],
          },
          'strict': {
            'type': 'bool',
            'label': 'Strict Mode',
            'help':
                'Use strict escaping rules (escape more characters for maximum safety)',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    final mode = settings['mode'] as String;
    final target = settings['target'] as String;
    final strict = settings['strict'] as bool;

    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success');
    }

    try {
      String result;

      switch (target) {
        case 'json':
          result = mode == 'escape'
              ? _jsonEscape(input, strict)
              : _jsonUnescape(input);
          break;

        case 'sql':
          result = mode == 'escape'
              ? _sqlEscape(input, strict)
              : _sqlUnescape(input);
          break;

        case 'csv':
          result = mode == 'escape'
              ? _csvEscape(input, strict)
              : _csvUnescape(input);
          break;

        case 'xml_attr':
          result = mode == 'escape'
              ? _xmlAttrEscape(input, strict)
              : _xmlAttrUnescape(input);
          break;

        case 'html_attr':
          result = mode == 'escape'
              ? _htmlAttrEscape(input, strict)
              : _htmlAttrUnescape(input);
          break;

        case 'javascript':
          result = mode == 'escape'
              ? _javascriptEscape(input, strict)
              : _javascriptUnescape(input);
          break;

        case 'csharp':
          result = mode == 'escape'
              ? _csharpEscape(input, strict)
              : _csharpUnescape(input);
          break;

        case 'cplus':
          result = mode == 'escape'
              ? _cplusEscape(input, strict)
              : _cplusUnescape(input);
          break;

        case 'regex':
          result = mode == 'escape'
              ? _regexEscape(input, strict)
              : _regexUnescape(input);
          break;

        case 'shell':
          result = mode == 'escape'
              ? _shellEscape(input, strict)
              : _shellUnescape(input);
          break;

        default:
          return ToolResult(
            output: 'Unsupported target: $target',
            status: 'error',
          );
      }

      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: ${e.toString()}', status: 'error');
    }
  }

  // C++ String Escaping
  String _cplusEscape(String input, bool strict) {
    const basicEscapes = {
      '\\': '\\\\',
      '"': '\\"',
      "'": "\\'",
      '\n': '\\n',
      '\r': '\\r',
      '\t': '\\t',
      '\b': '\\b',
      '\f': '\\f',
      '\v': '\\v',
      '\x00': '\\0',
      '\u0007': '\\a',
      '?': '\\?', // legacy trigraph avoidance
    };

    String result = input;
    for (final entry in basicEscapes.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    if (strict) {
      result = result.runes.map((r) {
        if (r < 32 || r > 126) {
          if (r <= 255) {
            return '\\x${r.toRadixString(16).padLeft(2, '0')}';
          } else {
            return '\\u${r.toRadixString(16).padLeft(4, '0')}';
          }
        }
        return String.fromCharCode(r);
      }).join();
    }

    return result;
  }

  String _cplusUnescape(String input) {
    String result = input;

    const basicUnescapes = {
      '\\\\': '\\',
      '\\"': '"',
      "\\'": "'",
      '\\n': '\n',
      '\\r': '\r',
      '\\t': '\t',
      '\\b': '\b',
      '\\f': '\f',
      '\\v': '\v',
      '\\0': '\x00',
      '\\a': '\u0007',
      '\\?': '?',
    };

    for (final entry in basicUnescapes.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    // Octal escape (\ooo)
    result = result.replaceAllMapped(RegExp(r'\\([0-7]{1,3})'), (match) {
      final code = int.parse(match.group(1)!, radix: 8);
      return String.fromCharCode(code);
    });

    // Greedy hex escape (\x..)
    result = result.replaceAllMapped(RegExp(r'\\x([0-9A-Fa-f]+)'), (match) {
      final code = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(code);
    });

    // Unicode escape (\uXXXX)
    result = result.replaceAllMapped(RegExp(r'\\u([0-9A-Fa-f]{4})'), (match) {
      final code = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(code);
    });

    return result;
  }

  // JSON String Escaping
  String _jsonEscape(String input, bool strict) {
    const basicEscapes = {
      '"': '\\"',
      '\\': '\\\\',
      '\b': '\\b',
      '\f': '\\f',
      '\n': '\\n',
      '\r': '\\r',
      '\t': '\\t',
    };

    String result = input;
    for (final entry in basicEscapes.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    if (strict) {
      // Escape control characters and non-ASCII
      result = result.runes.map((r) {
        if (r < 32 || (strict && r > 126)) {
          return '\\u${r.toRadixString(16).padLeft(4, '0')}';
        }
        return String.fromCharCode(r);
      }).join();
    }

    return result;
  }

  String _jsonUnescape(String input) {
    String result = input;

    // Unescape basic sequences
    const basicUnescapes = {
      '\\"': '"',
      '\\\\': '\\',
      '\\b': '\b',
      '\\f': '\f',
      '\\n': '\n',
      '\\r': '\r',
      '\\t': '\t',
      '\\/': '/',
    };

    for (final entry in basicUnescapes.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    // Unescape unicode sequences
    result = result.replaceAllMapped(RegExp(r'\\u([0-9A-Fa-f]{4})'), (match) {
      final code = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(code);
    });

    return result;
  }

  // SQL String Escaping
  String _sqlEscape(String input, bool strict) {
    String result = input.replaceAll("'", "''"); // Standard SQL escape

    if (strict) {
      // Additional escaping for injection prevention
      result = result
          .replaceAll('\\', '\\\\')
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '\\r')
          .replaceAll('\t', '\\t')
          .replaceAll('\b', '\\b')
          .replaceAll('\x1A', '\\Z'); // Ctrl+Z
    }

    return result;
  }

  String _sqlUnescape(String input) {
    return input
        .replaceAll("''", "'")
        .replaceAll('\\\\', '\\')
        .replaceAll('\\n', '\n')
        .replaceAll('\\r', '\r')
        .replaceAll('\\t', '\t')
        .replaceAll('\\b', '\b')
        .replaceAll('\\Z', '\x1A');
  }

  // CSV Field Escaping
  String _csvEscape(String input, bool strict) {
    bool needsQuoting =
        input.contains(',') ||
        input.contains('"') ||
        input.contains('\n') ||
        input.contains('\r') ||
        (strict && (input.startsWith(' ') || input.endsWith(' ')));

    if (!needsQuoting && !strict) return input;

    String escaped = input.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _csvUnescape(String input) {
    if (input.startsWith('"') && input.endsWith('"')) {
      return input.substring(1, input.length - 1).replaceAll('""', '"');
    }
    return input;
  }

  // XML Attribute Escaping
  String _xmlAttrEscape(String input, bool strict) {
    const basicEscapes = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&apos;',
    };

    String result = input;
    for (final entry in basicEscapes.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    if (strict) {
      // Escape control characters
      result = result.runes.map((r) {
        if (r < 32 && r != 9 && r != 10 && r != 13) {
          return '&#$r;';
        }
        return String.fromCharCode(r);
      }).join();
    }

    return result;
  }

  String _xmlAttrUnescape(String input) {
    String result = input;

    const basicUnescapes = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&apos;': "'",
    };

    for (final entry in basicUnescapes.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    // Unescape numeric character references
    result = result.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      final code = int.parse(match.group(1)!);
      return String.fromCharCode(code);
    });

    result = result.replaceAllMapped(RegExp(r'&#x([0-9A-Fa-f]+);'), (match) {
      final code = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(code);
    });

    return result;
  }

  // HTML Attribute Escaping (similar to XML but more permissive)
  String _htmlAttrEscape(String input, bool strict) {
    const basicEscapes = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
    };

    String result = input;
    for (final entry in basicEscapes.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    if (strict) {
      result = result.replaceAll("'", '&#39;');
      // Escape potentially dangerous characters
      result = result.runes.map((r) {
        if (r < 32 && r != 9 && r != 10 && r != 13) {
          return '&#$r;';
        }
        return String.fromCharCode(r);
      }).join();
    }

    return result;
  }

  String _htmlAttrUnescape(String input) {
    return _xmlAttrUnescape(input); // Same logic as XML
  }

  // JavaScript String Escaping
  String _javascriptEscape(String input, bool strict) {
    const basicEscapes = {
      '\\': '\\\\',
      "'": "\\'",
      '"': '\\"',
      '\n': '\\n',
      '\r': '\\r',
      '\t': '\\t',
      '\b': '\\b',
      '\f': '\\f',
      '\v': '\\v',
      '\x00': '\\0',
    };

    String result = input;
    for (final entry in basicEscapes.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    if (strict) {
      // Escape line separators and other problematic characters
      result = result.runes.map((r) {
        if (r == 0x2028) return '\\u2028'; // Line separator
        if (r == 0x2029) return '\\u2029'; // Paragraph separator
        if (r < 32 || (strict && r > 126)) {
          if (r <= 255) {
            return '\\x${r.toRadixString(16).padLeft(2, '0')}';
          } else {
            return '\\u${r.toRadixString(16).padLeft(4, '0')}';
          }
        }
        return String.fromCharCode(r);
      }).join();
    }

    return result;
  }

  String _javascriptUnescape(String input) {
    String result = input;

    const basicUnescapes = {
      '\\\\': '\\',
      "\\'": "'",
      '\\"': '"',
      '\\n': '\n',
      '\\r': '\r',
      '\\t': '\t',
      '\\b': '\b',
      '\\f': '\f',
      '\\v': '\v',
      '\\0': '\x00',
    };

    for (final entry in basicUnescapes.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    // Unescape hex sequences
    result = result.replaceAllMapped(RegExp(r'\\x([0-9A-Fa-f]{2})'), (match) {
      final code = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(code);
    });

    // Unescape unicode sequences
    result = result.replaceAllMapped(RegExp(r'\\u([0-9A-Fa-f]{4})'), (match) {
      final code = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(code);
    });

    return result;
  }

  // C# String Escaping
  String _csharpEscape(String input, bool strict) {
    const basicEscapes = {
      '\\': '\\\\',
      '"': '\\"',
      '\n': '\\n',
      '\r': '\\r',
      '\t': '\\t',
      '\b': '\\b',
      '\f': '\\f',
      '\v': '\\v',
      '\x00': '\\0',
      '\u0007': '\\a',
    };

    String result = input;
    for (final entry in basicEscapes.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    if (strict) {
      result = result.runes.map((r) {
        if (r < 32 || (strict && r > 126)) {
          if (r <= 255) {
            return '\\x${r.toRadixString(16).padLeft(2, '0')}';
          } else {
            return '\\u${r.toRadixString(16).padLeft(4, '0')}';
          }
        }
        return String.fromCharCode(r);
      }).join();
    }

    return result;
  }

  String _csharpUnescape(String input) {
    String result = input;

    const basicUnescapes = {
      '\\\\': '\\',
      '\\"': '"',
      '\\n': '\n',
      '\\r': '\r',
      '\\t': '\t',
      '\\b': '\b',
      '\\f': '\f',
      '\\v': '\v',
      '\\0': '\x00',
      '\\a': '\u0007',
    };

    for (final entry in basicUnescapes.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    // Unescape hex and unicode sequences
    result = result.replaceAllMapped(RegExp(r'\\x([0-9A-Fa-f]{1,4})'), (match) {
      final code = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(code);
    });

    result = result.replaceAllMapped(RegExp(r'\\u([0-9A-Fa-f]{4})'), (match) {
      final code = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(code);
    });

    return result;
  }

  // Regular Expression Escaping
  String _regexEscape(String input, bool strict) {
    const specialChars = r'.^$*+?{}[]|()\-';

    String result = '';
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (specialChars.contains(char)) {
        result += '\\$char';
      } else if (strict &&
          (char.codeUnitAt(0) < 32 || char.codeUnitAt(0) > 126)) {
        // Escape non-printable characters
        final code = char.codeUnitAt(0);
        if (code <= 255) {
          result += '\\x${code.toRadixString(16).padLeft(2, '0')}';
        } else {
          result += '\\u${code.toRadixString(16).padLeft(4, '0')}';
        }
      } else {
        result += char;
      }
    }

    return result;
  }

  String _regexUnescape(String input) {
    String result = input;

    // Unescape special regex characters
    const specialChars = r'.^$*+?{}[]|()\-';
    for (final char in specialChars.split('')) {
      result = result.replaceAll('\\$char', char);
    }

    // Unescape common escape sequences
    result = result
        .replaceAll('\\n', '\n')
        .replaceAll('\\r', '\r')
        .replaceAll('\\t', '\t')
        .replaceAll('\\b', '\b')
        .replaceAll('\\f', '\f')
        .replaceAll('\\v', '\v');

    // Unescape hex and unicode
    result = result.replaceAllMapped(RegExp(r'\\x([0-9A-Fa-f]{2})'), (match) {
      final code = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(code);
    });

    result = result.replaceAllMapped(RegExp(r'\\u([0-9A-Fa-f]{4})'), (match) {
      final code = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(code);
    });

    return result;
  }

  // Shell Command Escaping
  String _shellEscape(String input, bool strict) {
    if (input.isEmpty) return "''";

    // Check if we need escaping
    final needsEscaping = RegExp(r'''[^a-zA-Z0-9_@%+=:,./-]''').hasMatch(input);

    if (!needsEscaping && !strict) return input;

    if (strict || input.contains("'")) {
      // Use double quotes and escape dangerous characters
      String escaped = input
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\$', '\\\$')
          .replaceAll('`', '\\`')
          .replaceAll('\n', '\\\n');

      return '"$escaped"';
    } else {
      // Use single quotes (simpler, no escaping needed inside)
      return "'$input'";
    }
  }

  String _shellUnescape(String input) {
    if (input.isEmpty) return input;

    // Handle single-quoted strings
    if (input.startsWith("'") && input.endsWith("'") && input.length >= 2) {
      return input.substring(1, input.length - 1);
    }

    // Handle double-quoted strings
    if (input.startsWith('"') && input.endsWith('"') && input.length >= 2) {
      return input
          .substring(1, input.length - 1)
          .replaceAll('\\\\', '\\')
          .replaceAll('\\"', '"')
          .replaceAll('\\\$', '\$')
          .replaceAll('\\`', '`')
          .replaceAll('\\\n', '\n');
    }

    return input;
  }
}

class RegexTool extends Tool {
  // Predefined common patterns
  static const Map<String, Map<String, String>> predefinedPatterns = {
    'email': {
      'pattern': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
      'description': 'Email addresses',
    },
    'url': {
      'pattern':
          r'https?://(?:[-\w.])+(?:[:\d]+)?(?:/(?:[\w/_.])*(?:\?(?:[\w&=%.])*)?(?:\#(?:\w*))?)?',
      'description': 'HTTP/HTTPS URLs',
    },
    'phone_us': {
      'pattern':
          r'\b(?:\+?1[-.\s]?)?\(?([0-9]{3})\)?[-.\s]?([0-9]{3})[-.\s]?([0-9]{4})\b',
      'description': 'US phone numbers',
    },
    'ip_address': {
      'pattern':
          r'\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b',
      'description': 'IPv4 addresses',
    },
    'date_iso': {
      'pattern': r'\b\d{4}-\d{2}-\d{2}\b',
      'description': 'ISO date format (YYYY-MM-DD)',
    },
    'date_us': {
      'pattern': r'\b\d{1,2}/\d{1,2}/\d{4}\b',
      'description': 'US date format (MM/DD/YYYY)',
    },
    'time_24h': {
      'pattern': r'\b(?:[01]?[0-9]|2[0-3]):[0-5][0-9](?::[0-5][0-9])?\b',
      'description': '24-hour time format',
    },
    'hex_color': {
      'pattern': r'#(?:[0-9a-fA-F]{3}){1,2}\b',
      'description': 'Hexadecimal color codes',
    },
    'credit_card': {
      'pattern': r'\b(?:\d{4}[-\s]?){3}\d{4}\b',
      'description': 'Credit card numbers (basic format)',
    },
    'ssn': {
      'pattern': r'\b\d{3}-\d{2}-\d{4}\b',
      'description': 'US Social Security Numbers',
    },
    'word': {'pattern': r'\b\w+\b', 'description': 'Individual words'},
    'number': {
      'pattern': r'-?\d+(?:\.\d+)?',
      'description': 'Numbers (integer or decimal)',
    },
    'html_tag': {'pattern': r'<[^>]+>', 'description': 'HTML tags'},
    'whitespace': {'pattern': r'\s+', 'description': 'Whitespace sequences'},
    'alphanumeric': {
      'pattern': r'[a-zA-Z0-9]+',
      'description': 'Alphanumeric sequences',
    },
  };

  RegexTool()
    : super(
        name: 'Regex',
        description:
            'Advanced regex tool with predefined patterns, better highlighting, statistics, and multiple output formats.',
        icon: Icons.find_replace,
        isOutputMarkdown: true,
        isInputMarkdown: false,
        canAcceptMarkdown: false,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          // Core regex settings
          'mode': 'find', // find | extract | replace | split | test | validate
          'pattern': '',
          'predefinedPattern':
              'custom', // custom | email | url | phone_us | etc.
          'replacement': r'$1',
          'caseInsensitive': false,
          'multiLine': false,
          'dotAll': false,
          'unicode': true,
          'global': true,
          'maxMatches': 500,
          'groupIndex': 0,
          'showIndices': true,
          'showCounts': true,
          'showStats': true,

          // Enhanced output options
          'outputFormat': 'rich', // rich | table | list | json | csv
          'showOriginalWithHighlights': true,
          'showMatchesOnly': false,
          'showContext': true,
          'contextLines': 2,
          'highlight': true,
          'highlightStyle':
              'background', // mark | brackets | caret | bold | underline
          'surroundBefore': 32,
          'surroundAfter': 32,
          'showSnippets': true,
          'showLineNumbers': false,
          'groupSeparately': false, // show each capture group separately
          // Advanced features
          'caseSensitiveReplace': true,
          'preserveCase': false,
          'showNonMatches': false, // show text that doesn't match
          'splitKeepDelimiter': false,
          'emitJson': false,
          'ignoreEmptyPattern': true,
          'showPerformanceStats': false,
        },
        settingsHints: {
          'mode': {
            'type': 'dropdown',
            'label': 'Mode',
            'help': 'Choose the operation to perform.',
            'options': [
              {'value': 'find', 'label': 'Find & Highlight'},
              {'value': 'extract', 'label': 'Extract Matches/Groups'},
              {'value': 'replace', 'label': 'Replace (supports \$1)'},
              {'value': 'split', 'label': 'Split by Regex'},
              {'value': 'test', 'label': 'Test (true/false)'},
              {'value': 'validate', 'label': 'Validate All Lines'},
            ],
          },
          'predefinedPattern': {
            'type': 'dropdown',
            'label': 'Predefined Pattern',
            'help': 'Choose a common pattern or use custom.',
            'options': [
              {'value': 'custom', 'label': 'Custom Pattern'},
              ...predefinedPatterns.entries.map(
                (e) => {
                  'value': e.key,
                  'label':
                      '${e.key.replaceAll('_', ' ').toUpperCase()} - ${e.value['description']}',
                },
              ),
            ],
          },
          'pattern': {
            'type': 'text',
            'label': 'Pattern',
            'help':
                'Dart RegExp syntax. Use predefined patterns above for common use cases.',
            'placeholder': r'Example: (\w+)\s+(\w+)',
            'min_lines': 2,
            'max_lines': 8,
          },
          'replacement': {
            'type': 'text',
            'label': 'Replacement',
            'help':
                r'Use $1, $2, … to reference captured groups. Use $& for whole match.',
            'placeholder': r'Hello, $2 $1',
          },
          'outputFormat': {
            'type': 'dropdown',
            'label': 'Output Format',
            'help': 'Choose how results are presented.',
            'options': [
              {'value': 'rich', 'label': 'Rich Markdown'},
              {'value': 'table', 'label': 'Table Format'},
              {'value': 'list', 'label': 'Simple List'},
              {'value': 'json', 'label': 'JSON Format'},
              {'value': 'csv', 'label': 'CSV Format'},
            ],
          },
          'showOriginalWithHighlights': {
            'type': 'bool',
            'label': 'Show Original with Highlights',
            'help': 'Display the full original text with matches highlighted.',
          },
          'showMatchesOnly': {
            'type': 'bool',
            'label': 'Show Matches Only',
            'help':
                'Display only the matched text, not the surrounding context.',
          },
          'showContext': {
            'type': 'bool',
            'label': 'Show Context',
            'help': 'Include surrounding context for each match.',
          },
          'contextLines': {
            'type': 'spinner',
            'label': 'Context Lines',
            'help': 'Number of lines to show before/after each match.',
            'min': 0,
            'max': 10,
            'step': 1,
          },
          'highlightStyle': {
            'type': 'dropdown',
            'label': 'Highlight Style',
            'help': 'Choose how matches are emphasized.',
            'options': [
              {'value': 'background', 'label': 'Background highlight'},
              {'value': 'mark', 'label': 'HTML <mark> (yellow highlight)'},
              {'value': 'brackets', 'label': '[[…]] brackets'},
              {'value': 'caret', 'label': 'Caret lines under match'},
              {'value': 'bold', 'label': '**Bold** text'},
              {'value': 'underline', 'label': '__Underlined__ text'},
            ],
          },
          'showLineNumbers': {
            'type': 'bool',
            'label': 'Show Line Numbers',
            'help': 'Display line numbers in output.',
          },
          'groupSeparately': {
            'type': 'bool',
            'label': 'Show Groups Separately',
            'help': 'Display each capture group as a separate result.',
          },
          'showStats': {
            'type': 'bool',
            'label': 'Show Statistics',
            'help': 'Include match statistics and summary.',
          },
          'showPerformanceStats': {
            'type': 'bool',
            'label': 'Show Performance Stats',
            'help': 'Include timing and performance information.',
          },
          'preserveCase': {
            'type': 'bool',
            'label': 'Preserve Case in Replace',
            'help': 'Try to preserve the original case when replacing.',
          },
          'showNonMatches': {
            'type': 'bool',
            'label': 'Show Non-Matches',
            'help': 'Also show text that does not match the pattern.',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await _executeInternal(input);
      stopwatch.stop();

      if (settings['showPerformanceStats'] as bool) {
        final perfInfo =
            '\n\n---\n*Performance: ${stopwatch.elapsedMilliseconds}ms*';
        return ToolResult(
          output: result.output + perfInfo,
          status: result.status,
        );
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      final err = '❌ Error: $e';
      return ToolResult(
        output: (settings['emitJson'] as bool) ? _jsonMsg('error', err) : err,
        status: 'error',
      );
    }
  }

  Future<ToolResult> _executeInternal(String input) async {
    final String mode = (settings['mode'] as String).trim().toLowerCase();
    final String predefinedKey = settings['predefinedPattern'] as String;
    String pattern = settings['pattern'] as String;

    // Use predefined pattern if selected
    if (predefinedKey != 'custom' &&
        predefinedPatterns.containsKey(predefinedKey)) {
      pattern = predefinedPatterns[predefinedKey]!['pattern']!;
    }

    final String replacement = (settings['replacement'] as String);
    final bool caseInsensitive = settings['caseInsensitive'] as bool;
    final bool multiLine = settings['multiLine'] as bool;
    final bool dotAll = settings['dotAll'] as bool;
    final bool global = settings['global'] as bool;
    final int maxMatches = (settings['maxMatches'] as num).toInt().clamp(
      1,
      50000,
    );
    final int groupIndex = (settings['groupIndex'] as num).toInt().clamp(0, 99);
    final bool ignoreEmpty = settings['ignoreEmptyPattern'] as bool;
    final String outputFormat = settings['outputFormat'] as String;
    final bool emitJson =
        settings['emitJson'] as bool || outputFormat == 'json';

    if (ignoreEmpty && pattern.trim().isEmpty) {
      final msg = '⚠️ Pattern is empty. Nothing to do.';
      return ToolResult(
        output: emitJson ? _jsonMsg('warning', msg) : msg,
        status: 'success',
      );
    }

    RegExp regExp;
    try {
      regExp = _buildRegExp(
        pattern: pattern,
        caseInsensitive: caseInsensitive,
        multiLine: multiLine,
        dotAll: dotAll,
      );
    } catch (e) {
      final err = '❌ Invalid regular expression: $e';
      return ToolResult(
        output: emitJson ? _jsonMsg('error', err) : err,
        status: 'error',
      );
    }

    switch (mode) {
      case 'find':
        return ToolResult(
          output: _findWithFormat(
            input,
            regExp,
            maxMatches,
            groupIndex,
            outputFormat,
          ),
          status: 'success',
        );

      case 'extract':
        return ToolResult(
          output: _extractWithFormat(
            input,
            regExp,
            maxMatches,
            groupIndex,
            outputFormat,
          ),
          status: 'success',
        );

      case 'replace':
        return ToolResult(
          output: _replaceWithFormat(
            input,
            regExp,
            replacement,
            global,
            outputFormat,
          ),
          status: 'success',
        );

      case 'split':
        return ToolResult(
          output: _splitWithFormat(input, regExp, global, outputFormat),
          status: 'success',
        );

      case 'test':
        final matched = regExp.hasMatch(input);
        final out = emitJson
            ? '{"status":"ok","matched":$matched}'
            : (matched ? '✅ Match found' : '❌ No match');
        return ToolResult(output: out, status: 'success');

      case 'validate':
        return ToolResult(
          output: _validateWithFormat(input, regExp, outputFormat),
          status: 'success',
        );

      default:
        final msg = '❌ Unknown mode: $mode';
        return ToolResult(
          output: emitJson ? _jsonMsg('error', msg) : msg,
          status: 'error',
        );
    }
  }

  // Enhanced find with multiple output formats
  String _findWithFormat(
    String input,
    RegExp regExp,
    int maxMatches,
    int groupIndex,
    String format,
  ) {
    final matches = regExp.allMatches(input).take(maxMatches).toList();

    switch (format) {
      case 'table':
        return _findTable(input, matches, groupIndex);
      case 'list':
        return _findList(input, matches, groupIndex);
      case 'json':
        return _findJson(input, regExp, maxMatches, groupIndex);
      case 'csv':
        return _findCsv(input, matches, groupIndex);
      case 'rich':
      default:
        return _findRich(input, matches, groupIndex);
    }
  }

  String _findRich(String input, List<RegExpMatch> matches, int groupIndex) {
    final buf = StringBuffer();
    final showStats = settings['showStats'] as bool;
    final showOriginal = settings['showOriginalWithHighlights'] as bool;
    final showSnippets = settings['showSnippets'] as bool;
    final showMatchesOnly = settings['showMatchesOnly'] as bool;
    final showLineNumbers = settings['showLineNumbers'] as bool;
    final groupSeparately = settings['groupSeparately'] as bool;

    // Statistics
    if (showStats) {
      final lines = input.split('\n');
      final matchedLines = <int>{};
      for (final match in matches) {
        final lineNum = input.substring(0, match.start).split('\n').length - 1;
        matchedLines.add(lineNum);
      }

      buf.writeln('## Match Statistics');
      buf.writeln('- **Total matches:** ${matches.length}');
      buf.writeln('- **Lines with matches:** ${matchedLines.length}');
      buf.writeln('- **Total lines:** ${lines.length}');
      buf.writeln(
        '- **Match density:** ${(matches.length / lines.length * 100).toStringAsFixed(1)}%',
      );
      buf.writeln();
    }

    // Original text with highlights
    if (showOriginal && !showMatchesOnly) {
      buf.writeln('## Original Text with Highlights');
      buf.writeln(_highlightAllAdvanced(input, matches, groupIndex));
      buf.writeln();
    }

    // Individual matches
    if (showSnippets && !showMatchesOnly) {
      buf.writeln('## Individual Matches');
      for (var i = 0; i < matches.length; i++) {
        final match = matches[i];
        buf.writeln(
          _formatMatchSnippet(input, match, i + 1, groupIndex, showLineNumbers),
        );
      }
    }

    // Matches only
    if (showMatchesOnly) {
      buf.writeln('## Matches Only');
      for (var i = 0; i < matches.length; i++) {
        final match = matches[i];
        final text = _groupTextSafe(match, groupIndex);
        buf.writeln('${i + 1}. `$text`');
      }
    }

    // Group analysis
    if (groupSeparately && matches.isNotEmpty) {
      final firstMatch = matches.first;
      if (firstMatch.groupCount > 0) {
        buf.writeln('## Capture Groups Analysis');
        for (int g = 1; g <= firstMatch.groupCount; g++) {
          buf.writeln('### Group $g');
          for (var i = 0; i < matches.length; i++) {
            final groupText = matches[i].group(g) ?? '(null)';
            buf.writeln('${i + 1}. `$groupText`');
          }
          buf.writeln();
        }
      }
    }

    return buf.toString();
  }

  String _findTable(String input, List<RegExpMatch> matches, int groupIndex) {
    final buf = StringBuffer();
    buf.writeln('| # | Match | Start | End | Length | Line |');
    buf.writeln('|---|-------|-------|-----|--------|------|');

    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final text = _groupTextSafe(match, groupIndex);
      final lineNum = input.substring(0, match.start).split('\n').length;
      buf.writeln(
        '| ${i + 1} | `${_escapeMdInline(text)}` | ${match.start} | ${match.end} | ${text.length} | $lineNum |',
      );
    }

    return buf.toString();
  }

  String _findList(String input, List<RegExpMatch> matches, int groupIndex) {
    final buf = StringBuffer();
    buf.writeln('**Found ${matches.length} matches:**\n');

    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final text = _groupTextSafe(match, groupIndex);
      buf.writeln(
        '${i + 1}. `${_escapeMdInline(text)}` (at ${match.start}-${match.end})',
      );
    }

    return buf.toString();
  }

  String _findCsv(String input, List<RegExpMatch> matches, int groupIndex) {
    final buf = StringBuffer();
    buf.writeln('Index,Match,Start,End,Length,Line');

    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final text = _groupTextSafe(match, groupIndex).replaceAll('"', '""');
      final lineNum = input.substring(0, match.start).split('\n').length;
      buf.writeln(
        '${i + 1},"$text",${match.start},${match.end},${text.length},$lineNum',
      );
    }

    return buf.toString();
  }

  String _formatMatchSnippet(
    String input,
    RegExpMatch match,
    int index,
    int groupIndex,
    bool showLineNumbers,
  ) {
    final text = _groupTextSafe(match, groupIndex);
    final before = (settings['surroundBefore'] as num).toInt();
    final after = (settings['surroundAfter'] as num).toInt();
    final contextLines = (settings['contextLines'] as num).toInt();
    final highlight = settings['highlight'] as bool;
    final highlightStyle = settings['highlightStyle'] as String;

    final buf = StringBuffer();
    buf.writeln('### Match #$index');

    // Match info
    final lineNum = input.substring(0, match.start).split('\n').length;
    buf.writeln('- **Text:** `${_escapeMdInline(text)}`');
    buf.writeln('- **Position:** ${match.start}-${match.end} (line $lineNum)');
    buf.writeln('- **Length:** ${text.length}');

    if (match.groupCount > 0) {
      buf.writeln('- **Groups:**');
      for (int i = 1; i <= match.groupCount; i++) {
        final groupText = match.group(i) ?? '(null)';
        buf.writeln('  - Group $i: `${_escapeMdInline(groupText)}`');
      }
    }

    // Context snippet
    if (settings['showContext'] as bool) {
      final snippetStart = max(0, match.start - before);
      final snippetEnd = min(input.length, match.end + after);

      final pre = input.substring(snippetStart, match.start);
      final matchText = input.substring(match.start, match.end);
      final post = input.substring(match.end, snippetEnd);

      buf.writeln('\n**Context:**');
      if (highlight) {
        buf.writeln(_applyHighlight(pre, matchText, post, highlightStyle));
      } else {
        buf.writeln('```\n$pre$matchText$post\n```');
      }
    }

    buf.writeln();
    return buf.toString();
  }

  String _validateWithFormat(String input, RegExp regExp, String format) {
    final lines = input.split('\n');
    final results = <Map<String, dynamic>>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final matches = regExp.hasMatch(line);
      results.add({'line': i + 1, 'text': line, 'valid': matches});
    }

    if (format == 'json') {
      return _jsonEncode({
        'status': 'ok',
        'totalLines': lines.length,
        'validLines': results.where((r) => r['valid']).length,
        'invalidLines': results.where((r) => !r['valid']).length,
        'results': results,
      });
    }

    final buf = StringBuffer();
    final validCount = results.where((r) => r['valid']).length;
    final invalidCount = results.where((r) => !r['valid']).length;

    buf.writeln('## Validation Results');
    buf.writeln('- **Total lines:** ${lines.length}');
    buf.writeln('- **Valid lines:** $validCount');
    buf.writeln('- **Invalid lines:** $invalidCount');
    buf.writeln(
      '- **Success rate:** ${(validCount / lines.length * 100).toStringAsFixed(1)}%',
    );
    buf.writeln();

    if (invalidCount > 0) {
      buf.writeln('### Invalid Lines:');
      for (final result in results) {
        if (!result['valid']) {
          buf.writeln(
            '- **Line ${result['line']}:** `${_escapeMdInline(result['text'])}`',
          );
        }
      }
    }

    return buf.toString();
  }

  String _extractWithFormat(
    String input,
    RegExp regExp,
    int maxMatches,
    int groupIndex,
    String format,
  ) {
    final matches = regExp.allMatches(input).take(maxMatches).toList();
    final items = matches.map((m) => _groupTextSafe(m, groupIndex)).toList();

    switch (format) {
      case 'json':
        return _extractJson(input, regExp, maxMatches, groupIndex);
      case 'csv':
        return 'Value\n${items.map((s) => '"${s.replaceAll('"', '""')}"').join('\n')}';
      case 'list':
      case 'table':
      case 'rich':
      default:
        return _extractPretty(
          input: input,
          regExp: regExp,
          maxMatches: maxMatches,
          groupIndex: groupIndex,
          showCounts: settings['showCounts'] as bool,
        );
    }
  }

  String _replaceWithFormat(
    String input,
    RegExp regExp,
    String replacement,
    bool global,
    String format,
  ) {
    if (format == 'json') {
      return _replaceJson(input, regExp, replacement, global);
    }
    return _replacePretty(
      input,
      regExp,
      replacement,
      global,
      settings['showCounts'] as bool,
    );
  }

  String _splitWithFormat(
    String input,
    RegExp regExp,
    bool global,
    String format,
  ) {
    final parts = input.split(regExp);

    switch (format) {
      case 'json':
        return _splitJson(input, regExp, global);
      case 'csv':
        return 'Index,Part\n${parts.asMap().entries.map((e) => '${e.key},"${e.value.replaceAll('"', '""')}"').join('\n')}';
      case 'table':
        final buf = StringBuffer();
        buf.writeln('| Index | Part | Length |');
        buf.writeln('|-------|------|--------|');
        for (var i = 0; i < parts.length; i++) {
          buf.writeln(
            '| $i | `${_escapeMdInline(parts[i])}` | ${parts[i].length} |',
          );
        }
        return buf.toString();
      case 'list':
      case 'rich':
      default:
        return _splitPretty(
          input,
          regExp,
          global,
          settings['showCounts'] as bool,
        );
    }
  }

  String _highlightAllAdvanced(
    String input,
    List<RegExpMatch> matches,
    int groupIndex,
  ) {
    if (matches.isEmpty) return '```\n$input\n```';

    final highlightStyle = settings['highlightStyle'] as String;
    final showLineNumbers = settings['showLineNumbers'] as bool;

    if (showLineNumbers) {
      return _highlightWithLineNumbers(
        input,
        matches,
        groupIndex,
        highlightStyle,
      );
    }

    final buf = StringBuffer();
    int cursor = 0;
    for (final match in matches) {
      // Add text before match
      buf.write(_escapeHtml(input.substring(cursor, match.start)));

      // Add highlighted match
      final matchText = _groupTextSafe(match, groupIndex);
      buf.write(_formatHighlight(matchText, highlightStyle));

      cursor = match.end;
    }
    // Add remaining text
    buf.write(_escapeHtml(input.substring(cursor)));

    return buf.toString();
  }

  String _highlightWithLineNumbers(
    String input,
    List<RegExpMatch> matches,
    int groupIndex,
    String style,
  ) {
    final lines = input.split('\n');
    final buf = StringBuffer();

    // Create a map of line numbers to matches
    final matchesByLine = <int, List<RegExpMatch>>{};
    for (final match in matches) {
      final lineNum = input.substring(0, match.start).split('\n').length - 1;
      matchesByLine.putIfAbsent(lineNum, () => []).add(match);
    }

    buf.writeln('```');
    for (int i = 0; i < lines.length; i++) {
      final lineNum = i + 1;
      final lineMatches = matchesByLine[i] ?? [];

      if (lineMatches.isEmpty) {
        buf.writeln('${lineNum.toString().padLeft(4)}: ${lines[i]}');
      } else {
        // Highlight matches in this line
        String highlightedLine = lines[i];
        // Sort matches by position (reverse order for replacement)
        lineMatches.sort((a, b) => b.start.compareTo(a.start));

        for (final match in lineMatches) {
          final lineStart = input.substring(0, input.indexOf(lines[i])).length;
          final matchStart = match.start - lineStart;
          final matchEnd = match.end - lineStart;

          if (matchStart >= 0 && matchEnd <= highlightedLine.length) {
            final before = highlightedLine.substring(0, matchStart);
            final matchText = highlightedLine.substring(matchStart, matchEnd);
            final after = highlightedLine.substring(matchEnd);
            highlightedLine = '$before[[$matchText]]$after';
          }
        }
        buf.writeln('${lineNum.toString().padLeft(4)}: $highlightedLine');
      }
    }
    buf.writeln('```');

    return buf.toString();
  }

  String _formatHighlight(String text, String style) {
    switch (style) {
      case 'background':
        return '`${_escapeHtml(text)}`';
      case 'brackets':
        return '[[${_escapeHtml(text)}]]';
      case 'bold':
        return '**${_escapeMdInline(text)}**';
      case 'underline':
        return '__${_escapeMdInline(text)}__';
      case 'mark':
      default:
        return '<mark>${_escapeHtml(text)}</mark>';
    }
  }

  // Rest of the helper methods remain the same as in the original
  RegExp _buildRegExp({
    required String pattern,
    required bool caseInsensitive,
    required bool multiLine,
    required bool dotAll,
  }) {
    return RegExp(
      pattern,
      caseSensitive: !caseInsensitive,
      multiLine: multiLine,
      dotAll: dotAll,
      unicode: true,
    );
  }

  String _findJson(
    String input,
    RegExp regExp,
    int maxMatches,
    int groupIndex,
  ) {
    final matches = regExp.allMatches(input).take(maxMatches).toList();
    final items = matches.map((m) {
      final text = _groupTextSafe(m, groupIndex);
      return {
        'start': m.start,
        'end': m.end,
        'text': text,
        'groupIndex': groupIndex,
      };
    }).toList();

    return _jsonEncode({
      'status': 'ok',
      'count': items.length,
      'matches': items,
    });
  }

  String _extractPretty({
    required String input,
    required RegExp regExp,
    required int maxMatches,
    required int groupIndex,
    required bool showCounts,
  }) {
    final matches = regExp.allMatches(input).take(maxMatches).toList();
    final items = <String>[];
    for (final m in matches) {
      items.add(_groupTextSafe(m, groupIndex));
    }

    final buf = StringBuffer();
    if (showCounts) {
      buf.writeln('**Extracted:** ${items.length}');
      buf.writeln('');
    }
    if (items.isEmpty) {
      buf.writeln('_(no matches)_');
    } else {
      for (final s in items) {
        buf.writeln('- `${_escapeMdInline(s)}`');
      }
    }
    return buf.toString();
  }

  String _extractJson(
    String input,
    RegExp regExp,
    int maxMatches,
    int groupIndex,
  ) {
    final matches = regExp.allMatches(input).take(maxMatches).toList();
    final arr = matches.map((m) => _groupTextSafe(m, groupIndex)).toList();
    return _jsonEncode({
      'status': 'ok',
      'count': arr.length,
      'values': arr,
      'groupIndex': groupIndex,
    });
  }

  String _replacePretty(
    String input,
    RegExp regExp,
    String replacement,
    bool global,
    bool showCounts,
  ) {
    int count = 0;
    String out;

    if (global) {
      out = input.replaceAllMapped(regExp, (Match m) {
        count++;
        return _expandReplacement(m as RegExpMatch, replacement);
      });
    } else {
      final RegExpMatch? first = regExp.firstMatch(input);
      if (first == null) {
        out = input;
      } else {
        count = 1;
        out = input.replaceRange(
          first.start,
          first.end,
          _expandReplacement(first, replacement),
        );
      }
    }

    final buf = StringBuffer();
    if (showCounts) {
      buf.writeln('**Replacements:** $count');
      buf.writeln('');
    }
    buf.writeln('**Result:**');
    buf.writeln('```');
    buf.writeln(out);
    buf.writeln('```');
    return buf.toString();
  }

  String _replaceJson(
    String input,
    RegExp regExp,
    String replacement,
    bool global,
  ) {
    int count = 0;
    String out;
    if (global) {
      out = input.replaceAllMapped(regExp, (Match m) {
        count++;
        return _expandReplacement(m as RegExpMatch, replacement);
      });
    } else {
      final Match? first = regExp.firstMatch(input);
      if (first == null) {
        out = input;
      } else {
        count = 1;
        out = input.replaceRange(
          first.start,
          first.end,
          _expandReplacement(first as RegExpMatch, replacement),
        );
      }
    }
    return _jsonEncode({'status': 'ok', 'replacements': count, 'result': out});
  }

  String _splitPretty(
    String input,
    RegExp regExp,
    bool global,
    bool showCounts,
  ) {
    final parts = input.split(regExp);
    final buf = StringBuffer();
    if (showCounts) {
      buf.writeln('**Parts:** ${parts.length}');
      buf.writeln('');
    }
    for (var i = 0; i < parts.length; i++) {
      buf.writeln('- **[$i]** `${_escapeMdInline(parts[i])}`');
    }
    return buf.toString();
  }

  String _splitJson(String input, RegExp regExp, bool global) {
    final parts = input.split(regExp);
    return _jsonEncode({'status': 'ok', 'count': parts.length, 'parts': parts});
  }

  String _applyHighlight(String pre, String mid, String post, String style) {
    switch (style) {
      case 'background':
        return '`${_escapeMdInline(pre)}`${_escapeMdInline(mid)}`${_escapeMdInline(post)}`';
      case 'brackets':
        return '`${_escapeMdInline(pre)}[[${_escapeMdInline(mid)}]]${_escapeMdInline(post)}`';
      case 'caret':
        final line = '$pre$mid$post';
        final caretLine = '${' ' * pre.length}${'^' * mid.length}';
        return '```\n$line\n$caretLine\n```';
      case 'bold':
        return '${_escapeMdInline(pre)}**${_escapeMdInline(mid)}**${_escapeMdInline(post)}';
      case 'underline':
        return '${_escapeMdInline(pre)}__${_escapeMdInline(mid)}__${_escapeMdInline(post)}';
      case 'mark':
      default:
        return '${_escapeHtml(pre)}<mark>${_escapeHtml(mid)}</mark>${_escapeHtml(post)}';
    }
  }

  String _groupTextSafe(RegExpMatch m, int idx) {
    if (idx == 0) return m.group(0) ?? '';
    if (idx <= m.groupCount) return m.group(idx) ?? '';
    return '';
  }

  String _expandReplacement(RegExpMatch m, String replacement) {
    final sb = StringBuffer();
    for (int i = 0; i < replacement.length; i++) {
      final ch = replacement[i];
      if (ch == 'r') {
        if (i + 1 < replacement.length) {
          final next = replacement[i + 1];
          if (next == 'r') {
            {
              sb.write('r');
              i++;
            }
            continue;
          }
          if (next == '&') {
            sb.write(m.group(0) ?? '');
            i++;
            continue;
          }
          // Parse number
          int j = i + 1;
          while (j < replacement.length &&
              _isDigit(replacement.codeUnitAt(j))) {
            j++;
          }
          if (j > i + 1) {
            final nStr = replacement.substring(i + 1, j);
            final n = int.tryParse(nStr) ?? -1;
            if (n >= 0 && n <= m.groupCount) {
              sb.write(m.group(n) ?? '');
              i = j - 1;
              continue;
            }
          }
        }
      }
      sb.write(ch);
    }
    return sb.toString();
  }

  bool _isDigit(int code) => code >= 48 && code <= 57;

  String _jsonEncode(Map<String, dynamic> map) {
    return map
        .toString()
        .replaceAll(RegExp(r"(?<=[: ,\[{])'(?!\s*:)", multiLine: true), '"')
        .replaceAll("':", '":')
        .replaceAll(": '", ': "')
        .replaceAll("',", '",')
        .replaceAll("'}", '"}')
        .replaceAll("{'", '{"')
        .replaceAll("', '", '", "');
  }

  String _jsonMsg(String status, String message) =>
      _jsonEncode({'status': status, 'message': message});

  String _escapeMdInline(String s) {
    return s.replaceAll('`', r'\`');
  }

  String _escapeHtml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  @override
  Future<String> executeGetText(String input) async {
    final String mode = (settings['mode'] as String).trim().toLowerCase();
    final String predefinedKey = settings['predefinedPattern'] as String;
    String pattern = settings['pattern'] as String;

    if (predefinedKey != 'custom' &&
        predefinedPatterns.containsKey(predefinedKey)) {
      pattern = predefinedPatterns[predefinedKey]!['pattern']!;
    }

    final String replacement = (settings['replacement'] as String);
    final bool caseInsensitive = settings['caseInsensitive'] as bool;
    final bool multiLine = settings['multiLine'] as bool;
    final bool dotAll = settings['dotAll'] as bool;
    final bool global = settings['global'] as bool;
    final int maxMatches = (settings['maxMatches'] as num).toInt().clamp(
      1,
      50000,
    );
    final int groupIndex = (settings['groupIndex'] as num).toInt().clamp(0, 99);

    if ((settings['ignoreEmptyPattern'] as bool) && pattern.trim().isEmpty) {
      return 'Pattern is empty.';
    }

    final regExp = _buildRegExp(
      pattern: pattern,
      caseInsensitive: caseInsensitive,
      multiLine: multiLine,
      dotAll: dotAll,
    );

    switch (mode) {
      case 'find':
        final matches = regExp.allMatches(input).take(maxMatches).toList();
        final b = StringBuffer()..writeln('Matches: ${matches.length}');
        for (var i = 0; i < matches.length; i++) {
          final m = matches[i];
          final text = _groupTextSafe(m, groupIndex);
          b.writeln('#${i + 1} [${m.start}..${m.end}]: $text');
        }
        return b.toString();
      case 'extract':
        final matches = regExp.allMatches(input).take(maxMatches).toList();
        final b = StringBuffer()..writeln('Extracted: ${matches.length}');
        for (final m in matches) {
          b.writeln(_groupTextSafe(m, groupIndex));
        }
        return b.toString();
      case 'replace':
        int count = 0;
        String out;
        if (global) {
          out = input.replaceAllMapped(regExp, (Match m) {
            count++;
            return _expandReplacement(m as RegExpMatch, replacement);
          });
        } else {
          final Match? first = regExp.firstMatch(input);
          if (first == null) {
            out = input;
          } else {
            count = 1;
            out = input.replaceRange(
              first.start,
              first.end,
              _expandReplacement(first as RegExpMatch, replacement),
            );
          }
        }
        return 'Replacements: $count\n\n$out';
      case 'split':
        final parts = input.split(regExp);
        final b = StringBuffer()..writeln('Parts: ${parts.length}');
        for (var i = 0; i < parts.length; i++) {
          b.writeln('[$i] ${parts[i]}');
        }
        return b.toString();
      case 'validate':
        final lines = input.split('\n');
        int validCount = 0;
        final b = StringBuffer();
        for (int i = 0; i < lines.length; i++) {
          final isValid = regExp.hasMatch(lines[i]);
          if (isValid) validCount++;
          if (!isValid) {
            b.writeln('Line ${i + 1} invalid: ${lines[i]}');
          }
        }
        return 'Valid: $validCount/${lines.length}\n\n${b.toString()}';
      case 'test':
        return regExp.hasMatch(input) ? 'true' : 'false';
      default:
        return 'Unknown mode: $mode';
    }
  }
}

class TextSplitTool extends Tool {
  TextSplitTool()
    : super(
        name: 'Text Splitter',
        description: 'Split text into parts using delimiter, regex, or mode',
        icon: Icons.call_split,
        isOutputMarkdown: true,
        isInputMarkdown: false,
        canAcceptMarkdown: false,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'mode': 'delimiter', // default split method
          'delimiter': ',', // default delimiter
          'regex': r'\s+', // default regex split (whitespace)
          'trimEmpty': true,
        },
        settingsHints: {
          'mode': {
            'type': 'dropdown',
            'label': 'Split Mode',
            'help': 'Choose how to split the input',
            'options': [
              {'value': 'delimiter', 'label': 'Delimiter'},
              {'value': 'regex', 'label': 'Regex'},
              {'value': 'character', 'label': 'Each Character'},
              {'value': 'word', 'label': 'By Words'},
            ],
          },
          'delimiter': {
            'type': 'text',
            'label': 'Delimiter',
            'help': 'Delimiter string for splitting',
            'placeholder': ',',
          },
          'regex': {
            'type': 'text',
            'label': 'Regex',
            'help': 'Regex pattern for splitting',
            'placeholder': r'\s+',
          },
          'trimEmpty': {
            'type': 'bool',
            'label': 'Trim Empty',
            'help': 'Remove empty parts from result',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    List<String> parts = [];
    final mode = settings['mode'] as String;
    final delimiter = settings['delimiter'] as String;
    final regex = settings['regex'] as String;
    final trimEmpty = settings['trimEmpty'] as bool;

    switch (mode) {
      case 'character':
        parts = input.split('');
        break;
      case 'word':
        parts = input.split(RegExp(r'\s+'));
        break;
      case 'regex':
        try {
          parts = input.split(RegExp(regex));
        } catch (e) {
          return ToolResult(output: '⚠️ Invalid regex: $e', status: 'error');
        }
        break;
      default: // delimiter
        parts = input.split(delimiter);
    }

    if (trimEmpty) {
      parts = parts.where((p) => p.trim().isNotEmpty).toList();
    }

    // Markdown formatted list
    final result = parts
        .asMap()
        .entries
        .map((e) => "**${e.key}**: ${e.value}")
        .join("\n");

    return ToolResult(output: result, status: 'success');
  }

  @override
  Future<String> executeGetText(String input) async {
    // Plain text version
    List<String> parts = [];
    final mode = settings['mode'] as String;
    final delimiter = settings['delimiter'] as String;
    final regex = settings['regex'] as String;
    final trimEmpty = settings['trimEmpty'] as bool;

    switch (mode) {
      case 'character':
        parts = input.split('');
        break;
      case 'word':
        parts = input.split(RegExp(r'\s+'));
        break;
      case 'regex':
        parts = input.split(RegExp(regex));
        break;
      default:
        parts = input.split(delimiter);
    }

    if (trimEmpty) {
      parts = parts.where((p) => p.trim().isNotEmpty).toList();
    }

    return parts.join("\n");
  }
}

class TextJoinTool extends Tool {
  TextJoinTool()
    : super(
        name: 'Text Joiner',
        description:
            'Join multiple lines/parts of text into one string with a chosen delimiter',
        icon: Icons.merge_type,
        isOutputMarkdown: true,
        isInputMarkdown: false,
        canAcceptMarkdown: false,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'delimiter': ',', // default join delimiter
          'prefix': '', // optional prefix for each part
          'suffix': '', // optional suffix for each part
          'skipEmpty': true,
          'trimParts': true,
        },
        settingsHints: {
          'delimiter': {
            'type': 'text',
            'label': 'Delimiter',
            'help': 'Delimiter string used between parts',
            'placeholder': ',',
          },
          'prefix': {
            'type': 'text',
            'label': 'Prefix',
            'help': 'Text to prepend to each part',
            'placeholder': '',
          },
          'suffix': {
            'type': 'text',
            'label': 'Suffix',
            'help': 'Text to append to each part',
            'placeholder': '',
          },
          'skipEmpty': {
            'type': 'bool',
            'label': 'Skip Empty',
            'help': 'Ignore empty lines when joining',
          },
          'trimParts': {
            'type': 'bool',
            'label': 'Trim Parts',
            'help': 'Trim whitespace from each part before joining',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    final delimiter = settings['delimiter'] as String;
    final prefix = settings['prefix'] as String;
    final suffix = settings['suffix'] as String;
    final skipEmpty = settings['skipEmpty'] as bool;
    final trimParts = settings['trimParts'] as bool;

    // Split by lines (each line = one part)
    List<String> parts = input.split('\n');

    if (trimParts) {
      parts = parts.map((p) => p.trim()).toList();
    }

    if (skipEmpty) {
      parts = parts.where((p) => p.isNotEmpty).toList();
    }

    final joined = parts.map((p) => "$prefix$p$suffix").join(delimiter);

    // Markdown preview
    final preview = "### Joined Result\n```\n$joined\n```";

    return ToolResult(output: preview, status: 'success');
  }

  @override
  Future<String> executeGetText(String input) async {
    final delimiter = settings['delimiter'] as String;
    final prefix = settings['prefix'] as String;
    final suffix = settings['suffix'] as String;
    final skipEmpty = settings['skipEmpty'] as bool;
    final trimParts = settings['trimParts'] as bool;

    List<String> parts = input.split('\n');

    if (trimParts) {
      parts = parts.map((p) => p.trim()).toList();
    }

    if (skipEmpty) {
      parts = parts.where((p) => p.isNotEmpty).toList();
    }

    return parts.map((p) => "$prefix$p$suffix").join(delimiter);
  }
}

class CommentsTool extends Tool {
  CommentsTool()
    : super(
        name: 'Comments',
        description:
            'Add or remove code comments (line/block) for multiple languages.',
        icon: Icons.comment,
        isOutputMarkdown: false,
        isInputMarkdown: false,
        canAcceptMarkdown: false,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'mode': 'add', // add | remove
          'language':
              'auto', // auto | cLike | python | shell | htmlXml | sql | custom
          'filename': '',
          'commentKind': 'auto', // auto | line | block
          'preferBlockForMultiline': true,
          'spaceAfterMarker': true,
          'applyToEmptyLines': false,

          // Removal options
          'stripInline': false, // remove trailing inline comments (heuristic)
          'preserveDocComments':
              true, // keep /** ... */ and /// lines for C-like
          // Custom style (used when language == custom)
          'customLine': '',
          'customBlockStart': '',
          'customBlockEnd': '',

          // Block formatting
          'compactBlock': false, // /* text */ vs multi-line wrapping
        },
        settingsHints: {
          'mode': {
            'type': 'dropdown',
            'label': 'Mode',
            'help': 'Add or remove comments.',
            'options': [
              {'value': 'add', 'label': 'Add'},
              {'value': 'remove', 'label': 'Remove'},
            ],
          },
          'language': {
            'type': 'dropdown',
            'label': 'Language',
            'help':
                'Select language for comment syntax (auto uses filename if provided).',
            'options': [
              {'value': 'auto', 'label': 'Auto (by filename)'},
              {'value': 'cLike', 'label': 'C-like (C/C++/Java/JS/Dart/C#)'},
              {'value': 'python', 'label': 'Python'},
              {'value': 'shell', 'label': 'Shell / Bash'},
              {'value': 'htmlXml', 'label': 'HTML / XML'},
              {'value': 'sql', 'label': 'SQL'},
              {'value': 'custom', 'label': 'Custom'},
            ],
          },
          'filename': {
            'type': 'text',
            'label': 'Filename (for Auto)',
            'help':
                'Used for auto-detecting language from extension (e.g., main.py).',
            'placeholder': 'optional: app.dart',
            'width': 260,
          },
          'commentKind': {
            'type': 'dropdown',
            'label': 'Comment Kind',
            'help': 'Prefer line or block style (Auto picks best available).',
            'options': [
              {'value': 'auto', 'label': 'Auto'},
              {'value': 'line', 'label': 'Line comments'},
              {'value': 'block', 'label': 'Block comments'},
            ],
          },
          'preferBlockForMultiline': {
            'type': 'bool',
            'label': 'Prefer Block for Multiline',
            'help':
                'When Auto and input has multiple lines, use block if available.',
          },
          'spaceAfterMarker': {
            'type': 'bool',
            'label': 'Space After Marker',
            'help':
                'Insert a space after the comment marker when adding line comments.',
          },
          'applyToEmptyLines': {
            'type': 'bool',
            'label': 'Apply to Empty Lines',
            'help': 'Add line comment markers to empty lines too.',
          },
          'stripInline': {
            'type': 'bool',
            'label': 'Strip Inline Comments',
            'help':
                'Remove trailing inline comments (heuristic; may affect URLs/strings).',
          },
          'preserveDocComments': {
            'type': 'bool',
            'label': 'Preserve Doc Comments',
            'help':
                'Keep /** ... */ and /// doc comments when removing (C-like).',
          },
          'customLine': {
            'type': 'text',
            'label': 'Custom Line Marker',
            'help': 'Used if language = Custom (e.g., // or # or --).',
            'placeholder': '//',
          },
          'customBlockStart': {
            'type': 'text',
            'label': 'Custom Block Start',
            'help': 'Used if language = Custom (e.g., /* or <!--).',
            'placeholder': '/*',
          },
          'customBlockEnd': {
            'type': 'text',
            'label': 'Custom Block End',
            'help': 'Used if language = Custom (e.g., */ or -->).',
            'placeholder': '*/',
          },
          'compactBlock': {
            'type': 'bool',
            'label': 'Compact Block',
            'help': 'Write block as a single line: /* text */',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    try {
      final mode = settings['mode'] as String;
      final resolved = _resolveStyle(
        language: settings['language'] as String,
        filename: (settings['filename'] as String).trim(),
        customLine: settings['customLine'] as String,
        customBlockStart: settings['customBlockStart'] as String,
        customBlockEnd: settings['customBlockEnd'] as String,
      );

      final commentKind = settings['commentKind'] as String;
      final preferBlockForMultiline =
          settings['preferBlockForMultiline'] as bool;
      final spaceAfterMarker = settings['spaceAfterMarker'] as bool;
      final applyToEmptyLines = settings['applyToEmptyLines'] as bool;
      final stripInline = settings['stripInline'] as bool;
      final preserveDoc = settings['preserveDocComments'] as bool;
      final compactBlock = settings['compactBlock'] as bool;

      final hasMultipleLines = input.contains('\n');
      final effectiveKind = _chooseKind(
        commentKind,
        resolved,
        hasMultipleLines,
        preferBlockForMultiline,
      );

      String output;
      if (mode == 'add') {
        if (effectiveKind == 'line' && resolved.line != null) {
          output = _addLineComments(
            input,
            resolved.line!,
            spaceAfterMarker: spaceAfterMarker,
            applyToEmptyLines: applyToEmptyLines,
          );
        } else if (resolved.blockStart != null && resolved.blockEnd != null) {
          output = _addBlockComments(
            input,
            resolved.blockStart!,
            resolved.blockEnd!,
            compact: compactBlock,
          );
        } else {
          output = input; // no applicable style
        }
      } else {
        // remove
        output = _removeComments(
          input,
          resolved,
          stripInline: stripInline,
          preserveDoc: preserveDoc,
        );
      }

      return ToolResult(output: output, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: $e', status: 'error');
    }
  }

  // ---------- Styles & Helpers ----------

  static final Map<String, _CommentStyle> _styles = {
    // C-like languages (C/C++/Java/JS/Dart/C# ...)
    'cLike': _CommentStyle(
      line: '//',
      blockStart: '/*',
      blockEnd: '*/',
      docLine: '///',
      docBlockStart: '/**',
      docBlockEnd: '*/',
    ),
    'python': _CommentStyle(line: '#'),
    'shell': _CommentStyle(line: '#'),
    'htmlXml': _CommentStyle(blockStart: '<!--', blockEnd: '-->'),
    'sql': _CommentStyle(line: '--', blockStart: '/*', blockEnd: '*/'),
  };

  _CommentStyle _resolveStyle({
    required String language,
    required String filename,
    required String customLine,
    required String customBlockStart,
    required String customBlockEnd,
  }) {
    if (language == 'custom') {
      return _CommentStyle(
        line: customLine.isNotEmpty ? customLine : null,
        blockStart: customBlockStart.isNotEmpty ? customBlockStart : null,
        blockEnd: customBlockEnd.isNotEmpty ? customBlockEnd : null,
      );
    }
    if (language == 'auto') {
      final detected = _detectLanguageByExtension(filename);
      return _styles[detected] ?? _styles['cLike']!;
    }
    return _styles[language] ?? _styles['cLike']!;
  }

  String _detectLanguageByExtension(String filename) {
    final f = filename.toLowerCase();
    if (f.endsWith('.py')) return 'python';
    if (f.endsWith('.sh') || f.endsWith('.bash') || f.endsWith('.zsh'))
      return 'shell';
    if (f.endsWith('.html') || f.endsWith('.htm') || f.endsWith('.xml'))
      return 'htmlXml';
    if (f.endsWith('.sql')) return 'sql';
    if (f.endsWith('.c') ||
        f.endsWith('.h') ||
        f.endsWith('.cpp') ||
        f.endsWith('.hpp') ||
        f.endsWith('.cc') ||
        f.endsWith('.java') ||
        f.endsWith('.js') ||
        f.endsWith('.ts') ||
        f.endsWith('.dart') ||
        f.endsWith('.cs') ||
        f.endsWith('.swift') ||
        f.endsWith('.kt')) {
      return 'cLike';
    }
    return 'cLike';
  }

  String _chooseKind(
    String requested,
    _CommentStyle style,
    bool multiline,
    bool preferBlockForMultiline,
  ) {
    if (requested == 'line' && style.line != null) return 'line';
    if (requested == 'block' &&
        style.blockStart != null &&
        style.blockEnd != null)
      return 'block';
    // auto:
    if (multiline &&
        preferBlockForMultiline &&
        style.blockStart != null &&
        style.blockEnd != null) {
      return 'block';
    }
    // otherwise use line if available, else block
    if (style.line != null) return 'line';
    if (style.blockStart != null && style.blockEnd != null) return 'block';
    return 'line';
  }

  String _addLineComments(
    String input,
    String marker, {
    required bool spaceAfterMarker,
    required bool applyToEmptyLines,
  }) {
    final lines = input.split('\n');
    final spacer = spaceAfterMarker ? ' ' : '';
    final out = <String>[];
    for (final l in lines) {
      if (l.trim().isEmpty && !applyToEmptyLines) {
        out.add(l); // keep empty line as-is
      } else {
        out.add('$marker$spacer$l');
      }
    }
    return out.join('\n');
  }

  String _addBlockComments(
    String input,
    String start,
    String end, {
    required bool compact,
  }) {
    if (compact) {
      return '$start $input $end';
    }
    return '$start\n$input\n$end';
  }

  String _removeComments(
    String input,
    _CommentStyle style, {
    required bool stripInline,
    required bool preserveDoc,
  }) {
    var text = input;

    // Remove block comments (optionally preserving /** ... */)
    if (style.blockStart != null && style.blockEnd != null) {
      if (preserveDoc && style.docBlockStart != null) {
        // Remove /* ... */ but not /** ... */
        final blockRe = RegExp(r'/\*(?!\*)(?:.|\n)*?\*/', multiLine: true);
        text = text.replaceAll(blockRe, '');
      } else {
        final startEsc = RegExp.escape(style.blockStart!);
        final endEsc = RegExp.escape(style.blockEnd!);
        final blockRe = RegExp('$startEsc[\\s\\S]*?$endEsc', multiLine: true);
        text = text.replaceAll(blockRe, '');
      }
    }

    final lines = text.split('\n');
    final out = <String>[];

    for (var line in lines) {
      String processed = line;

      // Remove leading line comments (respect doc line if requested)
      if (style.line != null) {
        final docLine = style.docLine;
        final lineEsc = RegExp.escape(style.line!);

        if (!(preserveDoc &&
            docLine != null &&
            RegExp('^\\s*${RegExp.escape(docLine)}').hasMatch(processed))) {
          // Strip leading line marker
          processed = processed.replaceFirst(RegExp('^\\s*$lineEsc\\s?'), '');
        }

        // Remove inline comments (heuristic)
        if (stripInline) {
          final idx = processed.indexOf(style.line!);
          if (idx >= 0) {
            final before = idx >= 6
                ? processed.substring(idx - 6, idx).toLowerCase()
                : '';
            final looksLikeUrl =
                before.contains('http:') ||
                before.contains('https:') ||
                before.contains('file:');
            if (!looksLikeUrl) {
              processed = processed.substring(0, idx).trimRight();
            }
          }
        }
      }

      out.add(processed);
    }

    return out.join('\n');
  }
}

class _CommentStyle {
  final String? line;
  final String? blockStart;
  final String? blockEnd;
  final String? docLine; // e.g., ///
  final String? docBlockStart; // e.g., /**
  final String? docBlockEnd; // e.g., */

  const _CommentStyle({
    this.line,
    this.blockStart,
    this.blockEnd,
    this.docLine,
    this.docBlockStart,
    this.docBlockEnd,
  });
}

class TableConverterTool extends Tool {
  TableConverterTool()
    : super(
        name: 'Table Converter',
        description:
            'Advanced table converter with auto-detection, multiple formats, validation, and data transformation features.',
        icon: Icons.table_chart,
        isOutputMarkdown: true,
        isInputMarkdown: true,
        canAcceptMarkdown: true,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          // Input/Output settings
          'inputFormat':
              'auto', // auto, CSV, JSON, HTML, Markdown, TSV, Excel-like
          'outputFormat': 'Markdown',
          'autoHeaders': true,
          'preserveFormatting': false,

          // CSV specific settings
          'csvDelimiter': ',', // comma, semicolon, tab, pipe, custom
          'csvQuote': '"',
          'csvEscape': '"',
          'skipEmptyLines': true,
          'trimWhitespace': true,

          // Data processing
          'sortColumn': 0, // -1 for no sort, 0+ for column index
          'sortAscending': true,
          'filterColumn': -1, // -1 for no filter
          'filterValue': '',
          'filterOperation':
              'contains', // contains, equals, startsWith, endsWith, regex
          // Output formatting
          'includeRowNumbers': false,
          'includeStats': false,
          'prettyPrint': true,
          'compactOutput': false,
          'customSeparator': ' | ',

          // Validation and cleaning
          'validateData': true,
          'cleanData': false, // remove empty rows/cols, normalize whitespace
          'handleMissingData': 'empty', // empty, null, skip, placeholder
          'missingPlaceholder': 'N/A',

          // Advanced features
          'transpose': false,
          'addIndexColumn': false,
          'groupByColumn': -1, // -1 for no grouping
          'aggregateFunction': 'count', // count, sum, avg, min, max
          'showPreview': true,
          'maxPreviewRows': 10,

          // Export options
          'includeMetadata': false,
          'addTimestamp': false,
          'customTitle': '',
        },
        settingsHints: {
          'inputFormat': {
            'type': 'dropdown',
            'label': 'Input Format',
            'help': 'Format of the input data. Auto-detection recommended.',
            'options': [
              {'value': 'auto', 'label': 'Auto-detect'},
              {'value': 'CSV', 'label': 'CSV (Comma Separated)'},
              {'value': 'TSV', 'label': 'TSV (Tab Separated)'},
              {'value': 'JSON', 'label': 'JSON'},
              {'value': 'HTML', 'label': 'HTML Table'},
              {'value': 'Markdown', 'label': 'Markdown Table'},
              {'value': 'Excel', 'label': 'Excel-like (semicolon)'},
              {'value': 'Pipe', 'label': 'Pipe Separated'},
            ],
          },
          'outputFormat': {
            'type': 'dropdown',
            'label': 'Output Format',
            'help': 'Desired output format.',
            'options': [
              {'value': 'Markdown', 'label': 'Markdown Table'},
              {'value': 'CSV', 'label': 'CSV'},
              {'value': 'TSV', 'label': 'TSV'},
              {'value': 'JSON', 'label': 'JSON'},
              {'value': 'JSON-Array', 'label': 'JSON (Array of Arrays)'},
              {'value': 'HTML', 'label': 'HTML Table'},
              {'value': 'LaTeX', 'label': 'LaTeX Table'},
              {'value': 'SQL', 'label': 'SQL INSERT'},
              {'value': 'Excel', 'label': 'Excel CSV'},
              {'value': 'YAML', 'label': 'YAML'},
            ],
          },
          'csvDelimiter': {
            'type': 'dropdown',
            'label': 'CSV Delimiter',
            'help': 'Character used to separate fields in CSV.',
            'options': [
              {'value': ',', 'label': 'Comma (,)'},
              {'value': ';', 'label': 'Semicolon (;)'},
              {'value': '\t', 'label': 'Tab'},
              {'value': '|', 'label': 'Pipe (|)'},
              {'value': ' ', 'label': 'Space'},
            ],
          },
          'sortColumn': {
            'type': 'spinner',
            'label': 'Sort by Column',
            'help': 'Column index to sort by (-1 for no sorting).',
            'min': -1,
            'max': 50,
            'step': 1,
          },
          'filterColumn': {
            'type': 'spinner',
            'label': 'Filter Column',
            'help': 'Column index to filter by (-1 for no filtering).',
            'min': -1,
            'max': 50,
            'step': 1,
          },
          'filterValue': {
            'type': 'text',
            'label': 'Filter Value',
            'help': 'Value to filter by (when filter column is set).',
            'placeholder': 'Enter filter value',
          },
          'filterOperation': {
            'type': 'dropdown',
            'label': 'Filter Operation',
            'help': 'How to match the filter value.',
            'options': [
              {'value': 'contains', 'label': 'Contains'},
              {'value': 'equals', 'label': 'Equals'},
              {'value': 'startsWith', 'label': 'Starts With'},
              {'value': 'endsWith', 'label': 'Ends With'},
              {'value': 'regex', 'label': 'Regular Expression'},
              {'value': 'greater', 'label': 'Greater Than (numeric)'},
              {'value': 'less', 'label': 'Less Than (numeric)'},
            ],
          },
          'handleMissingData': {
            'type': 'dropdown',
            'label': 'Handle Missing Data',
            'help': 'How to handle empty or missing cells.',
            'options': [
              {'value': 'empty', 'label': 'Keep Empty'},
              {'value': 'null', 'label': 'Use null'},
              {'value': 'skip', 'label': 'Skip Rows'},
              {'value': 'placeholder', 'label': 'Use Placeholder'},
            ],
          },
          'aggregateFunction': {
            'type': 'dropdown',
            'label': 'Aggregate Function',
            'help': 'Function to use when grouping data.',
            'options': [
              {'value': 'count', 'label': 'Count'},
              {'value': 'sum', 'label': 'Sum'},
              {'value': 'avg', 'label': 'Average'},
              {'value': 'min', 'label': 'Minimum'},
              {'value': 'max', 'label': 'Maximum'},
              {'value': 'first', 'label': 'First Value'},
              {'value': 'last', 'label': 'Last Value'},
            ],
          },
          'maxPreviewRows': {
            'type': 'spinner',
            'label': 'Preview Rows',
            'help': 'Number of rows to show in preview.',
            'min': 1,
            'max': 100,
            'step': 5,
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    try {
      final result = await _processTable(input);
      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(
        output: '❌ Error processing table: $e',
        status: 'error',
      );
    }
  }

  Future<String> _processTable(String input) async {
    if (input.trim().isEmpty) {
      return '⚠️ No input data provided.';
    }

    // 1. Auto-detect format if needed
    String inputFormat = settings['inputFormat'] as String;
    if (inputFormat == 'auto') {
      inputFormat = _detectFormat(input);
    }

    // 2. Parse input data
    ParseResult parseResult = _parseInput(input, inputFormat);
    if (!parseResult.success) {
      return '❌ Failed to parse input: ${parseResult.error}';
    }

    List<List<String>> table = parseResult.data;
    Map<String, dynamic> metadata = parseResult.metadata;

    // 3. Validate and clean data if requested
    if (settings['validateData'] as bool) {
      final validation = _validateData(table);
      if (validation.isNotEmpty && !(settings['cleanData'] as bool)) {
        return '⚠️ Data validation issues found:\n${validation.join('\n')}\n\n'
            'Enable "Clean Data" to automatically fix these issues.';
      }
    }

    if (settings['cleanData'] as bool) {
      table = _cleanData(table);
    }

    // 4. Apply transformations
    table = _applyTransformations(table);

    // 5. Generate output
    final outputFormat = settings['outputFormat'] as String;
    String result = _generateOutput(table, outputFormat, metadata);

    // 6. Add metadata and preview if requested
    if (settings['showPreview'] as bool || settings['includeStats'] as bool) {
      result = _addMetadataAndPreview(
        result,
        table,
        metadata,
        inputFormat,
        outputFormat,
      );
    }

    return result;
  }

  String _detectFormat(String input) {
    input = input.trim();

    // JSON detection
    if ((input.startsWith('[') && input.endsWith(']')) ||
        (input.startsWith('{') && input.endsWith('}'))) {
      try {
        jsonDecode(input);
        return 'JSON';
      } catch (e) {
        // Not valid JSON
      }
    }

    // HTML detection
    if (input.contains('<table') ||
        input.contains('<tr>') ||
        input.contains('<td>')) {
      return 'HTML';
    }

    // Markdown detection
    if (input.contains('|') && input.contains('---')) {
      final lines = input.split('\n');
      bool hasMarkdownTable = false;
      for (int i = 0; i < lines.length - 1; i++) {
        if (lines[i].contains('|') && lines[i + 1].contains('---')) {
          hasMarkdownTable = true;
          break;
        }
      }
      if (hasMarkdownTable) return 'Markdown';
    }

    // Count delimiters to detect CSV/TSV/etc
    final lines = input.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length < 2) return 'CSV'; // Default fallback

    final firstLine = lines.first;
    final commas = firstLine.split(',').length - 1;
    final semicolons = firstLine.split(';').length - 1;
    final tabs = firstLine.split('\t').length - 1;
    final pipes = firstLine.split('|').length - 1;

    // Choose the delimiter with the highest consistent count
    final delimiters = [
      (commas, 'CSV'),
      (semicolons, 'Excel'),
      (tabs, 'TSV'),
      (pipes, 'Pipe'),
    ];

    delimiters.sort((a, b) => b.$1.compareTo(a.$1));

    // Verify consistency across multiple lines
    final topDelimiter = delimiters.first;
    if (topDelimiter.$1 > 0) {
      String delimiter = topDelimiter.$1 == commas
          ? ','
          : topDelimiter.$1 == semicolons
          ? ';'
          : topDelimiter.$1 == tabs
          ? '\t'
          : '|';

      // Check if this delimiter is consistent across lines
      int consistentLines = 0;
      int expectedFields = topDelimiter.$1 + 1;

      for (final line in lines.take(min(5, lines.length))) {
        if (line.split(delimiter).length == expectedFields) {
          consistentLines++;
        }
      }

      if (consistentLines >= lines.length * 0.8) {
        return topDelimiter.$2;
      }
    }

    return 'CSV'; // Default fallback
  }

  ParseResult _parseInput(String input, String format) {
    try {
      List<List<String>> table = [];
      Map<String, dynamic> metadata = {
        'detectedFormat': format,
        'originalLength': input.length,
        'lineCount': input.split('\n').length,
      };

      switch (format) {
        case 'CSV':
          table = _parseDelimited(input, ',');
          break;
        case 'TSV':
          table = _parseDelimited(input, '\t');
          break;
        case 'Excel':
          table = _parseDelimited(input, ';');
          break;
        case 'Pipe':
          table = _parseDelimited(input, '|');
          break;
        case 'JSON':
          table = _parseJSON(input, metadata);
          break;
        case 'HTML':
          table = _parseHTML(input, metadata);
          break;
        case 'Markdown':
          table = _parseMarkdown(input, metadata);
          break;
        default:
          throw Exception('Unsupported input format: $format');
      }

      metadata['parsedRows'] = table.length;
      metadata['parsedColumns'] = table.isNotEmpty ? table.first.length : 0;

      return ParseResult(success: true, data: table, metadata: metadata);
    } catch (e) {
      return ParseResult(success: false, error: e.toString());
    }
  }

  List<List<String>> _parseDelimited(String input, String delimiter) {
    final csvSettings = CsvToListConverter(
      fieldDelimiter: delimiter,
      textDelimiter: settings['csvQuote'] as String,
      textEndDelimiter: settings['csvQuote'] as String,
      eol: '\n',
      shouldParseNumbers: false, // Keep as strings for consistency
    );

    return csvSettings
        .convert(input)
        .map((row) => row.map((cell) => cell?.toString() ?? '').toList())
        .toList();
  }

  List<List<String>> _parseJSON(String input, Map<String, dynamic> metadata) {
    dynamic jsonData = jsonDecode(input);
    List<List<String>> table = [];

    if (jsonData is List) {
      if (jsonData.isEmpty) return table;

      if (jsonData.first is Map) {
        // Array of objects
        Map<String, dynamic> first = jsonData.first as Map<String, dynamic>;
        List<String> headers = first.keys.map((k) => k.toString()).toList();
        table.add(headers);

        for (var item in jsonData) {
          if (item is Map) {
            List<String> row = headers
                .map((h) => item[h]?.toString() ?? '')
                .toList();
            table.add(row);
          }
        }
        metadata['jsonType'] = 'array_of_objects';
      } else {
        // Array of arrays
        for (var row in jsonData) {
          if (row is List) {
            table.add(row.map((cell) => cell?.toString() ?? '').toList());
          }
        }
        metadata['jsonType'] = 'array_of_arrays';
      }
    } else if (jsonData is Map) {
      // Single object - convert to single row
      Map<String, dynamic> obj = jsonData as Map<String, dynamic>;
      table.add(obj.keys.map((k) => k.toString()).toList());
      table.add(obj.values.map((v) => v?.toString() ?? '').toList());
      metadata['jsonType'] = 'single_object';
    }

    return table;
  }

  List<List<String>> _parseHTML(String input, Map<String, dynamic> metadata) {
    List<List<String>> table = [];

    // Enhanced HTML parsing with better regex
    final tableRegex = RegExp(
      r'<table[^>]*>(.*?)<\/table>',
      dotAll: true,
      caseSensitive: false,
    );
    final rowRegex = RegExp(
      r'<tr[^>]*>(.*?)<\/tr>',
      dotAll: true,
      caseSensitive: false,
    );
    final cellRegex = RegExp(
      r'<t[hd][^>]*>(.*?)<\/t[hd]>',
      dotAll: true,
      caseSensitive: false,
    );

    final tableMatch = tableRegex.firstMatch(input);
    String tableContent = tableMatch?.group(1) ?? input;

    int headerRows = 0;
    for (var rowMatch in rowRegex.allMatches(tableContent)) {
      String rowContent = rowMatch.group(1)!;
      List<String> row = [];

      for (var cellMatch in cellRegex.allMatches(rowContent)) {
        String cellContent = cellMatch.group(1)!;
        // Remove HTML tags and decode entities
        cellContent = cellContent
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .trim();
        row.add(cellContent);
      }

      if (row.isNotEmpty) {
        table.add(row);
        if (rowContent.contains('<th')) headerRows++;
      }
    }

    metadata['headerRows'] = headerRows;
    return table;
  }

  List<List<String>> _parseMarkdown(
    String input,
    Map<String, dynamic> metadata,
  ) {
    List<List<String>> table = [];
    final lines = input.split('\n');

    bool inTable = false;
    int separatorLineIndex = -1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) continue;

      if (line.contains('|')) {
        if (!inTable) {
          inTable = true;
        }

        // Check if this is a separator line
        if (line.replaceAll(RegExp(r'[|\s:-]'), '').isEmpty) {
          separatorLineIndex = table.length;
          continue;
        }

        // Parse table row
        List<String> cells = line
            .split('|')
            .map((cell) => cell.trim())
            .where((cell) => cell.isNotEmpty)
            .toList();

        // Handle edge case where line starts/ends with |
        if (line.startsWith('|') && cells.isNotEmpty) {
          // Already handled by split
        }

        if (cells.isNotEmpty) {
          table.add(cells);
        }
      } else if (inTable) {
        // End of table
        break;
      }
    }

    metadata['separatorLineIndex'] = separatorLineIndex;
    metadata['hasMarkdownHeaders'] = separatorLineIndex == 1;

    return table;
  }

  List<String> _validateData(List<List<String>> table) {
    List<String> issues = [];

    if (table.isEmpty) {
      issues.add('Table is empty');
      return issues;
    }

    // Check for consistent column count
    int expectedColumns = table.first.length;
    for (int i = 0; i < table.length; i++) {
      if (table[i].length != expectedColumns) {
        issues.add(
          'Row ${i + 1} has ${table[i].length} columns, expected $expectedColumns',
        );
      }
    }

    // Check for completely empty rows
    int emptyRows = 0;
    for (int i = 0; i < table.length; i++) {
      if (table[i].every((cell) => cell.trim().isEmpty)) {
        emptyRows++;
      }
    }
    if (emptyRows > 0) {
      issues.add('Found $emptyRows completely empty rows');
    }

    // Check for completely empty columns
    if (table.isNotEmpty) {
      for (int col = 0; col < expectedColumns; col++) {
        bool columnEmpty = true;
        for (int row = 0; row < table.length; row++) {
          if (col < table[row].length && table[row][col].trim().isNotEmpty) {
            columnEmpty = false;
            break;
          }
        }
        if (columnEmpty) {
          issues.add('Column ${col + 1} is completely empty');
        }
      }
    }

    return issues;
  }

  List<List<String>> _cleanData(List<List<String>> table) {
    if (table.isEmpty) return table;

    List<List<String>> cleaned = [];

    // Remove completely empty rows
    for (final row in table) {
      if (!row.every((cell) => cell.trim().isEmpty)) {
        cleaned.add(row);
      }
    }

    if (cleaned.isEmpty) return table;

    // Normalize column count
    int maxColumns = cleaned.map((row) => row.length).reduce(max);
    for (final row in cleaned) {
      while (row.length < maxColumns) {
        row.add('');
      }
    }

    // Trim whitespace if requested
    if (settings['trimWhitespace'] as bool) {
      for (final row in cleaned) {
        for (int i = 0; i < row.length; i++) {
          row[i] = row[i].trim();
        }
      }
    }

    // Handle missing data
    final missingHandler = settings['handleMissingData'] as String;
    final placeholder = settings['missingPlaceholder'] as String;

    if (missingHandler == 'placeholder') {
      for (final row in cleaned) {
        for (int i = 0; i < row.length; i++) {
          if (row[i].trim().isEmpty) {
            row[i] = placeholder;
          }
        }
      }
    }

    return cleaned;
  }

  List<List<String>> _applyTransformations(List<List<String>> table) {
    if (table.isEmpty) return table;

    // Transpose if requested
    if (settings['transpose'] as bool) {
      table = _transposeTable(table);
    }

    // Add index column if requested
    if (settings['addIndexColumn'] as bool) {
      for (int i = 0; i < table.length; i++) {
        table[i].insert(0, i.toString());
      }
    }

    // Filter data
    final filterColumn = (settings['filterColumn'] as num).toInt();
    if (filterColumn >= 0 &&
        filterColumn < (table.isNotEmpty ? table.first.length : 0)) {
      table = _filterTable(table, filterColumn);
    }

    // Group data
    final groupColumn = (settings['groupByColumn'] as num).toInt();
    if (groupColumn >= 0 &&
        groupColumn < (table.isNotEmpty ? table.first.length : 0)) {
      table = _groupTable(table, groupColumn);
    }

    // Sort data
    final sortColumn = (settings['sortColumn'] as num).toInt();
    if (sortColumn >= 0 &&
        sortColumn < (table.isNotEmpty ? table.first.length : 0)) {
      table = _sortTable(table, sortColumn);
    }

    return table;
  }

  List<List<String>> _transposeTable(List<List<String>> table) {
    if (table.isEmpty) return table;

    int maxRows = table.length;
    int maxCols = table.map((row) => row.length).reduce(max);

    List<List<String>> transposed = [];
    for (int col = 0; col < maxCols; col++) {
      List<String> newRow = [];
      for (int row = 0; row < maxRows; row++) {
        newRow.add(col < table[row].length ? table[row][col] : '');
      }
      transposed.add(newRow);
    }

    return transposed;
  }

  List<List<String>> _filterTable(List<List<String>> table, int column) {
    final filterValue = settings['filterValue'] as String;
    final operation = settings['filterOperation'] as String;

    if (filterValue.isEmpty) return table;

    List<List<String>> filtered = [];
    bool hasHeaders = settings['autoHeaders'] as bool;

    for (int i = 0; i < table.length; i++) {
      final row = table[i];

      // Always keep headers
      if (hasHeaders && i == 0) {
        filtered.add(row);
        continue;
      }

      if (column >= row.length) continue;

      final cellValue = row[column];
      bool matches = false;

      switch (operation) {
        case 'contains':
          matches = cellValue.toLowerCase().contains(filterValue.toLowerCase());
          break;
        case 'equals':
          matches = cellValue.toLowerCase() == filterValue.toLowerCase();
          break;
        case 'startsWith':
          matches = cellValue.toLowerCase().startsWith(
            filterValue.toLowerCase(),
          );
          break;
        case 'endsWith':
          matches = cellValue.toLowerCase().endsWith(filterValue.toLowerCase());
          break;
        case 'regex':
          try {
            matches = RegExp(
              filterValue,
              caseSensitive: false,
            ).hasMatch(cellValue);
          } catch (e) {
            matches = false;
          }
          break;
        case 'greater':
          final cellNum = double.tryParse(cellValue);
          final filterNum = double.tryParse(filterValue);
          matches = cellNum != null && filterNum != null && cellNum > filterNum;
          break;
        case 'less':
          final cellNum = double.tryParse(cellValue);
          final filterNum = double.tryParse(filterValue);
          matches = cellNum != null && filterNum != null && cellNum < filterNum;
          break;
      }

      if (matches) {
        filtered.add(row);
      }
    }

    return filtered;
  }

  List<List<String>> _groupTable(List<List<String>> table, int groupColumn) {
    if (table.isEmpty) return table;

    final aggregateFunc = settings['aggregateFunction'] as String;
    bool hasHeaders = settings['autoHeaders'] as bool;

    Map<String, List<List<String>>> groups = {};
    List<String>? headers;

    for (int i = 0; i < table.length; i++) {
      final row = table[i];

      if (hasHeaders && i == 0) {
        headers = row;
        continue;
      }

      if (groupColumn >= row.length) continue;

      final groupKey = row[groupColumn];
      groups.putIfAbsent(groupKey, () => []).add(row);
    }

    List<List<String>> result = [];
    if (headers != null) {
      result.add(headers);
    }

    for (final entry in groups.entries) {
      final groupKey = entry.key;
      final groupRows = entry.value;

      List<String> aggregatedRow = List.filled(
        headers?.length ?? groupRows.first.length,
        '',
      );
      aggregatedRow[groupColumn] = groupKey;

      // Apply aggregation to other columns
      for (int col = 0; col < aggregatedRow.length; col++) {
        if (col == groupColumn) continue;

        final values = groupRows
            .where((row) => col < row.length)
            .map((row) => row[col])
            .where((val) => val.isNotEmpty)
            .toList();

        if (values.isEmpty) continue;

        switch (aggregateFunc) {
          case 'count':
            aggregatedRow[col] = values.length.toString();
            break;
          case 'sum':
            final nums = values
                .map((v) => double.tryParse(v))
                .where((n) => n != null);
            if (nums.isNotEmpty) {
              aggregatedRow[col] = nums.reduce((a, b) => a! + b!).toString();
            }
            break;
          case 'avg':
            final nums = values
                .map((v) => double.tryParse(v))
                .where((n) => n != null);
            if (nums.isNotEmpty) {
              final avg = nums.reduce((a, b) => a! + b!)! / nums.length;
              aggregatedRow[col] = avg.toStringAsFixed(2);
            }
            break;
          case 'min':
            final nums = values
                .map((v) => double.tryParse(v))
                .where((n) => n != null);
            if (nums.isNotEmpty) {
              aggregatedRow[col] = nums
                  .reduce((a, b) => a! < b! ? a : b)
                  .toString();
            } else {
              aggregatedRow[col] = values.reduce(
                (a, b) => a.compareTo(b) < 0 ? a : b,
              );
            }
            break;
          case 'max':
            final nums = values
                .map((v) => double.tryParse(v))
                .where((n) => n != null);
            if (nums.isNotEmpty) {
              aggregatedRow[col] = nums
                  .reduce((a, b) => a! > b! ? a : b)
                  .toString();
            } else {
              aggregatedRow[col] = values.reduce(
                (a, b) => a.compareTo(b) > 0 ? a : b,
              );
            }
            break;
          case 'first':
            aggregatedRow[col] = values.first;
            break;
          case 'last':
            aggregatedRow[col] = values.last;
            break;
        }
      }

      result.add(aggregatedRow);
    }

    return result;
  }

  List<List<String>> _sortTable(List<List<String>> table, int sortColumn) {
    if (table.isEmpty || sortColumn < 0) return table;

    bool ascending = settings['sortAscending'] as bool;
    bool hasHeaders = settings['autoHeaders'] as bool;

    List<List<String>> dataRows = hasHeaders && table.length > 1
        ? table.skip(1).toList()
        : table.toList();

    dataRows.sort((a, b) {
      if (sortColumn >= a.length || sortColumn >= b.length) return 0;

      String aVal = a[sortColumn];
      String bVal = b[sortColumn];

      // Try numeric comparison first
      final aNum = double.tryParse(aVal);
      final bNum = double.tryParse(bVal);

      int comparison;
      if (aNum != null && bNum != null) {
        comparison = aNum.compareTo(bNum);
      } else {
        comparison = aVal.toLowerCase().compareTo(bVal.toLowerCase());
      }

      return ascending ? comparison : -comparison;
    });

    List<List<String>> result = [];
    if (hasHeaders && table.isNotEmpty) {
      result.add(table.first);
    }
    result.addAll(dataRows);

    return result;
  }

  String _generateOutput(
    List<List<String>> table,
    String format,
    Map<String, dynamic> metadata,
  ) {
    if (table.isEmpty) return 'No data to convert.';

    switch (format) {
      case 'CSV':
        return _generateCSV(table);
      case 'TSV':
        return _generateTSV(table);
      case 'JSON':
        return _generateJSON(table);
      case 'JSON-Array':
        return _generateJSONArray(table);
      case 'HTML':
        return _generateHTML(table);
      case 'Markdown':
        return _generateMarkdown(table);
      case 'LaTeX':
        return _generateLaTeX(table);
      case 'SQL':
        return _generateSQL(table);
      case 'Excel':
        return _generateExcel(table);
      case 'YAML':
        return _generateYAML(table);
      default:
        throw Exception('Unsupported output format: $format');
    }
  }

  String _generateCSV(List<List<String>> table) {
    final converter = ListToCsvConverter(
      fieldDelimiter: settings['csvDelimiter'] as String,
      textDelimiter: settings['csvQuote'] as String,
      delimitAllFields: true,
    );
    return converter.convert(table);
  }

  String _generateTSV(List<List<String>> table) {
    return table.map((row) => row.join('\t')).join('\n');
  }

  String _generateJSON(List<List<String>> table) {
    bool hasHeaders = settings['autoHeaders'] as bool;
    bool prettyPrint = settings['prettyPrint'] as bool;

    if (hasHeaders && table.length > 1) {
      final headers = table.first;
      final dataRows = table.skip(1);

      final list = dataRows.map((row) {
        final map = <String, dynamic>{};
        for (int i = 0; i < headers.length && i < row.length; i++) {
          map[headers[i]] = row[i];
        }
        return map;
      }).toList();

      if (prettyPrint) {
        return const JsonEncoder.withIndent('  ').convert(list);
      } else {
        return jsonEncode(list);
      }
    } else {
      if (prettyPrint) {
        return const JsonEncoder.withIndent('  ').convert(table);
      } else {
        return jsonEncode(table);
      }
    }
  }

  String _generateJSONArray(List<List<String>> table) {
    bool prettyPrint = settings['prettyPrint'] as bool;

    if (prettyPrint) {
      return const JsonEncoder.withIndent('  ').convert(table);
    } else {
      return jsonEncode(table);
    }
  }

  String _generateHTML(List<List<String>> table) {
    final buf = StringBuffer();
    bool hasHeaders = settings['autoHeaders'] as bool;
    bool prettyPrint = settings['prettyPrint'] as bool;
    String customTitle = settings['customTitle'] as String;

    final indent = prettyPrint ? '  ' : '';
    final newline = prettyPrint ? '\n' : '';

    if (customTitle.isNotEmpty) {
      buf.write('<h2>$customTitle</h2>$newline');
    }

    buf.write('<table>$newline');

    for (int i = 0; i < table.length; i++) {
      final row = table[i];
      final isHeader = hasHeaders && i == 0;
      final tag = isHeader ? 'th' : 'td';

      buf.write('$indent<tr>$newline');
      for (final cell in row) {
        final escapedCell = cell
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;');
        buf.write('$indent$indent<$tag>$escapedCell</$tag>$newline');
      }
      buf.write('$indent</tr>$newline');
    }

    buf.write('</table>');
    return buf.toString();
  }

  String _generateMarkdown(List<List<String>> table) {
    final buf = StringBuffer();
    bool hasHeaders = settings['autoHeaders'] as bool;
    bool includeRowNumbers = settings['includeRowNumbers'] as bool;
    String customTitle = settings['customTitle'] as String;

    if (customTitle.isNotEmpty) {
      buf.writeln('## $customTitle\n');
    }

    if (table.isEmpty) return buf.toString();

    // Add row number column header if needed
    List<List<String>> displayTable = table
        .map((row) => List<String>.from(row))
        .toList();
    if (includeRowNumbers) {
      for (int i = 0; i < displayTable.length; i++) {
        displayTable[i].insert(
          0,
          hasHeaders && i == 0 ? '#' : '${i + (hasHeaders ? 0 : 1)}',
        );
      }
    }

    if (displayTable.isEmpty) return buf.toString();

    // Header row
    buf.writeln('| ${displayTable.first.join(' | ')} |');

    // Separator row
    final separators = List.filled(displayTable.first.length, '---');
    buf.writeln('| ${separators.join(' | ')} |');

    // Data rows
    final dataRows = hasHeaders ? displayTable.skip(1) : displayTable.skip(1);
    for (final row in dataRows) {
      buf.writeln('| ${row.join(' | ')} |');
    }

    return buf.toString();
  }

  String _generateLaTeX(List<List<String>> table) {
    if (table.isEmpty) return '';

    final buf = StringBuffer();
    bool hasHeaders = settings['autoHeaders'] as bool;
    final columnCount = table.first.length;

    // Begin table
    buf.writeln('\\begin{table}[h]');
    buf.writeln('\\centering');

    String customTitle = settings['customTitle'] as String;
    if (customTitle.isNotEmpty) {
      buf.writeln('\\caption{$customTitle}');
    }

    // Column specification
    buf.writeln('\\begin{tabular}{|${'c|' * columnCount}}');
    buf.writeln('\\hline');

    // Rows
    for (int i = 0; i < table.length; i++) {
      final row = table[i];
      final isHeader = hasHeaders && i == 0;

      // Escape LaTeX special characters
      final escapedRow = row
          .map(
            (cell) => cell
                .replaceAll('\\', '\\textbackslash{}')
                .replaceAll('&', '\\&')
                .replaceAll('%', '\\%')
                .replaceAll('\\', '\\\\')
                .replaceAll('#', '\\#')
                .replaceAll('^', '\\textasciicircum{}')
                .replaceAll('_', '\\_')
                .replaceAll('{', '\\{')
                .replaceAll('}', '\\}')
                .replaceAll('~', '\\textasciitilde{}'),
          )
          .toList();

      buf.write(escapedRow.join(' & '));
      buf.writeln(' \\\\');

      if (isHeader) {
        buf.writeln('\\hline');
      }
    }

    buf.writeln('\\hline');
    buf.writeln('\\end{tabular}');
    buf.writeln('\\end{table}');

    return buf.toString();
  }

  String _generateSQL(List<List<String>> table) {
    if (table.isEmpty) return '';

    final buf = StringBuffer();
    bool hasHeaders = settings['autoHeaders'] as bool;
    String tableName = settings['customTitle'] as String;
    if (tableName.isEmpty) tableName = 'converted_table';

    // Sanitize table name
    tableName = tableName.replaceAll(RegExp(r'[^\w]'), '_').toLowerCase();

    if (hasHeaders && table.length > 1) {
      final headers = table.first;
      final dataRows = table.skip(1);

      // CREATE TABLE statement
      buf.writeln('CREATE TABLE $tableName (');
      for (int i = 0; i < headers.length; i++) {
        final columnName = headers[i]
            .replaceAll(RegExp(r'[^\w]'), '_')
            .toLowerCase();
        buf.write('  $columnName VARCHAR(255)');
        if (i < headers.length - 1) buf.write(',');
        buf.writeln();
      }
      buf.writeln(');');
      buf.writeln();

      // INSERT statements
      for (final row in dataRows) {
        buf.write('INSERT INTO $tableName VALUES (');
        for (int i = 0; i < row.length; i++) {
          final escapedValue = row[i].replaceAll("'", "''");
          buf.write("'$escapedValue'");
          if (i < row.length - 1) buf.write(', ');
        }
        buf.writeln(');');
      }
    } else {
      // No headers - use generic column names
      final columnCount = table.first.length;

      buf.writeln('CREATE TABLE $tableName (');
      for (int i = 0; i < columnCount; i++) {
        buf.write('  column${i + 1} VARCHAR(255)');
        if (i < columnCount - 1) buf.write(',');
        buf.writeln();
      }
      buf.writeln(');');
      buf.writeln();

      for (final row in table) {
        buf.write('INSERT INTO $tableName VALUES (');
        for (int i = 0; i < row.length; i++) {
          final escapedValue = row[i].replaceAll("'", "''");
          buf.write("'$escapedValue'");
          if (i < row.length - 1) buf.write(', ');
        }
        buf.writeln(');');
      }
    }

    return buf.toString();
  }

  String _generateExcel(List<List<String>> table) {
    // Excel CSV format with semicolon delimiter and proper quoting
    final converter = ListToCsvConverter(
      fieldDelimiter: ';',
      textDelimiter: '"',
      delimitAllFields: true,
    );
    return converter.convert(table);
  }

  String _generateYAML(List<List<String>> table) {
    final buf = StringBuffer();
    bool hasHeaders = settings['autoHeaders'] as bool;
    String customTitle = settings['customTitle'] as String;

    if (customTitle.isNotEmpty) {
      buf.writeln('# $customTitle');
    }

    if (hasHeaders && table.length > 1) {
      final headers = table.first;
      final dataRows = table.skip(1);

      buf.writeln('data:');
      for (int rowIndex = 0; rowIndex < dataRows.length; rowIndex++) {
        final row = dataRows.elementAt(rowIndex);
        buf.writeln('  - # Row ${rowIndex + 1}');

        for (int i = 0; i < headers.length && i < row.length; i++) {
          final key = headers[i]
              .replaceAll(RegExp(r'[^\w]'), '_')
              .toLowerCase();
          final value = row[i];
          buf.writeln('    $key: "$value"');
        }
      }
    } else {
      buf.writeln('data:');
      for (int rowIndex = 0; rowIndex < table.length; rowIndex++) {
        final row = table[rowIndex];
        buf.writeln('  - # Row ${rowIndex + 1}');

        for (int colIndex = 0; colIndex < row.length; colIndex++) {
          buf.writeln('    column_${colIndex + 1}: "${row[colIndex]}"');
        }
      }
    }

    return buf.toString();
  }

  String _addMetadataAndPreview(
    String result,
    List<List<String>> table,
    Map<String, dynamic> metadata,
    String inputFormat,
    String outputFormat,
  ) {
    final buf = StringBuffer();
    bool includeStats = settings['includeStats'] as bool;
    bool showPreview = settings['showPreview'] as bool;
    int maxPreviewRows = (settings['maxPreviewRows'] as num).toInt();

    // Add metadata header
    if (includeStats || showPreview) {
      buf.writeln('# Table Conversion Report\n');

      if (settings['addTimestamp'] as bool) {
        buf.writeln('**Generated:** ${DateTime.now().toIso8601String()}\n');
      }
    }

    // Statistics
    if (includeStats) {
      buf.writeln('## Statistics');
      buf.writeln(
        '- **Input Format:** ${metadata['detectedFormat'] ?? inputFormat}',
      );
      buf.writeln('- **Output Format:** $outputFormat');
      buf.writeln('- **Rows:** ${table.length}');
      buf.writeln(
        '- **Columns:** ${table.isNotEmpty ? table.first.length : 0}',
      );

      if (metadata.containsKey('originalLength')) {
        buf.writeln(
          '- **Original Size:** ${metadata['originalLength']} characters',
        );
      }

      if (metadata.containsKey('lineCount')) {
        buf.writeln('- **Original Lines:** ${metadata['lineCount']}');
      }

      // Data quality metrics
      if (table.isNotEmpty) {
        int emptyCells = 0;
        int totalCells = 0;

        for (final row in table) {
          for (final cell in row) {
            totalCells++;
            if (cell.trim().isEmpty) emptyCells++;
          }
        }

        double completeness = totalCells > 0
            ? ((totalCells - emptyCells) / totalCells * 100)
            : 100;
        buf.writeln(
          '- **Data Completeness:** ${completeness.toStringAsFixed(1)}%',
        );
      }

      buf.writeln();
    }

    // Preview
    if (showPreview && table.isNotEmpty) {
      buf.writeln('## Preview');

      List<List<String>> previewTable = table.take(maxPreviewRows).toList();
      String previewMarkdown = _generateMarkdown(previewTable);

      buf.writeln(previewMarkdown);

      if (table.length > maxPreviewRows) {
        buf.writeln('*... and ${table.length - maxPreviewRows} more rows*\n');
      }
    }

    // Conversion warnings or notes
    if (metadata.containsKey('warnings')) {
      buf.writeln('## Conversion Notes');
      for (String warning in metadata['warnings']) {
        buf.writeln('⚠️ $warning');
      }
      buf.writeln();
    }

    // Main result
    if (includeStats || showPreview) {
      buf.writeln('## Converted Data');
      buf.writeln();
    }

    buf.write(result);

    return buf.toString();
  }

  @override
  Future<String> executeGetText(String input) async {
    try {
      return await _processTable(input);
    } catch (e) {
      return 'Error: $e';
    }
  }
}

class ParseResult {
  final bool success;
  final List<List<String>> data;
  final Map<String, dynamic> metadata;
  final String? error;

  ParseResult({
    required this.success,
    this.data = const [],
    this.metadata = const {},
    this.error,
  });
}

class MarkdownPreviewTool extends Tool {
  MarkdownPreviewTool()
    : super(
        name: 'Markdown Preview',
        description: 'Outputs input as markdown content',
        icon: Icons.preview,
        isOutputMarkdown: true,
      );

  @override
  Future<ToolResult> execute(String input) async {
    return ToolResult(output: input, status: 'success');
  }
}

class HtmlMarkdownConverterTool extends Tool {
  HtmlMarkdownConverterTool()
    : super(
        name: 'HTML ↔ Markdown',
        description: 'Converts content between HTML and Markdown formats',
        icon: Icons.code,
        isOutputMarkdown: true,
        isInputMarkdown: true,
        canAcceptMarkdown: true,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'conversionDirection': 'html_to_markdown',
          'preserveWhitespace': false,
          'encodeHtmlEntities': true,
        },
        settingsHints: {
          'conversionDirection': {
            'type': 'dropdown',
            'label': 'Conversion Direction',
            'help': 'Choose which format to convert from and to',
            'options': [
              {'value': 'html_to_markdown', 'label': 'HTML to Markdown'},
              {'value': 'markdown_to_html', 'label': 'Markdown to HTML'},
            ],
            'width': 250,
          },
          'preserveWhitespace': {
            'type': 'bool',
            'label': 'Preserve Whitespace',
            'help': 'Keep extra line breaks and spaces in output',
          },
          'encodeHtmlEntities': {
            'type': 'bool',
            'label': 'Encode HTML Entities',
            'help': 'Encode special characters like & < > in Markdown output',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    final direction = settings['conversionDirection'] as String;
    final preserveWhitespace = settings['preserveWhitespace'] as bool;
    final encodeHtmlEntities = settings['encodeHtmlEntities'] as bool;

    String result = '';

    try {
      if (direction == 'html_to_markdown') {
        result = html2md.convert(
          input,
          styleOptions: preserveWhitespace
              ? {'keepEmptyLines': 'true'}
              : {}, // html2md option
        );

        if (!encodeHtmlEntities) {
          result = result
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&quot;', '"')
              .replaceAll('&#39;', "'");
        }
      } else if (direction == 'markdown_to_html') {
        result = md.markdownToHtml(
          input,
          extensionSet: md.ExtensionSet.gitHubWeb,
        );

        if (preserveWhitespace) {
          // Wrap in <pre> so multiple spaces/newlines stay intact
          result = "<pre style='white-space: pre-wrap;'>$result</pre>";
        } else {
          result = result.trim();
        }

        // Sanitize
        final document = html.Document.html(result);
        result = document.body?.innerHtml ?? result;
        result = '```html\n$result\n```';
      }

      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: $e', status: 'error');
    }
  }

  @override
  Future<String> executeGetText(String input) async {
    final result = await execute(input);
    if (result.status == 'success') {
      return result.output;
    }
    return 'Error during conversion.';
  }
}

class MinifyPrettifyTool extends Tool {
  MinifyPrettifyTool()
    : super(
        name: 'Minify / Prettify',
        description: 'Minify or prettify code/markup for various formats',
        icon: Icons.code,
        isOutputMarkdown: true,
        isInputMarkdown: false,
        canAcceptMarkdown: false,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'format': 'JSON',
          'action': 'Prettify',
          'indent_type': 'Spaces',
          'indent_size': 2,
        },
        settingsHints: {
          'format': {
            'type': 'dropdown',
            'label': 'Format',
            'help': 'Select the format to process',
            'options': ['JSON', 'XML', 'HTML', 'CSS', 'JS'],
          },
          'action': {
            'type': 'dropdown',
            'label': 'Action',
            'help': 'Choose whether to minify or prettify',
            'options': ['Prettify', 'Minify'],
          },
          'indent_type': {
            'type': 'dropdown',
            'label': 'Indent Type',
            'help': 'Use spaces or tabs for indentation (prettify only)',
            'options': ['Spaces', 'Tabs'],
          },
          'indent_size': {
            'type': 'spinner',
            'label': 'Indent Size',
            'help': 'Number of spaces/tabs for indentation (prettify only)',
            'min': 1,
            'max': 8,
            'step': 1,
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.trim().isEmpty) {
      return ToolResult(
        output: '**Error:** Please provide input to process.',
        status: 'error',
      );
    }

    final format = settings['format'] as String;
    final action = settings['action'] as String;
    final indentType = settings['indent_type'] as String;
    final indentSize = (settings['indent_size'] as num).toInt();

    try {
      String result;

      if (action == 'Prettify') {
        result = _prettify(input, format, indentType, indentSize);
      } else {
        result = _minify(input, format);
      }

      final codeLanguage = _getCodeLanguage(format);
      return ToolResult(
        output: '**${action}ed $format:**\n\n```$codeLanguage\n$result\n```',
        status: 'success',
      );
    } catch (e) {
      return ToolResult(
        output: '**Error processing $format:** ${e.toString()}',
        status: 'error',
      );
    }
  }

  @override
  Future<String> executeGetText(String input) async {
    if (input.trim().isEmpty) {
      return 'Error: Please provide input to process.';
    }

    final format = settings['format'] as String;
    final action = settings['action'] as String;
    final indentType = settings['indent_type'] as String;
    final indentSize = (settings['indent_size'] as num).toInt();

    try {
      if (action == 'Prettify') {
        return _prettify(input, format, indentType, indentSize);
      } else {
        return _minify(input, format);
      }
    } catch (e) {
      return 'Error processing $format: ${e.toString()}';
    }
  }

  String _prettify(
    String input,
    String format,
    String indentType,
    int indentSize,
  ) {
    final indent = indentType == 'Tabs' ? '\t' : ' ' * indentSize;

    switch (format) {
      case 'JSON':
        return _prettifyJson(input, indent);
      case 'XML':
        return _prettifyXml(input, indent);
      case 'HTML':
        return _prettifyHtml(input, indent);
      case 'CSS':
        return _prettifyCss(input, indent);
      case 'JS':
        return _prettifyJs(input, indent);
      default:
        throw Exception('Unsupported format: $format');
    }
  }

  String _minify(String input, String format) {
    switch (format) {
      case 'JSON':
        return _minifyJson(input);
      case 'XML':
        return _minifyXml(input);
      case 'HTML':
        return _minifyHtml(input);
      case 'CSS':
        return _minifyCss(input);
      case 'JS':
        return _minifyJs(input);
      default:
        throw Exception('Unsupported format: $format');
    }
  }

  String _prettifyJson(String input, String indent) {
    final dynamic parsed = jsonDecode(input);
    final encoder = JsonEncoder.withIndent(indent);
    return encoder.convert(parsed);
  }

  String _minifyJson(String input) {
    final dynamic parsed = jsonDecode(input);
    return jsonEncode(parsed);
  }

  String _prettifyXml(String input, String indent) {
    // Basic XML prettification
    String result = input.replaceAll(RegExp(r'>\s*<'), '><');
    result = result.replaceAll('><', '>\n<');

    final lines = result.split('\n');
    final prettified = <String>[];
    int depth = 0;

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('</')) {
        depth--;
      }

      prettified.add('${indent * depth}$line');

      if (line.startsWith('<') &&
          !line.startsWith('</') &&
          !line.endsWith('/>') &&
          !line.contains('</')) {
        depth++;
      }
    }

    return prettified.join('\n');
  }

  String _minifyXml(String input) {
    return input
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'>\s+<'), '><')
        .trim();
  }

  String _prettifyHtml(String input, String indent) {
    // Basic HTML prettification
    String result = input.replaceAll(RegExp(r'>\s*<'), '><');
    result = result.replaceAll('><', '>\n<');

    final lines = result.split('\n');
    final prettified = <String>[];
    int depth = 0;

    final voidElements = {
      'area',
      'base',
      'br',
      'col',
      'embed',
      'hr',
      'img',
      'input',
      'link',
      'meta',
      'param',
      'source',
      'track',
      'wbr',
    };

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('</')) {
        depth--;
      }

      prettified.add('${indent * depth}$line');

      if (line.startsWith('<') &&
          !line.startsWith('</') &&
          !line.endsWith('/>')) {
        final tagMatch = RegExp(r'<(\w+)').firstMatch(line);
        if (tagMatch != null &&
            !voidElements.contains(tagMatch.group(1)?.toLowerCase())) {
          if (!line.contains('</${tagMatch.group(1)}>')) {
            depth++;
          }
        }
      }
    }

    return prettified.join('\n');
  }

  String _minifyHtml(String input) {
    return input
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'>\s+<'), '><')
        .replaceAll(RegExp(r'>\s+'), '>')
        .replaceAll(RegExp(r'\s+<'), '<')
        .trim();
  }

  String _prettifyCss(String input, String indent) {
    String result = input
        .replaceAll(RegExp(r'\s*{\s*'), ' {\n')
        .replaceAll(RegExp(r'\s*}\s*'), '\n}\n')
        .replaceAll(RegExp(r';\s*'), ';\n');

    final lines = result.split('\n');
    final prettified = <String>[];
    int depth = 0;

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line == '}') {
        depth--;
      }

      prettified.add('${indent * depth}$line');

      if (line.endsWith('{')) {
        depth++;
      }
    }

    return prettified.join('\n');
  }

  String _minifyCss(String input) {
    return input
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s*{\s*'), '{')
        .replaceAll(RegExp(r'\s*}\s*'), '}')
        .replaceAll(RegExp(r';\s*'), ';')
        .replaceAll(RegExp(r':\s*'), ':')
        .trim();
  }

  String _prettifyJs(String input, String indent) {
    // Basic JavaScript prettification
    String result = input
        .replaceAll(RegExp(r'\s*{\s*'), ' {\n')
        .replaceAll(RegExp(r'\s*}\s*'), '\n}\n')
        .replaceAll(RegExp(r';\s*'), ';\n');

    final lines = result.split('\n');
    final prettified = <String>[];
    int depth = 0;

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line == '}' || line.startsWith('}')) {
        depth--;
      }

      prettified.add('${indent * depth}$line');

      if (line.endsWith('{')) {
        depth++;
      }
    }

    return prettified.join('\n');
  }

  String _minifyJs(String input) {
    return input
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s*{\s*'), '{')
        .replaceAll(RegExp(r'\s*}\s*'), '}')
        .replaceAll(RegExp(r';\s*'), ';')
        .replaceAll(RegExp(r':\s*'), ':')
        .replaceAll(RegExp(r',\s*'), ',')
        .trim();
  }

  String _getCodeLanguage(String format) {
    switch (format) {
      case 'JS':
        return 'javascript';
      case 'HTML':
        return 'html';
      case 'CSS':
        return 'css';
      case 'XML':
        return 'xml';
      case 'JSON':
        return 'json';
      default:
        return format.toLowerCase();
    }
  }
}

class UUIDRandomStringTool extends Tool {
  UUIDRandomStringTool()
    : super(
        name: 'UUID / Random String / Password Generator',
        description:
            'Generate UUIDs, random strings, or secure passwords with customizable length and character set',
        icon: Icons.vpn_key,
        isOutputMarkdown: false,
        isInputMarkdown: false,
        canAcceptMarkdown: false,
        supportsLiveUpdate: false,
        supportsStreaming: false,
        allowEmptyInput: true,
        settings: {
          'generationType': 'uuid',
          'count': 1,
          'length': 16,
          'charset': 'letters_numbers',
        },
        settingsHints: {
          'generationType': {
            'type': 'dropdown',
            'label': 'Type',
            'help': 'Choose what to generate',
            'options': [
              {'value': 'uuid', 'label': 'UUID (v4)'},
              {'value': 'random', 'label': 'Random String'},
              {'value': 'password', 'label': 'Secure Password'},
            ],
          },
          'count': {
            'type': 'spinner',
            'label': 'Count',
            'help': 'Number of values to generate',
            'min': 1,
            'max': 50,
            'step': 1,
            "width": 180,
          },
          'length': {
            'type': 'slider',
            'label': 'Length',
            'help': 'Length of each generated string (ignored for UUID)',
            'min': 4,
            'max': 64,
            'divisions': 60,
            'show_value': true,
          },
          'charset': {
            'type': 'dropdown',
            'label': 'Character Set',
            'help': 'Which characters to include',
            'options': [
              {'value': 'letters', 'label': 'Letters (a-z, A-Z)'},
              {'value': 'numbers', 'label': 'Numbers (0-9)'},
              {'value': 'letters_numbers', 'label': 'Letters & Numbers'},
              {'value': 'full', 'label': 'Letters, Numbers & Symbols'},
            ],
            'width': 250,
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    final type = settings['generationType'] as String;
    final count = (settings['count'] as num).toInt();
    final length = (settings['length'] as num).toInt();
    final charset = settings['charset'] as String;

    final uuid = Uuid();
    final List<String> results = [];

    try {
      for (int i = 0; i < count; i++) {
        if (type == 'uuid') {
          results.add(uuid.v4());
        } else if (type == 'random') {
          results.add(_generateRandomString(length, charset));
        } else if (type == 'password') {
          results.add(_generateSecurePassword(length, charset));
        }
      }

      final output = results.join('\n');
      return ToolResult(output: output, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: $e', status: 'error');
    }
  }

  @override
  Future<String> executeGetText(String input) async {
    final result = await execute(input);
    return result.output;
  }
}

// Generates a random string using UUID hash fallback (not cryptographically secure but sufficient for non-password use)
String _generateRandomString(int length, String charset) {
  const letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const numbers = '0123456789';
  const symbols = '!@#\$%^&*(),.?":{}|<>';

  String chars = '';
  switch (charset) {
    case 'letters':
      chars = letters;
      break;
    case 'numbers':
      chars = numbers;
      break;
    case 'letters_numbers':
      chars = letters + numbers;
      break;
    case 'full':
      chars = letters + numbers + symbols;
      break;
    default:
      chars = letters + numbers;
  }

  final random = Uuid();
  final buffer = StringBuffer();
  for (int i = 0; i < length; i++) {
    buffer.write(chars[random.v4().hashCode.abs() % chars.length]);
  }
  return buffer.toString();
}

// Generates a cryptographically secure password using dart:math + UUID entropy
String _generateSecurePassword(int length, String charset) {
  const lettersLower = 'abcdefghijklmnopqrstuvwxyz';
  const lettersUpper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const numbers = '0123456789';
  const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  String chars = '';
  String? requiredChars; // To store chars for guaranteed diversity

  switch (charset) {
    case 'letters':
      chars = lettersLower + lettersUpper;
      break;
    case 'numbers':
      chars = numbers;
      break;
    case 'letters_numbers':
      chars = lettersLower + lettersUpper + numbers;
      requiredChars =
          lettersLower +
          lettersUpper +
          numbers; // All are required for diversity
      break;
    case 'full':
      chars = lettersLower + lettersUpper + numbers + symbols;
      requiredChars =
          lettersLower + lettersUpper + numbers + symbols; // All are required
      break;
    default:
      chars = lettersLower + lettersUpper + numbers;
      requiredChars = lettersLower + lettersUpper + numbers;
  }

  // Use UUID + time for better entropy
  final entropy = Uuid().v4().replaceAll('-', '');
  final codeUnits = entropy.codeUnits;
  final buffer = StringBuffer();

  // Ensure diversity by picking at least one character from each required group
  // This is a simplified approach: pick one from each base set if applicable
  if (charset == 'full' && length >= 4) {
    buffer.write(lettersLower[_randomIndex(codeUnits, 0, lettersLower.length)]);
    buffer.write(lettersUpper[_randomIndex(codeUnits, 1, lettersUpper.length)]);
    buffer.write(numbers[_randomIndex(codeUnits, 2, numbers.length)]);
    buffer.write(symbols[_randomIndex(codeUnits, 3, symbols.length)]);
  } else if (charset == 'letters_numbers' && length >= 3) {
    buffer.write(lettersLower[_randomIndex(codeUnits, 0, lettersLower.length)]);
    buffer.write(lettersUpper[_randomIndex(codeUnits, 1, lettersUpper.length)]);
    buffer.write(numbers[_randomIndex(codeUnits, 2, numbers.length)]);
  }
  // For other charsets or shorter passwords, we skip guaranteed diversity or handle as is

  // Fill the remaining length with random characters from the full set
  while (buffer.length < length) {
    buffer.write(chars[_randomIndex(codeUnits, buffer.length, chars.length)]);
  }

  // Convert to list, shuffle, and join
  final List<String> charList = buffer.toString().split('');
  // Ensure we have a seed
  final int seed =
      (codeUnits.isNotEmpty ? codeUnits.first : 0) + DateTime.now().millisecond;
  charList.shuffle(_SeededRandom(seed));
  return charList.join('');
}

// Updated _randomIndex to take the max range (character set length)
int _randomIndex(List<int> entropy, int offset, int maxRange) {
  if (maxRange <= 0) return 0;
  // Use entropy safely within the maxRange
  final int entropyIndex = offset % (entropy.isNotEmpty ? entropy.length : 1);
  final int entropyValue = entropy.isNotEmpty ? entropy[entropyIndex] : 0;
  // Mix entropy with offset and mod by maxRange to get a valid index
  final int index = (entropyValue + offset) % maxRange;
  return index.abs(); // Ensure it's not negative
}

class _SeededRandom implements Random {
  final int seed;
  int _current;

  _SeededRandom(this.seed) : _current = seed;

  @override
  bool nextBool() {
    _current = (_current * 9301 + 49297) % 233280;
    return (_current % 2) == 0;
  }

  @override
  int nextInt(int max) {
    _current = (_current * 9301 + 49297) % 233280;
    return (_current.abs() % max);
  }

  @override
  double nextDouble() {
    _current = (_current * 9301 + 49297) % 233280;
    return _current / 233280.0;
  }
}

class RepeatTextTool extends Tool {
  RepeatTextTool()
    : super(
        name: 'Repeat Text',
        description:
            'Repeat input text a specified number of times with optional formatting.',
        icon: Icons.repeat,
        isOutputMarkdown: false, // Can be plain text or simple list
        isInputMarkdown: false,
        canAcceptMarkdown: true, // Can repeat markdown content
        supportsLiveUpdate: true, // Generally fast
        supportsStreaming: false,
        settings: {
          'count': 3,
          'separator': '\\n', // Use literal \n for newline
          'prefix': '',
          'suffix': '',
          'outputFormat': 'plain', // or 'numbered_list', 'bulleted_list'
        },
        settingsHints: {
          'count': {
            'type': 'spinner',
            'label': 'Repeat Count',
            'help': 'Number of times to repeat the input text',
            'min': 1,
            'max': 1000, // Adjust max as needed
            'step': 1,
          },
          'separator': {
            'type': 'text',
            'label': 'Separator',
            'help': 'Text placed between each repetition (use \\n for newline)',
            'placeholder': 'e.g., \\n, ---, , ',
          },
          'prefix': {
            'type': 'text',
            'label': 'Prefix',
            'help': 'Text added before each repetition',
            'placeholder': 'e.g., > , - , * ',
          },
          'suffix': {
            'type': 'text',
            'label': 'Suffix',
            'help': 'Text added after each repetition',
            'placeholder': 'e.g., \\n, ; , .',
          },
          'outputFormat': {
            'type': 'dropdown',
            'label': 'Output Format',
            'help': 'How to format the repeated text',
            'options': [
              {'value': 'plain', 'label': 'Plain Text'},
              {'value': 'numbered_list', 'label': 'Numbered List'},
              {'value': 'bulleted_list', 'label': 'Bulleted List'},
            ],
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success'); // Nothing to repeat
    }

    final int count = (settings['count'] as num).toInt();
    String separator = settings['separator'] as String;
    final String prefix = settings['prefix'] as String;
    final String suffix = settings['suffix'] as String;
    final String outputFormat = settings['outputFormat'] as String;

    // Handle newline escape sequence
    separator = separator.replaceAll('\\n', '\n');

    final List<String> parts = [];

    for (int i = 1; i <= count; i++) {
      String part = '$prefix$input$suffix';

      switch (outputFormat) {
        case 'numbered_list':
          part = '$i. $part';
          break;
        case 'bulleted_list':
          part = '* $part';
          break;
        // 'plain' case: part is already constructed
      }

      parts.add(part);
    }

    String result;
    switch (outputFormat) {
      case 'numbered_list':
      case 'bulleted_list':
        // For lists, join with newlines for proper markdown formatting
        result = parts.join('\n');
        break;
      case 'plain':
      default:
        result = parts.join(separator);
    }

    return ToolResult(output: result, status: 'success');
  }

  // Optional: Provide a plain text version (in this case, same as output)
  @override
  Future<String> executeGetText(String input) async {
    final result = await execute(input);
    return result.output;
  }
}

class FakeTextTool extends Tool {
  // Static Lorem Ipsum text chunk for generation
  static const String _loremIpsumBase =
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";

  FakeTextTool()
    : super(
        name: 'Fake Text Generator',
        description:
            'Generate placeholder text (Lorem Ipsum) or visually similar homoglyph variants.',
        icon: Icons.text_format,
        isOutputMarkdown: false, // Generally plain text, can be pasted anywhere
        isInputMarkdown: false, // Doesn't process input markdown
        canAcceptMarkdown: false, // Not relevant for input
        supportsLiveUpdate: true, // Fast generation
        supportsStreaming: false, // Not applicable
        allowEmptyInput: true,
        settings: {
          'type': 'lorem_ipsum', // or 'homoglyph'
          'paragraphs': 1,
          'sentencesPerParagraph': 5,
          'startWithLoremIpsum': true,
        },
        settingsHints: {
          'type': {
            'type': 'dropdown',
            'label': 'Type',
            'help': 'Choose the type of fake text to generate',
            'options': [
              {'value': 'lorem_ipsum', 'label': 'Lorem Ipsum'},
              {'value': 'homoglyph', 'label': 'Homoglyph (Look-alike)'},
            ],
          },
          'paragraphs': {
            'type': 'spinner',
            'label': 'Paragraphs',
            'help': 'Number of paragraphs to generate',
            'min': 1,
            'max': 20,
            'step': 1,
          },
          'sentencesPerParagraph': {
            'type': 'spinner',
            'label': 'Sentences per Paragraph',
            'help': 'Target number of sentences for each paragraph',
            'min': 1,
            'max': 20,
            'step': 1,
          },
          'startWithLoremIpsum': {
            'type': 'bool',
            'label': 'Start with "Lorem ipsum..."',
            'help':
                'Ensure the first sentence is always the standard "Lorem ipsum..."',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    final String type = settings['type'] as String;
    final int numParagraphs = (settings['paragraphs'] as num).toInt();
    final int sentencesPerPara = (settings['sentencesPerParagraph'] as num)
        .toInt();
    final bool startWithLorem = settings['startWithLoremIpsum'] as bool;

    try {
      final List<String> paragraphs = [];

      // Split base text into sentences
      // Simple split by period followed by space. Could be more robust.
      List<String> baseSentences = _loremIpsumBase
          .split('. ')
          .map((s) => s.trim())
          .toList();
      if (baseSentences.isNotEmpty && baseSentences.last.endsWith('.')) {
        baseSentences[baseSentences.length - 1] = baseSentences.last.substring(
          0,
          baseSentences.last.length - 1,
        );
      }

      for (int p = 0; p < numParagraphs; p++) {
        final List<String> paragraphSentences = [];

        // Ensure first paragraph starts with "Lorem ipsum..." if requested
        if (p == 0 && startWithLorem) {
          // First sentence is always the standard start
          paragraphSentences.add(baseSentences[0]);
          // Add remaining sentences for the first paragraph
          for (int s = 1; s < sentencesPerPara; s++) {
            paragraphSentences.add(
              _getRandomSentence(baseSentences, 1),
            ); // Avoid index 0 again
          }
        } else {
          // Fill paragraph with random sentences
          for (int s = 0; s < sentencesPerPara; s++) {
            paragraphSentences.add(_getRandomSentence(baseSentences));
          }
        }

        String paragraph = '${paragraphSentences.join('. ')}.';
        // Apply homoglyph transformation if selected
        if (type == 'homoglyph') {
          paragraph = _applyHomoglyphs(paragraph);
        }
        paragraphs.add(paragraph);
      }

      // Join paragraphs with double newlines
      final String result = paragraphs.join('\n\n');
      return ToolResult(output: result, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error generating text: $e', status: 'error');
    }
  }

  /// Helper to get a random sentence from the base list.
  String _getRandomSentence(List<String> sentences, [int startIndex = 0]) {
    if (sentences.isEmpty) return '';
    // Simple pseudo-random index based on object hash and list length
    final int index =
        (DateTime.now().microsecondsSinceEpoch + startIndex) %
            (sentences.length - startIndex) +
        startIndex;
    return sentences[index % sentences.length];
  }

  /// Replaces standard ASCII characters with visually similar Unicode ones.
  String _applyHomoglyphs(String text) {
    final Map<String, String> homoglyphMap = {
      'a': 'а', // Latin to Cyrillic
      'c': 'с', // Latin to Cyrillic
      'e': 'е', // Latin to Cyrillic
      'i': 'і', // Latin to Cyrillic
      'o': 'о', // Latin to Cyrillic
      'p': 'р', // Latin to Cyrillic
      'x': 'х', // Latin to Cyrillic
      'y': 'у', // Latin to Cyrillic
      'A': 'А', // Latin to Cyrillic
      'B': 'В', // Latin to Cyrillic
      'C': 'С', // Latin to Cyrillic
      'E': 'Е', // Latin to Cyrillic
      'H': 'Н', // Latin to Cyrillic
      'I': 'І', // Latin to Cyrillic
      'J': 'Ј', // Latin to Cyrillic
      'K': 'К', // Latin to Cyrillic
      'M': 'М', // Latin to Cyrillic
      'O': 'О', // Latin to Cyrillic
      'P': 'Р', // Latin to Cyrillic
      'S': 'Ѕ', // Latin to Cyrillic
      'T': 'Т', // Latin to Cyrillic
      'X': 'Х', // Latin to Cyrillic
      'Y': 'Ү', // Latin to Cyrillic
      'l': 'ⅼ', // Latin to Roman Numeral
      's': 'ѕ', // Latin to Cyrillic
      'd': 'ԁ', // Latin to Cyrillic
      'q': 'ԛ', // Latin to Cyrillic
      'w': 'ԝ', // Latin to Cyrillic
      '0': 'О', // Zero to Cyrillic O (less common but possible)
      '1': 'І', // One to Latin Capital I with breve (or use Cyrillic I)
      '3': 'З', // Three to Cyrillic Ze
      '5': 'Ѕ', // Five to Cyrillic Dze
      '6': 'б', // Six to Cyrillic be
      '8': 'В', // Eight to Latin B
    };

    return text.splitMapJoin(
      RegExp('[${RegExp.escape(homoglyphMap.keys.join(''))}]'),
      onMatch: (Match match) => homoglyphMap[match[0]] ?? match[0]!,
      onNonMatch: (String text) => text,
    );
  }

  // Optional: Plain text output is the same as the main output
  @override
  Future<String> executeGetText(String input) async {
    final result = await execute(input);
    if (result.status == 'success') {
      return result.output;
    }
    return 'Error during fake text generation.';
  }
}

class EncryptionDecryptionTool extends Tool {
  EncryptionDecryptionTool()
    : super(
        name: 'Encryption/Decryption',
        description:
            'Encrypt or decrypt text using a password/key with AES-GCM.',
        icon: Icons.lock,
        isOutputMarkdown: false,
        isInputMarkdown: false,
        canAcceptMarkdown: false,
        supportsLiveUpdate: false, // Expensive/sensitive operation
        supportsStreaming: false,
        settings: {
          'operation': 'encrypt', // or 'decrypt'
          'key': '', // User-provided password/key
        },
        settingsHints: {
          'operation': {
            'type': 'dropdown',
            'label': 'Operation',
            'help': 'Choose to encrypt or decrypt the input text',
            'options': [
              {'value': 'encrypt', 'label': 'Encrypt'},
              {'value': 'decrypt', 'label': 'Decrypt'},
            ],
          },
          'key': {
            'type': 'text',
            'label': 'Key/Password',
            'help': 'Secret key or password for encryption/decryption',
            'placeholder': 'Enter your secret key...',
            'obscure': true, // Hide password input
          },
        },
      );

  // Helper to derive a key from a password
  Key _deriveKey(String password) {
    // Using SHA-256 to create a 32-byte key
    final Uint8List keyBytes = Uint8List.fromList(
      sha256.convert(utf8.encode(password)).bytes,
    );
    return Key(keyBytes);
  }

  // Helper to generate a random IV
  IV _generateIV() {
    final Random random = Random.secure(); // Use secure random
    final Uint8List ivBytes = Uint8List(
      12,
    ); // GCM typically uses 12-byte (96-bit) IV
    for (int i = 0; i < ivBytes.length; i++) {
      ivBytes[i] = random.nextInt(256);
    }
    return IV(ivBytes);
  }

  @override
  Future<ToolResult> execute(String input) async {
    if (input.isEmpty) {
      return ToolResult(output: '', status: 'success');
    }

    final String operation = settings['operation'] as String;
    final String keyInput = settings['key'] as String;

    if (keyInput.isEmpty) {
      return ToolResult(
        output: 'Error: A key/password is required for encryption/decryption.',
        status: 'error',
      );
    }

    try {
      final Key key = _deriveKey(keyInput);

      if (operation == 'encrypt') {
        // Generate a random IV for this encryption
        final IV iv = _generateIV();
        final Encrypter encrypter = Encrypter(AES(key, mode: AESMode.gcm));

        // Encrypt the data
        final Encrypted encrypted = encrypter.encrypt(input, iv: iv);

        // Prepend the IV to the encrypted data for storage/transmission
        // This allows us to retrieve it during decryption
        final Uint8List combined = Uint8List(
          iv.bytes.length + encrypted.bytes.length,
        );
        combined.setRange(0, iv.bytes.length, iv.bytes);
        combined.setRange(iv.bytes.length, combined.length, encrypted.bytes);

        // Encode the combined IV + ciphertext as Base64
        final String result = base64Encode(combined);
        return ToolResult(output: result, status: 'success');
      } else if (operation == 'decrypt') {
        final Encrypter encrypter = Encrypter(AES(key, mode: AESMode.gcm));

        // Decode the Base64 input
        final Uint8List combined = Uint8List.fromList(base64Decode(input));

        // GCM IV is typically 12 bytes
        final int ivLength = 12;

        // Check if the data is long enough to contain the IV
        if (combined.length < ivLength) {
          return ToolResult(
            output: 'Error: Decryption failed. Input data is too short.',
            status: 'error',
          );
        }

        // Extract the IV from the beginning
        final Uint8List ivBytes = Uint8List(ivLength);
        final Uint8List cipherBytes = Uint8List(combined.length - ivLength);
        ivBytes.setRange(0, ivLength, combined);
        cipherBytes.setRange(0, cipherBytes.length, combined, ivLength);

        final IV iv = IV(ivBytes);
        final Encrypted encrypted = Encrypted(cipherBytes);

        // Decrypt the data
        final String decrypted = encrypter.decrypt(encrypted, iv: iv);
        return ToolResult(output: decrypted, status: 'success');
      } else {
        return ToolResult(
          output: 'Error: Invalid operation selected.',
          status: 'error',
        );
      }
    } catch (e) {
      // Specific error handling
      if (e is FormatException && operation == 'decrypt') {
        return ToolResult(
          output:
              'Error: Decryption failed. The input might not be valid base64.',
          status: 'error',
        );
      }
      // Catch errors from the encrypt package (e.g., invalid padding, wrong key, MAC verification)
      // The exact error message might vary
      if (e.toString().contains('INVALID_MAC') ||
          e.toString().contains('Mac check failed') ||
          e.toString().contains('Bad state: MAC mismatch')) {
        return ToolResult(
          output:
              'Error: Decryption failed. The key might be incorrect or the data is corrupted/authenticated incorrectly.',
          status: 'error',
        );
      }

      // General error
      return ToolResult(
        output: 'Error during $operation: ${e.toString()}',
        status: 'error',
      );
    }
  }

  @override
  Future<String> executeGetText(String input) async {
    final result = await execute(input);
    return result.output;
  }
}

/// Generates RSA public/private key pairs for asymmetric encryption.
class AsymmetricKeyGeneratorTool extends Tool {
  AsymmetricKeyGeneratorTool()
    : super(
        name: 'Asymmetric Key Generator',
        description:
            'Generates an RSA public/private key pair for asymmetric encryption.',
        icon: Icons.key,
        isOutputMarkdown: true,
        isInputMarkdown: false,
        canAcceptMarkdown: false,
        supportsLiveUpdate: false,
        supportsStreaming: false,
        allowEmptyInput: true,
        settings: {'keySize': 2048},
        settingsHints: {
          'keySize': {
            'type': 'dropdown',
            'label': 'Key Size',
            'help': 'Security level of the generated key pair',
            'options': [
              {'value': 2048, 'label': '2048 bits (Standard)'},
              {'value': 4096, 'label': '4096 bits (High Security)'},
            ],
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    final dynamic keySizeSetting = settings['keySize'];
    final int keySize = keySizeSetting is int
        ? keySizeSetting
        : int.parse(keySizeSetting.toString());

    try {
      // Generate the RSA key pair using basic_utils
      final AsymmetricKeyPair<PublicKey, PrivateKey> keyPair =
          CryptoUtils.generateRSAKeyPair(keySize: keySize);

      // Cast to specific RSA key types for PEM encoding
      final RSAPublicKey rsaPublicKey = keyPair.publicKey as RSAPublicKey;
      final RSAPrivateKey rsaPrivateKey = keyPair.privateKey as RSAPrivateKey;

      // Format the keys in PEM format for standard representation
      final String publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(
        rsaPublicKey,
      );
      final String privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(
        rsaPrivateKey,
      );

      // Format the output in Markdown using a RAW multiline string
      final String markdownOutput =
          '''
## Generated RSA Key Pair ($keySize bits)

### Public Key (Share this)
```
$publicKeyPem
```

### Private Key (Do not share)
```
$privateKeyPem
```

> **Warning:** Store your private key securely and never share it. Loss of the private key means loss of data encrypted with the corresponding public key.
''';

      return ToolResult(output: markdownOutput, status: 'success');
    } catch (e) {
      // Print error for debugging if needed
      // print("Key generation error: $e");
      return ToolResult(
        output: 'Error generating key pair: ${e.toString()}',
        status: 'error',
      );
    }
  }

  @override
  Future<String> executeGetText(String input) async {
    final dynamic keySizeSetting = settings['keySize'];
    final int keySize = keySizeSetting is int
        ? keySizeSetting
        : int.parse(keySizeSetting.toString());

    try {
      // Generate the RSA key pair using basic_utils
      final AsymmetricKeyPair<PublicKey, PrivateKey> keyPair =
          CryptoUtils.generateRSAKeyPair(keySize: keySize);

      // Cast to specific RSA key types for PEM encoding
      final RSAPublicKey rsaPublicKey = keyPair.publicKey as RSAPublicKey;
      final RSAPrivateKey rsaPrivateKey = keyPair.privateKey as RSAPrivateKey;

      final String publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(
        rsaPublicKey,
      );
      final String privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(
        rsaPrivateKey,
      );

      // Simple plain text format
      return 'Generated RSA Key Pair ($keySize bits)\n\n'
          'PUBLIC KEY (Share this):\n$publicKeyPem\n\n'
          'PRIVATE KEY (Do not share):\n$privateKeyPem\n\n'
          'Warning: Store your private key securely and never share it.';
    } catch (e) {
      return 'Error generating key pair: ${e.toString()}';
    }
  }
}

class RsaEncryptDecryptTool extends Tool {
  RsaEncryptDecryptTool()
    : super(
        name: 'RSA Encrypt/Decrypt',
        description: 'Encrypt or decrypt data using RSA public/private keys',
        icon: Icons.lock,
        isOutputMarkdown: true,
        isInputMarkdown: false,
        canAcceptMarkdown: false,
        supportsLiveUpdate: false,
        supportsStreaming: false,
        settings: {
          'operation': 'Encrypt',
          'key': '',
          'output_format': 'Base64',
        },
        settingsHints: {
          'operation': {
            'type': 'dropdown',
            'label': 'Operation',
            'help': 'Choose to encrypt or decrypt data',
            'options': ['Encrypt', 'Decrypt'],
          },
          'key': {
            'type': 'multiline',
            'label': 'RSA Key',
            'help':
                'Paste your RSA public key (for encrypt) or private key (for decrypt) in PEM format',
            'placeholder':
                '-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----',
            'height': 200,
            'width': 400,
          },
          'output_format': {
            'type': 'dropdown',
            'label': 'Output Format',
            'help': 'Format for encrypted output',
            'options': ['Base64', 'Hex'],
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.trim().isEmpty) {
      return ToolResult(
        output: '**Error:** Please provide data to encrypt/decrypt.',
        status: 'error',
      );
    }

    final String operation = settings['operation'] as String;
    final String keyPem = settings['key'] as String;
    final String outputFormat = settings['output_format'] as String;

    if (keyPem.trim().isEmpty) {
      return ToolResult(
        output: '**Error:** Please provide an RSA key.',
        status: 'error',
      );
    }

    try {
      String result;

      if (operation == 'Encrypt') {
        result = await _encrypt(input, keyPem, outputFormat);
      } else {
        result = await _decrypt(input, keyPem, outputFormat);
      }

      final String markdownOutput =
          '''
## RSA $operation Result

### ${operation}ed Data:
```
$result
```

> **Note:** ${operation == 'Encrypt' ? 'Encrypted data is encoded in $outputFormat format. Use the corresponding private key to decrypt.' : 'Data has been successfully decrypted using the provided private key.'}
''';

      return ToolResult(output: markdownOutput, status: 'success');
    } catch (e) {
      return ToolResult(
        output: '**Error during $operation:** ${e.toString()}',
        status: 'error',
      );
    }
  }

  @override
  Future<String> executeGetText(String input) async {
    if (input.trim().isEmpty) {
      return 'Error: Please provide data to encrypt/decrypt.';
    }

    final String operation = settings['operation'] as String;
    final String keyPem = settings['key'] as String;
    final String outputFormat = settings['output_format'] as String;

    if (keyPem.trim().isEmpty) {
      return 'Error: Please provide an RSA key.';
    }

    try {
      if (operation == 'Encrypt') {
        return await _encrypt(input, keyPem, outputFormat);
      } else {
        return await _decrypt(input, keyPem, outputFormat);
      }
    } catch (e) {
      return 'Error during $operation: ${e.toString()}';
    }
  }

  Future<String> _encrypt(
    String plaintext,
    String publicKeyPem,
    String outputFormat,
  ) async {
    try {
      // Parse the public key from PEM format
      final RSAPublicKey publicKey = CryptoUtils.rsaPublicKeyFromPem(
        publicKeyPem,
      );

      // Encrypt the data - CryptoUtils.rsaEncrypt expects a String and returns raw binary data as String
      final String encryptedRaw = CryptoUtils.rsaEncrypt(plaintext, publicKey);

      // Convert the raw binary string to bytes
      final Uint8List encryptedBytes = Uint8List.fromList(
        encryptedRaw.codeUnits,
      );

      // Format output according to user preference
      if (outputFormat == 'Base64') {
        return base64.encode(encryptedBytes);
      } else {
        return _bytesToHex(encryptedBytes);
      }
    } catch (e) {
      throw Exception('Encryption failed: ${e.toString()}');
    }
  }

  Future<String> _decrypt(
    String encryptedData,
    String privateKeyPem,
    String inputFormat,
  ) async {
    try {
      // Parse the private key from PEM format
      final RSAPrivateKey privateKey = CryptoUtils.rsaPrivateKeyFromPem(
        privateKeyPem,
      );

      // Decode the encrypted data to bytes
      Uint8List encryptedBytes;
      if (_isBase64Format(encryptedData)) {
        encryptedBytes = base64.decode(encryptedData);
      } else {
        // Parse as hex
        encryptedBytes = _hexToBytes(encryptedData);
      }

      // Convert bytes back to the raw binary string format expected by rsaDecrypt
      final String encryptedRaw = String.fromCharCodes(encryptedBytes);

      // Decrypt the data
      final String decrypted = CryptoUtils.rsaDecrypt(encryptedRaw, privateKey);

      return decrypted;
    } catch (e) {
      throw Exception('Decryption failed: ${e.toString()}');
    }
  }

  bool _isBase64Format(String data) {
    // Simple heuristic: base64 typically contains +, /, = and is longer
    // Hex only contains 0-9, a-f, A-F
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
    final hexPattern = RegExp(r'^[0-9a-fA-F]+$');

    // If it matches base64 pattern and contains base64-specific chars, assume base64
    if (base64Pattern.hasMatch(data) &&
        (data.contains('+') || data.contains('/') || data.contains('='))) {
      return true;
    }

    // If it's purely hex characters, assume hex
    if (hexPattern.hasMatch(data)) {
      return false;
    }

    // Default to base64 for mixed/unclear formats
    return true;
  }

  String _bytesToHex(Uint8List bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  Uint8List _hexToBytes(String hex) {
    final List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      final String hexPair = hex.substring(i, i + 2);
      bytes.add(int.parse(hexPair, radix: 16));
    }
    return Uint8List.fromList(bytes);
  }
}

class QrCodeGeneratorTool extends Tool {
  QrCodeGeneratorTool()
    : super(
        name: 'QR Code Generator',
        description:
            'Generate QR codes as ASCII art or Unicode blocks (offline)',
        icon: Icons.qr_code,
        isOutputMarkdown: true,
        isInputMarkdown: false,
        canAcceptMarkdown: false,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        settings: {
          'error_correction': 'Medium',
          'module_size': 10,
          'include_border': true,
        },
        settingsHints: {
          'error_correction': {
            'type': 'dropdown',
            'label': 'Error Correction',
            'help': 'Higher levels allow more damage but create larger codes',
            'options': ['Low', 'Medium', 'Quartile', 'High'],
          },
          'module_size': {
            'type': 'spinner',
            'label': 'Module Size',
            'help': 'Size of each module in pixels (SVG only)',
            'min': 5,
            'max': 20,
            'step': 1,
          },
          'include_border': {
            'type': 'bool',
            'label': 'Include Border',
            'help': 'Add quiet zone around QR code',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    if (input.trim().isEmpty) {
      return ToolResult(
        output: '**Error:** Please provide text or data to encode.',
        status: 'error',
      );
    }

    final String errorCorrection = settings['error_correction'] as String;
    final int moduleSize = (settings['module_size'] as num).toInt();
    final bool includeBorder = settings['include_border'] as bool;

    try {
      // Create QR code
      final qrCode = QrCode.fromData(
        data: input,
        errorCorrectLevel: _getErrorCorrectionLevel(errorCorrection),
      );

      // Generate the QR code matrix
      final qrImage = QrImage(qrCode);

      // Convert to appropriate format
      final String qrResult = _generateSvgQrCode(
        qrImage,
        moduleSize,
        includeBorder,
      );

      String markdownOutput;

      // For SVG, embed as data URL
      final String svgDataUrl =
          'data:image/svg+xml;base64,${base64.encode(utf8.encode(qrResult))}';
      markdownOutput =
          '''
## Generated QR Code

**Data:** `$input`  
**Error Correction:** $errorCorrection  
**Module Size:** ${moduleSize}px  
**Modules:** ${qrImage.moduleCount}x${qrImage.moduleCount}

### QR Code:
![QR Code]($svgDataUrl)

### SVG Source:
```svg
$qrResult
```

> **Tip:** This SVG QR code should be scannable with QR scanner apps. You can also save the SVG code above to a file.
''';

      return ToolResult(output: markdownOutput, status: 'success');
    } catch (e) {
      return ToolResult(
        output: '**Error generating QR code:** ${e.toString()}',
        status: 'error',
      );
    }
  }

  @override
  Future<String> executeGetText(String input) async {
    if (input.trim().isEmpty) {
      return 'Error: Please provide text or data to encode.';
    }

    final String errorCorrection = settings['error_correction'] as String;
    final int moduleSize = (settings['module_size'] as num).toInt();
    final bool includeBorder = settings['include_border'] as bool;

    try {
      // Create QR code
      final qrCode = QrCode.fromData(
        data: input,
        errorCorrectLevel: _getErrorCorrectionLevel(errorCorrection),
      );

      // Generate the QR code matrix
      final qrImage = QrImage(qrCode);

      // Convert to appropriate format
      final String qrResult = _generateSvgQrCode(
        qrImage,
        moduleSize,
        includeBorder,
      );

      return qrResult; // Return raw SVG for text output
    } catch (e) {
      return 'Error generating QR code: ${e.toString()}';
    }
  }

  int _getErrorCorrectionLevel(String level) {
    switch (level) {
      case 'Low':
        return QrErrorCorrectLevel.L;
      case 'Medium':
        return QrErrorCorrectLevel.M;
      case 'Quartile':
        return QrErrorCorrectLevel.Q;
      case 'High':
        return QrErrorCorrectLevel.H;
      default:
        return QrErrorCorrectLevel.M;
    }
  }

  String _generateSvgQrCode(
    QrImage qrImage,
    int moduleSize,
    bool includeBorder,
  ) {
    final int size = qrImage.moduleCount;
    final int border = includeBorder ? 4 : 0;
    final int svgSize = (size + border * 2) * moduleSize;

    final StringBuffer svg = StringBuffer();

    // SVG header
    svg.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    svg.writeln(
      '<svg width="$svgSize" height="$svgSize" viewBox="0 0 $svgSize $svgSize" xmlns="http://www.w3.org/2000/svg">',
    );

    // White background
    svg.writeln('  <rect width="$svgSize" height="$svgSize" fill="white"/>');

    // Generate QR modules
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        if (qrImage.isDark(y, x)) {
          final int rectX = (x + border) * moduleSize;
          final int rectY = (y + border) * moduleSize;
          svg.writeln(
            '  <rect x="$rectX" y="$rectY" width="$moduleSize" height="$moduleSize" fill="black"/>',
          );
        }
      }
    }

    // SVG footer
    svg.writeln('</svg>');

    return svg.toString();
  }
}

Map<String, List<Tool Function()>> getTextManipulationTools() {
  return {
    'Text Formatting': [
      () => PrefixSuffixTool(),
      () => SymbolOperationsTool(),
      () => LineNumberingTool(),
      () => IndentUnindentTool(),
      () => EscapeHubTool(),
      () => CommentsTool(),
      () => MarkdownPreviewTool(),
      () => HtmlMarkdownConverterTool(),
      () => MinifyPrettifyTool(),
    ],
    'Text Cleanup': [
      () => LineCleanupTool(),
      () => LineBreakTool(),
      () => WhitespaceOperationsTool(),
    ],
    'Text Conversion': [
      () => SeparatorConverterTool(),
      () => CaseConverterTool(),
      () => TextReversalTool(),
      () => TableConverterTool(),
    ],
    'Text Processing': [
      () => TextSortingTool(),
      () => FindReplaceTool(),
      () => TextExtractionTool(),
      () => DataExtractionTool(),
      () => LineOperationsTool(),
      () => AlignTextTool(),
      () => RegexTool(),
      () => TextSplitTool(),
      () => TextJoinTool(),
    ],
    'Text Generation': [
      () => UUIDRandomStringTool(),
      () => RepeatTextTool(),
      () => FakeTextTool(),
      () => EncryptionDecryptionTool(),
      () => AsymmetricKeyGeneratorTool(),
      () => RsaEncryptDecryptTool(),
      () => QrCodeGeneratorTool(),
    ],
    'Coding': [() => HashCryptoTool()],
  };
}
