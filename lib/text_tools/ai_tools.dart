import 'package:flutter/material.dart';
import 'base_ai_tool.dart';
import 'package:utility_tools/models/tool.dart';
import 'package:utility_tools/services/ai_service.dart';

/// Example: Text summarization tool
class SummarizerTool extends BaseAITool {
  SummarizerTool({Map<String, dynamic>? settings})
    : super(
        settings:
            settings ??
            {
              'max_length': 200,
              'style': 'paragraph',
              'include_key_quotes': false,
            },
        name: 'Text Summarizer',
        description: 'Summarize long texts into key points',
        icon: Icons.summarize,
        settingsHints: {
          'max_length': {
            'type': 'number',
            'label': 'Max Length (words)',
            'help': 'Maximum length of summary in words',
            'min': 50,
            'max': 1000,
          },
          'style': {
            'type': 'dropdown',
            'label': 'Summary Style',
            'help': 'Choose the format for the summary output',
            'options': [
              {'value': 'paragraph', 'label': 'Paragraph Form'},
              {'value': 'bullet_points', 'label': 'Bullet Points'},
              {'value': 'key_points', 'label': 'Numbered Key Points'},
            ],
          },
          'include_key_quotes': {
            'type': 'bool',
            'label': 'Include Key Quotes',
            'help': 'Include important quotes from the original text',
          },
        },
      );

  @override
  String buildAISystemPrompt(String input) {
    final maxLength = settings['max_length'] ?? 200;
    final style = settings['style'] ?? 'paragraph';
    final includeQuotes = settings['include_key_quotes'] ?? false;

    return AIService.buildSystemPrompt(
      role: 'an expert text summarizer',
      instructions: [
        'Summarize the provided text clearly and concisely',
        'Focus on the most important points and key information',
        'Keep the summary under $maxLength words',
        if (style == 'bullet_points') 'Format as bullet points',
        if (style == 'key_points') 'Format as numbered key points',
        if (includeQuotes) 'Include important quotes from the original text',
      ],
      outputFormat: style == 'paragraph'
          ? 'A coherent paragraph'
          : 'Structured $style format',
    );
  }

  @override
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    return [
      ChatMessage(role: 'system', content: systemPrompt),
      ChatMessage(
        role: 'user',
        content: 'Please summarize this text:\n\n$input',
      ),
    ];
  }
}

/// Example: Code explanation tool
class CodeExplainerTool extends BaseAITool {
  CodeExplainerTool({Map<String, dynamic>? settings})
    : super(
        settings:
            settings ??
            {
              'language': 'auto',
              'custom_language': '',
              'explain_code': true,
              'generate_documentation': true,
              'explanation_level': 'intermediate',
              'documentation_style': 'both',
              'include_examples': true,
              'show_flow_diagram': false,
              'explain_algorithms': true,
              'include_type_info': true,
              'use_emojis': true,
              'show_complexity': false,
              'beginner_friendly': true,
            },
        name: 'Code Explainer & Documentation Generator',
        description:
            'Explains code functionality and generates comprehensive documentation without modifying original code',
        icon: Icons.description_outlined,
        settingsHints: {
          'language': {
            'type': 'dropdown',
            'label': 'Programming Language',
            'help': 'Select the programming language or use auto-detection',
            'options': [
              {'value': 'auto', 'label': '🔍 Auto-Detect'},
              ...PROGRAMMING_LANGUAGES.entries.map(
                (e) => {'value': e.key, 'label': e.value},
              ),
            ],
          },
          'custom_language': {
            'type': 'text',
            'label': 'Custom Language',
            'help':
                'Specify custom language name (only used when "Custom Language..." is selected)',
            'placeholder': 'e.g., Assembly, COBOL, etc.',
          },
          'explain_code': {
            'type': 'bool',
            'label': 'Explain Code Functionality',
            'help': 'Provide detailed explanations of what the code does',
          },
          'generate_documentation': {
            'type': 'bool',
            'label': 'Generate Documentation',
            'help': 'Create documentation comments and external documentation',
          },
          'explanation_level': {
            'type': 'dropdown',
            'label': 'Explanation Level',
            'help': 'Technical level of explanations provided',
            'options': [
              {'value': 'beginner', 'label': 'Beginner (Simple explanations)'},
              {'value': 'intermediate', 'label': 'Intermediate (Balanced)'},
              {'value': 'expert', 'label': 'Expert (Technical details)'},
            ],
          },
          'documentation_style': {
            'type': 'dropdown',
            'label': 'Documentation Style',
            'help': 'How to present the documentation',
            'options': [
              {'value': 'inline_comments', 'label': 'Inline Comments Only'},
              {
                'value': 'external_docs',
                'label': 'External Documentation Only',
              },
              {'value': 'both', 'label': 'Both Inline & External'},
            ],
          },
          'include_examples': {
            'type': 'bool',
            'label': 'Include Usage Examples',
            'help': 'Show how to use functions, classes, and methods',
          },
          'show_flow_diagram': {
            'type': 'bool',
            'label': 'Show Flow Diagram',
            'help': 'Create simple text-based flow diagrams for complex logic',
          },
          'explain_algorithms': {
            'type': 'bool',
            'label': 'Explain Algorithms',
            'help': 'Break down algorithmic logic and data structures used',
          },
          'include_type_info': {
            'type': 'bool',
            'label': 'Include Type Information',
            'help':
                'Explain parameter types, return values, and data structures',
          },
          'use_emojis': {
            'type': 'bool',
            'label': 'Use Emojis',
            'help': 'Add relevant emojis to make explanations more engaging',
          },
          'show_complexity': {
            'type': 'bool',
            'label': 'Show Time/Space Complexity',
            'help': 'Include Big O notation analysis for algorithms',
          },
          'beginner_friendly': {
            'type': 'bool',
            'label': 'Beginner-Friendly Mode',
            'help': 'Explain programming concepts and terminology used',
          },
        },
      );

  @override
  String buildAISystemPrompt(String input) {
    // Auto-detect language if set to 'auto'
    String language = settings['language'] ?? 'auto';
    String actualLanguage;

    if (language == 'auto') {
      actualLanguage = detectLanguage(input);
    } else if (language == 'custom') {
      actualLanguage = settings['custom_language'] ?? 'Unknown Language';
    } else {
      actualLanguage = PROGRAMMING_LANGUAGES[language] ?? 'Unknown Language';
    }

    bool explainCode = settings['explain_code'] ?? true;
    bool generateDocumentation = settings['generate_documentation'] ?? true;
    String explanationLevel = settings['explanation_level'] ?? 'intermediate';
    String documentationStyle = settings['documentation_style'] ?? 'both';
    bool includeExamples = settings['include_examples'] ?? true;
    bool showFlowDiagram = settings['show_flow_diagram'] ?? false;
    bool explainAlgorithms = settings['explain_algorithms'] ?? true;
    bool includeTypeInfo = settings['include_type_info'] ?? true;
    bool useEmojis = settings['use_emojis'] ?? true;
    bool showComplexity = settings['show_complexity'] ?? false;
    bool beginnerFriendly = settings['beginner_friendly'] ?? true;

    List<String> instructions = [
      'You are analyzing $actualLanguage code to provide explanations and documentation',
      'CRITICAL: Never modify, rewrite, or change the original code in any way',
      'Your job is to explain and document, not to edit or improve the code',
    ];

    // Main functionality
    if (explainCode) {
      instructions.add(
        'Provide clear explanations of what each part of the code does',
      );
    }

    if (generateDocumentation) {
      instructions.add('Generate appropriate documentation for the code');
    }

    // Explanation level
    switch (explanationLevel) {
      case 'beginner':
        instructions.addAll([
          'Use simple, non-technical language suitable for beginners',
          'Explain basic programming concepts as you encounter them',
          'Avoid jargon and use analogies where helpful',
        ]);
        break;
      case 'intermediate':
        instructions.addAll([
          'Provide balanced explanations suitable for developers with some experience',
          'Use appropriate technical terminology with brief explanations',
          'Focus on the logic and structure of the code',
        ]);
        break;
      case 'expert':
        instructions.addAll([
          'Use technical terminology and provide detailed technical explanations',
          'Focus on implementation details, patterns, and architectural decisions',
          'Assume familiarity with advanced programming concepts',
        ]);
        break;
    }

    // Documentation style
    switch (documentationStyle) {
      case 'inline_comments':
        instructions.addAll([
          'Generate inline comments that could be added to the code',
          'Follow $actualLanguage commenting conventions',
          'Provide line-by-line or block-by-block commentary',
        ]);
        break;
      case 'external_docs':
        instructions.addAll([
          'Create external documentation like README sections or API docs',
          'Focus on high-level functionality and usage',
          'Structure documentation for external consumption',
        ]);
        break;
      case 'both':
        instructions.addAll([
          'Provide both inline comments and external documentation',
          'Show how the code would look with proper comments',
          'Also create external documentation for the overall functionality',
        ]);
        break;
    }

    // Additional features
    if (includeExamples) {
      instructions.add(
        'Include usage examples showing how to call functions or use classes',
      );
    }

    if (showFlowDiagram) {
      instructions.add(
        'Create simple text-based flow diagrams for complex logic flows',
      );
    }

    if (explainAlgorithms) {
      instructions.addAll([
        'Break down any algorithms or complex logic into step-by-step explanations',
        'Explain the reasoning behind algorithmic choices',
      ]);
    }

    if (includeTypeInfo) {
      instructions.addAll([
        'Explain parameter types, return values, and data structures',
        'Clarify what each variable and function expects and returns',
      ]);
    }

    if (useEmojis) {
      instructions.addAll([
        'Use relevant emojis to make explanations more engaging and easier to follow',
        'Use 📝 for documentation, 🔧 for functions, 📊 for data, ⚡ for performance notes, etc.',
      ]);
    }

    if (showComplexity) {
      instructions.add(
        'Include time and space complexity analysis (Big O notation) for algorithms',
      );
    }

    if (beginnerFriendly) {
      instructions.addAll([
        'Define programming terms and concepts as they appear',
        'Use analogies and real-world comparisons to explain abstract concepts',
        'Assume the reader may not be familiar with all programming concepts',
      ]);
    }

    // Output formatting
    instructions.addAll([
      'Structure your response with clear sections using markdown headings',
      'Use code blocks with proper syntax highlighting',
      'Make explanations clear, logical, and easy to follow',
      'Always preserve the original code exactly as provided',
      'Focus on understanding rather than criticism',
    ]);

    return AIService.buildSystemPrompt(
      role:
          'an expert code educator and technical writer specializing in $actualLanguage',
      context:
          'You help developers understand code by providing clear explanations and comprehensive documentation. You focus on education and understanding without modifying the original code.',
      instructions: instructions,
    );
  }

  @override
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    return [
      ChatMessage(role: 'system', content: systemPrompt),
      ChatMessage(
        role: 'user',
        content:
            'Please explain this code and generate documentation:\n\n```\n$input\n```',
      ),
    ];
  }

  // Simple language detection helper (same as analysis tool)
  String detectLanguage(String code) {
    code = code.toLowerCase();

    // Check for distinctive patterns
    if (code.contains('extends ') && code.contains('func ')) return 'GDScript';
    if (code.contains('#include') || code.contains('std::')) return 'C++';
    if (code.contains('function ') ||
        code.contains('const ') ||
        code.contains('let ')) {
      return 'JavaScript';
    }
    if (code.contains('def ') && code.contains(':')) return 'Python';
    if (code.contains('class ') &&
        code.contains('{') &&
        code.contains('void ')) {
      return 'Java';
    }
    if (code.contains('public class ') || code.contains('using system')) {
      return 'C#';
    }
    if (code.contains('interface ') && code.contains(': ')) return 'TypeScript';
    if (code.contains('fn ') && code.contains('->')) return 'Rust';
    if (code.contains('func ') && code.contains('package ')) return 'Go';
    if (code.contains('<?php')) return 'PHP';
    if (code.contains('end') && code.contains('do')) return 'Lua';

    // Default fallback
    return 'Unknown (Auto-detection failed - please select manually)';
  }
}

/// Example: Translation tool
class TranslatorTool extends BaseAITool {
  TranslatorTool({Map<String, dynamic>? settings})
    : super(
        settings:
            settings ??
            {
              'target_language': 'Spanish',
              'tone': 'neutral',
              'preserve_formatting': true,
            },
        name: 'Translator',
        description: 'Translate text between languages',
        icon: Icons.translate,
        settingsHints: {
          'target_language': {
            'type': 'dropdown',
            'label': 'Target Language',
            'help': 'Language to translate text into',
            'options': [
              'English',
              'Spanish',
              'French',
              'German',
              'Italian',
              'Portuguese',
              'Russian',
              'Chinese',
              'Japanese',
              'Korean',
              'Arabic',
              'Hindi',
              'Marathi',
              'Telugu',
              'Gujarati',
            ],
          },
          'tone': {
            'type': 'dropdown',
            'label': 'Translation Tone',
            'help': 'Style and formality of the translation',
            'options': [
              {'value': 'neutral', 'label': 'Neutral'},
              {'value': 'formal', 'label': 'Formal'},
              {'value': 'casual', 'label': 'Casual'},
              {'value': 'professional', 'label': 'Professional'},
            ],
          },
          'preserve_formatting': {
            'type': 'bool',
            'label': 'Preserve Formatting',
            'help': 'Keep original text structure and formatting',
          },
        },
      );

  @override
  String buildAISystemPrompt(String input) {
    final targetLanguage = settings['target_language'] ?? 'Spanish';
    final tone = settings['tone'] ?? 'neutral';
    final preserveFormatting = settings['preserve_formatting'] ?? true;

    return AIService.buildSystemPrompt(
      role: 'a professional translator',
      instructions: [
        'Translate the provided text to $targetLanguage',
        'Maintain the original meaning and context',
        'Use a $tone tone in the translation',
        if (preserveFormatting) 'Preserve any formatting or structure',
        'Only return the translation, no explanations',
      ],
    );
  }

  @override
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    return [
      ChatMessage(role: 'system', content: systemPrompt),
      ChatMessage(role: 'user', content: input),
    ];
  }
}

