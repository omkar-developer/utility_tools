import 'package:flutter/widgets.dart';

/// The result of running a tool.
class ToolResult {
  final String output;
  final String? status;

  const ToolResult({required this.output, this.status});
}

/// Base interface for a tool.
abstract class Tool {
  final String name;
  final String description;
  final IconData icon;
  final bool isOutputMarkdown;
  final bool isInputMarkdown;
  final bool canAcceptMarkdown;
  final bool supportsLiveUpdate; // Add this line
  final bool supportsStreaming; // Add this for streaming support
  final bool allowEmptyInput;
  Map<String, dynamic> settings;
  Map<String, dynamic>? settingsHints;

  /// Each tool must implement its own execution logic.
  Future<ToolResult> execute(String input);

  /// Optional streaming execution - override in tools that support it
  Stream<String>? executeStream(String input) {
    // Default implementation: return null (no streaming support)
    return null;
  }

  /// New method: Get plain text output regardless of tool's native format
  Future<String> executeGetText(String input) async {
    final result = await execute(input);

    // If tool outputs markdown, convert to plain text
    if (isOutputMarkdown && result.output.isNotEmpty) {
      return markdownToPlainText(result.output);
    }

    // Otherwise return as-is (already plain text)
    return result.output;
  }

  /// Helper method to convert markdown to plain text
  String markdownToPlainText(String markdown) {
    return markdown
        .replaceAll(RegExp(r'#+\s*'), '') // Headers
        .replaceAll(RegExp(r'\*{1,2}([^*]+)\*{1,2}'), r'$1') // Bold/italic
        .replaceAll(
          RegExp(r'_{1,2}([^_]+)_{1,2}'),
          r'$1',
        ) // Underscore bold/italic
        .replaceAll(RegExp(r'`{1,3}([^`]+)`{1,3}'), r'$1') // Code
        .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1') // Links
        .replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '') // Images
        .replaceAll(RegExp(r'^\s*[-*+]\s+'), '') // Unordered lists
        .replaceAll(RegExp(r'^\s*\d+\.\s+'), '') // Ordered lists
        .replaceAll(RegExp(r'>\s+'), '') // Blockquotes
        .replaceAll(RegExp(r'---|___|\*\*\*'), '') // Horizontal rules
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Excess newlines
        .trim();
  }

  Tool({
    required this.name,
    required this.description,
    required this.icon,
    this.settings = const {},
    this.isOutputMarkdown = false,
    this.isInputMarkdown = false,
    this.canAcceptMarkdown = false,
    this.supportsLiveUpdate = true, // Default true for existing tools
    this.supportsStreaming = false, // Default false for existing tools
    this.allowEmptyInput = false,
    this.settingsHints,
  });
}

class ToolExecution {
  final DateTime timestamp;
  final String input;
  final String output;
  final Duration executionTime;
  final bool success;
  final String? errorMessage;
  final String? status;

  ToolExecution({
    required this.timestamp,
    required this.input,
    required this.output,
    required this.executionTime,
    required this.success,
    this.errorMessage,
    this.status,
  });
}

class ChainedTool {
  final Tool tool;
  final List<ToolExecution> executions;
  final bool enabled;
  final String id;

  ChainedTool({required this.tool, required this.id, this.enabled = true})
    : executions = [];

  ChainedTool copyWith({bool? enabled}) {
    final newTool = ChainedTool(
      tool: tool,
      id: id,
      enabled: enabled ?? this.enabled,
    );
    newTool.executions.addAll(executions);
    return newTool;
  }

  void addExecution(ToolExecution execution) {
    executions.add(execution);
  }

  ToolExecution? get lastExecution =>
      executions.isEmpty ? null : executions.last;
  bool get hasExecuted => executions.isNotEmpty;
  bool get lastExecutionSuccess => lastExecution?.success ?? false;
}
