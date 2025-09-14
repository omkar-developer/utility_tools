import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tiktoken_tokenizer_gpt4o_o1/tiktoken_tokenizer_gpt4o_o1.dart';
import 'package:utility_tools/classes/js_change_notifier.dart';
import 'package:utility_tools/services/js_script_service.dart';
import 'package:utility_tools/widgets/category_toolbar.dart';
import 'package:utility_tools/models/tool.dart';
import 'package:utility_tools/widgets/chain_tools_panel.dart';
import 'package:utility_tools/widgets/io_card.dart';
import 'package:utility_tools/widgets/js_script_library_dialog.dart';
import 'package:utility_tools/widgets/settings_editor.dart';
import 'package:utility_tools/widgets/status_bar.dart';
import '../classes/chain_executer.dart';
import 'package:utility_tools/services/chain_persistence_service.dart';
import 'package:utility_tools/models/saved_chain.dart';
import 'package:utility_tools/widgets/chain_save_dialog.dart';
import 'package:utility_tools/widgets/chain_library_dialog.dart';
import 'package:utility_tools/text_tools/text_transform_tools.dart';
import 'package:utility_tools/text_tools/ai_tools.dart';
import 'package:utility_tools/text_tools/splitter_tools.dart';
import 'package:utility_tools/text_tools/js_tool.dart';
import 'package:utility_tools/text_tools/text_analyzer_tools.dart';
import 'package:utility_tools/text_tools/text_manipulation_tools.dart';
import 'package:utility_tools/text_tools/encoding_decoding_tool.dart';
import 'package:utility_tools/services/app_settings.dart';
import 'package:utility_tools/text_tools/misc_tools.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Tool? selectedTool;
  bool isProcessing = false;
  bool livePreview = false;
  String statusMessage = 'Select a tool to get started';
  ToolStatus currentStatus = ToolStatus.idle;
  String output = '';
  bool chainModeEnabled = false;
  bool isChainExecuting = false;
  bool isOutputMD = false;
  SavedChain? _currentLoadedChain;

  StreamSubscription<String>? _streamSub;
  bool _isStreaming = false;
  bool _isCancelStreaming = false;
  final ScrollController scrollController = ScrollController();

  TextEditingController inputController = TextEditingController();

  Timer? _debounceTimer;
  Timer? _debounceTimer2;
  String _lastProcessedInput = '';
  Tool? _lastProcessedTool;
  int _executionCounter = 0;
  List<ChainedTool> _chainedTools = [];

  String inputStatus = '';

  Map<String, List<Tool Function()>> toolCategories = {};

  var tiktoken = Tiktoken(OpenAiModel.gpt_4);

  bool showSettings = true;

  void appendCategories(Map<String, List<Tool Function()>> categories) {
    for (final category in categories.entries) {
      toolCategories.putIfAbsent(category.key, () => []);
      toolCategories[category.key]!.addAll(category.value);
    }
  }

  bool getLivePreview() {
    final toolEnabled =
        selectedTool != null && selectedTool!.supportsLiveUpdate;
    return livePreview && !chainModeEnabled && toolEnabled;
  }

  Future<void> _cancelStream() async {
    if (!_isStreaming) return;
    if (_isCancelStreaming) return;
    setState(() => _isCancelStreaming = true);
    await _streamSub?.cancel();
    setState(() {
      isProcessing = false;
      _isStreaming = false;
      _isCancelStreaming = false;
    });
    _updateStatus('Operation cancelled', ToolStatus.warning);
  }

  bool _isNearBottom() {
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    const threshold = 50.0; // pixels from bottom to still auto-scroll
    return (maxScroll - currentScroll) <= threshold;
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

  void loadAllTools() {
    toolCategories = {};

    // Add static tools
    appendCategories(getTransformTextTools());
    appendCategories(AIToolFactory.getAIToolCategories());
    appendCategories(getSplitterTools());
    appendCategories(getJsTools());
    appendCategories(getTextAnalyzerTools());
    appendCategories(getTextManipulationTools());
    appendCategories(getEncodingDecodingTools());
    appendCategories(getMiscTools());

    final tools = JsScriptService.getJsTools();
    // Add dynamic JS tools (after Hive box is ready)
    appendCategories(tools);
    appendCategories(JsScriptService.getJsAiTools());
  }

  void onLibChange() => setState(() {
    loadAllTools();
  });

  @override
  void initState() {
    super.initState();
    _initializeChainPersistence();
    //appendCategories(getTextToolCategories());
    JSChangeNotifier.instance.addListener(onLibChange);
    loadAllTools();
    inputController.addListener(_onInputChangedDebounced);
  }

  @override
  void dispose() {
    JSChangeNotifier.instance.removeListener(onLibChange);
    _debounceTimer?.cancel();
    _debounceTimer2?.cancel();
    inputController.dispose();

    scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChainPersistence() async {
    try {
      await ChainPersistenceService.initialize();
      _updateStatus('Chain persistence initialized', ToolStatus.success);
    } catch (e) {
      _updateStatus(
        'Failed to initialize chain persistence: $e',
        ToolStatus.error,
      );
    }
  }

  void _onInputChangedDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer2?.cancel();

    _debounceTimer2 = Timer(const Duration(milliseconds: 2000), () {
      setState(() {
        if (!AppSettings.countTokens) return;
        final currentInput = inputController.text;
        int count = tiktoken.encode(currentInput).length;
        inputStatus = '(token count: $count)';
      });
    });
    if (chainModeEnabled || selectedTool == null || !getLivePreview()) return;

    final currentInput = inputController.text;
    if (currentInput.isEmpty && !selectedTool!.allowEmptyInput) {
      _updateStatus('Ready', ToolStatus.idle);
      _lastProcessedInput = '';
    }

    if (currentInput == _lastProcessedInput &&
        selectedTool == _lastProcessedTool &&
        !selectedTool!.allowEmptyInput) {
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted && selectedTool != null && currentInput.isNotEmpty) {
        _executeTool();
      }
    });
  }

  void _onToolSelected(Tool tool) {
    setState(() {
      selectedTool = tool;
      statusMessage = 'Tool selected: ${tool.name}';
      currentStatus = ToolStatus.success;
      showSettings = tool.allowEmptyInput;
      if (tool.allowEmptyInput) inputController.text = '';
    });

    if (chainModeEnabled) return;

    _debounceTimer?.cancel();
    final currentInput = inputController.text;
    if ((currentInput != _lastProcessedInput || tool != _lastProcessedTool) &&
        tool.supportsLiveUpdate) {
      _debounceTimer = Timer(const Duration(milliseconds: 100), () {
        if (mounted) _executeTool();
      });
    }
  }

  void _onToolSettingsChanged(Tool tool, Map<String, dynamic> newSettings) {
    final currentInput = inputController.text;
    if (currentInput.isNotEmpty && !chainModeEnabled && livePreview) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) _executeTool();
      });
    }
    _updateStatus('Settings updated for ${tool.name}', ToolStatus.success);
  }

  Future<void> _executeTool() async {
    if (chainModeEnabled) {
      await _executeChain();
      return;
    }
    if (selectedTool == null) return;

    final input = inputController.text;
    if (input.isEmpty && !selectedTool!.allowEmptyInput) {
      _updateStatus('No input provided', ToolStatus.warning);
      return;
    }

    // Cancel previous stream if any
    await _streamSub?.cancel();

    final currentExecutionId = ++_executionCounter;

    setState(() {
      isProcessing = true;
      _isStreaming = false;
      output = ''; // clear previous
    });
    _updateStatus(
      'Processing with ${selectedTool!.name}...',
      ToolStatus.processing,
    );

    try {
      // Check if tool supports streaming
      if (selectedTool!.supportsStreaming) {
        _isCancelStreaming = false;
        final stream = selectedTool!.executeStream(input);
        if (stream != null) {
          // STREAMING EXECUTION
          _isStreaming = true;
          _streamSub = stream.listen(
            (chunk) {
              if (currentExecutionId != _executionCounter || !mounted) return;
              setState(() {
                output += chunk;
                isOutputMD =
                    selectedTool!.isOutputMarkdown; // Set markdown flag
              });
              //Only auto-scroll if user is near bottom
              if (_isNearBottom()) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  scrollController.jumpTo(
                    scrollController.position.maxScrollExtent,
                  );
                });
              }
            },
            onError: (error) {
              if (currentExecutionId != _executionCounter || !mounted) return;
              setState(() {
                output = '### Error\n```\n$error\n```';
                isOutputMD = true;
              });
              _updateStatus(
                'Error in ${selectedTool!.name}: $error',
                ToolStatus.error,
              );
            },
            onDone: () {
              if (currentExecutionId != _executionCounter || !mounted) return;
              setState(() {
                isProcessing = false;
                _isStreaming = false;
              });
              _updateStatus(
                '${selectedTool!.name} completed',
                ToolStatus.success,
              );
            },
            cancelOnError: true,
          );
        } else {
          // Fallback to normal execution if stream is null
          await _executeNormal(input, currentExecutionId);
        }
      } else {
        // NORMAL EXECUTION
        await _executeNormal(input, currentExecutionId);
      }
    } catch (error) {
      if (currentExecutionId != _executionCounter || !mounted) return;
      setState(() {
        output = '### Error\n```\n$error\n```';
        isOutputMD = true;
        isProcessing = false;
      });
      _updateStatus('Error in ${selectedTool!.name}: $error', ToolStatus.error);
    }
  }

  Future<void> _executeNormal(String input, int currentExecutionId) async {
    final result = await selectedTool!.execute(input);
    if (currentExecutionId != _executionCounter || !mounted) return;

    setState(() {
      output = result.output;
      isOutputMD = selectedTool!.isOutputMarkdown;
      isProcessing = false;
    });
    _updateStatus(
      '${selectedTool!.name}: ${result.status ?? 'Completed'}',
      ToolStatus.success,
    );
  }

  Future<void> _executeChain() async {
    final input = inputController.text;
    if (input.isEmpty) {
      _updateStatus(
        'No input provided for chain execution',
        ToolStatus.warning,
      );
      return;
    }

    if (_chainedTools.isEmpty) {
      _updateStatus('No tools in chain', ToolStatus.warning);
      return;
    }

    if (isChainExecuting) return;

    setState(() {
      isChainExecuting = true;
      isProcessing = true;
    });

    _updateStatus('Executing tool chain...', ToolStatus.processing);

    try {
      final executions = await ChainExecutor.executeChain(_chainedTools, input);

      if (!mounted) return;

      if (executions.isNotEmpty) {
        final lastExecution = executions.last;
        setState(() {
          output = lastExecution.success
              ? lastExecution.output
              : '### Chain Execution Failed\n```\n${lastExecution.errorMessage ?? 'Unknown error'}\n```';
          isOutputMD = lastExecution.success
              ? _chainedTools.last.tool.isOutputMarkdown
              : true;
        });

        if (lastExecution.success) {
          _updateStatus(
            'Chain executed successfully (${executions.length} tools)',
            ToolStatus.success,
          );
        } else {
          _updateStatus(
            'Chain execution failed at step ${executions.length}',
            ToolStatus.error,
          );
        }
      } else {
        setState(() {
          output =
              '### No Tools Executed\nNo tools were processed in this chain.';
          isOutputMD = true;
        });
        _updateStatus(
          'Chain execution completed but no tools ran',
          ToolStatus.warning,
        );
      }

      setState(() {});
    } catch (error) {
      if (!mounted) return;

      setState(() {
        output = '### Chain Execution Error\n```\n$error\n```';
        isOutputMD = true;
      });
      _updateStatus('Chain execution error: $error', ToolStatus.error);
    } finally {
      if (mounted) {
        setState(() {
          isChainExecuting = false;
          isProcessing = false;
        });
      }
    }
  }

  Future<void> _executeChainUntil(int index) async {
    final input = inputController.text;
    if (input.isEmpty) {
      _updateStatus(
        'No input provided for partial chain execution',
        ToolStatus.warning,
      );
      return;
    }

    if (_chainedTools.isEmpty || index >= _chainedTools.length) {
      _updateStatus('Invalid chain execution range', ToolStatus.warning);
      return;
    }

    if (isChainExecuting) return;

    setState(() {
      isChainExecuting = true;
      isProcessing = true;
    });

    _updateStatus(
      'Executing chain until step ${index + 1}...',
      ToolStatus.processing,
    );

    try {
      final toolsToExecute = _chainedTools.take(index + 1).toList();
      final executions = await ChainExecutor.executeChain(
        toolsToExecute,
        input,
      );

      if (!mounted) return;

      if (executions.isNotEmpty) {
        final lastExecution = executions.last;
        setState(() {
          output = lastExecution.success
              ? lastExecution.output
              : '### Partial Chain Execution Failed\n```\n${lastExecution.errorMessage ?? 'Unknown error'}\n```';
          isOutputMD = lastExecution.success
              ? toolsToExecute.last.tool.isOutputMarkdown
              : true;
        });

        if (lastExecution.success) {
          _updateStatus(
            'Partial chain executed successfully (${executions.length}/${index + 1} tools)',
            ToolStatus.success,
          );
        } else {
          _updateStatus(
            'Partial chain execution failed at step ${executions.length}',
            ToolStatus.error,
          );
        }
      }

      setState(() {});
    } catch (error) {
      if (!mounted) return;

      setState(() {
        output = '### Partial Chain Execution Error\n```\n$error\n```';
        isOutputMD = true;
      });
      _updateStatus('Partial chain execution error: $error', ToolStatus.error);
    } finally {
      if (mounted) {
        setState(() {
          isChainExecuting = false;
          isProcessing = false;
        });
      }
    }
  }

  // Chain persistence methods
  Future<void> _saveCurrentChain() async {
    if (_chainedTools.isEmpty) {
      _updateStatus('No tools to save', ToolStatus.warning);
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ChainSaveDialog(existingChain: _currentLoadedChain),
    );

    if (result != null) {
      try {
        if (_currentLoadedChain != null) {
          // Update existing chain
          _currentLoadedChain!.name = result['name'];
          _currentLoadedChain!.description = result['description'];
          _currentLoadedChain!.category = result['category'];
          _currentLoadedChain!.tags = result['tags'];
          _currentLoadedChain!.tools = _chainedTools
              .map((ct) => SavedTool.fromChainedTool(ct))
              .toList();

          await ChainPersistenceService.updateChain(_currentLoadedChain!);
          _updateStatus(
            'Chain "${_currentLoadedChain!.name}" updated successfully',
            ToolStatus.success,
          );
        } else {
          // Save new chain
          final newChain = SavedChain.fromChainedTools(
            _chainedTools,
            name: result['name'],
            description: result['description'],
            category: result['category'],
            tags: result['tags'],
          );

          await ChainPersistenceService.saveChain(newChain);
          setState(() {
            _currentLoadedChain = newChain;
          });
          _updateStatus(
            'Chain "${newChain.name}" saved successfully',
            ToolStatus.success,
          );
        }
      } catch (e) {
        _updateStatus('Failed to save chain: $e', ToolStatus.error);
      }
    }
  }

  Future<void> _loadChain() async {
    final selectedChain = await showDialog<SavedChain>(
      context: context,
      builder: (context) => const ChainLibraryDialog(),
    );

    if (selectedChain != null) {
      try {
        final chainedTools = selectedChain.toChainedTools(toolCategories);
        setState(() {
          _chainedTools = chainedTools;
          _currentLoadedChain = selectedChain;
          chainModeEnabled = true; // Switch to chain mode
        });
        _updateStatus(
          'Loaded chain "${selectedChain.name}" with ${chainedTools.length} tools',
          ToolStatus.success,
        );
      } catch (e) {
        _updateStatus('Failed to load chain: $e', ToolStatus.error);
      }
    }
  }

  void _newChain() {
    setState(() {
      _chainedTools = [];
      _currentLoadedChain = null;
      chainModeEnabled = true;
    });
    _updateStatus('New chain created', ToolStatus.success);
  }

  void _updateStatus(String message, ToolStatus status) {
    if (!mounted) return;
    setState(() {
      statusMessage = message;
      currentStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isMobile = screenWidth < 768;

    return Scaffold(
      body: Column(
        children: [
          // Top toolbar - responsive layout
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 4.0 : 8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: _buildToolbar(context, isMobile, isTablet),
          ),

          // Main content area - responsive layout
          Expanded(
            child: Container(
              child: _buildMainContent(context, isDesktop, isTablet, isMobile),
            ),
          ),

          // Status bar
          StatusBar(
            leftText: statusMessage,
            centerText: inputController.text.isNotEmpty
                ? 'Characters: ${inputController.text.length}'
                : '',
            rightText: chainModeEnabled
                ? (isChainExecuting
                      ? 'Executing chain...'
                      : '${_chainedTools.where((t) => t.enabled).length}/${_chainedTools.length} tools ready')
                : (selectedTool != null && !isProcessing
                      ? 'Ready'
                      : isProcessing
                      ? 'Processing...'
                      : 'No tool selected'),
            status: currentStatus,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, bool isMobile, bool isTablet) {
    final theme = Theme.of(context);

    if (isMobile) {
      // Mobile: Stack vertically for more space
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First row: Mode toggle and actions
          Row(
            children: [
              Tooltip(
                message: chainModeEnabled
                    ? 'Switch to single tool mode'
                    : 'Switch to chain mode',
                child: IconButton(
                  icon: Icon(
                    chainModeEnabled ? Icons.link : Icons.link_off,
                    size: 20,
                    color: chainModeEnabled ? theme.colorScheme.primary : null,
                  ),
                  onPressed: () {
                    setState(() => chainModeEnabled = !chainModeEnabled);
                    _updateStatus(
                      chainModeEnabled
                          ? 'Chain mode enabled'
                          : 'Single tool mode enabled',
                      ToolStatus.idle,
                    );
                  },
                ),
              ),
              if (chainModeEnabled) ...[
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: _newChain,
                  tooltip: 'New chain',
                ),
                IconButton(
                  icon: const Icon(Icons.save, size: 20),
                  onPressed: _chainedTools.isNotEmpty
                      ? _saveCurrentChain
                      : null,
                  tooltip: 'Save chain',
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open, size: 20),
                  onPressed: _loadChain,
                  tooltip: 'Load chain',
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          // Second row: Tool selection or chain info
          if (!chainModeEnabled)
            CategoryToolBar(
              categories: toolCategories,
              initialCategory: 'Basic',
              liveUpdate: getLivePreview(),
              onToolSelected: _onToolSelected,
              onToolSettingsChanged: _onToolSettingsChanged,
              useEmbeddedSettings: true,
              showSettings: !showSettings,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentLoadedChain != null
                        ? 'Chain: ${_currentLoadedChain!.name}'
                        : 'Chain Mode Active',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _currentLoadedChain != null
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_currentLoadedChain != null)
                    Text(
                      '${_chainedTools.length} tools',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.disabledColor,
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
    }

    // Desktop/Tablet: Horizontal layout
    return Row(
      children: [
        Tooltip(
          message: chainModeEnabled
              ? 'Switch to single tool mode'
              : 'Switch to chain mode',
          child: IconButton(
            icon: Icon(
              chainModeEnabled ? Icons.link : Icons.link_off,
              size: 24,
              color: chainModeEnabled ? theme.colorScheme.primary : null,
            ),
            onPressed: () {
              setState(() => chainModeEnabled = !chainModeEnabled);
              _updateStatus(
                chainModeEnabled
                    ? 'Chain mode enabled'
                    : 'Single tool mode enabled',
                ToolStatus.idle,
              );
            },
          ),
        ),
        if (chainModeEnabled) ...[
          Tooltip(
            message: 'New chain',
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _newChain,
            ),
          ),
          Tooltip(
            message: 'Save chain',
            child: IconButton(
              icon: const Icon(Icons.save),
              onPressed: _chainedTools.isNotEmpty ? _saveCurrentChain : null,
            ),
          ),
          Tooltip(
            message: 'Load chain',
            child: IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: _loadChain,
            ),
          ),
        ],
        if (!chainModeEnabled)
          Expanded(
            child: CategoryToolBar(
              categories: toolCategories,
              initialCategory: 'Basic',
              liveUpdate: getLivePreview(),
              onToolSelected: _onToolSelected,
              onToolSettingsChanged: _onToolSettingsChanged,
              useEmbeddedSettings: true,
              showSettings: !showSettings,
            ),
          )
        else
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    _currentLoadedChain != null
                        ? 'Chain: ${_currentLoadedChain!.name}'
                        : 'Chain Mode: Add and execute tools in sequence',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _currentLoadedChain != null
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                      fontWeight: _currentLoadedChain != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  if (_currentLoadedChain != null) ...[
                    const Spacer(),
                    Text(
                      '${_chainedTools.length} tools',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.disabledColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  void onSaveJs(BuildContext context) {
    final jsCodeRegex = RegExp(
      r'```(?:js|javascript)\s*([\s\S]*)```',
      multiLine: true,
      dotAll: true,
    );

    final match = jsCodeRegex.firstMatch(output);
    final jsCode = match?.group(1)?.trim() ?? '';

    if (jsCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No JS code found in output')),
      );
      return;
    }

    JsScriptLibraryHelper.showAddScriptDialog(
      context,
      scriptText: jsCode,
      category: 'Js Tools',
      onSaved: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            loadAllTools();
          });
        });
      },
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    if (isMobile) {
      // Mobile: Vertical stack with chain panel as modal/drawer
      return Column(
        children: [
          if (chainModeEnabled)
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              child: ElevatedButton.icon(
                onPressed: () => _showChainPanel(context),
                icon: const Icon(Icons.list, size: 16),
                label: Text('Manage Chain (${_chainedTools.length} tools)'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ),
          showSettings && selectedTool != null && selectedTool!.allowEmptyInput
              ? _buildSettingsPanel(context)
              : Expanded(
                  flex: 1,
                  child: IOCard(
                    label: "Input",
                    isOutput: false,
                    isCancelStreaming: _isCancelStreaming,
                    isStreaming: _isStreaming,
                    onCancelStreaming: () => _cancelStream(),
                    controller: inputController,
                    onExecute: _executeTool,
                    statusMessage: inputStatus,
                  ),
                ),
          const SizedBox(height: 2),
          Expanded(
            flex: 1,
            child: IOCard(
              label: "Output",
              isOutput: true,
              isCancelStreaming: _isCancelStreaming,
              format: isOutputMD ? IOFormat.markdown : IOFormat.text,
              livePreview: getLivePreview(),
              isStreaming: _isStreaming,
              onCancelStreaming: () => _cancelStream(),
              onSaveJS: () => onSaveJs(context),
              showSaveJSButton:
                  selectedTool != null &&
                  selectedTool!.name == 'Tool Generator',
              content: output,
              scrollController: scrollController,
              onLivePreviewChanged: (value) => setState(() {
                livePreview = value;
                if (!chainModeEnabled) _executeTool();
              }),
            ),
          ),
        ],
      );
    }

    // Desktop/Tablet: Horizontal layout
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chainModeEnabled)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ChainToolsPanel(
              tools: _chainedTools,
              onChanged: (newTools) => setState(() => _chainedTools = newTools),
              onToolSettingsChanged: (chainedTool, settings) => setState(() {}),
              onExecute: (_) => _executeChain(),
              onExecuteUntil: (index, _) => _executeChainUntil(index),
              toolCategories: toolCategories,
            ),
          ),
        showSettings && selectedTool != null && selectedTool!.allowEmptyInput
            ? _buildSettingsPanel(context)
            : Expanded(
                flex: isDesktop ? 1 : 1,
                child: IOCard(
                  label: "Input",
                  isOutput: false,
                  isCancelStreaming: _isCancelStreaming,
                  isStreaming: _isStreaming,
                  controller: inputController,
                  onCancelStreaming: () => _cancelStream(),
                  livePreview: getLivePreview(),
                  onExecute: _executeTool,
                  statusMessage: inputStatus,
                ),
              ),
        const SizedBox(width: 8),
        Expanded(
          flex: isDesktop ? 1 : 1,
          child: IOCard(
            label: "Output",
            isOutput: true,
            isCancelStreaming: _isCancelStreaming,
            format: isOutputMD ? IOFormat.markdown : IOFormat.text,
            livePreview: getLivePreview(),
            onCancelStreaming: () => _cancelStream(),
            onSaveJS: () => onSaveJs(context),
            showSaveJSButton:
                selectedTool != null && selectedTool!.name == 'Tool Generator',
            isStreaming: _isStreaming,
            content: output,
            scrollController: scrollController,
            onLivePreviewChanged: (value) => setState(() {
              livePreview = value;
              if (!chainModeEnabled) _executeTool();
            }),
          ),
        ),
      ],
    );
  }

  void _showChainPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Chain Tools',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ChainToolsPanel(
                tools: _chainedTools,
                onChanged: (newTools) =>
                    setState(() => _chainedTools = newTools),
                onToolSettingsChanged: (chainedTool, settings) =>
                    setState(() {}),
                onExecute: (_) {
                  Navigator.pop(context);
                  _executeChain();
                },
                onExecuteUntil: (index, _) {
                  Navigator.pop(context);
                  _executeChainUntil(index);
                },
                toolCategories: toolCategories,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
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
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SizedBox(
              width: 500,
              child: SettingsEditor(
                settings: Map<String, dynamic>.from(selectedTool!.settings),
                showApplyButton: false,
                settingsHints: selectedTool?.settingsHints,
                liveUpdate: true,
                useColumnMode: true,
                onChanged: (newSettings) {
                  selectedTool!.settings.clear();
                  selectedTool!.settings.addAll(newSettings);
                  _onToolSettingsChanged(selectedTool!, newSettings);
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(width: 500, child: _buildProcess(context)),
        ],
      ),
    );
  }

  Widget _buildProcess(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(child: const SizedBox()),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 6),
          child: Align(
            alignment: Alignment.centerRight,
            child: _isStreaming
                ? Tooltip(
                    message: 'Cancel streaming',
                    child: ElevatedButton(
                      onPressed: _isCancelStreaming ? null : _cancelStream,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: const Size(80, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),

                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    shape:
                                        BoxShape.rectangle, // square stop icon
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Cancel'),
                        ],
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _executeTool,
                    child: const Text('Process'),
                  ),
          ),
        ),
      ],
    );
  }
}
