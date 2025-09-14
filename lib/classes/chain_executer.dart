import 'package:utility_tools/models/tool.dart';
import 'package:utility_tools/text_tools/splitter_tools.dart';

class ChainExecutor {
  static Future<List<ToolExecution>> executeChain(
    List<ChainedTool> tools,
    String initialInput,
  ) async {
    final executions = <ToolExecution>[];
    String currentInput = initialInput;
    int i = 0;

    while (i < tools.length) {
      final chainedTool = tools[i];
      if (!chainedTool.enabled) {
        i++;
        continue;
      }

      final stopwatch = Stopwatch()..start();

      try {
        // Check if this is a splitter tool
        if (chainedTool.tool is SplitterTool) {
          final splitterTool = chainedTool.tool as SplitterTool;
          final toolsToConsume = splitterTool.toolsToConsume;

          // Get the next N tools to consume
          final consumedTools = <ChainedTool>[];
          for (int j = 1; j <= toolsToConsume && i + j < tools.length; j++) {
            final tool = tools[i + j];
            if (tool.tool is! SplitterTool) {
              consumedTools.add(tools[i + j]);
            }
          }

          // Execute splitter with consumed tools
          final result = await splitterTool.executeSplitter(
            currentInput,
            consumedTools,
          );

          final execution = ToolExecution(
            timestamp: DateTime.now(),
            input: currentInput,
            output: result.output,
            executionTime: stopwatch.elapsed,
            success: result.status != 'error',
            status: result.status,
          );

          chainedTool.addExecution(execution);
          executions.add(execution);
          currentInput = result.output;

          // Skip the consumed tools
          i += toolsToConsume + 1;
        } else {
          // Regular tool execution
          bool useTextOutput = false;
          if (i + 1 < tools.length) {
            final nextTool = tools[i + 1];
            useTextOutput =
                chainedTool.tool.isOutputMarkdown &&
                !nextTool.tool.canAcceptMarkdown;
          }

          String output;
          String status;
          if (useTextOutput) {
            output = await chainedTool.tool.executeGetText(currentInput);
            status = 'success';
          } else {
            final result = await chainedTool.tool.execute(currentInput);
            output = result.output;
            status = result.status ?? 'success';
          }

          final execution = ToolExecution(
            timestamp: DateTime.now(),
            input: currentInput,
            output: output,
            executionTime: stopwatch.elapsed,
            success: status != 'error',
            status: status,
          );

          chainedTool.addExecution(execution);
          executions.add(execution);
          currentInput = output;

          i++;
        }
      } catch (e) {
        final execution = ToolExecution(
          timestamp: DateTime.now(),
          input: currentInput,
          output: '',
          executionTime: stopwatch.elapsed,
          success: false,
          errorMessage: e.toString(),
        );

        chainedTool.addExecution(execution);
        executions.add(execution);
        break;
      }
    }

    return executions;
  }
}
