import 'package:utility_tools/models/tool.dart';
import 'package:flutter/material.dart';

// Abstract splitter tool interface
abstract class SplitterTool extends Tool {
  // Number of next tools this splitter will consume and execute
  int get toolsToConsume;

  // Split input into array of items
  List<String> splitInput(String input);

  // Combine processed items back into single output
  String combineResults(List<String> results);

  // Execute the consumed tools on each split item
  Future<ToolResult> executeSplitter(
    String input,
    List<ChainedTool> consumedTools,
  ) async {
    final items = splitInput(input);
    final processedItems = <String>[];

    for (final item in items) {
      String currentInput = item;

      // Execute each consumed tool in sequence on this item
      for (final chainedTool in consumedTools) {
        if (!chainedTool.enabled) continue;

        try {
          // Check if we need text output for next tool
          bool useTextOutput = false;
          final currentIndex = consumedTools.indexOf(chainedTool);
          if (currentIndex + 1 < consumedTools.length) {
            final nextTool = consumedTools[currentIndex + 1];
            useTextOutput =
                chainedTool.tool.isOutputMarkdown &&
                !nextTool.tool.canAcceptMarkdown;
          }

          // Execute with appropriate method
          if (useTextOutput) {
            currentInput = await chainedTool.tool.executeGetText(currentInput);
          } else {
            final result = await chainedTool.tool.execute(currentInput);
            if (result.status == 'error') {
              return ToolResult(
                output: 'Error processing item: ${result.output}',
                status: 'error',
              );
            }
            currentInput = result.output;
          }
        } catch (e) {
          return ToolResult(
            output: 'Error processing item: $e',
            status: 'error',
          );
        }
      }

      processedItems.add(currentInput);
    }

    final combinedResult = combineResults(processedItems);
    return ToolResult(output: combinedResult, status: 'success');
  }

  SplitterTool({
    required super.name,
    required super.description,
    required super.icon,
    super.settings,
    super.settingsHints,
    super.isOutputMarkdown,
    super.isInputMarkdown,
    super.canAcceptMarkdown,
  });
}

// Example implementation: Line Splitter Tool
class LineSplitterTool extends SplitterTool {
  @override
  int get toolsToConsume => settings['tools_to_consume'] ?? 1;

  @override
  List<String> splitInput(String input) {
    final lines = input.split('\n');

    if (settings['skip_empty_lines'] == true) {
      return lines.where((line) => line.trim().isNotEmpty).toList();
    }

    return lines;
  }

  @override
  String combineResults(List<String> results) {
    final outputFormat = settings['output_format'];
    final separator = settings['line_separator'] ?? '\n';

    switch (outputFormat) {
      case 'numbered':
        final startNumber = settings['start_number'] ?? 1;
        return results
            .asMap()
            .entries
            .map((entry) => '${entry.key + startNumber}. ${entry.value}')
            .join(separator);
      case 'bulleted':
        final bullet = settings['bullet_character'] ?? '•';
        return results.map((result) => '$bullet $result').join(separator);
      case 'indexed':
        return results
            .asMap()
            .entries
            .map((entry) => '[${entry.key}] ${entry.value}')
            .join(separator);
      default: // 'plain'
        return results.join(separator);
    }
  }

  @override
  Future<ToolResult> execute(String input) async {
    // This shouldn't be called directly - executor should use executeSplitter
    return ToolResult(
      output: 'LineSplitterTool requires executor support',
      status: 'error',
    );
  }

  LineSplitterTool()
    : super(
        name: 'Line Splitter',
        description:
            'Splits input by lines and executes next tools on each line',
        icon: Icons.format_list_bulleted,
        settings: {
          'tools_to_consume': 1,
          'output_format': 'plain',
          'skip_empty_lines': true,
          'line_separator': '\n',
          'start_number': 1,
          'bullet_character': '•',
        },
        settingsHints: {
          'tools_to_consume': {
            'type': 'spinner',
            'label': 'Tools to Consume',
            'help': 'Number of next tools to execute on each line',
            'min': 1,
            'max': 10,
            'step': 1,
          },
          'output_format': {
            'type': 'dropdown',
            'label': 'Output Format',
            'help': 'How to format the combined results',
            'options': [
              {'value': 'plain', 'label': 'Plain Text'},
              {'value': 'numbered', 'label': 'Numbered Lines'},
              {'value': 'bulleted', 'label': 'Bulleted Lines'},
              {'value': 'indexed', 'label': 'Indexed [0] Lines'},
            ],
          },
          'skip_empty_lines': {
            'type': 'bool',
            'label': 'Skip Empty Lines',
            'help': 'Ignore empty lines when splitting input',
          },
          'line_separator': {
            'type': 'text',
            'label': 'Line Separator',
            'help': 'Character(s) to use when combining results',
            'placeholder': '\\n',
            'width': 150,
          },
          'start_number': {
            'type': 'spinner',
            'label': 'Start Number',
            'help': 'Starting number for numbered format',
            'min': 0,
            'max': 100,
            'step': 1,
          },
          'bullet_character': {
            'type': 'text',
            'label': 'Bullet Character',
            'help': 'Character to use for bulleted format',
            'placeholder': '•',
            'width': 100,
          },
        },
      );
}

// Word Splitter Tool Example
class WordSplitterTool extends SplitterTool {
  @override
  int get toolsToConsume => settings['tools_to_consume'] ?? 1;

  @override
  List<String> splitInput(String input) {
    final splitPattern = settings['split_pattern'] ?? r'\s+';
    final regex = RegExp(splitPattern);
    final words = input.split(regex);

    if (settings['filter_empty'] == true) {
      return words.where((word) => word.trim().isNotEmpty).toList();
    }

    return words;
  }

  @override
  String combineResults(List<String> results) {
    final joinWith = settings['join_with'] ?? ' ';
    return results.join(joinWith);
  }

  @override
  Future<ToolResult> execute(String input) async {
    return ToolResult(
      output: 'WordSplitterTool requires executor support',
      status: 'error',
    );
  }

  WordSplitterTool()
    : super(
        name: 'Word Splitter',
        description:
            'Splits input by words and executes next tools on each word',
        icon: Icons.text_fields,
        settings: {
          'tools_to_consume': 1,
          'split_pattern': r'\s+',
          'filter_empty': true,
          'join_with': ' ',
        },
        settingsHints: {
          'tools_to_consume': {
            'type': 'spinner',
            'label': 'Tools to Consume',
            'help': 'Number of next tools to execute on each word',
            'min': 1,
            'max': 10,
            'step': 1,
          },
          'split_pattern': {
            'type': 'text',
            'label': 'Split Pattern (RegEx)',
            'help': 'Regular expression pattern for splitting words',
            'placeholder': r'\s+',
            'width': 200,
          },
          'filter_empty': {
            'type': 'bool',
            'label': 'Filter Empty Words',
            'help': 'Remove empty strings from word list',
          },
          'join_with': {
            'type': 'text',
            'label': 'Join With',
            'help': 'String to use when combining processed words',
            'placeholder': ' ',
            'width': 150,
          },
        },
      );
}

Map<String, List<Tool Function()>> getSplitterTools() {
  return {
    'Splitter': [() => LineSplitterTool(), () => WordSplitterTool()],
  };
}