/// Example: Creative writing assistant
class WritingAssistantTool extends BaseAITool {
  WritingAssistantTool({Map<String, dynamic>? settings})
    : super(
        settings:
            settings ??
            {
              'task': 'improve',
              'style': 'maintain original',
              'creativity_level': 50.0,
              'word_count_target': 0,
            },
        name: 'Writing Assistant',
        description: 'Help improve and enhance your writing',
        icon: Icons.edit,
        settingsHints: {
          'task': {
            'type': 'dropdown',
            'label': 'Writing Task',
            'help': 'What you want to do with the text',
            'options': [
              {'value': 'improve', 'label': 'Improve Quality'},
              {'value': 'proofread', 'label': 'Proofread & Fix'},
              {'value': 'expand', 'label': 'Expand Content'},
              {'value': 'rewrite', 'label': 'Rewrite Completely'},
            ],
          },
          'style': {
            'type': 'dropdown',
            'label': 'Writing Style',
            'help': 'Target style for the output',
            'options': [
              {'value': 'maintain original', 'label': 'Keep Original Style'},
              {'value': 'formal', 'label': 'Formal'},
              {'value': 'casual', 'label': 'Casual'},
              {'value': 'academic', 'label': 'Academic'},
              {'value': 'creative', 'label': 'Creative'},
            ],
          },
          'creativity_level': {
            'type': 'slider',
            'label': 'Creativity Level',
            'help': 'How creative vs conservative the changes should be',
            'min': 0.0,
            'max': 100.0,
            'divisions': 20,
            'show_value': true,
          },
          'word_count_target': {
            'type': 'number',
            'label': 'Target Word Count',
            'help': 'Desired word count (0 = no target)',
            'min': 0,
            'max': 10000,
          },
        },
      );

  @override
  String buildAISystemPrompt(String input) {
    final task = settings['task'] ?? 'improve';
    final style = settings['style'] ?? 'maintain original';
    final creativityLevel = settings['creativity_level'] ?? 50.0;
    final wordCountTarget = settings['word_count_target'] ?? 0;

    return AIService.buildSystemPrompt(
      role: 'a professional writing assistant',
      context: 'You help users improve their writing quality',
      instructions: [
        'Task: ${_getTaskDescription(task)}',
        if (style != 'maintain original') 'Use a $style writing style',
        'Maintain the original intent and meaning',
        'Use a creativity level of ${creativityLevel.toInt()}% (0=conservative, 100=very creative)',
        if (wordCountTarget > 0) 'Target approximately $wordCountTarget words',
        'Provide clear, actionable improvements',
        if (task == 'proofread') 'Focus on grammar, spelling, and clarity',
      ],
    );
  }

  @override
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    final task = settings['task'] ?? 'improve';
    return [
      ChatMessage(role: 'system', content: systemPrompt),
      ChatMessage(role: 'user', content: 'Please $task this text:\n\n$input'),
    ];
  }

  String _getTaskDescription(String task) {
    switch (task) {
      case 'improve':
        return 'Improve the overall quality and clarity of the text';
      case 'proofread':
        return 'Check and correct grammar, spelling, and punctuation';
      case 'expand':
        return 'Expand the text with more details and examples';
      case 'rewrite':
        return 'Rewrite the text while maintaining the core message';
      default:
        return 'Improve the text quality';
    }
  }
}

class ToolGeneratorTool extends BaseAITool {
  ToolGeneratorTool({Map<String, dynamic>? settings})
    : super(
        settings:
            settings ??
            {
              'tool_category': 'TextTransform',
              'tool_type': 'regular',
              'language': 'javascript',
              'include_export': false,
              'add_comments': false,
            },
        name: 'Tool Generator',
        description:
            'Generate custom tools using AI based on your requirements',
        icon: Icons.build_circle,
        settingsHints: {
          'language': {
            'type': 'dropdown',
            'label': 'Programming Language',
            'help': 'Choose the language for the generated tool',
            'options': [
              {'value': 'dart', 'label': 'Dart/Flutter'},
              {'value': 'javascript', 'label': 'JavaScript'},
            ],
          },
          'tool_category': {
            'type': 'dropdown',
            'label': 'Tool Category',
            'help': 'Which category should this tool belong to?',
            'options': [
              {'value': 'TextTransform', 'label': 'Text Transformation'},
              {'value': 'Coding', 'label': 'Coding Tools'},
              {'value': 'Converters', 'label': 'Format Converters'},
              {'value': 'DataProcessing', 'label': 'Data Processing'},
              {'value': 'TextAnalysis', 'label': 'Text Analysis'},
              {'value': 'AI', 'label': 'AI Tools'},
            ],
          },
          'tool_type': {
            'type': 'dropdown',
            'label': 'Tool Type',
            'help': 'Regular tool or AI-powered tool?',
            'options': [
              {'value': 'regular', 'label': 'Regular Tool'},
              {'value': 'ai', 'label': 'AI Tool'},
            ],
          },
          'include_export': {
            'type': 'bool',
            'label': 'Include Export Function',
            'help': 'Generate the export function at the end (Dart only)',
          },
          'add_comments': {
            'type': 'bool',
            'label': 'Add Code Comments',
            'help': 'Include helpful comments in the generated code',
          },
        },
      );

  @override
  String buildAISystemPrompt(String input) {
    final language = settings['language'] ?? 'dart';
    final category = settings['tool_category'] ?? 'TextTransform';
    final toolType = settings['tool_type'] ?? 'regular';
    final includeExport = settings['include_export'] ?? true;
    final addComments = settings['add_comments'] ?? true;

    if (language == 'javascript') {
      return _buildJavaScriptPrompt(category, toolType, addComments);
    } else {
      return _buildDartPrompt(category, toolType, includeExport, addComments);
    }
  }

  String _buildJavaScriptPrompt(
    String category,
    String toolType,
    bool addComments,
  ) {
    final isAiTool = toolType == 'ai';

    return AIService.buildSystemPrompt(
      role: 'an expert JavaScript developer and tool creator',
      context:
          'You create JavaScript tools for a text processing application using a specific framework',
      instructions: [
        'Generate a complete JavaScript tool following the exact framework structure',
        'Tool category: $category',
        'Tool type: ${isAiTool ? 'AI Tool (JS AI Tool)' : 'Regular Tool (JS Tool)'}',
        if (addComments)
          'Include helpful code comments explaining functionality',
        '',
        if (isAiTool) ...[
          'JAVASCRIPT AI TOOL STRUCTURE:',
          '',
          'var name = "Tool Name";',
          'var description = "Tool description";',
          'var icon = "icon_name";',
          'var isOutputMarkdown = false;',
          'var isInputMarkdown = false;',
          'var canAcceptMarkdown = false;',
          'var supportsLiveUpdate = true;',
          'var allowEmptyInput = false;',
          '',
          'var settings = {',
          '  "setting1": "default_value"',
          '};',
          '',
          'var settingsHints = {',
          '  "setting1": {',
          '    "type": "dropdown",',
          '    "label": "Setting Label",',
          '    "help": "Help text",',
          '    "options": [',
          '      {"value": "val1", "label": "Label 1"},',
          '      {"value": "val2", "label": "Label 2"}',
          '    ]',
          '  }',
          '};',
          '',
          'function buildAISystemPrompt(input, settings) {',
          '  // Build AI system prompt based on input and settings',
          '  return "You are an expert at...";',
          '}',
          '',
          'function buildAIMessages(input, systemPrompt, settings) {',
          '  // Return array of message objects',
          '  return [',
          '    {"role": "system", "content": systemPrompt},',
          '    {"role": "user", "content": input}',
          '  ];',
          '}',
        ] else ...[
          'JAVASCRIPT TOOL STRUCTURE:',
          '',
          'var name = "Tool Name";',
          'var description = "Tool description";',
          'var icon = "icon_name";',
          'var isOutputMarkdown = true;',
          'var isInputMarkdown = false;',
          'var canAcceptMarkdown = false;',
          'var supportsLiveUpdate = true;',
          'var allowEmptyInput = false;',
          '',
          'var settings = {',
          '  "setting1": "default_value"',
          '};',
          '',
          'var settingsHints = {',
          '  "setting1": {',
          '    "type": "dropdown",',
          '    "label": "Setting Label",',
          '    "help": "Help text",',
          '    "options": [',
          '      {"value": "val1", "label": "Label 1"}',
          '    ]',
          '  }',
          '};',
          '',
          'function execute(input, settings) {',
          '  // Process input using settings',
          '  // Access settings directly: settings.setting1',
          '  var result = input; // Process here',
          '  return result;',
          '}',
        ],
        '',
        'NEW OUTPUT FORMATS SUPPORTED:',
        '- Tools can now return base64 image data directly',
        '- Use code blocks for visual output: ```svg, ```png, ```jpg, ```gif',
        '- Example SVG output: return "```svg\\n<svg>...</svg>\\n```";',
        '- Example base64 PNG: return "```png\\ndata:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==\\n```";',
        '',
        'ALLOWEMPTYINPUT PROPERTY EXPLANATION:',
        '- Set allowEmptyInput = true for tools that don\'t need text input from user',
        '- This hides the multi-line input box and passes empty string as input',
        '- Perfect for: password generators, calculators, random generators, utilities, image generators',
        '- Set allowEmptyInput = false for tools that process user text input',
        '- Examples of allowEmptyInput = true: password generator, QR code generator, random quote generator, image creator',
        '- Examples of allowEmptyInput = false: text formatter, translator, summarizer',
        '',
        'ALL JS SETTING TYPES AVAILABLE:',
        '- bool: {"type": "bool", "label": "Label", "help": "Help text"}',
        '- text: {"type": "text", "label": "Label", "help": "Help", "placeholder": "Enter..."}',
        '- multiline: {"type": "multiline", "label": "Label", "help": "Help", "placeholder": "Enter...", "rows": 3}',
        '- number: {"type": "number", "label": "Label", "min": 0, "max": 100, "decimal": false}',
        '- spinner: {"type": "spinner", "label": "Label", "min": 0, "max": 100, "step": 1, "decimal": false, "decimals": 1}',
        '- slider: {"type": "slider", "label": "Label", "min": 0, "max": 100, "divisions": 10, "show_range": true}',
        '- dropdown: {"type": "dropdown", "label": "Label", "options": [{"value": "val1", "label": "Label1"}]}',
        '- multiselect: {"type": "multiselect", "label": "Label", "options": [{"value": "val1", "label": "Label1"}], "min_selections": 1, "max_selections": 3}',
        '- color: {"type": "color", "label": "Color", "help": "Pick a color", "alpha": true, "presets": true}',
        '',
        'SETTING TYPE DETAILS:',
        '- spinner: Interactive number input with +/- buttons. Set "decimal": true for float values',
        '- slider: Visual slider control. Use "divisions" for stepped values, "show_range" to display min/max',
        '- multiselect: Allow selecting multiple options. Returns array of selected values',
        '- color: Color picker. Returns hex color string. Set "alpha": true for opacity, "presets": false to hide preset colors',
        '- multiline: Multi-row text input. Set "rows" to control height',
        '',
        'AVAILABLE ICON NAMES:',
        if (isAiTool)
          '- "auto_awesome", "psychology", "smart_toy", "lightbulb", "translate", "summarize", "chat", "image", "brush", "palette"'
        else
          '- "edit", "transform", "code", "format_paint", "functions", "build", "filter_list", "password", "calculate", "casino", "image", "qr_code", "color_lens", "tune"',
        '',
        'CRITICAL REQUIREMENTS:',
        if (isAiTool) ...[
          '- Must have buildAISystemPrompt(input, settings) function that returns a string',
          '- Must have buildAIMessages(input, systemPrompt, settings) function that returns array',
          '- Access settings directly: settings.settingName',
          '- buildAIMessages must return array of objects with "role" and "content" properties',
          '- Can return visual output using code blocks: ```svg, ```png, etc.',
        ] else ...[
          '- Must have execute(input, settings) function that returns a string',
          '- Access settings directly: settings.settingName',
          '- Execute Function should process the input and return the result string',
          '- Can return visual output using code blocks: ```svg, ```png, etc.',
          '- For image generation tools, return base64 data or SVG markup in appropriate code blocks',
        ],
        '- All metadata variables (name, description, icon, etc.) must be defined',
        '- Settings object must contain all configurable options with defaults',
        '- SettingsHints must define UI configuration for each setting',
        '- Set allowEmptyInput appropriately based on whether tool needs text input',
        '- For multiselect settings, default value should be an array',
        '- For color settings, default value should be a hex color string like "#3498db"',
        '',
        'EXAMPLE MULTISELECT SETTING:',
        'var settings = {',
        '  "options": ["option1", "option2"]  // Array of selected values',
        '};',
        '',
        'var settingsHints = {',
        '  "options": {',
        '    "type": "multiselect",',
        '    "label": "Choose Options",',
        '    "help": "Select one or more options",',
        '    "options": [',
        '      {"value": "option1", "label": "Option 1"},',
        '      {"value": "option2", "label": "Option 2"},',
        '      {"value": "option3", "label": "Option 3"}',
        '    ],',
        '    "min_selections": 1,',
        '    "max_selections": 3',
        '  }',
        '};',
        '',
        'EXAMPLE COLOR SETTING:',
        'var settings = {',
        '  "background_color": "#3498db",',
        '  "event_date": "2024-01-01",',
        '  "event_time": "09:00",',
        '  "range": {"start": 20, "end": 80}',
        '};',
        '',
        'var settingsHints = {',
        '  "background_color": {',
        '    "type": "color",',
        '    "label": "Background Color",',
        '    "help": "Choose the background color",',
        '    "alpha": true,',
        '    "presets": true',
        '  },',
        '  "event_date": {',
        '    "type": "date",',
        '    "label": "Event Date",',
        '    "help": "Choose event date",',
        '    "min_date": "2024-01-01",',
        '    "max_date": "2030-12-31"',
        '  },',
        '  "event_time": {',
        '    "type": "time",',
        '    "label": "Event Time",',
        '    "help": "Choose event time",',
        '    "format": "24h"',
        '  },',
        '  "range": {',
        '    "type": "range",',
        '    "label": "Value Range",',
        '    "min": 0,',
        '    "max": 100,',
        '    "default_start": 20,',
        '    "default_end": 80',
        '  }',
        '};',
        '',
        'OUTPUT REQUIREMENTS:',
        '- Use only standard ASCII characters - avoid Unicode symbols like →, ‑, etc.',
        '- Generate ONLY the JavaScript code, no template comments or headers',
        '- Wrap the output in a JavaScript markdown code block',
        '- Do NOT include "JS TOOL TEMPLATE" or similar comments',
        '- Use clean, functional code without unnecessary variables',
        '- For image/visual output, use appropriate code block markers',
        '',
        'Generate ONLY valid JavaScript code following this EXACT pattern.',
        'Do NOT invent new framework elements or deviate from the structure.',
        'Consider whether the tool needs user text input to determine allowEmptyInput value.',
      ],
    );
  }

