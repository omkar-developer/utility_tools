import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jsf/jsf.dart';
import 'package:utility_tools/models/tool.dart';

class JsTool extends Tool {
  JsRuntime? _js;
  final String script;

  // Static finalizer for automatic cleanup
  static final Finalizer<JsRuntime> _finalizer = Finalizer((js) {
    try {
      js.dispose();
    } catch (e) {
      // Ignore disposal errors during finalization
    }
  });

  JsTool._internal({
    required this.script,
    required super.name,
    required super.description,
    required super.icon,
    required super.isOutputMarkdown,
    required super.isInputMarkdown,
    required super.canAcceptMarkdown,
    required super.supportsLiveUpdate,
    required super.supportsStreaming,
    required super.allowEmptyInput,
    required super.settings,
    required Map<String, dynamic> super.settingsHints,
  });

  static JsTool fromScript(String scriptContent) {
    final js = JsRuntime(); // Create runtime
    js.eval(scriptContent); // Evaluate script here

    dynamic getGlobal(String name, [dynamic def]) {
      try {
        final val = js.eval(name);
        return val ?? def;
      } catch (_) {
        return def;
      }
    }

    final hasExecute = js.eval('typeof execute === "function"');
    if (hasExecute != true) {
      throw 'Script must define an "execute" function';
    }

    final name = getGlobal('name', 'Unnamed Tool') as String;
    final description = getGlobal('description', '') as String;
    final iconName = getGlobal('icon', 'extension') as String;
    final icon = _getIconFromName(iconName);
    final isOutputMarkdown = getGlobal('isOutputMarkdown', false) as bool;
    final isInputMarkdown = getGlobal('isInputMarkdown', false) as bool;
    final canAcceptMarkdown = getGlobal('canAcceptMarkdown', false) as bool;
    final supportsLiveUpdate = getGlobal('supportsLiveUpdate', true) as bool;
    final allowEmptyInput = getGlobal('allowEmptyInput', false) as bool;

    final settingsJson = js.eval('JSON.stringify(settings);');
    final hintsJson = js.eval('JSON.stringify(settingsHints);');

    final settings = (settingsJson != null)
        ? Map<String, dynamic>.from(jsonDecode(settingsJson))
        : <String, dynamic>{};

    final settingsHints = (hintsJson != null)
        ? Map<String, dynamic>.from(jsonDecode(hintsJson))
        : <String, dynamic>{};

    final tool = JsTool._internal(
      script: scriptContent,
      name: name,
      description: description,
      icon: icon,
      isOutputMarkdown: isOutputMarkdown,
      isInputMarkdown: isInputMarkdown,
      canAcceptMarkdown: canAcceptMarkdown,
      supportsLiveUpdate: supportsLiveUpdate,
      supportsStreaming: false,
      allowEmptyInput: allowEmptyInput,
      settings: settings,
      settingsHints: settingsHints,
    );

    // Assign the runtime that has the script
    tool._js?.dispose(); // Dispose the placeholder runtime
    tool._js = js; // Attach the runtime containing the evaluated script

    tool._attachFinalizer();
    return tool;
  }

  // Alternative factory for loading from URL
  static Future<JsTool> fromUrl(String url) async {
    // You'd need to implement HTTP fetching here
    // For web: use dart:html's HttpRequest
    // For other platforms: use http package
    throw UnimplementedError('URL loading not implemented yet');
  }

  @override
  Future<ToolResult> execute(String input) async {
    try {
      // Escape input string properly
      final escapedInput = _escapeJsString(input);

      final jsSettings = _dartToJs(settings);

      // Call execute function with proper string escaping
      final result = _js?.eval('execute("$escapedInput", $jsSettings);');

      return ToolResult(
        output: result?.toString() ?? 'No output',
        status: 'success',
      );
    } catch (e) {
      return ToolResult(output: 'Execution error: $e', status: 'error');
    }
  }

