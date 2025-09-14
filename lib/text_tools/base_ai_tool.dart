import 'package:utility_tools/models/tool.dart';
import 'package:utility_tools/services/ai_service.dart';

/// Base class for AI-powered tools
abstract class BaseAITool extends Tool {
  final AIService aiService;

  BaseAITool({
    required super.name,
    required super.description,
    required super.icon,
    Map<String, dynamic> settings = const {},
    super.isOutputMarkdown = true,
    super.isInputMarkdown = true,
    super.canAcceptMarkdown = true,
    super.allowEmptyInput = false,
    super.settingsHints,
  }) : aiService = AIService.fromAppSettings(),
       super(
         settings: Map<String, dynamic>.from(settings),
         supportsLiveUpdate: false,
         supportsStreaming: true,
       );

  /// Dispose resources
  void dispose() {
    aiService.dispose();
  }

  /// Clear conversation history
  void clearHistory() {
    aiService.clearHistory();
  }

  /// Add a message to conversation history
  void addToHistory(String role, String content) {
    aiService.addToHistory(role, content);
  }

  /// Get current conversation history
  List<ChatMessage> get conversationHistory => aiService.conversationHistory;

  /// Override executeStream to provide streaming functionality
  @override
  Stream<String>? executeStream(String input) async* {
    try {
      await for (final chunk in _processAIRequestInternal(
        input,
        streaming: true,
      )) {
        yield chunk;
      }
    } on AIException catch (e) {
      yield 'AI Error: $e';
    } catch (e) {
      yield 'Error: $e';
    }
  }

  /// Enhanced execute method that supports streaming
  @override
  Future<ToolResult> execute(String input) async {
    try {
      final buffer = StringBuffer();
      await for (final chunk in _processAIRequestInternal(
        input,
        streaming: false,
      )) {
        buffer.write(chunk);
      }
      return ToolResult(output: buffer.toString(), status: 'success');
    } on AIException catch (e) {
      return ToolResult(output: 'AI Error: $e', status: 'error');
    } catch (e) {
      return ToolResult(output: 'Error: $e', status: 'error');
    }
  }

  /// Internal method that handles both streaming and non-streaming
  Stream<String> _processAIRequestInternal(
    String input, {
    required bool streaming,
  }) async* {
    final systemPrompt = buildAISystemPrompt(input);
    final messages = buildAIMessages(input, systemPrompt);

    if (streaming) {
      await for (final chunk in aiService.streamComplete(
        input,
        messages: messages,
      )) {
        yield chunk;
      }
    } else {
      final response = await aiService.complete(input, messages: messages);
      yield response.content;
    }
  }

  /// Abstract method: Build the system prompt for this tool
  String buildAISystemPrompt(String input);

  /// Abstract method: Build the messages array for this tool
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    return [
      ChatMessage.text(role: 'system', text: systemPrompt),
      ChatMessage.text(role: 'user', text: input),
    ];
  }
}