  String _buildDartPrompt(
    String category,
    String toolType,
    bool includeExport,
    bool addComments,
  ) {
    return AIService.buildSystemPrompt(
      role: 'an expert Dart/Flutter developer and tool creator',
      context:
          'You create tools for a text processing application using a specific framework',
      instructions: [
        'Generate a complete Dart tool following the exact framework structure',
        'Tool category: $category',
        'Tool type: ${toolType == 'ai' ? 'AI Tool (extends BaseAITool)' : 'Regular Tool (extends Tool)'}',
        if (addComments)
          'Include helpful code comments explaining functionality',
        if (includeExport) 'Include the export function at the end',
        '',
        'EXACT FRAMEWORK STRUCTURE TO FOLLOW:',
        '',
        'REGULAR TOOL TEMPLATE:',
        'class [Name]Tool extends Tool {',
        '  [Name]Tool() : super(',
        '    name: \'Tool Name\',',
        '    description: \'Description\',',
        '    icon: Icons.icon_name,',
        '    allowEmptyInput: false,',
        '    settings: {',
        '      \'setting1\': defaultValue1,',
        '      \'setting2\': defaultValue2,',
        '    },',
        '    settingsHints: {',
        '      \'setting1\': {\'type\': \'bool\', \'label\': \'Label\', \'help\': \'Help text\'},',
        '    },',
        '  );',
        '',
        '  @override',
        '  Future<ToolResult> execute(String input) async {',
        '    // Access settings with: settings[\'setting_name\']',
        '    // Process input here',
        '    return ToolResult(output: result, status: \'success\');',
        '  }',
        '}',
        '',
        'AI TOOL TEMPLATE:',
        'class [Name]Tool extends BaseAITool {',
        '  [Name]Tool({required super.aiConfig, Map<String, dynamic>? settings}) : super(',
        '    settings: settings ?? { /* defaults */ },',
        '    name: \'AI Tool Name\',',
        '    description: \'Description\',',
        '    icon: Icons.icon_name,',
        '    allowEmptyInput: false,',
        '    settingsHints: { /* hints */ },',
        '  );',
        '',
        '  @override',
        '  String buildAISystemPrompt(String input) {',
        '    return AIService.buildSystemPrompt(',
        '      role: \'assistant role\',',
        '      context: \'context\',',
        '      instructions: [\'instruction1\', \'instruction2\'],',
        '    );',
        '  }',
        '',
        '  @override',
        '  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {',
        '    return [',
        '      ChatMessage(role: \'system\', content: systemPrompt),',
        '      ChatMessage(role: \'user\', content: input),',
        '    ];',
        '  }',
        '}',
        '',
        'NEW OUTPUT FORMATS SUPPORTED:',
        '- Tools can now return base64 image data directly',
        '- Use code blocks for visual output: ```svg, ```png, ```jpg, ```gif',
        '- Example SVG output: return ToolResult(output: "```svg\\n<svg>...</svg>\\n```", status: \'success\');',
        '- Example base64 PNG: return ToolResult(output: "```png\\ndata:image/png;base64,iVBORw0K...\\n```", status: \'success\');',
        '',
        'ALLOWEMPTYINPUT PROPERTY EXPLANATION:',
        '- Set allowEmptyInput: true for tools that don\'t need text input from user',
        '- This hides the multi-line input box and passes empty string as input',
        '- Perfect for: password generators, calculators, random generators, utilities, image generators',
        '- Set allowEmptyInput: false for tools that process user text input',
        '- Examples of allowEmptyInput: true: password generator, QR code generator, UUID generator, image creator',
        '- Examples of allowEmptyInput: false: text formatter, case converter, word counter',
        '',
        'ALL SETTING TYPES AVAILABLE:',
        '- bool: {\'type\': \'bool\', \'label\': \'Label\', \'help\': \'Help text\'}',
        '- text: {\'type\': \'text\', \'label\': \'Label\', \'help\': \'Help\', \'placeholder\': \'Enter...\'}',
        '- multiline: {\'type\': \'multiline\', \'label\': \'Label\', \'help\': \'Help\', \'placeholder\': \'Enter...\', \'rows\': 3}',
        '- number: {\'type\': \'number\', \'label\': \'Label\', \'min\': 0, \'max\': 100, \'decimal\': false}',
        '- spinner: {\'type\': \'spinner\', \'label\': \'Label\', \'min\': 0, \'max\': 100, \'step\': 1, \'decimal\': false, \'decimals\': 1}',
        '- slider: {\'type\': \'slider\', \'label\': \'Label\', \'min\': 0, \'max\': 100, \'divisions\': 10, \'show_range\': true}',
        '- dropdown: {\'type\': \'dropdown\', \'label\': \'Label\', \'options\': [\'opt1\', \'opt2\']}',
        '- multiselect: {\'type\': \'multiselect\', \'label\': \'Label\', \'options\': [\'opt1\', \'opt2\'], \'min_selections\': 1, \'max_selections\': 3}',
        '- color: {\'type\': \'color\', \'label\': \'Color\', \'help\': \'Pick a color\', \'alpha\': true, \'presets\': true}',
        '',
        'SETTING TYPE DETAILS:',
        '- spinner: Interactive number input with +/- buttons. Set \'decimal\': true for double values',
        '- slider: Visual slider control. Use \'divisions\' for stepped values, \'show_range\' to display min/max',
        '- multiselect: Allow selecting multiple options. Returns List<String> of selected values',
        '- color: Color picker. Returns hex color string. Set \'alpha\': true for opacity, \'presets\': false to hide preset colors',
        '- multiline: Multi-row text input. Set \'rows\' to control height',
        '- date: Date picker. Returns YYYY-MM-DD format. Set min_date/max_date for restrictions',
        '- time: Time picker. Returns HH:MM format. Set \'format\': \'24h\' or \'12h\'',
        '- range: Dual slider for min/max selection. Returns Map with \'start\' and \'end\' keys',
        '- file: File picker (Dart only). Returns file path. Set \'accept\' for extensions, \'multiple\' for multi-select',
        '',
        'CRITICAL: Only extend Tool or BaseAITool classes. No other base classes exist.',
        'CRITICAL: Access settings with settings[\'key_name\'] syntax.',
        'CRITICAL: Must return ToolResult(output: string, status: \'success\').',
        'CRITICAL: Set allowEmptyInput appropriately based on whether tool needs text input.',
        'CRITICAL: For multiselect settings, default value should be a List<String>',
        'CRITICAL: For color settings, default value should be a hex color string like \'#3498db\'',
        '',
        if (includeExport) ...[
          'EXPORT FUNCTION TEMPLATE (if requested):',
          'Map<String, List<Tool Function()>> get[Category]Tools() {',
          '  return {',
          '    \'Category Name\': [() => ToolNameTool()],',
          '  };',
          '}',
          '',
        ],
        'EXAMPLE COMPLETE REGULAR TOOL (Text Processing):',
        'class ExampleTool extends Tool {',
        '  ExampleTool() : super(',
        '    name: \'Example\',',
        '    description: \'Example tool\',',
        '    icon: Icons.build,',
        '    allowEmptyInput: false, // Needs text input',
        '    settings: {\'enabled\': true},',
        '    settingsHints: {',
        '      \'enabled\': {\'type\': \'bool\', \'label\': \'Enable\', \'help\': \'Toggle feature\'}',
        '    },',
        '  );',
        '  @override',
        '  Future<ToolResult> execute(String input) async {',
        '    bool enabled = settings[\'enabled\'];',
        '    String result = enabled ? input.toUpperCase() : input;',
        '    return ToolResult(output: result, status: \'success\');',
        '  }',
        '}',
        '',
        'EXAMPLE TOOL WITH NEW CONTROLS:',
        'class AdvancedTool extends Tool {',
        '  AdvancedTool() : super(',
        '    name: \'Advanced Tool\',',
        '    description: \'Tool with various controls\',',
        '    icon: Icons.tune,',
        '    allowEmptyInput: false,',
        '    settings: {',
        '      \'count\': 5,',
        '      \'quality\': 0.8,',
        '      \'options\': [\'option1\', \'option2\'],',
        '      \'color\': \'#3498db\',',
        '      \'description\': \'Default text\',',
        '    },',
        '    settingsHints: {',
        '      \'count\': {\'type\': \'spinner\', \'label\': \'Count\', \'min\': 1, \'max\': 20, \'step\': 1},',
        '      \'quality\': {\'type\': \'slider\', \'label\': \'Quality\', \'min\': 0.0, \'max\': 1.0, \'divisions\': 10},',
        '      \'options\': {',
        '        \'type\': \'multiselect\',',
        '        \'label\': \'Options\',',
        '        \'options\': [\'option1\', \'option2\', \'option3\'],',
        '        \'min_selections\': 1,',
        '        \'max_selections\': 3',
        '      },',
        '      \'color\': {\'type\': \'color\', \'label\': \'Theme Color\', \'alpha\': true},',
        '      \'description\': {\'type\': \'multiline\', \'label\': \'Description\', \'rows\': 3},',
        '    },',
        '  );',
        '',
        '  @override',
        '  Future<ToolResult> execute(String input) async {',
        '    int count = settings[\'count\'];',
        '    double quality = settings[\'quality\'];',
        '    List<String> options = settings[\'options\'];',
        '    String color = settings[\'color\'];',
        '    String description = settings[\'description\'];',
        '    ',
        '    // Process using all settings',
        '    String result = processAdvanced(input, count, quality, options, color, description);',
        '    return ToolResult(output: result, status: \'success\');',
        '  }',
        '}',
        '',
        'EXAMPLE PASSWORD GENERATOR TOOL (No Input Needed):',
        'class PasswordGeneratorTool extends Tool {',
        '  PasswordGeneratorTool() : super(',
        '    name: \'Password Generator\',',
        '    description: \'Generate secure passwords\',',
        '    icon: Icons.security,',
        '    allowEmptyInput: true, // No text input needed',
        '    settings: {\'length\': 12, \'includeSymbols\': true},',
        '    settingsHints: {',
        '      \'length\': {\'type\': \'spinner\', \'label\': \'Length\', \'min\': 4, \'max\': 64},',
        '      \'includeSymbols\': {\'type\': \'bool\', \'label\': \'Include Symbols\'}',
        '    },',
        '  );',
        '  @override',
        '  Future<ToolResult> execute(String input) async {',
        '    // input will be empty string - use settings only',
        '    int length = settings[\'length\'];',
        '    bool symbols = settings[\'includeSymbols\'];',
        '    String password = generatePassword(length, symbols);',
        '    return ToolResult(output: password, status: \'success\');',
        '  }',
        '}',
        '',
        'EXAMPLE IMAGE GENERATOR TOOL:',
        'class ImageGeneratorTool extends Tool {',
        '  ImageGeneratorTool() : super(',
        '    name: \'Simple Image Generator\',',
        '    description: \'Generate simple SVG images\',',
        '    icon: Icons.image,',
        '    allowEmptyInput: true, // No text input needed',
        '    settings: {',
        '      \'width\': 200,',
        '      \'height\': 200,',
        '      \'color\': \'#3498db\',',
        '    },',
        '    settingsHints: {',
        '      \'width\': {\'type\': \'spinner\', \'label\': \'Width\', \'min\': 50, \'max\': 800},',
        '      \'height\': {\'type\': \'spinner\', \'label\': \'Height\', \'min\': 50, \'max\': 800},',
        '      \'color\': {\'type\': \'color\', \'label\': \'Fill Color\'},',
        '    },',
        '  );',
        '',
        '  @override',
        '  Future<ToolResult> execute(String input) async {',
        '    int width = settings[\'width\'];',
        '    int height = settings[\'height\'];',
        '    String color = settings[\'color\'];',
        '    ',
        '    String svg = \'<svg width="\$width" height="\$height" xmlns="http://www.w3.org/2000/svg">\'',
        '        \'<rect width="\$width" height="\$height" fill="\$color"/>\'',
        '        \'</svg>\';',
        '    ',
        '    return ToolResult(output: \'```svg\\n\$svg\\n```\', status: \'success\');',
        '  }',
        '}',
        '',
        'Generate ONLY valid Dart code following these EXACT patterns.',
        'Do NOT invent new classes, methods, or framework elements.',
        'Consider whether the tool needs user text input to determine allowEmptyInput value.',
        'Use the appropriate setting types for the tool\'s functionality.',
      ],
    );
  }

  @override
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    final language = settings['language'] ?? 'dart';

    return [
      ChatMessage(role: 'system', content: systemPrompt),
      ChatMessage(
        role: 'user',
        content:
            'Create a ${language.toUpperCase()} tool with these requirements:\n\n$input\n\nGenerate the complete ${language.toUpperCase()} code following the framework structure. Consider whether this tool needs text input from the user to determine the allowEmptyInput property value. Use appropriate setting controls (spinner, slider, multiselect, color, etc.) based on the tool\'s functionality.',
      ),
    ];
  }
}

class TextEnhancementTool extends BaseAITool {
  TextEnhancementTool({Map<String, dynamic>? settings})
    : super(
        settings:
            settings ??
            {
              'fix_grammar': true,
              'adjust_tone': true,
              'tone_type': 'professional',
              'adjust_reading_level': false,
              'reading_level': 'grade_8',
              'preserve_formatting': true,
              'improve_clarity': true,
              'fix_punctuation': true,
            },
        name: 'Text Enhancement',
        description:
            'Fix grammar, adjust tone, and improve readability of your text',
        icon: Icons.edit_outlined,
        settingsHints: {
          'fix_grammar': {
            'type': 'bool',
            'label': 'Fix Grammar & Spelling',
            'help': 'Correct grammatical errors and spelling mistakes',
          },
          'adjust_tone': {
            'type': 'bool',
            'label': 'Adjust Tone',
            'help': 'Change the tone/style of the text',
          },
          'tone_type': {
            'type': 'dropdown',
            'label': 'Target Tone',
            'help': 'The desired tone for the output text',
            'options': [
              {'value': 'professional', 'label': 'Professional'},
              {'value': 'casual', 'label': 'Casual & Friendly'},
              {'value': 'formal', 'label': 'Formal & Academic'},
              {'value': 'conversational', 'label': 'Conversational'},
              {'value': 'persuasive', 'label': 'Persuasive'},
              {'value': 'empathetic', 'label': 'Empathetic & Warm'},
              {'value': 'confident', 'label': 'Confident & Assertive'},
              {'value': 'neutral', 'label': 'Neutral & Objective'},
            ],
          },
          'adjust_reading_level': {
            'type': 'bool',
            'label': 'Adjust Reading Level',
            'help': 'Simplify or adjust text complexity for target audience',
          },
          'reading_level': {
            'type': 'dropdown',
            'label': 'Target Reading Level',
            'help': 'The complexity level for the output text',
            'options': [
              {'value': 'grade_5', 'label': 'Grade 5 (Simple)'},
              {'value': 'grade_8', 'label': 'Grade 8 (Clear)'},
              {'value': 'grade_12', 'label': 'Grade 12 (Standard)'},
              {'value': 'college', 'label': 'College Level'},
              {'value': 'expert', 'label': 'Expert/Technical'},
            ],
          },
          'preserve_formatting': {
            'type': 'bool',
            'label': 'Preserve Original Formatting',
            'help': 'Keep the original structure, headings, and formatting',
          },
          'improve_clarity': {
            'type': 'bool',
            'label': 'Improve Clarity',
            'help': 'Make sentences clearer and more concise',
          },
          'fix_punctuation': {
            'type': 'bool',
            'label': 'Fix Punctuation',
            'help': 'Correct punctuation and formatting issues',
          },
        },
      );

