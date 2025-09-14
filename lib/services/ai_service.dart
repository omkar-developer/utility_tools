import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'app_settings.dart';

/// Configuration for AI service connection
class AIConfig {
  final String baseUrl;
  final String? apiKey;
  final String defaultModel;
  final int maxTokens;
  final double temperature;
  final Duration timeout;

  const AIConfig({
    this.baseUrl = 'http://localhost:11434/v1',
    this.apiKey,
    this.defaultModel = 'llama2',
    this.maxTokens = 2048,
    this.temperature = 0.7,
    this.timeout = const Duration(seconds: 60),
  });

  factory AIConfig.openai({
    required String apiKey,
    String model = 'gpt-3.5-turbo',
    int maxTokens = 2048,
    double temperature = 0.7,
  }) {
    return AIConfig(
      baseUrl: 'https://api.openai.com/v1',
      apiKey: apiKey,
      defaultModel: model,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }

  factory AIConfig.ollama({
    String baseUrl = 'http://localhost:11434/v1',
    String model = 'llava', // Changed default to vision model
    int maxTokens = 2048,
    double temperature = 0.7,
  }) {
    return AIConfig(
      baseUrl: baseUrl,
      defaultModel: model,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }
}

/// Message content that can contain text and/or images
class MessageContent {
  final String? text;
  final String? imageUrl;
  final String type; // "text" or "image_url"

  const MessageContent({this.text, this.imageUrl, required this.type});

  Map<String, dynamic> toJson() {
    if (type == 'image_url' && imageUrl != null) {
      return {
        'type': 'image_url',
        'image_url': {'url': imageUrl!},
      };
    } else {
      return {'type': 'text', 'text': text ?? ''};
    }
  }
}

/// Message in a chat conversation with support for multimodal content
class ChatMessage {
  final String role;
  final dynamic content; // Can be String or List<MessageContent>

  const ChatMessage({required this.role, required this.content});

  /// Constructor for simple text messages
  ChatMessage.text({required this.role, required String text}) : content = text;

  /// Constructor for messages with images (OpenAI/Ollama compatible format)
  ChatMessage.withImages({
    required this.role,
    required String text,
    required List<String> imageDataUrls, // Now expects full data URLs
  }) : content = [
         MessageContent(type: 'text', text: text),
         ...imageDataUrls.map(
           (dataUrl) => MessageContent(
             type: 'image_url',
             imageUrl: dataUrl, // Use the full data URL as-is
           ),
         ),
       ];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {'role': role};

    // Handle different content formats
    if (content is String) {
      result['content'] = content;
    } else if (content is List<MessageContent>) {
      // OpenAI multimodal format (also compatible with Ollama v1 endpoint)
      result['content'] = (content as List<MessageContent>)
          .map((c) => c.toJson())
          .toList();
    } else if (content is List) {
      // Handle legacy list format
      result['content'] = content;
    } else {
      result['content'] = content.toString();
    }

    return result;
  }

  /// Check if message contains images
  bool get hasImages {
    if (content is List<MessageContent>) {
      return (content as List<MessageContent>).any(
        (c) => c.type == 'image_url',
      );
    }
    return false;
  }
}

/// Response from AI service
class AIResponse {
  final String content;
  final String? model;
  final int? tokensUsed;
  final String? finishReason;

  const AIResponse({
    required this.content,
    this.model,
    this.tokensUsed,
    this.finishReason,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('No choices in AI response');
    }

    final firstChoice = choices[0] as Map<String, dynamic>;
    final message = firstChoice['message'] as Map<String, dynamic>;

    return AIResponse(
      content: message['content'] as String? ?? '',
      model: json['model'] as String?,
      tokensUsed: json['usage']?['total_tokens'] as int?,
      finishReason: firstChoice['finish_reason'] as String?,
    );
  }
}

/// Exception thrown when AI service encounters an error
class AIException implements Exception {
  final String message;
  final int? statusCode;
  final String? details;

  const AIException(this.message, {this.statusCode, this.details});

