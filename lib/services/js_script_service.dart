import 'package:hive/hive.dart';
import 'package:utility_tools/models/tool.dart';
import 'package:utility_tools/text_tools/base_ai_tool.dart';
import 'package:utility_tools/models/js_script_model.dart';
import 'package:utility_tools/text_tools/js_tool.dart';
import 'package:utility_tools/text_tools/js_ai_tool.dart';

class JsScriptService {
  static const String _boxName = 'js_scripts';
  static Box<JsScript>? _box;

  static Future<void> init() async {
    Hive.registerAdapter(JsScriptAdapter());
    Hive.registerAdapter(JsScriptTypeAdapter());
    _box = await Hive.openBox<JsScript>(_boxName);
  }

  static Box<JsScript> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('JsScriptService not initialized. Call init() first.');
    }
    return _box!;
  }

  // CRUD Operations
  static Future<void> saveScript(JsScript script) async {
    await box.put(script.id, script);
  }

  static JsScript? getScript(String id) {
    return box.get(id);
  }

  static List<JsScript> getAllScripts() {
    return box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static List<JsScript> getScriptsByType(JsScriptType type) {
    return box.values.where((script) => script.type == type).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static List<JsScript> getScriptsByCategory(String category) {
    return box.values.where((script) => script.category == category).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static List<String> getAllCategories() {
    final categories = box.values
        .map((script) => script.category)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  static Future<void> deleteScript(String id) async {
    await box.delete(id);
  }

  static Future<void> updateScript(JsScript script) async {
    script.updatedAt = DateTime.now();
    await script.save();
  }

  // Tool Generation Functions
  static Map<String, List<Tool Function()>> getJsTools() {
    final scripts = getScriptsByType(JsScriptType.regular);
    final Map<String, List<Tool Function()>> toolsByCategory = {};

    for (final script in scripts) {
      final category = script.category;
      if (!toolsByCategory.containsKey(category)) {
        toolsByCategory[category] = [];
      }
      toolsByCategory[category]!.add(() => JsTool.fromScript(script.script));
    }

    return toolsByCategory;
  }

  static Map<String, List<BaseAITool Function()>> getJsAiTools() {
    final scripts = getScriptsByType(JsScriptType.ai);
    final Map<String, List<BaseAITool Function()>> toolsByCategory = {};

    for (final script in scripts) {
      final category = script.category;
      if (!toolsByCategory.containsKey(category)) {
        toolsByCategory[category] = [];
      }
      toolsByCategory[category]!.add(() => JsAiTool.fromScript(script.script));
    }

    return toolsByCategory;
  }

  // Import default scripts
  static Future<void> importDefaultScripts() async {
    final defaultScripts = _getDefaultScripts();

    for (final scriptData in defaultScripts) {
      final matches = box.values.where(
        (script) => script.name == scriptData['name'],
      );
      if (matches.isEmpty) {
        final script = JsScript.fromScript(
          scriptData['script'] ?? '',
          category: scriptData['category'],
        );
        await saveScript(script);
      }
    }
  }

  static List<Map<String, String>> _getDefaultScripts() {
    return [
      {
        'name': 'Echo Tool',
        'script': '''
var name = "Echo Tool";
var description = "Repeats back the input with some formatting";
var icon = "text_fields";
var isOutputMarkdown = false;
var isInputMarkdown = false;
var canAcceptMarkdown = false;
var supportsLiveUpdate = true;

function execute(input, settings) {
  return "Echo: " + input + "\\n\\nSettings: " + JSON.stringify(settings);
}
''',
        'category': 'Text Processing',
      },
      {
        'name': 'Reverse Tool',
        'script': '''
var name = "Reverse Tool";
var description = "Reverses the input text";
var icon = "code";
var isOutputMarkdown = false;
var isInputMarkdown = false;
var canAcceptMarkdown = false;
var supportsLiveUpdate = true;

function execute(input, settings) {
  return input.split("").reverse().join("");
}
''',
        'category': 'Text Processing',
      },
      {
        'name': 'AI Summarizer',
        'script': '''
var name = "AI Summarizer";
var description = "Uses AI to summarize text content";
var icon = "summarize";
var isOutputMarkdown = true;
var isInputMarkdown = true;
var canAcceptMarkdown = true;
var supportsLiveUpdate = true;

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
    "bullet_points": "Format as bullet points with - prefix",
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
    {"role": "user", "content": "Please summarize this text:\\n\\n" + input}
  ];
}
''',
        'category': 'AI Tools',
      },
    ];
  }
}