  @override
  String buildAISystemPrompt(String input) {
    List<String> instructions = [];
    String role = 'a professional text editor and writing assistant';
    String context =
        'You help users improve their written content by fixing errors, adjusting tone, and enhancing readability.';

    // Grammar and spelling
    if (settings['fix_grammar'] == true) {
      instructions.add('Fix all grammar and spelling errors');
    }

    // Tone adjustment
    if (settings['adjust_tone'] == true) {
      String toneType = settings['tone_type'] ?? 'professional';
      Map<String, String> toneDescriptions = {
        'professional': 'professional, polished, and business-appropriate',
        'casual': 'casual, friendly, and approachable',
        'formal': 'formal, academic, and sophisticated',
        'conversational': 'conversational, natural, and engaging',
        'persuasive': 'persuasive, compelling, and influential',
        'empathetic': 'empathetic, warm, and understanding',
        'confident': 'confident, assertive, and authoritative',
        'neutral': 'neutral, objective, and unbiased',
      };
      instructions.add(
        'Adjust the tone to be ${toneDescriptions[toneType] ?? 'professional'}',
      );
    }

    // Reading level
    if (settings['adjust_reading_level'] == true) {
      String readingLevel = settings['reading_level'] ?? 'grade_8';
      Map<String, String> levelDescriptions = {
        'grade_5':
            'very simple language suitable for 5th grade reading level (use short sentences, common words)',
        'grade_8':
            'clear, accessible language suitable for 8th grade reading level',
        'grade_12': 'standard complexity suitable for high school level',
        'college':
            'sophisticated language suitable for college-educated audience',
        'expert':
            'technical, expert-level language with specialized terminology',
      };
      instructions.add(
        'Adjust the complexity to ${levelDescriptions[readingLevel]}',
      );
    }

    // Clarity improvement
    if (settings['improve_clarity'] == true) {
      instructions.add(
        'Improve clarity by simplifying complex sentences, removing redundancy, and enhancing flow',
      );
    }

    // Punctuation
    if (settings['fix_punctuation'] == true) {
      instructions.add(
        'Correct all punctuation, capitalization, and formatting issues',
      );
    }

    // Formatting preservation
    if (settings['preserve_formatting'] == true) {
      instructions.add(
        'Preserve the original document structure, including headings, bullet points, and paragraph breaks',
      );
      instructions.add('Maintain any markdown formatting present in the input');
    }

    // General guidelines
    instructions.addAll([
      'Keep the core message and meaning intact',
      'Only make necessary changes - don\'t over-edit',
      'If the input is already well-written, make minimal improvements',
      'Return the improved text in markdown format',
      'Do not add explanations or comments about the changes made',
    ]);

    return AIService.buildSystemPrompt(
      role: role,
      context: context,
      instructions: instructions,
    );
  }

  @override
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    return [
      ChatMessage(role: 'system', content: systemPrompt),
      ChatMessage(role: 'user', content: 'Please enhance this text:\n\n$input'),
    ];
  }
}

// ignore: constant_identifier_names
const Map<String, String> PROGRAMMING_LANGUAGES = {
  'gdscript': 'GDScript',
  'cpp': 'C++',
  'javascript': 'JavaScript',
  'python': 'Python',
  'dart': 'Dart',
  'java': 'Java',
  'csharp': 'C#',
  'typescript': 'TypeScript',
  'rust': 'Rust',
  'go': 'Go',
  'php': 'PHP',
  'ruby': 'Ruby',
  'swift': 'Swift',
  'kotlin': 'Kotlin',
  'scala': 'Scala',
  'lua': 'Lua',
  'custom': 'Custom Language...',
};

class CodeAnalysisTool extends BaseAITool {
  CodeAnalysisTool({Map<String, dynamic>? settings})
    : super(
        settings:
            settings ??
            {
              'language': 'auto',
              'custom_language': '',
              'review_code': true,
              'check_performance': true,
              'scan_security': true,
              'analyze_complexity': true,
              'analysis_depth': 'thorough',
              'explanation_level': 'intermediate',
              'include_examples': true,
              'focus_on_education': true,
              'show_severity_icons': true,
              'show_checkmarks': true,
              'show_pointing_hands': true,
              'highlight_changes': true,
            },
        name: 'Code Analysis Suite',
        description:
            'Comprehensive code analysis including review, performance, security, and complexity analysis with educational explanations',
        icon: Icons.bug_report_outlined,
        settingsHints: {
          'language': {
            'type': 'dropdown',
            'label': 'Programming Language',
            'help': 'Select the programming language or use auto-detection',
            'options': [
              {'value': 'auto', 'label': '🔍 Auto-Detect'},
              ...PROGRAMMING_LANGUAGES.entries.map(
                (e) => {'value': e.key, 'label': e.value},
              ),
            ],
          },
          'custom_language': {
            'type': 'text',
            'label': 'Custom Language',
            'help':
                'Specify custom language name (only used when "Custom Language..." is selected)',
            'placeholder': 'e.g., Assembly, COBOL, etc.',
          },
          'review_code': {
            'type': 'bool',
            'label': 'Code Review',
            'help':
                'Review code for bugs, best practices, and code quality issues',
          },
          'check_performance': {
            'type': 'bool',
            'label': 'Performance Analysis',
            'help':
                'Analyze code for performance bottlenecks and optimization opportunities',
          },
          'scan_security': {
            'type': 'bool',
            'label': 'Security Scan',
            'help':
                'Identify potential security vulnerabilities and unsafe practices',
          },
          'analyze_complexity': {
            'type': 'bool',
            'label': 'Complexity Analysis',
            'help': 'Analyze code complexity and suggest simplifications',
          },
          'analysis_depth': {
            'type': 'dropdown',
            'label': 'Analysis Depth',
            'help': 'How thorough should the analysis be',
            'options': [
              {'value': 'quick', 'label': 'Quick Overview'},
              {'value': 'standard', 'label': 'Standard Analysis'},
              {'value': 'thorough', 'label': 'Thorough Deep-Dive'},
            ],
          },
          'explanation_level': {
            'type': 'dropdown',
            'label': 'Explanation Level',
            'help': 'Technical level of explanations provided',
            'options': [
              {'value': 'beginner', 'label': 'Beginner (Simple explanations)'},
              {'value': 'intermediate', 'label': 'Intermediate (Balanced)'},
              {'value': 'expert', 'label': 'Expert (Technical details)'},
            ],
          },
          'include_examples': {
            'type': 'bool',
            'label': 'Include Examples',
            'help': 'Provide code examples showing improvements and fixes',
          },
          'focus_on_education': {
            'type': 'bool',
            'label': 'Educational Focus',
            'help':
                'Emphasize learning and understanding rather than just listing issues',
          },
          'show_severity_icons': {
            'type': 'bool',
            'label': 'Show Severity Icons',
            'help':
                'Add colored emoji icons to indicate issue severity (🔴 Critical, 🟡 Warning, 🔵 Info)',
          },
          'show_checkmarks': {
            'type': 'bool',
            'label': 'Show Fixed Version Checkmarks',
            'help':
                'Add ✅ checkmarks to highlight improved/fixed code sections',
          },
          'show_pointing_hands': {
            'type': 'bool',
            'label': 'Show Change Indicators',
            'help':
                'Add 👉 or  👈 pointing hands to highlight issues in code block as inline comment emoji.',
          },
          'highlight_changes': {
            'type': 'bool',
            'label': 'Highlight Code Changes',
            'help': 'Use formatting to emphasize before/after code differences',
          },
        },
      );

  @override
  String buildAISystemPrompt(String input) {
    // Auto-detect language if set to 'auto'
    String language = settings['language'] ?? 'auto';
    String actualLanguage;

    if (language == 'auto') {
      // Simple language detection based on code patterns
      actualLanguage = detectLanguage(input);
    } else if (language == 'custom') {
      actualLanguage = settings['custom_language'] ?? 'Unknown Language';
    } else {
      actualLanguage = PROGRAMMING_LANGUAGES[language] ?? 'Unknown Language';
    }

    List<String> analysisTypes = [];
    if (settings['review_code'] == true) analysisTypes.add('code review');
    if (settings['check_performance'] == true) {
      analysisTypes.add('performance analysis');
    }
    if (settings['scan_security'] == true) {
      analysisTypes.add('security scanning');
    }
    if (settings['analyze_complexity'] == true) {
      analysisTypes.add('complexity analysis');
    }

    String analysisDepth = settings['analysis_depth'] ?? 'thorough';
    String explanationLevel = settings['explanation_level'] ?? 'intermediate';
    bool includeExamples = settings['include_examples'] ?? true;
    bool focusOnEducation = settings['focus_on_education'] ?? true;
    bool showSeverityIcons = settings['show_severity_icons'] ?? true;
    bool showCheckmarks = settings['show_checkmarks'] ?? true;
    bool showPointingHands = settings['show_pointing_hands'] ?? true;
    bool highlightChanges = settings['highlight_changes'] ?? true;

    List<String> instructions = [
      'You are analyzing $actualLanguage code',
      'Perform the following types of analysis: ${analysisTypes.join(", ")}',
    ];

    // Analysis depth instructions
    switch (analysisDepth) {
      case 'quick':
        instructions.add(
          'Provide a quick overview focusing on the most critical issues',
        );
        break;
      case 'standard':
        instructions.add(
          'Provide standard analysis covering main issues and improvements',
        );
        break;
      case 'thorough':
        instructions.add(
          'Perform thorough analysis covering all aspects in detail',
        );
        break;
    }

    // Explanation level instructions
    switch (explanationLevel) {
      case 'beginner':
        instructions.add(
          'Use simple, beginner-friendly explanations avoiding technical jargon',
        );
        break;
      case 'intermediate':
        instructions.add(
          'Provide balanced explanations suitable for developers with some experience',
        );
        break;
      case 'expert':
        instructions.add(
          'Use technical terminology and provide detailed technical explanations',
        );
        break;
    }

    // Analysis-specific instructions
    if (settings['review_code'] == true) {
      instructions.addAll([
        'Review code for bugs, logic errors, and potential runtime issues',
        'Check adherence to $actualLanguage best practices and conventions',
        'Identify code quality issues and maintainability concerns',
      ]);
    }

    if (settings['check_performance'] == true) {
      instructions.addAll([
        'Identify performance bottlenecks and inefficient algorithms',
        'Suggest optimization opportunities specific to $actualLanguage',
        'Analyze time and space complexity where relevant',
      ]);
    }

    if (settings['scan_security'] == true) {
      instructions.addAll([
        'Identify potential security vulnerabilities',
        'Check for unsafe practices and input validation issues',
        'Highlight areas that could lead to security breaches',
      ]);
    }

    if (settings['analyze_complexity'] == true) {
      instructions.addAll([
        'Analyze code complexity and readability',
        'Suggest ways to simplify overly complex code',
        'Identify areas that could benefit from refactoring',
      ]);
    }

    // Output format instructions
    instructions.addAll([
      'Structure your response with clear sections for each analysis type',
      'Use markdown formatting for better readability',
      'Prioritize issues from most critical to least critical',
    ]);

    // Emoji and formatting options
    if (showSeverityIcons) {
      instructions.addAll([
        'Use severity icons: 🔴 for Critical issues, 🟡 for Warnings, 🔵 for Info/Suggestions',
        'Place the appropriate severity icon before each issue heading',
      ]);
    }

    if (showCheckmarks && includeExamples) {
      instructions.add(
        'Add ✅ checkmarks before improved/fixed code examples to highlight the corrected version',
      );
    }

    if (showPointingHands) {
      instructions.add(
        'Use 👉 pointing hand emoji to highlight specific lines or sections where changes were made',
      );
    }

    if (highlightChanges && includeExamples) {
      instructions.addAll([
        'When showing before/after code examples, clearly label them as "❌ Problematic Code:" and "✅ Improved Code:"',
        'Use code highlighting to emphasize the differences between original and improved versions',
      ]);
    }

    if (includeExamples) {
      instructions.add(
        'Provide code examples showing how to fix or improve identified issues',
      );
    }

    if (focusOnEducation) {
      instructions.addAll([
        'Focus on educational value - explain WHY something is an issue, not just WHAT the issue is',
        'Help the developer learn and understand the underlying principles',
        'Provide context about why certain practices are recommended',
      ]);
    }

    instructions.addAll([
      'If no issues are found in a category, briefly mention that the code looks good in that area',
      'Be constructive and encouraging in your feedback',
      'Do not modify or rewrite the original code - only analyze and suggest',
    ]);

    return AIService.buildSystemPrompt(
      role:
          'an expert code analyst and educator specializing in $actualLanguage',
      context:
          'You help developers improve their code through comprehensive analysis and educational explanations. You focus on teaching principles rather than just pointing out issues.',
      instructions: instructions,
    );
  }