  @override
  String toString() {
    if (statusCode != null) {
      return 'AIException ($statusCode): $message';
    }
    return 'AIException: $message';
  }
}

/// Service class for AI completions and streaming with image support
class AIService {
  final http.Client _httpClient;
  final List<ChatMessage> _conversationHistory = [];

  // Optional config override - if null, uses AppSettings
  final AIConfig? _configOverride;

  AIService({AIConfig? config, http.Client? httpClient})
    : _configOverride = config,
      _httpClient = httpClient ?? http.Client();

  /// Get current effective config (from override or AppSettings)
  AIConfig get effectiveConfig {
    if (_configOverride != null) {
      return _configOverride;
    }

    // Build config from AppSettings
    return AIConfig(
      baseUrl: AppSettings.aiBaseUrl,
      defaultModel: AppSettings.aiModel,
      apiKey: AppSettings.aiApiKey.isNotEmpty ? AppSettings.aiApiKey : null,
      maxTokens: AppSettings.aiMaxTokens,
      temperature: AppSettings.aiTemperature,
    );
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// Add a message to conversation history
  void addToHistory(
    String role,
    String content, {
    List<String>? imageDataUrls,
  }) {
    if (imageDataUrls != null && imageDataUrls.isNotEmpty) {
      _conversationHistory.add(
        ChatMessage.withImages(
          role: role,
          text: content,
          imageDataUrls: imageDataUrls,
        ),
      );
    } else {
      _conversationHistory.add(ChatMessage.text(role: role, text: content));
    }
  }

  /// Get current conversation history
  List<ChatMessage> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  /// Make a simple AI completion request
  Future<AIResponse> complete(
    String prompt, {
    String? model,
    double? temperature,
    int? maxTokens,
    List<ChatMessage>? messages,
    bool saveToHistory = true,
  }) async {
    final config = effectiveConfig;

    final requestMessages =
        messages ?? [ChatMessage.text(role: 'user', text: prompt)];

    if (saveToHistory && messages == null) {
      addToHistory('user', prompt);
    }

    final response = await _makeRequest(
      messages: requestMessages,
      model: model ?? config.defaultModel,
      temperature: temperature ?? config.temperature,
      maxTokens: maxTokens ?? config.maxTokens,
    );

    if (saveToHistory) {
      addToHistory('assistant', response.content);
    }

    return response;
  }

  /// Make a completion request with images
  Future<AIResponse> completeWithImages(
    String prompt,
    List<String> imageDataUrls, { // Now expects full data URLs
    String? model,
    double? temperature,
    int? maxTokens,
    bool saveToHistory = true,
  }) async {
    final config = effectiveConfig;

    final message = ChatMessage.withImages(
      role: 'user',
      text: prompt,
      imageDataUrls: imageDataUrls,
    );

    final response = await _makeRequest(
      messages: [message],
      model: model ?? config.defaultModel,
      temperature: temperature ?? config.temperature,
      maxTokens: maxTokens ?? config.maxTokens,
    );

    if (saveToHistory) {
      addToHistory('user', prompt, imageDataUrls: imageDataUrls);
      addToHistory('assistant', response.content);
    }

    return response;
  }

  /// Make a completion request with conversation history
  Future<AIResponse> completeWithHistory(
    String prompt, {
    String? model,
    double? temperature,
    int? maxTokens,
    String? systemPrompt,
    List<String>? imageDataUrls,
  }) async {
    final config = effectiveConfig;
    final messages = <ChatMessage>[];

    if (systemPrompt != null) {
      messages.add(ChatMessage.text(role: 'system', text: systemPrompt));
    }

    messages.addAll(_conversationHistory);

    // Add user message with or without images
    if (imageDataUrls != null && imageDataUrls.isNotEmpty) {
      messages.add(
        ChatMessage.withImages(
          role: 'user',
          text: prompt,
          imageDataUrls: imageDataUrls,
        ),
      );
    } else {
      messages.add(ChatMessage.text(role: 'user', text: prompt));
    }

    final response = await _makeRequest(
      messages: messages,
      model: model ?? config.defaultModel,
      temperature: temperature ?? config.temperature,
      maxTokens: maxTokens ?? config.maxTokens,
    );

    addToHistory('user', prompt, imageDataUrls: imageDataUrls);
    addToHistory('assistant', response.content);

    return response;
  }

  /// Stream completion (for real-time responses)
  Stream<String> streamComplete(
    String prompt, {
    String? model,
    double? temperature,
    int? maxTokens,
    List<ChatMessage>? messages,
  }) async* {
    final config = effectiveConfig;
    final requestMessages =
        messages ?? [ChatMessage.text(role: 'user', text: prompt)];

    await for (final chunk in _makeStreamRequest(
      messages: requestMessages,
      model: model ?? config.defaultModel,
      temperature: temperature ?? config.temperature,
      maxTokens: maxTokens ?? config.maxTokens,
    )) {
      yield chunk;
    }
  }

  /// Check if the current model supports vision
  bool get supportsVision {
    final model = effectiveConfig.defaultModel.toLowerCase();
    return model.contains('vision') ||
        model.contains('llava') ||
        model.contains('bakllava') ||
        model.contains('gpt-4') ||
        model == 'claude-3-opus' ||
        model == 'claude-3-sonnet' ||
        model == 'claude-3-haiku';
  }

  /// Internal method to make HTTP request to AI service
  Future<AIResponse> _makeRequest({
    required List<ChatMessage> messages,
    required String model,
    required double temperature,
    required int maxTokens,
  }) async {
    final config = effectiveConfig;

    final requestBody = {
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
    };

    final headers = {'Content-Type': 'application/json'};

    if (config.apiKey != null) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }

    try {
      final response = await _httpClient
          .post(
            Uri.parse('${config.baseUrl}/chat/completions'),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(config.timeout);

      if (response.statusCode != 200) {
        String errorMessage = 'Unknown error';
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage =
              errorBody['error']?['message'] ??
              errorBody['error'] ??
              'HTTP ${response.statusCode}';
        } catch (e) {
          errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        }

        throw AIException(
          errorMessage,
          statusCode: response.statusCode,
          details: response.body,
        );
      }

      final responseData = jsonDecode(response.body);
      return AIResponse.fromJson(responseData);
    } on TimeoutException {
      throw const AIException('Request timed out');
    } on FormatException catch (e) {
      throw AIException('Invalid response format: $e');
    } catch (e) {
      if (e is AIException) rethrow;
      throw AIException('Request failed: $e');
    }
  }