  @override
  Future<String> executeGetText(String input) async {
    try {
      final escapedInput = _escapeJsString(input);
      final jsSettings = _dartToJs(settings);

      final hasFunc = _js?.eval('typeof executeGetText === "function"');
      if (hasFunc == true) {
        final result = _js?.eval(
          'executeGetText("$escapedInput", $jsSettings);',
        );
        return result?.toString() ?? '';
      } else {
        final res = await execute(input);
        return res.output;
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  // Properly dispose of JS runtime
  void dispose() {
    try {
      _finalizer.detach(this);
      _js?.dispose();
    } catch (e) {
      // Ignore disposal errors
    }
  }

  // Attach finalizer for automatic cleanup
  void _attachFinalizer() {
    if (_js != null) _finalizer.attach(this, _js!);
  }

  // Escape strings for safe JS injection
  static String _escapeJsString(String input) {
    return input
        .replaceAll('\\', '\\\\') // Escape backslashes first
        .replaceAll('"', '\\"') // Escape double quotes
        .replaceAll('\n', '\\n') // Escape newlines
        .replaceAll('\r', '\\r') // Escape carriage returns
        .replaceAll('\t', '\\t'); // Escape tabs
  }

  static IconData _getIconFromName(String? iconName) {
    if (iconName == null) return Icons.extension;
    final icons = {
      'javascript': Icons.javascript,
      'text_fields': Icons.text_fields,
      'code': Icons.code,
      'transform': Icons.transform,
      'edit': Icons.edit,
      'format_paint': Icons.format_paint,
      'functions': Icons.functions,
      'auto_fix_high': Icons.auto_fix_high,
      'tune': Icons.tune,
      'build': Icons.build,
      'extension': Icons.extension,
      'language': Icons.language,
      'translate': Icons.translate,
      'spellcheck': Icons.spellcheck,
      'find_replace': Icons.find_replace,
      'sort': Icons.sort,
      'filter_list': Icons.filter_list,
      'calculate': Icons.calculate,
      'analytics': Icons.analytics,
      'schedule': Icons.schedule,
      'layers': Icons.layers,
      'dashboard': Icons.dashboard,
    };
    return icons[iconName] ?? Icons.extension;
  }

  static String _dartToJs(dynamic obj) {
    if (obj == null) return 'null';
    if (obj is String) return '"${_escapeJsString(obj)}"';
    if (obj is num || obj is bool) return obj.toString();
    if (obj is Map<String, dynamic>) {
      final entries = obj.entries
          .map((e) => '"${_escapeJsString(e.key)}": ${_dartToJs(e.value)}')
          .join(',');
      return '{$entries}';
    }
    if (obj is List) {
      final entries = obj.map((e) => _dartToJs(e)).join(',');
      return '[$entries]';
    }
    return 'null';
  }
}

// Simple JS script string
const String _echoToolScript = r"""
var name = "Echo Tool";
var description = "Repeats back the input with some formatting";
var icon = "text_fields";
var isOutputMarkdown = false;
var isInputMarkdown = false;
var canAcceptMarkdown = false;
var supportsLiveUpdate = true;
var allowEmptyInput = false;

function execute(input, settings) {
  return "🔁 Echo: " + input + "\n\nSettings: " + JSON.stringify(settings);
}
""";

// ----------------------
// Reverse Tool
// ----------------------
const String _reverseToolScript = r"""
var name = "Reverse Tool";
var description = "Reverses the input text";
var icon = "code";
var isOutputMarkdown = false;
var isInputMarkdown = false;
var canAcceptMarkdown = false;
var supportsLiveUpdate = true;
var allowEmptyInput = false;

function execute(input, settings) {
  // simple string reversal
  return input.split("").reverse().join("");
}
""";

// ----------------------
// Markdown Formatter Tool
// ----------------------
const String _markdownToolScript = r"""
var name = "Markdown Tool";
var description = "Formats input text as Markdown with optional uppercase and prefix";
var icon = "format_paint";
var isOutputMarkdown = true;
var isInputMarkdown = true;
var canAcceptMarkdown = true;
var supportsLiveUpdate = true;
var allowEmptyInput = false;

// Settings with defaults
var settings = {
  "uppercase": true,
  "prefix": ">> "
};

// Settings hints for UI
var settingsHints = {
  "prefix": {
    "type": "dropdown",
    "label": "Line Prefix",
    "help": "Text prepended to each line",
    "options": [
      { "value": ">> ", "label": "Double Arrow" },
      { "value": "* ", "label": "Asterisk" },
      { "value": "- ", "label": "Dash" }
    ]
  }
};

function execute(input, _settings) {
  var cfg = Object.assign({}, settings, _settings);

  var lines = input.split("\n");
  var processed = lines.map(function(line) {
    if (cfg.uppercase) line = line.toUpperCase();
    return cfg.prefix + line;
  });

  return "```markdown\n" + processed.join("\n") + "\n```";
}
""";

// ----------------------
// Example tool that allows empty input
// ----------------------
const String _emptyInputToolScript = r"""
var name = "Random Quote Tool";
var description = "Generates a random quote (works without input)";
var icon = "auto_fix_high";
var isOutputMarkdown = false;
var isInputMarkdown = false;
var canAcceptMarkdown = false;
var supportsLiveUpdate = true;
var allowEmptyInput = true;

function execute(input, settings) {
  var quotes = [
    "The only way to do great work is to love what you do. - Steve Jobs",
    "Innovation distinguishes between a leader and a follower. - Steve Jobs",
    "Life is what happens to you while you're busy making other plans. - John Lennon",
    "The future belongs to those who believe in the beauty of their dreams. - Eleanor Roosevelt"
  ];
  
  var randomQuote = quotes[Math.floor(Math.random() * quotes.length)];
  
  if (input && input.trim()) {
    return "Your input: " + input + "\n\nRandom quote: " + randomQuote;
  } else {
    return "Random quote: " + randomQuote;
  }
}
""";

// ----------------------
// Export tools
// ----------------------
Map<String, List<Tool Function()>> getJsTools() {
  return {
    'Js Tools': [
      () => JsTool.fromScript(_echoToolScript),
      () => JsTool.fromScript(_reverseToolScript),
      () => JsTool.fromScript(_markdownToolScript),
      () => JsTool.fromScript(_emptyInputToolScript),
    ],
  };
}