  @override
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    return [
      ChatMessage(role: 'system', content: systemPrompt),
      ChatMessage(
        role: 'user',
        content: 'Please analyze this code:\n\n```\n$input\n```',
      ),
    ];
  }

  // Simple language detection helper
  String detectLanguage(String code) {
    code = code.toLowerCase();

    // Check for distinctive patterns
    if (code.contains('extends ') && code.contains('func ')) return 'GDScript';
    if (code.contains('#include') || code.contains('std::')) return 'C++';
    if (code.contains('function ') ||
        code.contains('const ') ||
        code.contains('let ')) {
      return 'JavaScript';
    }
    if (code.contains('def ') && code.contains(':')) return 'Python';
    if (code.contains('class ') &&
        code.contains('{') &&
        code.contains('void ')) {
      return 'Java';
    }
    if (code.contains('public class ') || code.contains('using system')) {
      return 'C#';
    }
    if (code.contains('interface ') && code.contains(': ')) return 'TypeScript';
    if (code.contains('fn ') && code.contains('->')) return 'Rust';
    if (code.contains('func ') && code.contains('package ')) return 'Go';
    if (code.contains('<?php')) return 'PHP';
    if (code.contains('end') && code.contains('do')) return 'Lua';

    // Default fallback
    return 'Unknown (Auto-detection failed - please select manually)';
  }
}

class FunctionGeneratorTool extends BaseAITool {
  FunctionGeneratorTool({Map<String, dynamic>? settings})
    : super(
        settings:
            settings ??
            {
              'language': 'gdscript',
              'custom_language': '',
              'generation_type': 'function',
              'include_comments': true,
              'include_type_hints': true,
              'include_examples': true,
              'coding_style': 'standard',
              'error_handling': true,
            },
        name: 'Function/Class Generator',
        description:
            'Generate functions, classes, or code snippets from natural language descriptions',
        icon: Icons.auto_fix_high_outlined,
        settingsHints: {
          'language': {
            'type': 'dropdown',
            'label': 'Programming Language',
            'help': 'Target programming language for code generation',
            'options': [
              {'value': 'gdscript', 'label': 'GDScript'},
              {'value': 'cpp', 'label': 'C++'},
              {'value': 'javascript', 'label': 'JavaScript'},
              {'value': 'python', 'label': 'Python'},
              {'value': 'dart', 'label': 'Dart'},
              {'value': 'java', 'label': 'Java'},
              {'value': 'csharp', 'label': 'C#'},
              {'value': 'custom', 'label': 'Custom Language...'},
            ],
          },
          'custom_language': {
            'type': 'text',
            'label': 'Custom Language',
            'help': 'Specify custom language name',
            'placeholder': 'e.g., Rust, Go, etc.',
          },
          'generation_type': {
            'type': 'dropdown',
            'label': 'Generation Type',
            'help': 'What type of code to generate',
            'options': [
              {'value': 'function', 'label': 'Function/Method'},
              {'value': 'class', 'label': 'Class/Object'},
              {'value': 'snippet', 'label': 'Code Snippet'},
              {'value': 'module', 'label': 'Module/Package'},
            ],
          },
          'include_comments': {
            'type': 'bool',
            'label': 'Include Comments',
            'help': 'Add explanatory comments to generated code',
          },
          'include_type_hints': {
            'type': 'bool',
            'label': 'Include Type Hints',
            'help': 'Add type annotations where applicable',
          },
          'include_examples': {
            'type': 'bool',
            'label': 'Include Usage Examples',
            'help': 'Show how to use the generated code',
          },
          'coding_style': {
            'type': 'dropdown',
            'label': 'Coding Style',
            'help': 'Code formatting and style preferences',
            'options': [
              {'value': 'standard', 'label': 'Standard/Clean'},
              {'value': 'verbose', 'label': 'Verbose/Detailed'},
              {'value': 'minimal', 'label': 'Minimal/Compact'},
            ],
          },
          'error_handling': {
            'type': 'bool',
            'label': 'Include Error Handling',
            'help': 'Add proper error checking and exception handling',
          },
        },
      );

  @override
  String buildAISystemPrompt(String input) {
    String language = settings['language'] == 'custom'
        ? (settings['custom_language'] ?? 'Unknown')
        : (PROGRAMMING_LANGUAGES[settings['language']] ?? 'GDScript');

    String generationType = settings['generation_type'] ?? 'function';
    bool includeComments = settings['include_comments'] ?? true;
    bool includeTypeHints = settings['include_type_hints'] ?? true;
    bool includeExamples = settings['include_examples'] ?? true;
    String codingStyle = settings['coding_style'] ?? 'standard';
    bool errorHandling = settings['error_handling'] ?? true;

    List<String> instructions = [
      'Generate clean, functional $language code based on the user\'s description',
      'Focus on creating ${generationType == 'function'
          ? 'functions or methods'
          : generationType == 'class'
          ? 'classes with appropriate methods and properties'
          : generationType == 'snippet'
          ? 'code snippets'
          : 'modules or packages'}',
    ];

    if (includeComments) {
      instructions.add(
        'Include clear, helpful comments explaining the code\'s purpose and functionality',
      );
    }

    if (includeTypeHints &&
        [
          'python',
          'dart',
          'typescript',
          'java',
          'csharp',
          'cpp',
        ].contains(settings['language'])) {
      instructions.add(
        'Include proper type hints and annotations where supported by $language',
      );
    }

    if (errorHandling) {
      instructions.add(
        'Include appropriate error handling and input validation',
      );
    }

    switch (codingStyle) {
      case 'verbose':
        instructions.add(
          'Use verbose, well-documented code with detailed explanations',
        );
        break;
      case 'minimal':
        instructions.add(
          'Keep code concise and minimal while maintaining readability',
        );
        break;
      default:
        instructions.add('Use clean, standard coding practices and formatting');
    }

    if (includeExamples) {
      instructions.add(
        'Provide usage examples showing how to call/use the generated code',
      );
    }

    instructions.addAll([
      'Follow $language naming conventions and best practices',
      'Ensure code is production-ready and follows language-specific patterns',
      'Use proper syntax highlighting in code blocks',
    ]);

    return AIService.buildSystemPrompt(
      role: 'an expert $language developer and code generator',
      context:
          'You create clean, functional code from natural language descriptions, following best practices and conventions.',
      instructions: instructions,
    );
  }

  @override
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    return [
      ChatMessage(role: 'system', content: systemPrompt),
      ChatMessage(role: 'user', content: 'Generate code for: $input'),
    ];
  }
}

class CodeConverterTool extends BaseAITool {
  CodeConverterTool({Map<String, dynamic>? settings})
    : super(
        settings:
            settings ??
            {
              'source_language': 'auto',
              'target_language': 'gdscript',
              'custom_source': '',
              'custom_target': '',
              'conversion_style': 'idiomatic',
              'include_comments': true,
              'explain_changes': true,
              'preserve_logic': true,
              'add_notes': true,
            },
        name: 'Code Converter',
        description:
            'Convert code between different programming languages while preserving functionality',
        icon: Icons.transform_outlined,
        settingsHints: {
          'source_language': {
            'type': 'dropdown',
            'label': 'Source Language',
            'help': 'Programming language to convert from',
            'options': [
              {'value': 'auto', 'label': '🔍 Auto-Detect'},
              ...PROGRAMMING_LANGUAGES.entries.map(
                (e) => {'value': e.key, 'label': e.value},
              ),
            ],
          },
          'target_language': {
            'type': 'dropdown',
            'label': 'Target Language',
            'help': 'Programming language to convert to',
            'options': PROGRAMMING_LANGUAGES.entries
                .map((e) => {'value': e.key, 'label': e.value})
                .toList(),
          },
          'custom_source': {
            'type': 'text',
            'label': 'Custom Source Language',
            'placeholder': 'e.g., Assembly, COBOL, etc.',
          },
          'custom_target': {
            'type': 'text',
            'label': 'Custom Target Language',
            'placeholder': 'e.g., Rust, Go, etc.',
          },
          'conversion_style': {
            'type': 'dropdown',
            'label': 'Conversion Style',
            'help': 'How to adapt code to target language',
            'options': [
              {'value': 'direct', 'label': 'Direct Translation'},
              {'value': 'idiomatic', 'label': 'Idiomatic (Language-specific)'},
              {'value': 'modern', 'label': 'Modern Best Practices'},
            ],
          },
          'include_comments': {
            'type': 'bool',
            'label': 'Include Comments',
            'help': 'Add explanatory comments to converted code',
          },
          'explain_changes': {
            'type': 'bool',
            'label': 'Explain Changes',
            'help': 'Explain what changed and why during conversion',
          },
          'preserve_logic': {
            'type': 'bool',
            'label': 'Preserve Original Logic',
            'help': 'Maintain exact same functionality and behavior',
          },
          'add_notes': {
            'type': 'bool',
            'label': 'Add Conversion Notes',
            'help':
                'Include notes about language differences and considerations',
          },
        },
      );

  @override
  String buildAISystemPrompt(String input) {
    String sourceLanguage = settings['source_language'] == 'auto'
        ? detectLanguage(input)
        : settings['source_language'] == 'custom'
        ? (settings['custom_source'] ?? 'Unknown')
        : (PROGRAMMING_LANGUAGES[settings['source_language']] ?? 'Unknown');

    String targetLanguage = settings['target_language'] == 'custom'
        ? (settings['custom_target'] ?? 'Unknown')
        : (PROGRAMMING_LANGUAGES[settings['target_language']] ?? 'GDScript');

    String conversionStyle = settings['conversion_style'] ?? 'idiomatic';
    bool includeComments = settings['include_comments'] ?? true;
    bool explainChanges = settings['explain_changes'] ?? true;
    bool preserveLogic = settings['preserve_logic'] ?? true;
    bool addNotes = settings['add_notes'] ?? true;

    List<String> instructions = [
      'Convert code from $sourceLanguage to $targetLanguage',
      'Maintain the exact same functionality and behavior as the original code',
    ];

    if (preserveLogic) {
      instructions.add(
        'Preserve all original logic, algorithms, and data structures',
      );
    }

    switch (conversionStyle) {
      case 'direct':
        instructions.add(
          'Perform direct translation with minimal changes to structure',
        );
        break;
      case 'idiomatic':
        instructions.add(
          'Adapt code to use $targetLanguage idioms, patterns, and best practices',
        );
        break;
      case 'modern':
        instructions.add(
          'Use modern $targetLanguage features and contemporary coding practices',
        );
        break;
    }

    if (includeComments) {
      instructions.add('Add helpful comments explaining the converted code');
    }

    if (explainChanges) {
      instructions.add(
        'Explain what changes were made during conversion and why they were necessary',
      );
    }

    if (addNotes) {
      instructions.add(
        'Include notes about important differences between the source and target languages',
      );
    }

    instructions.addAll([
      'Follow $targetLanguage naming conventions and syntax rules',
      'Handle language-specific features appropriately (memory management, types, etc.)',
      'Ensure the converted code will compile and run correctly',
      'Use proper syntax highlighting in code blocks',
    ]);

    return AIService.buildSystemPrompt(
      role:
          'an expert polyglot programmer specializing in code conversion between different languages',
      context:
          'You convert code between programming languages while preserving functionality and adapting to target language conventions.',
      instructions: instructions,
    );
  }

  @override
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    return [
      ChatMessage(role: 'system', content: systemPrompt),
      ChatMessage(
        role: 'user',
        content: 'Convert this code:\n\n```\n$input\n```',
      ),
    ];
  }

  // Simple language detection helper
  String detectLanguage(String code) {
    code = code.toLowerCase();
    if (code.contains('extends ') && code.contains('func ')) return 'GDScript';
    if (code.contains('#include') || code.contains('std::')) return 'C++';
    if (code.contains('function ') ||
        code.contains('const ') ||
        code.contains('let ')) {
      return 'JavaScript';
    }
    if (code.contains('def ') && code.contains(':')) return 'Python';
    if (code.contains('class ') &&
        code.contains('{') &&
        code.contains('void ')) {
      return 'Java';
    }
    if (code.contains('public class ') || code.contains('using system')) {
      return 'C#';
    }
    return 'Unknown (Auto-detection failed)';
  }
}

class RegexBuilderTool extends BaseAITool {
  RegexBuilderTool({Map<String, dynamic>? settings})
    : super(
        settings:
            settings ??
            {
              'regex_flavor': 'javascript',
              'include_explanation': true,
              'include_examples': true,
              'include_test_cases': true,
              'show_groups': true,
              'optimization_level': 'balanced',
              'case_sensitive': true,
            },
        name: 'Regex Builder',
        description:
            'Create regex patterns from natural language descriptions and explain existing patterns',
        icon: Icons.pattern_outlined,
        settingsHints: {
          'regex_flavor': {
            'type': 'dropdown',
            'label': 'Regex Flavor',
            'help': 'Choose regex engine/flavor for compatibility',
            'options': [
              {'value': 'javascript', 'label': 'JavaScript (ECMAScript)'},
              {'value': 'python', 'label': 'Python (re module)'},
              {'value': 'pcre', 'label': 'PCRE (PHP, etc.)'},
              {'value': 'java', 'label': 'Java'},
              {'value': 'dotnet', 'label': '.NET'},
              {'value': 'posix', 'label': 'POSIX'},
            ],
          },
          'include_explanation': {
            'type': 'bool',
            'label': 'Include Explanation',
            'help': 'Explain how the regex pattern works',
          },
          'include_examples': {
            'type': 'bool',
            'label': 'Include Examples',
            'help': 'Show example strings that match and don\'t match',
          },
          'include_test_cases': {
            'type': 'bool',
            'label': 'Include Test Cases',
            'help': 'Provide test strings to validate the pattern',
          },
          'show_groups': {
            'type': 'bool',
            'label': 'Show Capture Groups',
            'help': 'Explain capture groups and what they extract',
          },
          'optimization_level': {
            'type': 'dropdown',
            'label': 'Optimization Level',
            'help': 'Balance between readability and performance',
            'options': [
              {'value': 'readable', 'label': 'Readable (Clear structure)'},
              {'value': 'balanced', 'label': 'Balanced (Good mix)'},
              {'value': 'optimized', 'label': 'Optimized (Performance)'},
            ],
          },
          'case_sensitive': {
            'type': 'bool',
            'label': 'Case Sensitive by Default',
            'help': 'Whether patterns should be case-sensitive',
          },
        },
      );

