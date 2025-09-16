import 'package:flutter/material.dart';
import 'package:utility_tools/widgets/tool_bar.dart';
import 'package:utility_tools/models/tool.dart';
import 'settings_editor.dart';

class CategoryToolBar extends StatefulWidget {
  final Map<String, List<Tool Function()>> categories;
  final List<String> hiddenCategories;
  final String? initialCategory;
  final void Function(Tool) onToolSelected;
  final void Function(Tool, Map<String, dynamic>) onToolSettingsChanged;
  final bool useEmbeddedSettings;
  final bool liveUpdate;
  final bool showSettings;
  final void Function(String message)? onError;

  const CategoryToolBar({
    super.key,
    required this.categories,
    required this.onToolSelected,
    required this.onToolSettingsChanged,
    this.initialCategory,
    this.useEmbeddedSettings = false,
    this.liveUpdate = false,
    this.hiddenCategories = const ["Splitter"],
    this.showSettings = true,
    this.onError,
  });

  @override
  State<CategoryToolBar> createState() => _CategoryToolBarState();
}

class _CategoryToolBarState extends State<CategoryToolBar> {
  String? selectedCategory;
  Tool? selectedTool;
  bool showEmbeddedSettings = false;
  int _rebuildId = 0;

  Map<String, Tool> _toolCache = {};
  final Map<String, int> _lastFactoriesHash = {};

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory ?? widget.categories.keys.first;
  }

  void _forceRebuild() {
    setState(() {
      _rebuildId++; // increment to trigger rebuild
    });
  }

  List<Tool> get currentTools {
    if (selectedCategory == null) return [];
    final factories = widget.categories[selectedCategory!] ?? [];

    // Create a hash of the factory list to detect any changes
    final factoriesHash = Object.hashAll(factories.map((f) => f.hashCode));

    // If hash changed, clear cache for this category
    if (_lastFactoriesHash[selectedCategory!] != factoriesHash) {
      _toolCache.removeWhere(
        (key, value) => key.startsWith('$selectedCategory-'),
      );
      _lastFactoriesHash[selectedCategory!] = factoriesHash;
    }

    return List.generate(factories.length, (index) {
      final cacheKey = '$selectedCategory-$index';
      if (!_toolCache.containsKey(cacheKey)) {
        try {
          _toolCache[cacheKey] = factories[index]();
        } catch (e, st) {
          widget.onError?.call(
            'Failed to load tool from factory $index in category $selectedCategory. Error: $e\n$st',
          );
          return null;
        }
      }
      return _toolCache[cacheKey];
    }).whereType<Tool>().toList(); // filters out nulls
  }

  void debugTools(Map<String, List<Tool Function()>> toolsByCategory) {
    for (final entry in toolsByCategory.entries) {
      debugPrint('Category: ${entry.key}');
      for (final toolFactory in entry.value) {
        final tool = toolFactory();
        debugPrint('  Tool: ${tool.name}');
      }
    }
  }

  void _onToolSelected(Tool tool) {
    setState(() {
      selectedTool = tool;
      _rebuildId++;
    });
    widget.onToolSelected(tool);
  }

  void _showSettingsDialog() async {
    if (selectedTool == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${selectedTool!.name} Settings'),
        content: SettingsEditor(
          useColumnMode: true,
          settings: Map<String, dynamic>.from(selectedTool!.settings),
          settingsHints: selectedTool!.settingsHints,
          liveUpdate: false,
          showApplyButton: false,
          onChanged: (_) {},
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(selectedTool!.settings);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      selectedTool!.settings
        ..clear()
        ..addAll(result);
      widget.onToolSettingsChanged(selectedTool!, result);
    }
  }

  void _toggleEmbeddedSettings() {
    if (selectedTool == null) return;
    setState(() {
      showEmbeddedSettings = !showEmbeddedSettings;
    });
  }

  void debugPrintCurrentTools() {
    final tools = currentTools;
    debugPrint("Current tools for category: $selectedCategory");
    for (var i = 0; i < tools.length; i++) {
      debugPrint("  [$i] ${tools[i].name} (${tools[i].runtimeType})");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isMobile = screenWidth < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main toolbar row - responsive layout
        Container(
          padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
          child: _buildToolbarContent(context, isDesktop, isTablet, isMobile),
        ),

        // Embedded settings - show when toggled and tool is selected
        if (showEmbeddedSettings && selectedTool != null && widget.showSettings)
          Container(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height *
                  0.4, // Limit to 40% of screen height
            ),
            padding: const EdgeInsets.all(12),
            margin: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest
                  .withAlpha((0.3 * 255).toInt()),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withAlpha((0.2 * 255).toInt()),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tune,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tool Settings',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          setState(() => showEmbeddedSettings = false),
                      icon: const Icon(Icons.close, size: 18),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(24, 24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 100,
                      maxHeight: 200,
                    ),
                    child: SingleChildScrollView(
                      child: SettingsEditor(
                        key: ValueKey(_rebuildId),
                        settings: Map<String, dynamic>.from(
                          selectedTool!.settings,
                        ),
                        showApplyButton: false,
                        settingsHints: selectedTool?.settingsHints,
                        liveUpdate: widget.liveUpdate,
                        useColumnMode: false,
                        onChanged: (newSettings) {
                          selectedTool!.settings.clear();
                          selectedTool!.settings.addAll(newSettings);
                          widget.onToolSettingsChanged(
                            selectedTool!,
                            newSettings,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildToolbarContent(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    if (isMobile) {
      // Mobile: Stack category and toolbar vertically for better space usage
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category and settings row
          Row(
            children: [
              Expanded(child: _buildCategoryDropdown(context, compact: true)),
              if (selectedTool != null && widget.showSettings) ...[
                const SizedBox(width: 8),
                _buildSettingsButton(context, compact: true),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Toolbar
          ToolBar(
            tools: currentTools,
            selectedTool: selectedTool,
            onToolSelected: _onToolSelected,
          ),
        ],
      );
    }

    // Desktop/Tablet: Horizontal layout with proper sizing
    return Row(
      children: [
        Expanded(
          child: ToolBar(
            firstWidget: SizedBox(
              width: isDesktop ? 200 : 160,
              child: _buildCategoryDropdown(context),
            ),
            tools: currentTools,
            selectedTool: selectedTool,
            onToolSelected: _onToolSelected,
          ),
        ),

        // Settings button - fixed width
        if (selectedTool != null && widget.showSettings) ...[
          const SizedBox(width: 16),
          _buildSettingsButton(context),
        ],
      ],
    );
  }

  Widget _buildCategoryDropdown(BuildContext context, {bool compact = false}) {
    return Container(
      height: compact ? 36 : 40,
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outline.withAlpha((0.3 * 255).toInt()),
        ),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.categories.keys.contains(selectedCategory)
              ? selectedCategory
              : null,
          hint: Text(
            'Category',
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
          ),
          style: TextStyle(
            fontSize: compact ? 12 : 14,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          items: widget.categories.keys
              .where((category) => !widget.hiddenCategories.contains(category))
              .map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category, overflow: TextOverflow.ellipsis),
                );
              })
              .toList(),
          onChanged: (value) {
            setState(() {
              if (selectedCategory != value) {
                _toolCache = {};
              }
              selectedCategory = value;
              selectedTool = null;
              showEmbeddedSettings = false;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context, {bool compact = false}) {
    return Container(
      height: compact ? 36 : 40,
      width: compact ? 36 : 40,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outline.withAlpha((0.3 * 255).toInt()),
        ),
        borderRadius: BorderRadius.circular(8),
        color: showEmbeddedSettings
            ? Theme.of(
                context,
              ).colorScheme.primary.withAlpha((0.1 * 255).toInt())
            : Theme.of(context).colorScheme.surface,
      ),
      child: IconButton(
        onPressed: widget.useEmbeddedSettings
            ? _toggleEmbeddedSettings
            : _showSettingsDialog,
        icon: Icon(
          widget.useEmbeddedSettings
              ? (showEmbeddedSettings ? Icons.expand_less : Icons.settings)
              : Icons.settings,
          size: compact ? 16 : 18,
          color: showEmbeddedSettings
              ? Theme.of(context).colorScheme.primary
              : Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
        ),
        style: IconButton.styleFrom(padding: EdgeInsets.zero),
      ),
    );
  }
}