  /// Internal method to make streaming HTTP request
  Stream<String> _makeStreamRequest({
    required List<ChatMessage> messages,
    required String model,
    required double temperature,
    required int maxTokens,
  }) async* {
    final config = effectiveConfig;

    final requestBody = {
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
    };

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    };

    if (config.apiKey != null) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }

    // Use the OpenAI-compatible endpoint for both OpenAI and Ollama
    final url = '${config.baseUrl}/chat/completions';

    try {
      final request = http.Request('POST', Uri.parse(url));
      request.headers.addAll(headers);
      request.body = jsonEncode(requestBody);

      final response = await _httpClient.send(request).timeout(config.timeout);

      if (response.statusCode != 200) {
        throw AIException(
          'Stream request failed',
          statusCode: response.statusCode,
        );
      }

      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');

        // Keep the last incomplete line in buffer
        buffer = lines.removeLast();

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') return;

            if (data.isEmpty) continue;

            try {
              final json = jsonDecode(data);
              final choices = json['choices'] as List?;
              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'] as Map<String, dynamic>?;
                final content = delta?['content'] as String?;
                if (content != null && content.isNotEmpty) {
                  yield content;
                }
              }
            } catch (e) {
              // Skip malformed chunks
              continue;
            }
          }
        }
      }
    } on TimeoutException {
      throw const AIException('Stream request timed out');
    } catch (e) {
      if (e is AIException) rethrow;
      throw AIException('Stream request failed: $e');
    }
  }

  /// Helper function to extract base64 images from input with format detection
  /// Returns (cleanText, dataUrls) - preserves full data URLs with format
  static (String, List<String>) extractBase64Images(String input) {
    final imageRegex = RegExp(r'data:image/([^;]+);base64,([A-Za-z0-9+/=]+)');
    final imageMatches = imageRegex.allMatches(input);

    if (imageMatches.isEmpty) {
      return (input, <String>[]);
    }

    final dataUrls = imageMatches.map((match) => match.group(0)!).toList();
    final cleanInput = input.replaceAll(imageRegex, '[Image]').trim();

    return (cleanInput, dataUrls);
  }

  /// Validate if string contains valid base64 image data URLs
  static bool hasValidBase64Images(String input) {
    final imageRegex = RegExp(r'data:image/([^;]+);base64,([A-Za-z0-9+/=]+)');
    final matches = imageRegex.allMatches(input);

    if (matches.isEmpty) return false;

    for (final match in matches) {
      final format = match.group(1);
      final base64Data = match.group(2);

      // Check if format is supported
      if (format == null ||
          ![
            'jpeg',
            'jpg',
            'png',
            'gif',
            'webp',
            'bmp',
          ].contains(format.toLowerCase())) {
        return false;
      }

      // Check if base64 data is valid
      if (base64Data == null || !isValidBase64Image(base64Data)) {
        return false;
      }
    }

    return true;
  }

  /// Extract just the format from a data URL
  static String? getImageFormat(String dataUrl) {
    final match = RegExp(r'data:image/([^;]+);base64,').firstMatch(dataUrl);
    return match?.group(1);
  }

  /// Create a service instance that uses AppSettings
  static AIService fromAppSettings() {
    return AIService();
  }

  /// Create a service instance with custom config (ignores AppSettings)
  static AIService withCustomConfig(AIConfig config) {
    return AIService(config: config);
  }

  /// Get current settings info for debugging
  Map<String, dynamic> getCurrentSettings() {
    final config = effectiveConfig;
    return {
      'baseUrl': config.baseUrl,
      'model': config.defaultModel,
      'hasApiKey': config.apiKey != null,
      'maxTokens': config.maxTokens,
      'temperature': config.temperature,
      'isUsingAppSettings': _configOverride == null,
      'supportsVision': supportsVision,
      'endpoint': '${config.baseUrl}/chat/completions',
    };
  }

  /// Helper method to format system prompts
  static String buildSystemPrompt({
    required String role,
    String? context,
    List<String>? instructions,
    String? outputFormat,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('You are $role.');

    if (context != null) {
      buffer.writeln('\nContext: $context');
    }

    if (instructions != null && instructions.isNotEmpty) {
      buffer.writeln('\nInstructions:');
      for (final instruction in instructions) {
        buffer.writeln('- $instruction');
      }
    }

    if (outputFormat != null) {
      buffer.writeln('\nOutput format: $outputFormat');
    }

    return buffer.toString();
  }

  /// Helper method to extract code blocks from AI responses
  static List<String> extractCodeBlocks(String response, [String? language]) {
    final codeBlocks = <String>[];
    final pattern = language != null
        ? RegExp(r'```' + language + r'\n(.*?)\n```', dotAll: true)
        : RegExp(r'```\w*\n(.*?)\n```', dotAll: true);

    final matches = pattern.allMatches(response);
    for (final match in matches) {
      if (match.group(1) != null) {
        codeBlocks.add(match.group(1)!.trim());
      }
    }

    return codeBlocks;
  }

  /// Helper method to clean AI responses
  static String cleanResponse(String response) {
    return response
        .replaceAll(RegExp(r'```\w*\n(.*?)\n```', dotAll: true), r'$1')
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        .trim();
  }

  /// Helper to convert file to base64 (you'll need to implement file reading)
  static String encodeImageToBase64(List<int> imageBytes) {
    return base64Encode(imageBytes);
  }

  /// Helper to create data URL from base64
  static String createDataUrl(
    String base64Image, {
    String mimeType = 'image/jpeg',
  }) {
    return 'data:$mimeType;base64,$base64Image';
  }

  /// Validate base64 image string
  static bool isValidBase64Image(String base64String) {
    try {
      base64Decode(base64String);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Test connection to AI service
  Future<bool> testConnection() async {
    try {
      final response = await complete('test', saveToHistory: false);
      return response.content.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