  @override
  String buildAISystemPrompt(String input) {
    String regexFlavor = settings['regex_flavor'] ?? 'javascript';
    bool includeExplanation = settings['include_explanation'] ?? true;
    bool includeExamples = settings['include_examples'] ?? true;
    bool includeTestCases = settings['include_test_cases'] ?? true;
    bool showGroups = settings['show_groups'] ?? true;
    String optimizationLevel = settings['optimization_level'] ?? 'balanced';
    bool caseSensitive = settings['case_sensitive'] ?? true;

    List<String> instructions = [
      'You are an expert in regular expressions and pattern matching',
      'Create regex patterns compatible with $regexFlavor engine',
    ];

    // Determine if this is pattern creation or explanation
    if (input.contains(RegExp(r'[\[\](){}*+?|\\^$.]'))) {
      instructions.add(
        'The input appears to contain a regex pattern - explain how it works',
      );
    } else {
      instructions.add(
        'The input is a description - create a regex pattern that matches it',
      );
    }

    // Case sensitivity
    if (!caseSensitive) {
      instructions.add(
        'Make patterns case-insensitive by default (use appropriate flags)',
      );
    }

    // Optimization level
    switch (optimizationLevel) {
      case 'readable':
        instructions.addAll([
          'Prioritize readability and maintainability over performance',
          'Use clear, self-documenting patterns even if longer',
          'Break complex patterns into logical parts',
        ]);
        break;
      case 'optimized':
        instructions.addAll([
          'Optimize for performance and efficiency',
          'Use atomic groups and possessive quantifiers where beneficial',
          'Minimize backtracking and redundancy',
        ]);
        break;
      default: // balanced
        instructions.add(
          'Balance readability and performance in the regex pattern',
        );
    }

    if (includeExplanation) {
      instructions.addAll([
        'Provide clear explanations of how the regex pattern works',
        'Break down each part of the pattern and explain its purpose',
        'Use plain language to describe what each component matches',
      ]);
    }

    if (showGroups) {
      instructions.addAll([
        'Identify and explain any capture groups in the pattern',
        'Show what each group captures and how to access the captured text',
        'Distinguish between capturing and non-capturing groups',
      ]);
    }

    if (includeExamples) {
      instructions.addAll([
        'Provide example strings that WILL match the pattern',
        'Provide example strings that will NOT match the pattern',
        'Show edge cases and corner cases where applicable',
      ]);
    }

    if (includeTestCases) {
      instructions.add(
        'Include a set of test strings to validate the regex pattern works correctly',
      );
    }

    instructions.addAll([
      'Use proper markdown formatting with code blocks for regex patterns',
      'Highlight the regex pattern clearly and make it copy-pasteable',
      'Include any necessary flags or modifiers for the chosen flavor',
      'Be precise about regex syntax specific to $regexFlavor',
    ]);

    return AIService.buildSystemPrompt(
      role: 'a regex expert and pattern matching specialist',
      context:
          'You help users create, understand, and optimize regular expression patterns for various use cases and regex engines.',
      instructions: instructions,
    );
  }

  @override
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    // Detect if input is a regex pattern or description
    bool isRegexPattern = input.contains(RegExp(r'[\[\](){}*+?|\\^$.]'));

    String prompt = isRegexPattern
        ? 'Explain this regex pattern:\n\n`$input`'
        : 'Create a regex pattern for: $input';

    return [
      ChatMessage(role: 'system', content: systemPrompt),
      ChatMessage(role: 'user', content: prompt),
    ];
  }
}

class ChartGeneratorTool extends BaseAITool {
  ChartGeneratorTool({Map<String, dynamic>? settings})
    : super(
        settings:
            settings ??
            {
              'chart_type': 'bar',
              'color_scheme': 'modern',
              'include_title': true,
              'include_labels': true,
              'include_legend': true,
              'include_grid': true,
              'chart_width': 800,
              'chart_height': 400,
              'animation_friendly': false,
              'responsive': true,
              'data_source': 'text',
              'style_theme': 'clean',
            },
        name: 'Chart Generator',
        description:
            'Generate beautiful SVG charts from data descriptions or raw data',
        icon: Icons.bar_chart_outlined,
        settingsHints: {
          'chart_type': {
            'type': 'dropdown',
            'label': 'Chart Type',
            'help': 'Type of chart to generate',
            'options': [
              {'value': 'bar', 'label': '📊 Bar Chart'},
              {'value': 'line', 'label': '📈 Line Chart'},
              {'value': 'pie', 'label': '🥧 Pie Chart'},
              {'value': 'scatter', 'label': '⚪ Scatter Plot'},
              {'value': 'area', 'label': '📉 Area Chart'},
              {'value': 'donut', 'label': '🍩 Donut Chart'},
              {'value': 'histogram', 'label': '📊 Histogram'},
              {'value': 'radar', 'label': '🕸️ Radar Chart'},
            ],
          },
          'color_scheme': {
            'type': 'dropdown',
            'label': 'Color Scheme',
            'help': 'Color palette for the chart',
            'options': [
              {'value': 'modern', 'label': 'Modern Blues'},
              {'value': 'vibrant', 'label': 'Vibrant Colors'},
              {'value': 'pastel', 'label': 'Soft Pastels'},
              {'value': 'professional', 'label': 'Professional'},
              {'value': 'monochrome', 'label': 'Monochrome'},
              {'value': 'gradient', 'label': 'Gradient'},
              {'value': 'custom', 'label': 'Auto-select'},
            ],
          },
          'include_title': {
            'type': 'bool',
            'label': 'Include Title',
            'help': 'Add a title to the chart',
          },
          'include_labels': {
            'type': 'bool',
            'label': 'Include Data Labels',
            'help': 'Show values on chart elements',
          },
          'include_legend': {
            'type': 'bool',
            'label': 'Include Legend',
            'help': 'Add legend to explain chart elements',
          },
          'include_grid': {
            'type': 'bool',
            'label': 'Include Grid Lines',
            'help': 'Add grid lines for easier reading',
          },
          'chart_width': {
            'type': 'spinner',
            'label': 'Chart Width (px)',
            'help': 'Width of the generated chart',
            'min': 300,
            'max': 1200,
            'step': 50,
          },
          'chart_height': {
            'type': 'spinner',
            'label': 'Chart Height (px)',
            'help': 'Height of the generated chart',
            'min': 200,
            'max': 800,
            'step': 50,
          },
          'animation_friendly': {
            'type': 'bool',
            'label': 'Animation Ready',
            'help': 'Generate SVG optimized for animations',
          },
          'responsive': {
            'type': 'bool',
            'label': 'Responsive Design',
            'help': 'Make chart responsive to container size',
          },
          'data_source': {
            'type': 'dropdown',
            'label': 'Data Input Type',
            'help': 'How data is provided in the input',
            'options': [
              {'value': 'text', 'label': 'Text Description'},
              {'value': 'csv', 'label': 'CSV Data'},
              {'value': 'json', 'label': 'JSON Data'},
              {'value': 'mixed', 'label': 'Mixed/Auto-detect'},
            ],
          },
          'style_theme': {
            'type': 'dropdown',
            'label': 'Style Theme',
            'help': 'Overall visual style of the chart',
            'options': [
              {'value': 'clean', 'label': 'Clean & Minimal'},
              {'value': 'modern', 'label': 'Modern & Sleek'},
              {'value': 'classic', 'label': 'Classic & Traditional'},
              {'value': 'bold', 'label': 'Bold & Striking'},
            ],
          },
        },
      );

  @override
  String buildAISystemPrompt(String input) {
    String chartType = settings['chart_type'] ?? 'bar';
    String colorScheme = settings['color_scheme'] ?? 'modern';
    bool includeTitle = settings['include_title'] ?? true;
    bool includeLabels = settings['include_labels'] ?? true;
    bool includeLegend = settings['include_legend'] ?? true;
    bool includeGrid = settings['include_grid'] ?? true;
    int chartWidth = settings['chart_width'] ?? 800;
    int chartHeight = settings['chart_height'] ?? 400;
    bool animationFriendly = settings['animation_friendly'] ?? false;
    bool responsive = settings['responsive'] ?? true;
    String dataSource = settings['data_source'] ?? 'text';
    String styleTheme = settings['style_theme'] ?? 'clean';

    List<String> instructions = [
      'You are an expert data visualization specialist who creates beautiful SVG charts',
      'Generate a $chartType chart in SVG format from the provided data',
      'The chart should be ${chartWidth}x$chartHeight pixels in size',
    ];

    // Chart-specific instructions
    Map<String, String> chartInstructions = {
      'bar':
          'Create vertical or horizontal bars with proper spacing and proportions',
      'line': 'Create smooth line connections between data points with markers',
      'pie': 'Create circular segments with proper angles and labels',
      'scatter': 'Create individual points with optional trend lines',
      'area': 'Create filled areas under line charts with gradients',
      'donut': 'Create a pie chart with a hollow center',
      'histogram': 'Create bars representing frequency distribution',
      'radar': 'Create a spider/radar chart with multiple axes',
    };
    instructions.add(
      chartInstructions[chartType] ?? 'Create the requested chart type',
    );

    // Color scheme instructions
    Map<String, String> colorInstructions = {
      'modern':
          'Use modern blue gradients and contemporary colors (#3B82F6, #1D4ED8, #60A5FA)',
      'vibrant':
          'Use bright, energetic colors (#EF4444, #F59E0B, #10B981, #8B5CF6)',
      'pastel': 'Use soft, muted colors (#FCA5A5, #FDE68A, #86EFAC, #A5B4FC)',
      'professional':
          'Use business-appropriate colors (#374151, #6B7280, #9CA3AF)',
      'monochrome':
          'Use shades of gray and black (#000000, #404040, #808080, #C0C0C0)',
      'gradient': 'Use gradient fills and colors that blend smoothly',
      'custom': 'Choose appropriate colors that match the data theme',
    };
    instructions.add(
      colorInstructions[colorScheme] ?? 'Use appropriate colors',
    );

    // Style theme instructions
    Map<String, String> styleInstructions = {
      'clean': 'Use minimal, clean design with thin lines and subtle colors',
      'modern':
          'Use contemporary design with rounded corners and smooth gradients',
      'classic':
          'Use traditional chart styling with serif fonts and formal appearance',
      'bold': 'Use thick lines, strong colors, and prominent visual elements',
    };
    instructions.add(styleInstructions[styleTheme] ?? 'Use clean styling');

    // Optional elements
    if (includeTitle) {
      instructions.add('Include a descriptive title at the top of the chart');
    }
    if (includeLabels) {
      instructions.add(
        'Add data value labels directly on or near chart elements',
      );
    }
    if (includeLegend) {
      instructions.add(
        'Include a legend explaining chart categories or series',
      );
    }
    if (includeGrid) {
      instructions.add('Add subtle grid lines to help read values');
    }

    // Technical requirements
    if (responsive) {
      instructions.add('Make the SVG responsive using viewBox attribute');
    }
    if (animationFriendly) {
      instructions.add(
        'Structure SVG elements to be animation-ready with proper IDs and classes',
      );
    }

    // Data handling based on input type
    switch (dataSource) {
      case 'csv':
        instructions.add(
          'Parse the CSV data and extract appropriate columns for the chart',
        );
        break;
      case 'json':
        instructions.add(
          'Parse the JSON data structure and use appropriate fields',
        );
        break;
      case 'text':
        instructions.add(
          'Extract data from the text description and infer appropriate values',
        );
        break;
      default:
        instructions.add(
          'Auto-detect the data format and extract relevant information',
        );
    }

    instructions.addAll([
      'Generate clean, valid SVG code that renders properly in browsers',
      'Use semantic SVG elements (rect, circle, path, text, etc.) appropriately',
      'Include proper accessibility features like titles and descriptions',
      'Ensure text is readable and appropriately sized',
      'Make sure the chart accurately represents the provided data',
      'Use consistent spacing, alignment, and proportions',
      'IMPORTANT: Output ONLY the SVG code wrapped in ```svg code blocks',
      'Do not include explanations or additional text outside the SVG',
    ]);

    return AIService.buildSystemPrompt(
      role: 'a professional data visualization expert and SVG chart specialist',
      context:
          'You create beautiful, accurate charts in SVG format from various data inputs, focusing on clarity, aesthetics, and proper data representation.',
      instructions: instructions,
    );
  }

  @override
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    return [
      ChatMessage(role: 'system', content: systemPrompt),
      ChatMessage(
        role: 'user',
        content: 'Create a chart from this data:\n\n$input',
      ),
    ];
  }
}

