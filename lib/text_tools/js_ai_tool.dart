import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jsf/jsf.dart';
import 'package:utility_tools/text_tools/base_ai_tool.dart';
import 'package:utility_tools/services/ai_service.dart';

class JsAiTool extends BaseAITool {
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

  JsAiTool._internal({
    required this.script,
    required super.name,
    required super.description,
    required super.icon,
    required super.isOutputMarkdown,
    required super.isInputMarkdown,
    required super.canAcceptMarkdown,
    required super.allowEmptyInput,
    required super.settings,
    required Map<String, dynamic> super.settingsHints,
  });

  static JsAiTool fromScript(String scriptContent) {
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

    // Validate required AI functions
    final hasSystemPrompt = js.eval(
      'typeof buildAISystemPrompt === "function"',
    );
    final hasMessages = js.eval('typeof buildAIMessages === "function"');

    if (hasSystemPrompt != true) {
      throw 'JS AI Tool script must define a "buildAISystemPrompt" function';
    }
    if (hasMessages != true) {
      throw 'JS AI Tool script must define a "buildAIMessages" function';
    }

    final name = getGlobal('name', 'Unnamed AI Tool') as String;
    final description = getGlobal('description', '') as String;
    final iconName = getGlobal('icon', 'auto_awesome') as String;
    final icon = _getIconFromName(iconName);
    final isOutputMarkdown = getGlobal('isOutputMarkdown', false) as bool;
    final isInputMarkdown = getGlobal('isInputMarkdown', false) as bool;
    final canAcceptMarkdown = getGlobal('canAcceptMarkdown', false) as bool;
    final supportsLiveUpdate = getGlobal('supportsLiveUpdate', true) as bool;
    final allowEmptyInput = getGlobal('allowEmptyInput', false) as bool;

    // FIXED: Check if settings/settingsHints exist before trying to stringify them
    Map<String, dynamic> settings = <String, dynamic>{};
    Map<String, dynamic> settingsHints = <String, dynamic>{};

    try {
      // Check if settings exists and is an object
      final settingsType = js.eval('typeof settings');
      if (settingsType == 'object') {
        final settingsJson = js.eval('JSON.stringify(settings);');
        if (settingsJson != null) {
          settings = Map<String, dynamic>.from(jsonDecode(settingsJson));
        }
      }
    } catch (e) {
      // Settings doesn't exist or can't be serialized, use empty map
      settings = <String, dynamic>{};
    }

    try {
      // Check if settingsHints exists and is an object
      final hintsType = js.eval('typeof settingsHints');
      if (hintsType == 'object') {
        final hintsJson = js.eval('JSON.stringify(settingsHints);');
        if (hintsJson != null) {
          settingsHints = Map<String, dynamic>.from(jsonDecode(hintsJson));
        }
      }
    } catch (e) {
      // SettingsHints doesn't exist or can't be serialized, use empty map
      settingsHints = <String, dynamic>{};
    }

    final tool = JsAiTool._internal(
      script: scriptContent,
      name: name,
      description: description,
      icon: icon,
      isOutputMarkdown: isOutputMarkdown,
      isInputMarkdown: isInputMarkdown,
      canAcceptMarkdown: canAcceptMarkdown,
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

  @override
  String buildAISystemPrompt(String input) {
    try {
      final escapedInput = _escapeJsString(input);
      final jsSettings = _dartToJs(settings);

      final result = _js?.eval(
        'buildAISystemPrompt("$escapedInput", $jsSettings);',
      );
      return result?.toString() ?? '';
    } catch (e) {
      return 'Error building system prompt: $e';
    }
  }

  @override
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    try {
      final escapedInput = _escapeJsString(input);
      final escapedSystemPrompt = _escapeJsString(systemPrompt);
      final jsSettings = _dartToJs(settings);

      final result = _js?.eval(
        'JSON.stringify(buildAIMessages("$escapedInput", "$escapedSystemPrompt", $jsSettings));',
      );

      if (result == null) return [];

      final List<dynamic> messages = jsonDecode(result);
      return messages.map((msg) {
        return ChatMessage(
          role: msg['role']?.toString() ?? 'user',
          content: msg['content']?.toString() ?? '',
        );
      }).toList();
    } catch (e) {
      // Return fallback messages on error
      return [
        ChatMessage(role: 'system', content: systemPrompt),
        ChatMessage(role: 'user', content: input),
      ];
    }
  }

  // Properly dispose of JS runtime
  @override
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
    if (iconName == null) return Icons.auto_awesome;
    final icons = {
      'auto_awesome': Icons.auto_awesome,
      'psychology': Icons.psychology,
      'smart_toy': Icons.smart_toy,
      'auto_fix_high': Icons.auto_fix_high,
      'lightbulb': Icons.lightbulb,
      'translate': Icons.translate,
      'spellcheck': Icons.spellcheck,
      'summarize': Icons.summarize,
      'quiz': Icons.quiz,
      'edit_note': Icons.edit_note,
      'code': Icons.code,
      'transform': Icons.transform,
      'functions': Icons.functions,
      'analytics': Icons.analytics,
      'chat': Icons.chat,
      'question_answer': Icons.question_answer,
    };
    return icons[iconName] ?? Icons.auto_awesome;
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

// Example JS AI Tool Scripts
const String _summarizerAiScript = r"""
var name = "AI Summarizer";
var description = "Uses AI to summarize text content";
var icon = "summarize";
var isOutputMarkdown = true;
var isInputMarkdown = true;
var canAcceptMarkdown = true;
var supportsLiveUpdate = true;
var allowEmptyInput = false;

var settings = {
  "length": "medium",
  "style": "bullet_points"
};

var settingsHints = {
  "length": {
    "type": "dropdown",
    "label": "Summary Length",
    "help": "How long should the summary be?",
    "options": [
      {"value": "short", "label": "Short"},
      {"value": "medium", "label": "Medium"},
      {"value": "long", "label": "Long"}
    ]
  },
  "style": {
    "type": "dropdown",
    "label": "Summary Style",
    "help": "Format of the summary",
    "options": [
      {"value": "paragraph", "label": "Paragraph"},
      {"value": "bullet_points", "label": "Bullet Points"},
      {"value": "numbered", "label": "Numbered List"}
    ]
  }
};

function buildAISystemPrompt(input, settings) {
  var lengthInstructions = {
    "short": "Keep it very concise, around 2-3 sentences or points",
    "medium": "Provide a moderate summary, around 4-6 sentences or points", 
    "long": "Create a detailed summary, around 8-10 sentences or points"
  };
  
  var styleInstructions = {
    "paragraph": "Format as flowing paragraphs",
    "bullet_points": "Format as bullet points with • prefix",
    "numbered": "Format as a numbered list"
  };

  return "You are an expert at summarizing text. " + 
         lengthInstructions[settings.length] + ". " +
         styleInstructions[settings.style] + ". " +
         "Focus on the main ideas and key information.";
}

function buildAIMessages(input, systemPrompt, settings) {
  return [
    {"role": "system", "content": systemPrompt},
    {"role": "user", "content": "Please summarize this text:\n\n" + input}
  ];
}
""";

const String _translatorAiScript = r"""
var name = "AI Translator";
var description = "Translates text to different languages using AI";
var icon = "translate";
var isOutputMarkdown = false;
var isInputMarkdown = true;
var canAcceptMarkdown = true;
var supportsLiveUpdate = true;
var allowEmptyInput = false;

var settings = {
  "target_language": "spanish",
  "preserve_formatting": true,
  "tone": "natural"
};

var settingsHints = {
  "target_language": {
    "type": "dropdown",
    "label": "Target Language",
    "help": "Language to translate to",
    "options": [
      {"value": "spanish", "label": "Spanish"},
      {"value": "french", "label": "French"},
      {"value": "german", "label": "German"},
      {"value": "italian", "label": "Italian"},
      {"value": "portuguese", "label": "Portuguese"},
      {"value": "chinese", "label": "Chinese"},
      {"value": "japanese", "label": "Japanese"}
    ]
  },
  "tone": {
    "type": "dropdown",
    "label": "Translation Tone",
    "help": "Style of translation",
    "options": [
      {"value": "natural", "label": "Natural"},
      {"value": "formal", "label": "Formal"},
      {"value": "casual", "label": "Casual"}
    ]
  },
  "preserve_formatting": {
    "type": "bool",
    "label": "Preserve Formatting",
    "help": "Keep original text structure and formatting"
  }
};

function buildAISystemPrompt(input, settings) {
  var toneInstructions = {
    "natural": "Use natural, flowing language",
    "formal": "Use formal, professional language",
    "casual": "Use casual, conversational language"
  };
  
  var formatInstruction = settings.preserve_formatting ? 
    "Preserve the original formatting, structure, and line breaks." : 
    "Focus on meaning over exact formatting.";

  return "You are an expert translator. Translate text to " + settings.target_language + 
         ". " + toneInstructions[settings.tone] + ". " + formatInstruction + 
         " Provide only the translation, no explanations.";
}

function buildAIMessages(input, systemPrompt, settings) {
  return [
    {"role": "system", "content": systemPrompt},
    {"role": "user", "content": input}
  ];
}
""";

// Example AI tool that allows empty input
const String _ideaGeneratorAiScript = r"""
var name = "AI Idea Generator";
var description = "Generates creative ideas (works with or without input)";
var icon = "lightbulb";
var isOutputMarkdown = true;
var isInputMarkdown = true;
var canAcceptMarkdown = true;
var supportsLiveUpdate = true;
var allowEmptyInput = true;

var settings = {
  "category": "business",
  "creativity_level": "balanced",
  "count": 5
};

var settingsHints = {
  "category": {
    "type": "dropdown",
    "label": "Idea Category",
    "help": "Type of ideas to generate",
    "options": [
      {"value": "business", "label": "Business Ideas"},
      {"value": "creative", "label": "Creative Projects"},
      {"value": "problem_solving", "label": "Problem Solutions"},
      {"value": "content", "label": "Content Ideas"},
      {"value": "product", "label": "Product Ideas"}
    ]
  },
  "creativity_level": {
    "type": "dropdown",
    "label": "Creativity Level",
    "help": "How creative should the ideas be?",
    "options": [
      {"value": "practical", "label": "Practical"},
      {"value": "balanced", "label": "Balanced"},
      {"value": "innovative", "label": "Highly Creative"}
    ]
  },
  "count": {
    "type": "dropdown",
    "label": "Number of Ideas",
    "help": "How many ideas to generate",
    "options": [
      {"value": 3, "label": "3 Ideas"},
      {"value": 5, "label": "5 Ideas"},
      {"value": 10, "label": "10 Ideas"}
    ]
  }
};

function buildAISystemPrompt(input, settings) {
  var categoryPrompts = {
    "business": "Generate innovative business ideas",
    "creative": "Generate creative project ideas",
    "problem_solving": "Generate solutions to problems",
    "content": "Generate content creation ideas",
    "product": "Generate product development ideas"
  };
  
  var creativityInstructions = {
    "practical": "Focus on realistic, implementable ideas",
    "balanced": "Balance practicality with creativity",
    "innovative": "Think outside the box with highly creative ideas"
  };

  return "You are a creative idea generator. " + categoryPrompts[settings.category] + 
         ". " + creativityInstructions[settings.creativity_level] + 
         ". Generate exactly " + settings.count + " ideas. Format as a numbered list with brief explanations.";
}

function buildAIMessages(input, systemPrompt, settings) {
  var userPrompt;
  
  if (input && input.trim()) {
    userPrompt = "Based on this context: \"" + input + "\"\n\nPlease generate " + 
                 settings.count + " " + settings.category + " ideas.";
  } else {
    userPrompt = "Please generate " + settings.count + " " + settings.category + " ideas.";
  }
  
  return [
    {"role": "system", "content": systemPrompt},
    {"role": "user", "content": userPrompt}
  ];
}
""";

// Export function for JS AI Tools
Map<String, List<BaseAITool Function()>> getJsAiTools() {
  return {
    'JS AI Tools': [
      () => JsAiTool.fromScript(_summarizerAiScript),
      () => JsAiTool.fromScript(_translatorAiScript),
      () => JsAiTool.fromScript(_ideaGeneratorAiScript),
    ],
  };
}
