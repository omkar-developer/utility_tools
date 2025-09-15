import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:utility_tools/classes/js_change_notifier.dart';
import 'package:utility_tools/widgets/js_script_library_dialog.dart';
import 'package:window_manager/window_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'page/home.dart';
import 'widgets/settings_editor.dart'; // Assuming you have this
import 'services/app_settings.dart';
import 'package:utility_tools/services/js_script_service.dart';

import 'package:highlight/highlight.dart';

/// GDScript highlighting mode for highlight.dart
final gdscript = Mode(
  refs: {},
  case_insensitive: false,
  keywords: {
    "keyword": """
      class extends func var const static signal enum
      export onready tool setget
      break continue pass return
      if elif else for while match in
      and or not is as
      self preload assert await yield
      breakpoint remotesync master puppet slave
    """,
    "literal": "true false null PI TAU INF NAN",
    "built_in": """
      print range
      Vector2 Vector3 Vector4 Rect2 Transform2D Transform3D AABB
      Basis Quat Color Plane RID Object Node NodePath
      Dictionary Array PackedByteArray PackedInt32Array PackedFloat32Array
      PackedStringArray PackedVector2Array PackedVector3Array
      Resource PackedScene
    """,
  },
  contains: [
    // Single-line comments
    Mode(className: 'comment', begin: '#', end: r'$'),

    // Strings
    Mode(className: 'string', begin: '"""', end: '"""'),
    Mode(className: 'string', begin: "'''", end: "'''"),
    Mode(className: 'string', begin: '"', end: '"'),
    Mode(className: 'string', begin: "'", end: "'"),

    // Numbers
    Mode(className: 'number', begin: r'\b\d+(\.\d+)?([eE][+-]?\d+)?'),

    // Annotations like @export, @onready
    Mode(className: 'meta', begin: r'@[A-Za-z_]\w*'),

    // Function definitions
    Mode(
      className: 'function',
      beginKeywords: 'func',
      end: r'[:\{]',
      excludeEnd: true,
      contains: [
        Mode(className: 'title', begin: r'[A-Za-z_]\w*', relevance: 0),
      ],
    ),

    // Class definitions
    Mode(
      className: 'class',
      beginKeywords: 'class',
      end: r'[:\{]',
      excludeEnd: true,
      contains: [Mode(className: 'title', begin: r'[A-Za-z_]\w*')],
    ),
  ],
);