class UIDesignTool extends BaseAITool {
  UIDesignTool({Map<String, dynamic>? settings})
    : super(
        settings:
            settings ??
            {
              'design_type': 'mockup',
              'device_type': 'desktop',
              'design_style': 'modern',
              'color_scheme': 'neutral',
              'include_placeholder_text': true,
              'include_icons': true,
              'fidelity_level': 'medium',
              'canvas_width': 800,
              'canvas_height': 600,
              'responsive_layout': true,
              'include_annotations': false,
              'icon_style': 'outline',
              'ui_framework': 'generic',
            },
        name: 'UI Mockup & Icon Creator',
        description:
            'Generate UI wireframes, mockups, and custom icons in SVG format',
        icon: Icons.design_services_outlined,
        settingsHints: {
          'design_type': {
            'type': 'dropdown',
            'label': 'Design Type',
            'help': 'What type of design to create',
            'options': [
              {'value': 'mockup', 'label': '🖥️ UI Mockup'},
              {'value': 'wireframe', 'label': '📐 Wireframe'},
              {'value': 'icon', 'label': '🎨 Icon/Logo'},
              {'value': 'component', 'label': '🧩 UI Component'},
              {'value': 'layout', 'label': '📱 Layout Structure'},
            ],
          },
          'device_type': {
            'type': 'dropdown',
            'label': 'Device/Format',
            'help': 'Target device or format for the design',
            'options': [
              {'value': 'desktop', 'label': '🖥️ Desktop'},
              {'value': 'mobile', 'label': '📱 Mobile'},
              {'value': 'tablet', 'label': '📱 Tablet'},
              {'value': 'icon', 'label': '🎨 Icon (Square)'},
              {'value': 'banner', 'label': '🖼️ Banner/Header'},
              {'value': 'card', 'label': '🃏 Card Component'},
            ],
          },
          'design_style': {
            'type': 'dropdown',
            'label': 'Design Style',
            'help': 'Visual style and aesthetic',
            'options': [
              {'value': 'modern', 'label': 'Modern & Clean'},
              {'value': 'minimal', 'label': 'Minimal & Simple'},
              {'value': 'material', 'label': 'Material Design'},
              {'value': 'ios', 'label': 'iOS Style'},
              {'value': 'glassmorphism', 'label': 'Glassmorphism'},
              {'value': 'neumorphism', 'label': 'Neumorphism'},
              {'value': 'retro', 'label': 'Retro/Vintage'},
            ],
          },
          'color_scheme': {
            'type': 'dropdown',
            'label': 'Color Scheme',
            'help': 'Color palette for the design',
            'options': [
              {'value': 'neutral', 'label': 'Neutral Grays'},
              {'value': 'blue', 'label': 'Blue Theme'},
              {'value': 'green', 'label': 'Green Theme'},
              {'value': 'purple', 'label': 'Purple Theme'},
              {'value': 'orange', 'label': 'Orange Theme'},
              {'value': 'monochrome', 'label': 'Black & White'},
              {'value': 'colorful', 'label': 'Multi-color'},
              {'value': 'custom', 'label': 'Auto-select'},
            ],
          },
          'fidelity_level': {
            'type': 'dropdown',
            'label': 'Fidelity Level',
            'help': 'Level of detail and polish',
            'options': [
              {'value': 'low', 'label': 'Low (Basic shapes)'},
              {'value': 'medium', 'label': 'Medium (Some details)'},
              {'value': 'high', 'label': 'High (Detailed)'},
            ],
          },
          'canvas_width': {
            'type': 'spinner',
            'label': 'Canvas Width (px)',
            'help': 'Width of the design canvas',
            'min': 200,
            'max': 1400,
            'step': 50,
          },
          'canvas_height': {
            'type': 'spinner',
            'label': 'Canvas Height (px)',
            'help': 'Height of the design canvas',
            'min': 200,
            'max': 1000,
            'step': 50,
          },
          'include_placeholder_text': {
            'type': 'bool',
            'label': 'Include Placeholder Text',
            'help': 'Add realistic placeholder content',
          },
          'include_icons': {
            'type': 'bool',
            'label': 'Include Icons',
            'help': 'Add relevant icons to the design',
          },
          'responsive_layout': {
            'type': 'bool',
            'label': 'Responsive Layout',
            'help': 'Design with responsive principles',
          },
          'include_annotations': {
            'type': 'bool',
            'label': 'Include Annotations',
            'help': 'Add design notes and specifications',
          },
          'icon_style': {
            'type': 'dropdown',
            'label': 'Icon Style',
            'help': 'Style for icons in the design',
            'options': [
              {'value': 'outline', 'label': 'Outline'},
              {'value': 'filled', 'label': 'Filled'},
              {'value': 'duotone', 'label': 'Duotone'},
              {'value': 'minimal', 'label': 'Minimal'},
            ],
          },
          'ui_framework': {
            'type': 'dropdown',
            'label': 'UI Framework Style',
            'help': 'Design system or framework to emulate',
            'options': [
              {'value': 'generic', 'label': 'Generic/Custom'},
              {'value': 'bootstrap', 'label': 'Bootstrap'},
              {'value': 'tailwind', 'label': 'Tailwind CSS'},
              {'value': 'material', 'label': 'Material UI'},
              {'value': 'ant', 'label': 'Ant Design'},
              {'value': 'chakra', 'label': 'Chakra UI'},
            ],
          },
        },
      );

  @override
  String buildAISystemPrompt(String input) {
    String designType = settings['design_type'] ?? 'mockup';
    String deviceType = settings['device_type'] ?? 'desktop';
    String designStyle = settings['design_style'] ?? 'modern';
    String colorScheme = settings['color_scheme'] ?? 'neutral';
    String fidelityLevel = settings['fidelity_level'] ?? 'medium';
    int canvasWidth = settings['canvas_width'] ?? 800;
    int canvasHeight = settings['canvas_height'] ?? 600;
    bool includePlaceholderText = settings['include_placeholder_text'] ?? true;
    bool includeIcons = settings['include_icons'] ?? true;
    bool responsiveLayout = settings['responsive_layout'] ?? true;
    bool includeAnnotations = settings['include_annotations'] ?? false;
    String iconStyle = settings['icon_style'] ?? 'outline';
    String uiFramework = settings['ui_framework'] ?? 'generic';

    List<String> instructions = [
      'You are an expert UI/UX designer and icon artist who creates beautiful SVG designs',
      'Generate a $designType in SVG format based on the description',
      'Canvas size should be ${canvasWidth}x$canvasHeight pixels',
      'Target device/format: $deviceType',
    ];

    // Design type specific instructions
    Map<String, List<String>> typeInstructions = {
      'mockup': [
        'Create a realistic UI mockup with proper layouts, components, and visual hierarchy',
        'Include typical UI elements like headers, navigation, content areas, buttons',
        'Use realistic proportions and spacing between elements',
      ],
      'wireframe': [
        'Create a low-fidelity wireframe focusing on layout and structure',
        'Use simple shapes, boxes, and lines to represent UI elements',
        'Focus on information architecture rather than visual design',
      ],
      'icon': [
        'Create a clean, recognizable icon that represents the concept clearly',
        'Use simple, scalable shapes that work at different sizes',
        'Focus on clarity and instant recognition',
      ],
      'component': [
        'Design a reusable UI component (button, card, input, etc.)',
        'Include different states if relevant (hover, active, disabled)',
        'Make it modular and self-contained',
      ],
      'layout': [
        'Create a structural layout showing content organization',
        'Focus on grid systems, spacing, and responsive breakpoints',
        'Show how elements flow and adapt',
      ],
    };
    instructions.addAll(
      typeInstructions[designType] ?? typeInstructions['mockup']!,
    );

    // Device-specific adaptations
    Map<String, String> deviceInstructions = {
      'desktop': 'Design for desktop screens with mouse/keyboard interaction',
      'mobile':
          'Design for mobile with touch-friendly elements and vertical scrolling',
      'tablet': 'Design for tablet with touch interface and medium screen size',
      'icon': 'Create square format suitable for app icons or UI elements',
      'banner': 'Create wide horizontal format for headers or banners',
      'card': 'Create compact card component with contained information',
    };
    instructions.add(
      deviceInstructions[deviceType] ?? deviceInstructions['desktop']!,
    );

    // Design style instructions
    Map<String, List<String>> styleInstructions = {
      'modern': [
        'Clean lines, subtle shadows, contemporary colors',
        'Sans-serif typography, generous whitespace',
      ],
      'minimal': [
        'Extremely simple, lots of whitespace',
        'Limited color palette, focus on typography',
      ],
      'material': [
        'Google Material Design principles',
        'Elevation, cards, floating action buttons',
      ],
      'ios': [
        'Apple iOS design language',
        'Rounded corners, blur effects, system colors',
      ],
      'glassmorphism': [
        'Semi-transparent elements with blur effects',
        'Layered glass-like appearance',
      ],
      'neumorphism': [
        'Soft shadows creating pressed/raised effects',
        'Subtle depth and tactile appearance',
      ],
      'retro': [
        'Vintage colors and typography',
        'Classic design elements from past decades',
      ],
    };
    instructions.addAll(
      styleInstructions[designStyle] ?? styleInstructions['modern']!,
    );

    // Color scheme
    Map<String, String> colorInstructions = {
      'neutral':
          'Use grays, whites, and subtle accent colors (#F3F4F6, #6B7280, #111827)',
      'blue': 'Use blue-based palette (#3B82F6, #1E40AF, #DBEAFE)',
      'green': 'Use green-based palette (#10B981, #047857, #D1FAE5)',
      'purple': 'Use purple-based palette (#8B5CF6, #7C3AED, #EDE9FE)',
      'orange': 'Use orange-based palette (#F59E0B, #D97706, #FEF3C7)',
      'monochrome': 'Use only black, white, and grays',
      'colorful': 'Use multiple vibrant colors harmoniously',
      'custom': 'Choose colors that match the content theme',
    };
    instructions.add(
      colorInstructions[colorScheme] ?? colorInstructions['neutral']!,
    );

    // Fidelity level
    switch (fidelityLevel) {
      case 'low':
        instructions.addAll([
          'Use basic rectangles and simple shapes',
          'Minimal details, focus on layout structure',
          'Gray boxes for images, simple lines for text',
        ]);
        break;
      case 'high':
        instructions.addAll([
          'Include detailed elements, realistic content',
          'Add visual polish, shadows, gradients',
          'Use realistic imagery placeholders and styling',
        ]);
        break;
      default: // medium
        instructions.addAll([
          'Balance simplicity with useful detail',
          'Include key visual elements without overcomplicating',
          'Show enough detail to understand functionality',
        ]);
    }

    // Optional features
    if (includePlaceholderText) {
      instructions.add(
        'Include realistic placeholder text (Lorem ipsum, realistic headings, etc.)',
      );
    }
    if (includeIcons) {
      instructions.add('Add relevant $iconStyle icons to enhance the design');
    }
    if (responsiveLayout) {
      instructions.add(
        'Design with responsive principles (flexible layouts, appropriate sizing)',
      );
    }
    if (includeAnnotations) {
      instructions.add(
        'Add design annotations explaining key decisions and measurements',
      );
    }

    // Framework styling
    if (uiFramework != 'generic') {
      instructions.add(
        'Follow $uiFramework design system principles and component styling',
      );
    }

    // Technical requirements
    instructions.addAll([
      'Generate clean, valid SVG code that renders properly in browsers',
      'Use semantic grouping with <g> elements for logical sections',
      'Include proper text elements for readable content',
      'Use consistent spacing, alignment, and proportions',
      'Make elements properly sized and positioned',
      'Use viewBox for scalability if responsive layout is enabled',
      'IMPORTANT: Output ONLY the SVG code wrapped in ```svg code blocks',
      'Do not include explanations or additional text outside the SVG',
    ]);

    return AIService.buildSystemPrompt(
      role:
          'an expert UI/UX designer and icon artist specializing in SVG-based designs',
      context:
          'You create beautiful, functional UI mockups, wireframes, and icons in SVG format, focusing on usability, aesthetics, and modern design principles.',
      instructions: instructions,
    );
  }

  @override
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    return [
      ChatMessage(role: 'system', content: systemPrompt),
      ChatMessage(role: 'user', content: 'Create a design for: $input'),
    ];
  }
}

class ImageAnalyzerTool extends BaseAITool {
  ImageAnalyzerTool({Map<String, dynamic>? settings})
    : super(
        settings:
            settings ??
            {
              'analysis_type': 'detailed_description',
              'extract_text': true,
              'include_colors': true,
              'include_objects': true,
              'include_emotions': false,
              'output_format': 'markdown',
              'custom_query': '',
            },
        name: 'Image Analyzer',
        description:
            'Analyze images with AI - extract text, describe content, identify objects',
        icon: Icons.image_search,
        settingsHints: {
          'analysis_type': {
            'type': 'dropdown',
            'label': 'Analysis Type',
            'help': 'Choose the type of image analysis to perform',
            'options': [
              {
                'value': 'detailed_description',
                'label': 'Detailed Description',
              },
              {'value': 'quick_summary', 'label': 'Quick Summary'},
              {'value': 'technical_analysis', 'label': 'Technical Analysis'},
              {'value': 'accessibility_alt', 'label': 'Accessibility Alt Text'},
              {
                'value': 'content_extraction',
                'label': 'Content Extraction Only',
              },
            ],
          },
          'extract_text': {
            'type': 'bool',
            'label': 'Extract Text (OCR)',
            'help': 'Extract and transcribe any text found in the image',
          },
          'include_colors': {
            'type': 'bool',
            'label': 'Analyze Colors',
            'help': 'Include color palette and dominant color analysis',
          },
          'include_objects': {
            'type': 'bool',
            'label': 'Identify Objects',
            'help':
                'Identify and describe objects, people, and items in the image',
          },
          'include_emotions': {
            'type': 'bool',
            'label': 'Detect Emotions',
            'help':
                'Analyze facial expressions and emotional content (if applicable)',
          },
          'output_format': {
            'type': 'dropdown',
            'label': 'Output Format',
            'help': 'Choose how to format the analysis results',
            'options': ['markdown', 'plain_text', 'structured'],
          },
          'custom_query': {
            'type': 'text',
            'label': 'Custom Query',
            'help':
                'Optional: Enter a custom instruction for how to analyze the image',
          },
        },
      );

  @override
  String buildAISystemPrompt(String input) {
    final analysisType = settings['analysis_type'] as String;
    final extractText = settings['extract_text'] as bool;
    final includeColors = settings['include_colors'] as bool;
    final includeObjects = settings['include_objects'] as bool;
    final includeEmotions = settings['include_emotions'] as bool;
    final outputFormat = settings['output_format'] as String;

    final instructions = <String>[];

    final customQuery = settings['custom_query'] as String?;
    if (customQuery != null && customQuery.trim().isNotEmpty) {
      instructions.add(
        "Follow this user-provided custom query: \"$customQuery\"",
      );
    }

    // Base instructions based on analysis type
    switch (analysisType) {
      case 'detailed_description':
        instructions.addAll([
          'Provide a comprehensive and detailed description of the image',
          'Include information about composition, lighting, and visual elements',
          'Describe the scene, setting, and atmosphere',
        ]);
        break;
      case 'quick_summary':
        instructions.addAll([
          'Provide a brief, concise summary of what the image shows',
          'Focus on the main subject and key details only',
          'Keep the description under 100 words',
        ]);
        break;
      case 'technical_analysis':
        instructions.addAll([
          'Analyze the technical aspects of the image',
          'Comment on composition, lighting, perspective, and visual techniques',
          'Identify the likely camera angle, style, and photographic elements',
        ]);
        break;
      case 'accessibility_alt':
        instructions.addAll([
          'Create concise, descriptive alt text suitable for accessibility',
          'Focus on essential information that conveys the image\'s purpose',
          'Keep it brief but informative (under 150 characters if possible)',
        ]);
        break;
      case 'content_extraction':
        instructions.addAll([
          'Focus primarily on extracting and organizing content from the image',
          'Minimize subjective descriptions, focus on factual content',
        ]);
        break;
    }

    // Add specific analysis instructions
    if (extractText) {
      instructions.add(
        'Extract and transcribe ALL visible text, including signs, labels, documents, handwriting, etc.',
      );
    }

    if (includeColors) {
      instructions.add(
        'Analyze the color palette, dominant colors, and color scheme',
      );
    }

    if (includeObjects) {
      instructions.add(
        'Identify and list all visible objects, people, animals, and items',
      );
    }

    if (includeEmotions && analysisType != 'content_extraction') {
      instructions.add(
        'If people are visible, describe their expressions, emotions, and body language',
      );
    }

    // Output format instructions
    switch (outputFormat) {
      case 'markdown':
        instructions.addAll([
          'Format output using clean Markdown with appropriate headers',
          'Use bullet points and structured sections for organization',
          'Bold important terms and use code blocks for extracted text',
        ]);
        break;
      case 'plain_text':
        instructions.addAll([
          'Use plain text format without special formatting',
          'Organize information in clear paragraphs',
          'Use simple bullet points with dashes if needed',
        ]);
        break;
      case 'structured':
        instructions.addAll([
          'Organize output into clear sections with headers',
          'Present information in a structured, systematic way',
          'Group related information together',
        ]);
        break;
    }

    return AIService.buildSystemPrompt(
      role: 'an expert image analyst and computer vision specialist',
      context:
          'You analyze images with precision and detail, extracting both visual and textual information.',
      instructions: instructions,
      outputFormat: outputFormat == 'markdown'
          ? 'Use proper Markdown formatting'
          : null,
    );
  }

