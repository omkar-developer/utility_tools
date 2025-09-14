import 'package:hive/hive.dart';

part 'js_script_model.g.dart';

// Run: flutter packages pub run build_runner build

@HiveType(typeId: 2)
class JsScript extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String script;

  @HiveField(3)
  JsScriptType type;

  @HiveField(4)
  String category;

  @HiveField(5)
  String description;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  JsScript({
    required this.id,
    required this.name,
    required this.script,
    required this.type,
    required this.category,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JsScript.fromScript(String scriptContent, {String? category}) {
    final type = detectScriptType(scriptContent);
    final name = extractNameFromScript(scriptContent);
    final description = extractDescriptionFromScript(scriptContent);

    return JsScript(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      script: scriptContent,
      type: type,
      category: category ?? 'General',
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static JsScriptType detectScriptType(String script) {
    // Check for AI tool specific functions
    if (script.contains('buildAISystemPrompt') &&
        script.contains('buildAIMessages')) {
      return JsScriptType.ai;
    }
    // Check for regular tool execute function
    if (script.contains('function execute(')) {
      return JsScriptType.regular;
    }
    // Default to regular if uncertain
    return JsScriptType.regular;
  }

  static String extractNameFromScript(String script) {
    // Match: var name = "value" or var name = 'value'
    final nameRegex = RegExp(r'''var\s+name\s*=\s*["']([^"']*)["']''');
    final match = nameRegex.firstMatch(script);
    return match?.group(1) ?? 'Unnamed Script';
  }

  static String extractDescriptionFromScript(String script) {
    // Match: var description = "value" or var description = 'value'
    final descRegex = RegExp(r'''var\s+description\s*=\s*["']([^"']*)["']''');
    final match = descRegex.firstMatch(script);
    return match?.group(1) ?? '';
  }

  void updateScript(String newScript) {
    script = newScript;
    name = extractNameFromScript(newScript);
    description = extractDescriptionFromScript(newScript);
    type = detectScriptType(newScript);
    updatedAt = DateTime.now();
    save();
  }
}

@HiveType(typeId: 3)
enum JsScriptType {
  @HiveField(0)
  regular,
  @HiveField(1)
  ai,
}
