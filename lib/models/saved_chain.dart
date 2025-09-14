// models/saved_chain.dart
import 'package:hive/hive.dart';
import 'package:utility_tools/models/tool.dart';

part 'saved_chain.g.dart'; // This will be generated

@HiveType(typeId: 0)
class SavedChain extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late List<SavedTool> tools;

  @HiveField(4)
  late DateTime created;

  @HiveField(5)
  late DateTime modified;

  @HiveField(6)
  String? category;

  @HiveField(7)
  List<String>? tags;

  SavedChain({
    required this.id,
    required this.name,
    required this.description,
    required this.tools,
    required this.created,
    required this.modified,
    this.category,
    this.tags,
  });

  SavedChain.empty()
    : id = '',
      name = '',
      description = '',
      tools = [],
      created = DateTime.now(),
      modified = DateTime.now();

  // Convert from ChainedTool list to SavedChain
  static SavedChain fromChainedTools(
    List<ChainedTool> chainedTools, {
    required String name,
    String description = '',
    String? category,
    List<String>? tags,
  }) {
    return SavedChain(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      tools: chainedTools.map((ct) => SavedTool.fromChainedTool(ct)).toList(),
      created: DateTime.now(),
      modified: DateTime.now(),
      category: category,
      tags: tags,
    );
  }

  // Convert SavedChain back to ChainedTool list
  List<ChainedTool> toChainedTools(
    Map<String, List<Tool Function()>> toolCategories,
  ) {
    final result = <ChainedTool>[];

    for (final savedTool in tools) {
      final tool = savedTool.createTool(toolCategories);
      if (tool != null) {
        final chainedTool = ChainedTool(
          tool: tool,
          id: savedTool.id,
          enabled: savedTool.enabled,
        );
        result.add(chainedTool);
      }
    }

    return result;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'tools': tools.map((t) => t.toJson()).toList(),
    'created': created.toIso8601String(),
    'modified': modified.toIso8601String(),
    'category': category,
    'tags': tags,
  };

  static SavedChain fromJson(Map<String, dynamic> json) => SavedChain(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    tools: (json['tools'] as List).map((t) => SavedTool.fromJson(t)).toList(),
    created: DateTime.parse(json['created']),
    modified: DateTime.parse(json['modified']),
    category: json['category'],
    tags: json['tags']?.cast<String>(),
  );
}

@HiveType(typeId: 1)
class SavedTool extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String toolType; // Tool class name

  @HiveField(2)
  late Map<String, dynamic> settings;

  @HiveField(3)
  late bool enabled;

  @HiveField(4)
  late int order;

  @HiveField(5)
  String? category;

  SavedTool({
    required this.id,
    required this.toolType,
    required this.settings,
    required this.enabled,
    required this.order,
    this.category,
  });

  SavedTool.empty()
    : id = '',
      toolType = '',
      settings = {},
      enabled = true,
      order = 0;

  static SavedTool fromChainedTool(ChainedTool chainedTool) {
    return SavedTool(
      id: chainedTool.id,
      toolType: chainedTool.tool.runtimeType.toString(),
      settings: Map<String, dynamic>.from(chainedTool.tool.settings),
      enabled: chainedTool.enabled,
      order: 0, // Will be set by the list index
    );
  }

  // Create a Tool instance from SavedTool
  Tool? createTool(Map<String, List<Tool Function()>> toolCategories) {
    // Find the tool factory by matching the tool type name
    for (final category in toolCategories.values) {
      for (final toolFactory in category) {
        final tool = toolFactory();
        if (tool.runtimeType.toString() == toolType) {
          // Apply saved settings
          tool.settings.clear();
          tool.settings.addAll(settings);
          return tool;
        }
      }
    }
    return null; // Tool type not found
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'toolType': toolType,
    'settings': settings,
    'enabled': enabled,
    'order': order,
    'category': category,
  };

  static SavedTool fromJson(Map<String, dynamic> json) => SavedTool(
    id: json['id'],
    toolType: json['toolType'],
    settings: Map<String, dynamic>.from(json['settings']),
    enabled: json['enabled'],
    order: json['order'],
    category: json['category'],
  );
}