  @override
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    // Use helper function to extract images
    final (cleanText, images) = AIService.extractBase64Images(input);

    final messages = [ChatMessage.text(role: 'system', text: systemPrompt)];

    if (images.isNotEmpty) {
      // Prepare user message based on analysis type
      String userMessage;
      final analysisType = settings['analysis_type'] as String;
      final customQuery = settings['custom_query'] as String?;

      if (cleanText.isNotEmpty && cleanText != '[Image]') {
        userMessage = cleanText;
      } else if (customQuery != null && customQuery.trim().isNotEmpty) {
        userMessage = customQuery.trim();
      } else {
        // Generate default message based on analysis type
        switch (analysisType) {
          case 'detailed_description':
            userMessage = 'Please provide a detailed analysis of this image.';
            break;
          case 'quick_summary':
            userMessage =
                'Please provide a quick summary of what this image shows.';
            break;
          case 'technical_analysis':
            userMessage = 'Please analyze the technical aspects of this image.';
            break;
          case 'accessibility_alt':
            userMessage =
                'Please create accessibility alt text for this image.';
            break;
          case 'content_extraction':
            userMessage =
                'Please extract all content and information from this image.';
            break;
          default:
            userMessage = 'Please analyze this image.';
        }
      }

      // Send message with images
      messages.add(
        ChatMessage.withImages(
          role: 'user',
          text: userMessage,
          imageDataUrls: images,
        ),
      );
    } else {
      // No images found - provide helpful message
      final analysisType = settings['analysis_type'] as String;
      String responseMessage;

      switch (analysisType) {
        case 'accessibility_alt':
          responseMessage =
              'I can create accessibility alt text for images. Please provide an image in the format: data:image/png;base64,... or data:image/jpeg;base64,...';
          break;
        case 'content_extraction':
          responseMessage =
              'I can extract text and content from images using OCR. Please provide an image containing text, documents, signs, or other readable content.';
          break;
        case 'technical_analysis':
          responseMessage =
              'I can analyze the technical aspects of images including composition, lighting, and photographic techniques. Please share an image to analyze.';
          break;
        default:
          responseMessage =
              'I can analyze images to extract text, describe content, identify objects, and more. Please provide an image in the format: data:image/png;base64,... or data:image/jpeg;base64,...';
      }

      if (input.trim().isNotEmpty) {
        responseMessage += '\n\nYour message: $input';
      }

      messages.add(ChatMessage.text(role: 'assistant', text: responseMessage));
    }

    return messages;
  }

  @override
  Future<String> executeGetText(String input) async {
    final result = await execute(input);

    // For plain text output, clean up markdown if present
    final outputFormat = settings['output_format'] as String;
    if (outputFormat == 'plain_text') {
      return result.output
          .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1') // Remove bold
          .replaceAll(RegExp(r'\*(.*?)\*'), r'$1') // Remove italic
          .replaceAll(RegExp(r'`(.*?)`'), r'$1') // Remove code
          .replaceAll(RegExp(r'^#+\s*', multiLine: true), '') // Remove headers
          .replaceAll(
            RegExp(r'^-\s*', multiLine: true),
            '• ',
          ); // Convert bullets
    }

    return result.output;
  }
}

class CodeDocTool extends BaseAITool {
  CodeDocTool({Map<String, dynamic>? settings})
    : super(
        settings:
            settings ??
            {
              'language': 'Auto-detect',
              'include_private': true,
              'max_description_length': 'Medium',
              'output_style': 'Compact',
            },
        name: 'Universal Code Documenter',
        description:
            'Generates compact, LLM-optimized documentation from any programming language code',
        icon: Icons.description,
        settingsHints: {
          'language': {
            'type': 'dropdown',
            'label': 'Target Language',
            'help':
                'Programming language to document (auto-detect works for most)',
            'options': [
              'Auto-detect',
              'GDScript',
              'Python',
              'JavaScript',
              'TypeScript',
              'Java',
              'C#',
              'C++',
              'Rust',
              'Go',
              'Swift',
              'Kotlin',
              'Dart',
              'PHP',
              'Ruby',
            ],
          },
          'include_private': {
            'type': 'bool',
            'label': 'Include Private Members',
            'help': 'Include private/internal methods and properties',
          },
          'max_description_length': {
            'type': 'dropdown',
            'label': 'Description Detail',
            'help': 'How detailed should descriptions be',
            'options': ['Minimal', 'Medium', 'Detailed'],
          },
          'output_style': {
            'type': 'dropdown',
            'label': 'Output Style',
            'help': 'Documentation format style',
            'options': ['Compact', 'Standard', 'Detailed'],
          },
        },
      );

  @override
  String buildAISystemPrompt(String input) {
    final language = settings['language'] as String;
    final includePrivate = settings['include_private'] as bool;
    final descriptionLevel = settings['max_description_length'] as String;
    final style = settings['output_style'] as String;

    String languageContext = language == 'Auto-detect'
        ? 'any programming language'
        : language;

    String detailLevel =
        {
          'Minimal': 'very brief, only for non-obvious names',
          'Medium': 'concise but informative',
          'Detailed': 'comprehensive but still compact',
        }[descriptionLevel] ??
        'concise but informative';

    String privateInstruction = includePrivate
        ? 'Include private/internal members.'
        : 'Exclude private/internal members (those starting with _, private keyword, etc.).';

    return AIService.buildSystemPrompt(
      role: 'a code documentation expert',
      context:
          'You generate compact, LLM-optimized documentation from $languageContext code.',
      instructions: [
        'Generate clear, compact documentation optimized for LLM input with minimal tokens.',
        'Analyze the provided code and create a structured summary.',
        privateInstruction,
        'Use descriptions that are $detailLevel.',
        'Follow this exact format:',
        '',
        '## Class/Module: [Name] ([extends/implements if applicable]): [1-sentence purpose]',
        '',
        '- **Properties/Fields:**',
        '  - property_name: [brief description if needed]',
        '  - obvious_property',
        '',
        '- **Methods/Functions:**',
        '  - method_name(): [brief description if not obvious]',
        '  - method_with_params(param1, param2): [description if needed]',
        '',
        '- **Events/Signals:** (if applicable)',
        '  - event_name: [when triggered, if not obvious]',
        '',
        '- **Constants/Enums:** (if applicable)',
        '  - CONSTANT_NAME: [description if needed]',
        '',
        '- **Notes:** (only if important)',
        '  - [Important constraints, behaviors, or usage notes]',
        '',
        'Rules:',
        '- Only include descriptions for non-obvious names',
        '- Skip trivial getters/setters unless they have special behavior',
        '- Group similar items together',
        '- Keep descriptions under 50 characters for compact output',
        '- If no clear class structure, document as "Module" or "Script"',
        '- For functions outside classes, use "## Functions:" section',
        style == 'Compact'
            ? '- Be extremely concise, prioritize token efficiency'
            : style == 'Detailed'
            ? '- Include more context and examples where helpful'
            : '- Balance clarity with brevity',
      ],
    );
  }

  @override
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    return [
      ChatMessage(role: 'system', content: systemPrompt),
      ChatMessage(
        role: 'user',
        content: 'Document this code:\n\n```\n$input\n```',
      ),
    ];
  }
}

class GDScriptDocGenerator extends BaseAITool {
  GDScriptDocGenerator({Map<String, dynamic>? settings})
    : super(
        settings:
            settings ??
            {
              'include_header_doc': true,
              'document_private': true,
              'use_bbcode': true,
              'include_param_docs': true,
              'include_return_docs': true,
              'detail_level': 'Standard',
              'add_examples': false,
            },
        name: 'GDScript Doc Generator',
        description:
            'Generates proper Godot-style ## documentation comments for GDScript code',
        icon: Icons.auto_stories,
        settingsHints: {
          'include_header_doc': {
            'type': 'bool',
            'label': 'Include Script Header Doc',
            'help': 'Add documentation header at the top of the script',
          },
          'document_private': {
            'type': 'bool',
            'label': 'Document Private Members',
            'help':
                'Add documentation to private methods/variables (starting with _)',
          },
          'use_bbcode': {
            'type': 'bool',
            'label': 'Use BBCode Formatting',
            'help':
                'Include [b]bold[/b], [param], [return] tags in documentation',
          },
          'include_param_docs': {
            'type': 'bool',
            'label': 'Document Parameters',
            'help': 'Add [param name]: descriptions for function parameters',
          },
          'include_return_docs': {
            'type': 'bool',
            'label': 'Document Return Values',
            'help': 'Add [return]: descriptions for function return values',
          },
          'detail_level': {
            'type': 'dropdown',
            'label': 'Documentation Detail',
            'help': 'How detailed should the documentation be',
            'options': ['Brief', 'Standard', 'Detailed'],
          },
          'add_examples': {
            'type': 'bool',
            'label': 'Include Usage Examples',
            'help': 'Add code examples in documentation where helpful',
          },
        },
      );

  @override
  String buildAISystemPrompt(String input) {
    final includeHeader = settings['include_header_doc'] as bool;
    final documentPrivate = settings['document_private'] as bool;
    final useBBCode = settings['use_bbcode'] as bool;
    final includeParams = settings['include_param_docs'] as bool;
    final includeReturns = settings['include_return_docs'] as bool;
    final detailLevel = settings['detail_level'] as String;
    final addExamples = settings['add_examples'] as bool;

    String detailInstruction =
        {
          'Brief': 'Keep descriptions short and to the point',
          'Standard': 'Provide clear, informative descriptions',
          'Detailed': 'Include comprehensive descriptions with context',
        }[detailLevel] ??
        'Provide clear, informative descriptions';

    return AIService.buildSystemPrompt(
      role: 'a GDScript documentation expert',
      context:
          'You generate proper Godot-style ## documentation comments for GDScript code following official Godot documentation standards.',
      instructions: [
        'Add Godot-style documentation comments to GDScript code WITHOUT changing any existing code.',
        'KEEP ALL CODE INTACT - only add/modify comments that start with ##.',
        '',
        '## Documentation Format Rules:',
        '1. Use ## at the start of every documentation line',
        '2. Place comments directly above the member being documented',
        '3. All lines in a doc block must start with ##',
        '4. Use [br] for manual line breaks inside doc comments',
        '',
        includeHeader
            ? '## Script Header Documentation:'
            : '## Skip script header documentation',
        includeHeader
            ? 'Start with a header block before any members if the script has a class or extends:'
            : '',
        includeHeader ? '- First line: Brief summary' : '',
        includeHeader ? '- Optional: Longer description after blank line' : '',
        '',
        '## Member Documentation:',
        'Document these members: var, const, signal, enum, func, class',
        documentPrivate
            ? 'Include private members (starting with _)'
            : 'Skip private members (starting with _)',
        '',
        '## Variable/Constant Format:',
        '```gdscript',
        '## Description of the variable.',
        '@export var player_health: int',
        '```',
        '',
        '## Signal Format:',
        '```gdscript',
        'signal health_changed ## Emitted when player health changes.',
        '```',
        '',
        '## Enum Format:',
        '```gdscript',
        'enum State {',
        '    IDLE, ## Player is not moving.',
        '    MOVING ## Player is currently moving.',
        '}',
        '```',
        '',
        '## Function Documentation:',
        includeParams
            ? 'Use [param param_name]: to describe parameters'
            : 'Skip parameter documentation',
        includeReturns
            ? 'Use [return]: to describe return values'
            : 'Skip return value documentation',
        '```gdscript',
        '## Heals the player by the specified amount.[br]',
        includeParams
            ? '## [param amount]: How much health to restore.[br]'
            : '',
        includeReturns
            ? '## [return]: The new health value after healing.'
            : '',
        'func heal(amount: int) -> int:',
        '    pass',
        '```',
        '',
        useBBCode
            ? '## BBCode Formatting (use these):'
            : '## No BBCode formatting - use plain text',
        useBBCode ? '- [b]bold[/b], [i]italic[/i] for emphasis' : '',
        useBBCode ? '- [param name] for parameter names' : '',
        useBBCode ? '- [return] for return descriptions' : '',
        useBBCode ? '- [method Class.method] for method references' : '',
        useBBCode ? '- [member Class.property] for property references' : '',
        useBBCode ? '- [br] for line breaks' : '',
        '',
        addExamples
            ? 'Include usage examples where helpful using [codeblock] tags'
            : 'Do not include code examples',
        '',
        '## Important Rules:',
        '- Do NOT remove class_name or extends statements',
        '- Do NOT change any existing code structure',
        '- Only add ## documentation comments',
        '- Place docs directly above each member',
        detailInstruction,
        '- Make educated guesses for unclear names based on context',
        '- Maintain proper indentation matching the code',
        '',
        'Output the complete code with added documentation comments.',
      ],
    );
  }

  @override
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    return [
      ChatMessage(role: 'system', content: systemPrompt),
      ChatMessage(
        role: 'user',
        content:
            'Add Godot-style ## documentation to this GDScript code:\n\n```gdscript\n$input\n```',
      ),
    ];
  }
}

/// Factory class to create AI tools with different configurations
class AIToolFactory {
  /// Get AI tools in the format expected by your existing system
  static Map<String, List<Tool Function()>> getAIToolCategories() {
    return {
      'AI Text Processing': [
        () => SummarizerTool(),
        () => WritingAssistantTool(),
        () => TextEnhancementTool(),
        () => TranslatorTool(),
        () => ToolGeneratorTool(),
      ],
      'AI Image Analysis': [() => ImageAnalyzerTool()],
      'AI Code Tools': [
        () => CodeExplainerTool(),
        () => CodeAnalysisTool(),
        () => FunctionGeneratorTool(),
        () => CodeConverterTool(),
        () => RegexBuilderTool(),
        () => CodeDocTool(),
        () => GDScriptDocGenerator(),
      ],
      'AI Data Visualization': [
        () => ChartGeneratorTool(),
        () => UIDesignTool(),
      ],
    };
  }
}
