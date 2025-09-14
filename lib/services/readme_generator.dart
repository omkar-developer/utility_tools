// ignore_for_file: unnecessary_string_interpolations

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:utility_tools/models/tool.dart'; // for IconData
// import your Tool class + toolCategories map here

Future<void> generateReadme(
  String outputPath,
  Map<String, List<Tool Function()>> toolCategories, {
  bool compact = true,
}) async {
  final buffer = StringBuffer();

  buffer.writeln('# Tools List');
  buffer.writeln();
  buffer.writeln('This file is auto-generated from the tool metadata.');
  buffer.writeln();

  toolCategories.forEach((category, toolFactories) {
    buffer.writeln('## $category');
    buffer.writeln();

    for (final factory in toolFactories) {
      final tool = factory();

      if (compact) {
        // 🔹 Compact mode → single line per tool
        buffer.writeln('- **${tool.name}**: ${tool.description}');
      } else {
        // 🔹 Full mode → detailed info
        buffer.writeln('### ${tool.name}');
        buffer.writeln();
        buffer.writeln('${tool.description}');
        buffer.writeln();

        buffer.writeln('- Icon: `${tool.icon.codePoint.toRadixString(16)}`');
        buffer.writeln('- Output as Markdown: ${tool.isOutputMarkdown}');
        buffer.writeln('- Input as Markdown: ${tool.isInputMarkdown}');
        buffer.writeln('- Accepts Markdown: ${tool.canAcceptMarkdown}');
        buffer.writeln('- Supports Live Update: ${tool.supportsLiveUpdate}');
        buffer.writeln('- Supports Streaming: ${tool.supportsStreaming}');
        buffer.writeln('- Allow Empty Input: ${tool.allowEmptyInput}');

        if (tool.settings.isNotEmpty) {
          buffer.writeln('- Settings:');
          tool.settings.forEach((key, value) {
            buffer.writeln('  - `$key`: $value');
          });
        }

        if (tool.settingsHints != null && tool.settingsHints!.isNotEmpty) {
          buffer.writeln('- Settings Hints:');
          tool.settingsHints!.forEach((key, value) {
            buffer.writeln('  - `$key`: $value');
          });
        }

        buffer.writeln();
      }
    }
    buffer.writeln();
  });

  final file = File(outputPath);
  await file.writeAsString(buffer.toString());
  if (kDebugMode) {
    print('README.md generated at $outputPath (compact=$compact)');
  }
}