// Service to fetch Ollama models
class OllamaService {
  static Future<List<String>> getAvailableModels(String baseUrl) async {
    try {
      // Convert OpenAI-style URL to Ollama API URL
      String ollamaUrl = baseUrl.replaceAll('/v1', '');
      if (!ollamaUrl.endsWith('/')) ollamaUrl += '/';

      final response = await http
          .get(
            Uri.parse('${ollamaUrl}api/tags'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['models'] as List<dynamic>?;
        if (models != null) {
          return models.map((model) => model['name'] as String).toList();
        }
      }
    } catch (e) {
      print('Error fetching Ollama models: $e');
    }

    // Return default models if fetch fails
    return [
      'qwen2.5-coder:7b',
      'qwen2.5-coder:14b',
      'qwen2.5-coder:32b',
      'llama3.2:3b',
      'llama3.2:1b',
      'deepseek-coder-v2:16b',
      'codestral:22b',
    ];
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize AppSettings
  await AppSettings.init();

  if (!kIsWeb) {
    // Desktop-only: initialize JS scripts & window manager
    await JsScriptService.init();
    await JsScriptService.importDefaultScripts();

    await windowManager.ensureInitialized();

    final windowSize = AppSettings.rememberWindowSize
        ? AppSettings.windowSize
        : const Size(1340, 1024);

    WindowOptions windowOptions = WindowOptions(
      size: windowSize,
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } else {
    // Web-only: load default scripts from assets if needed
    await JsScriptService.init();
    await JsScriptService.importDefaultScripts();
  }

  // Register syntax highlighting
  highlight.registerLanguage('gdscript', gdscript);
  highlight.registerLanguage('gd', gdscript);
  highlight.registerLanguage('godot', gdscript);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyAppState>();
  }
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = AppSettings.themeMode;

  void updateTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
      AppSettings.themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Utility Tools',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    // Only add window listener on desktop platforms
    if (!kIsWeb) {
      windowManager.addListener(this);
    }
    // Initialize sidebar state based on screen size for web
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkInitialSidebarState();
      });
    }
  }

  void _checkInitialSidebarState() {
    if (mounted) {
      final screenWidth = MediaQuery.of(context).size.width;
      setState(() {
        _isSidebarCollapsed = screenWidth < 1024; // Collapse on mobile
      });
    }
  }

  @override
  void dispose() {
    // Only remove window listener on desktop platforms
    if (!kIsWeb) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowResize() {
    if (!kIsWeb && AppSettings.rememberWindowSize) {
      windowManager.getSize().then((size) {
        AppSettings.windowSize = size;
      });
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use different layouts for web and desktop
    if (kIsWeb) {
      return _buildWebLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildWebLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isSidebarCollapsed ? 61 : 180,
            child: _buildSidebar(),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Minimal top bar for web
                _buildWebTopBar(),
                // Main content
                const Expanded(child: Home()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _buildCustomAppBar(context),
      ),
      body: const Home(),
    );
  }

  Widget _buildWebTopBar() {
    // This method is no longer used in the web layout
    return const SizedBox.shrink();
  }

  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(40),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildSidebarItem(
            icon: _isSidebarCollapsed ? Icons.menu : Icons.keyboard_arrow_left,
            label: 'Utility Tools',
            onTap: _toggleSidebar,
          ),
          // App branding
          const Divider(height: 1),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSidebarItem(
                  icon: Icons.home,
                  label: 'Home',
                  onTap: () {
                    // Navigate to home or refresh
                  },
                  isSelected: true,
                ),
                _buildSidebarItem(
                  icon: Icons.library_books,
                  label: 'Tools Library',
                  onTap: () => JsScriptLibraryHelper.showLibraryDialog(
                    context,
                    callback: () => JSChangeNotifier.instance.reloadTools(),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1),
                ),

                // Quick actions section
                if (!_isSidebarCollapsed) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                _buildSidebarItem(
                  icon: Icons.fullscreen,
                  label: 'Fullscreen',
                  onTap: _toggleFullscreen,
                ),
                _buildSidebarItem(
                  icon: Icons.refresh,
                  label: 'Refresh',
                  onTap: _refreshPage,
                ),
                _buildSidebarItem(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: _shareApp,
                ),
              ],
            ),
          ),

          // Footer with theme toggle and collapse button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 1),
              const SizedBox(height: 8),
              _buildSidebarItem(
                icon: Icons.settings,
                label: 'Settings',
                onTap: _showGlobalSettingsDialog,
              ),
              _buildSidebarItem(
                icon: Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
                label: 'Toggle theme',
                onTap: () {
                  final newTheme =
                      Theme.of(context).brightness == Brightness.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
                  MyApp.of(context)?.updateTheme(newTheme);
                  AppSettings.themeMode = newTheme;
                },
              ),
              _buildSidebarItem(
                icon: Icons.info_outline,
                label: 'About',
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: _isSidebarCollapsed ? label : '',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  if (!_isSidebarCollapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    final isDesktop =
        !kIsWeb &&
        (Theme.of(context).platform == TargetPlatform.windows ||
            Theme.of(context).platform == TargetPlatform.linux ||
            Theme.of(context).platform == TargetPlatform.macOS);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // App title and drag area
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: isDesktop
                  ? (_) => windowManager.startDragging()
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 56,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Image.asset("assets/icons/icon.png", height: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Utility Tools',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Library button
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: 'Manage JavaScript tools Library',
            onPressed: () => JsScriptLibraryHelper.showLibraryDialog(
              context,
              callback: () => JSChangeNotifier.instance.reloadTools(),
            ),
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _showGlobalSettingsDialog,
          ),
          // Info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () => _showAboutDialog(context),
          ),
          // Custom window controls (desktop only)
          if (isDesktop) _buildWindowControls(context),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildWindowControls(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 8),
        _WindowControlButton(
          icon: Icons.minimize,
          onPressed: () => windowManager.minimize(),
          tooltip: 'Minimize',
        ),
        _WindowControlButton(
          icon: Icons.crop_square,
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
          tooltip: 'Maximize/Restore',
        ),
        _WindowControlButton(
          icon: Icons.close,
          onPressed: () => windowManager.close(),
          tooltip: 'Close',
          isClose: true,
        ),
      ],
    );
  }

  void _toggleFullscreen() {
    // Web fullscreen functionality
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press F11 to toggle fullscreen in your browser'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Fullscreen not supported: $e');
    }
  }

  void _refreshPage() {
    // Web refresh functionality
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press Ctrl+R or F5 to refresh the page'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Refresh not supported: $e');
    }
  }

  void _shareApp() {
    // Web share functionality
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copy the current URL to share this app'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Share not supported: $e');
    }
  }

  Future<List<Map<String, String>>> fetchModels(
    Map<String, TextEditingController> controllers,
  ) async {
    final baseUrl = controllers["ai_base_url"]?.text.trim() ?? "";
    final apiKey = controllers["ai_api_key"]?.text.trim();

    if (baseUrl.isEmpty) {
      throw Exception("Base URL is required");
    }

    // always append /models to whatever base URL is set
    final url = baseUrl.endsWith("/models") ? baseUrl : "$baseUrl/models";

    final headers = <String, String>{"Content-Type": "application/json"};
    if (apiKey != null && apiKey.isNotEmpty) {
      headers["Authorization"] = "Bearer $apiKey";
    }

    final res = await http.get(Uri.parse(url), headers: headers);

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch models: ${res.statusCode} ${res.body}");
    }

    final body = jsonDecode(res.body);

    if (body is Map && body.containsKey("data") && body["data"] is List) {
      return (body["data"] as List)
          .map<Map<String, String>>(
            (m) => {
              "id": m["id"].toString(),
              "object": m["object"]?.toString() ?? "model",
            },
          )
          .toList();
    }

    throw Exception("Unexpected models response format: ${res.body}");
  }

  void _showGlobalSettingsDialog() async {
    if (!mounted) return;
    final currentContext = context;

    // Fetch available models
    List<String> availableModels = [];
    try {
      availableModels = await OllamaService.getAvailableModels(
        AppSettings.aiBaseUrl,
      );
    } catch (e) {
      // Use default models if fetch fails
      availableModels = [
        'qwen2.5-coder:7b',
        'qwen2.5-coder:14b',
        'qwen2.5-coder:32b',
        'llama3.2:3b',
        'llama3.2:1b',
        'deepseek-coder-v2:16b',
        'codestral:22b',
      ];
    }

    if (!mounted) return;

    // Create settings map for the settings dialog
    final Map<String, dynamic> settings = {
      'theme_mode': AppSettings.themeMode == ThemeMode.light
          ? 'Light'
          : AppSettings.themeMode == ThemeMode.dark
          ? 'Dark'
          : 'System',
      'ai_base_url': AppSettings.aiBaseUrl,
      'ai_model': AppSettings.aiModel,
      'ai_api_key': AppSettings.aiApiKey,
      'ai_max_tokens': AppSettings.aiMaxTokens,
      'ai_temperature': AppSettings.aiTemperature,
      'auto_save_enabled': AppSettings.autoSaveEnabled,
      'count_tokens': AppSettings.countTokens,
    };

    // Add desktop-specific settings only if not on web
    if (!kIsWeb) {
      settings['remember_window_size'] = AppSettings.rememberWindowSize;
    }

    final Map<String, dynamic> settingsHints = {
      'theme_mode': {
        'type': 'dropdown',
        'label': 'Theme',
        'help': 'Choose app theme',
        'options': ['System', 'Light', 'Dark'],
      },
      'ai_base_url': {
        'type': 'text',
        'label': 'AI Base URL',
        'help':
            'Base URL for AI service (Ollama: http://localhost:11434/v1, OpenAI: https://api.openai.com/v1)',
        'placeholder': kIsWeb
            ? 'https://api.openai.com/v1'
            : 'http://localhost:11434/v1',
        'options': [
          if (!kIsWeb)
            {'label': 'Ollama', 'value': 'http://localhost:11434/v1'},
          {'label': 'OpenAI', 'value': 'https://api.openai.com/v1'},
          {'label': 'Groq', 'value': 'https://api.groq.com/openai/v1'},
          {'label': 'Anthropic', 'value': 'https://api.anthropic.com/v1'},
          {'label': 'Cohere', 'value': 'https://api.cohere.ai/v1'},
          {'label': 'Mistral', 'value': 'https://api.mistral.ai/v1'},
          {'label': 'Google PaLM', 'value': 'https://api.palm.google.com/v1'},
          {
            'label': 'Hugging Face',
            'value': 'https://api-inference.huggingface.co/models',
          },
          {'label': 'Replicate', 'value': 'https://api.replicate.com/v1'},
          {
            'label': 'IBM Watson',
            'value':
                'https://api.us-south.tone-analyzer.watson.cloud.ibm.com/instances/{instance_id}/v3/tone',
          },
          {
            'label': 'Microsoft Azure OpenAI',
            'value': 'https://api.openai.azure.com/v1',
          },
          {'label': 'Vercel AI SDK', 'value': 'https://api.vercel.com/ai/v1'},
          {'label': 'AI21 Labs', 'value': 'https://api.ai21.com/studio/v1'},
          {'label': 'OpenRouter', 'value': 'https://api.openrouter.ai/v1'},
        ],
      },
      'ai_model': {
        'type': 'text',
        'label': 'AI Model',
        'help':
            'AI model name to use (automatically fetched from Ollama or enter custom)',
        'optionsCallback': fetchModels,
        'placeholder': kIsWeb ? 'gpt-3.5-turbo' : 'qwen2.5-coder:7b',
      },
      'ai_api_key': {
        'type': 'text',
        'obscure': true,
        'label': 'API Key',
        'help': kIsWeb
            ? 'API key required for online services'
            : 'API key for online services (leave empty for local Ollama)',
        'placeholder': 'Enter API key for online services',
      },
      'ai_max_tokens': {
        'type': 'number',
        'label': 'Max Tokens',
        'help': 'Maximum tokens for AI responses',
        'min': 512,
        'max': 8192,
      },
      'ai_temperature': {
        'type': 'slider',
        'label': 'AI Temperature',
        'help':
            'Controls randomness in AI responses (0.0 = deterministic, 1.0 = creative)',
        'min': 0.0,
        'max': 1.0,
        'divisions': 20,
        'show_value': true,
      },
      'auto_save_enabled': {
        'type': 'bool',
        'label': 'Auto-save Settings',
        'help': 'Automatically save tool settings when changed',
      },
    };

    // Add desktop-specific settings only if not on web
    if (!kIsWeb) {
      settingsHints['remember_window_size'] = {
        'type': 'bool',
        'label': 'Remember Window Size',
        'help': 'Save and restore window size on startup',
      };
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SettingsDialog(
        title: 'Settings',
        settingsHints: settingsHints,
        settings: Map<String, dynamic>.from(settings),
      ),
    );

    if (result != null && mounted) {
      // Apply settings
      final themeMode = result['theme_mode'] as String;
      final newThemeMode = themeMode == 'Light'
          ? ThemeMode.light
          : themeMode == 'Dark'
          ? ThemeMode.dark
          : ThemeMode.system;

      AppSettings.aiBaseUrl = result['ai_base_url'] as String;
      AppSettings.aiModel = result['ai_model'] as String;
      AppSettings.aiApiKey = result['ai_api_key'] as String;
      AppSettings.aiMaxTokens = result['ai_max_tokens'] as int;
      AppSettings.aiTemperature = result['ai_temperature'] as double;
      AppSettings.autoSaveEnabled = result['auto_save_enabled'] as bool;
      AppSettings.countTokens = result['count_tokens'] as bool;

      // Desktop-specific settings
      if (!kIsWeb && result.containsKey('remember_window_size')) {
        AppSettings.rememberWindowSize = result['remember_window_size'] as bool;
      }

      // Update theme if mounted
      if (mounted) {
        if (AppSettings.themeMode != newThemeMode) {
          AppSettings.themeMode = newThemeMode;
          MyApp.of(currentContext)?.updateTheme(newThemeMode);
        }

        // Show confirmation
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Utility Tools',
      applicationVersion: '1.3.0',
      applicationIcon: Image.asset(
        "assets/icons/icon.png",
        width: 64,
        height: 64,
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
          'A comprehensive collection of text processing and manipulation tools.',
        ),
        const SizedBox(height: 16),
        const Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('• Text formatting and cleanup'),
        const Text('• Data conversion and extraction'),
        const Text('• Encoding and encryption tools'),
        const Text('• Code processing utilities'),
        const Text('• AI-powered text tools'),
        const SizedBox(height: 16),
        if (kIsWeb) ...[
          const Text(
            'Web Version Features:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('• Cross-platform compatibility'),
          const Text('• No installation required'),
          const Text('• Automatic updates'),
          const Text('• Cloud-based AI services'),
          const SizedBox(height: 16),
        ],
        Text(
          kIsWeb
              ? 'Built with Flutter Web and powered by cloud AI services.'
              : 'Built with Flutter and powered by AI models like Ollama and OpenAI-compatible APIs.',
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
        if (kIsWeb) ...[
          const SizedBox(height: 16),
          Text(
            'Note: Local Ollama support is not available in the web version. Please use cloud-based AI services.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }
}

class _WindowControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isClose;

  const _WindowControlButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isClose = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 32,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          hoverColor: isClose
              ? Colors.red.withOpacity(0.1)
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              size: 16,
              color: isClose ? null : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
