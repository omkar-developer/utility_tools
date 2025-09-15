import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:utility_tools/models/js_script_model.dart';
import 'package:utility_tools/services/ai_service.dart';
import 'package:utility_tools/services/file_converter.dart';
import 'package:utility_tools/services/js_script_service.dart';
import 'package:utility_tools/text_tools/js_ai_tool.dart';
import 'package:utility_tools/text_tools/js_tool.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:archive/archive.dart';

class JsScriptLibraryDialog extends StatefulWidget {
  const JsScriptLibraryDialog({super.key});

  @override
  State<JsScriptLibraryDialog> createState() => _JsScriptLibraryDialogState();
}

class _JsScriptLibraryDialogState extends State<JsScriptLibraryDialog> {
  List<JsScript> _scripts = [];
  String _selectedCategory = 'All';
  JsScriptType? _selectedType;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadScripts();
  }

  void _loadScripts() {
    setState(() {
      _scripts = JsScriptService.getAllScripts();
    });
  }

  List<JsScript> get _filteredScripts {
    var filtered = _scripts;

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where(
            (script) =>
                script.name.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                script.description.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ),
          )
          .toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((script) => script.category == _selectedCategory)
          .toList();
    }

    // Filter by type
    if (_selectedType != null) {
      filtered = filtered
          .where((script) => script.type == _selectedType)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...JsScriptService.getAllCategories()];

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.library_books, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'JavaScript Tools Library',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add),
                  tooltip: 'Add New Script',
                ),
                IconButton(
                  onPressed: () => _importScript(),
                  icon: const Icon(Icons.upload_file),
                  tooltip: 'Import Script',
                ),
                IconButton(
                  onPressed: () => _importScriptsFromZip(context),
                  icon: const Icon(Icons.drive_folder_upload),
                  tooltip: 'Import scripts from ZIP',
                ),
                IconButton(
                  onPressed: () => _exportScriptsAsZip(context, _scripts),
                  icon: const Icon(Icons.download),
                  tooltip: 'Export scripts as ZIP',
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),

            // Filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search scripts...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value!),
                ),
                const SizedBox(width: 8),
                DropdownButton<JsScriptType?>(
                  value: _selectedType,
                  hint: const Text('Type'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Types'),
                    ),
                    ...JsScriptType.values.map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedType = value),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scripts List
            Expanded(
              child: _filteredScripts.isEmpty
                  ? const Center(
                      child: Text(
                        'No scripts found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredScripts.length,
                      itemBuilder: (context, index) {
                        final script = _filteredScripts[index];
                        return _ScriptCard(
                          script: script,
                          onEdit: () => _showAddEditDialog(script),
                          onDelete: () => _deleteScript(script),
                          onDuplicate: () => _duplicateScript(script),
                          onExport: () => _exportScript(context, script),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog([JsScript? script]) {
    showDialog(
      context: context,
      builder: (context) => AddEditScriptDialog(
        script: script,
        onSave: (savedScript) {
          _loadScripts();
        },
      ),
    );
  }

  void _deleteScript(JsScript script) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Script'),
        content: Text('Are you sure you want to delete "${script.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await JsScriptService.deleteScript(script.id);
              _loadScripts();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _duplicateScript(JsScript script) async {
    final duplicate = JsScript.fromScript(
      script.script,
      category: script.category,
    );
    duplicate.name = '${script.name} (Copy)';
    await JsScriptService.saveScript(duplicate);
    _loadScripts();
  }

  void _importScript() async {
    final str = await FileExporter.openFile(maxLength: 128000);
    if (str.isEmpty) return;

    try {
      final lines = str.split('\n');
      String? id;

      // Check for UUID on the first line
      if (lines.isNotEmpty && lines.first.startsWith('//uuid:')) {
        id = lines.first.substring('//uuid:'.length).trim();
        lines.removeAt(0); // remove the uuid comment
      }

      final scriptBody = lines.join('\n');
      final script = JsScript.fromScript(scriptBody);

      // Override with existing id if found
      if (id != null && id.isNotEmpty) {
        script.id = id;
      }

      await JsScriptService.saveScript(script);
      _loadScripts();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Script imported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing script: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importScriptsFromZip(BuildContext context) async {
    try {
      final bytes = await FileExporter.openBinaryFile();
      if (bytes == null) return;

      final archive = ZipDecoder().decodeBytes(bytes);

      final importedScripts = <JsScript>[];
      final failedFiles = <String>[];

      for (final file in archive) {
        if (file.isFile && file.name.endsWith('.js')) {
          try {
            var content = String.fromCharCodes(file.content as List<int>);
            String? extractedId;

            // Check for //uuid:<id> at the very top
            final uuidPattern = RegExp(r'^//uuid:([^\r\n]+)');
            final match = uuidPattern.firstMatch(content);
            if (match != null) {
              extractedId = match.group(1);
              // Remove uuid line before parsing as script
              content = content.substring(match.end).trimLeft();
            }

            final script = JsScript.fromScript(content);

            // Restore existing UUID if present, else generate new
            if (extractedId != null) {
              script.id = extractedId;
            }

            importedScripts.add(script);
          } catch (e) {
            failedFiles.add(file.name);
          }
        }
      }

      for (final script in importedScripts) {
        await JsScriptService.saveScript(script); // overwrites if same id
      }

      _loadScripts();

      if (context.mounted) {
        String message = 'Imported ${importedScripts.length} scripts from ZIP';
        if (failedFiles.isNotEmpty) {
          message += '\nFailed to import: ${failedFiles.join(', ')}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing scripts from ZIP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

Future<void> _exportScript(BuildContext context, JsScript script) async {
  try {
    final filename = '${script.name}.js';

    final content = '//uuid:${script.id}\n${script.script}';

    await FileExporter.saveTextFile(content, filename);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File saved as $filename'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _exportScriptsAsZip(
  BuildContext context,
  List<JsScript> scripts,
) async {
  try {
    final archive = Archive();

    for (final script in scripts) {
      // Prepend UUID as comment at the top
      final content = '//uuid:${script.id}\n${script.script}';
      final bytes = Uint8List.fromList(content.codeUnits);

      // Save inside "scripts_library/" folder
      final filename = 'scripts_library/${script.name}.js';
      archive.addFile(ArchiveFile(filename, bytes.length, bytes));
    }

    // Encode archive to ZIP
    final zipData = Uint8List.fromList(ZipEncoder().encode(archive)!);

    // Save the file
    await FileExporter.saveBinaryFile(zipData, 'scripts_library.zip');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scripts saved as zip'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving Scripts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _ScriptCard extends StatelessWidget {
  final JsScript script;
  final VoidCallback onEdit;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _ScriptCard({
    required this.script,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  script.type == JsScriptType.ai
                      ? Icons.psychology
                      : Icons.extension,
                  color: script.type == JsScriptType.ai
                      ? Colors.purple
                      : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    script.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    script.type.name.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: script.type == JsScriptType.ai
                      ? Colors.purple.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'export':
                        onExport();
                        break;
                      case 'duplicate':
                        onDuplicate();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'export', child: Text('Export')),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Text('Duplicate'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            if (script.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                script.description,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(script.category),
                  backgroundColor: Colors.grey[800],
                ),
                const Spacer(),
                Text(
                  'Updated: ${script.updatedAt.toString().substring(0, 16)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the library dialog
class JsScriptLibraryHelper {
  static Future<void> showAddScriptDialog(
    BuildContext context, {
    JsScript? script,
    String? category,
    String? scriptText,
    Function()? onSaved,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AddEditScriptDialog(
        script: script,
        initialScriptText: scriptText,
        initialCategory: category,
        onSave: (savedScript) {
          // close dialog
        },
      ),
    );

    // After the dialog is closed, call the callback
    onSaved?.call();
  }

  static Future<void> showLibraryDialog(
    BuildContext context, {
    Function()? callback,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => const JsScriptLibraryDialog(),
    );
    callback?.call();
  }

  static Widget buildLibraryButton(
    BuildContext context, {
    Function()? callback,
  }) {
    return IconButton(
      onPressed: () => showLibraryDialog(context, callback: callback),
      icon: const Icon(Icons.library_books),
      tooltip: 'Manage JS Script Library',
    );
  }
}

class AddEditScriptDialog extends StatefulWidget {
  final JsScript? script;
  final String? initialScriptText;
  final String? initialCategory;
  final Function(JsScript) onSave;

  const AddEditScriptDialog({
    super.key,
    this.script,
    this.initialScriptText,
    this.initialCategory,
    required this.onSave,
  });

  @override
  State<AddEditScriptDialog> createState() => _AddEditScriptDialogState();
}

class _AddEditScriptDialogState extends State<AddEditScriptDialog> {
  final _formKey = GlobalKey<FormState>();
  late final CodeController _codeController;
  final _categoryController = TextEditingController();
  final _aiPromptController = TextEditingController();
  final _scrollController = ScrollController();

  String _detectedName = '';
  String _detectedDescription = '';
  JsScriptType _detectedType = JsScriptType.regular;

  // AI-related state
  late final AIService _aiService;
  bool _isAiProcessing = false;
  final List<ChatMessage> _aiChatHistory = [];
  String? _currentAiRequest;

  @override
  void initState() {
    super.initState();

    // Initialize AI service
    _aiService = AIService.fromAppSettings();

    // Initialize code controller with JavaScript syntax highlighting
    _codeController = CodeController(
      text: _getInitialScript(),
      language: javascript,
    );

    // Initialize category
    _categoryController.text =
        widget.script?.category ?? widget.initialCategory ?? '';

    // Set up listeners
    _codeController.addListener(_updateDetectedInfo);
    _updateDetectedInfo();
  }

  String _getInitialScript() {
    if (widget.script != null) {
      return widget.script!.script;
    } else if (widget.initialScriptText != null) {
      return widget.initialScriptText!;
    }
    return '';
  }

  void _updateDetectedInfo() {
    final script = _codeController.text;
    setState(() {
      _detectedName = JsScript.extractNameFromScript(script);
      _detectedDescription = JsScript.extractDescriptionFromScript(script);
      _detectedType = JsScript.detectScriptType(script);
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _categoryController.dispose();
    _aiPromptController.dispose();
    _scrollController.dispose();
    _aiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = JsScriptService.getAllCategories();

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Text(
                    widget.script == null ? 'Add New Script' : 'Edit Script',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_isAiProcessing)
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Processing...',
                          style: TextStyle(
                            color: Colors.blue[400],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.cancel, size: 18),
                          onPressed: _cancelAiRequest,
                          tooltip: 'Cancel AI Request',
                        ),
                      ],
                    ),
                ],
              ),
              const Divider(),

              // Detected info
              if (_detectedName.isNotEmpty) ...[
                Card(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detected: $_detectedName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_detectedDescription.isNotEmpty)
                                Text('Description: $_detectedDescription'),
                              Text('Type: ${_detectedType.name.toUpperCase()}'),
                            ],
                          ),
                        ),
                        Icon(
                          _detectedType == JsScriptType.ai
                              ? Icons.psychology
                              : Icons.code,
                          color: _detectedType == JsScriptType.ai
                              ? Colors.purple
                              : Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Category field
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Please enter a category';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    hint: const Text('Quick'),
                    items: categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _categoryController.text = value;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Code editor section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'JavaScript Code',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CodeTheme(
                          data: CodeThemeData(
                            styles:
                                Theme.of(context).brightness == Brightness.dark
                                ? atomOneDarkTheme
                                : githubTheme,
                          ),
                          child: CodeField(
                            controller: _codeController,
                            expands: true,
                            maxLines: null,
                            textStyle: TextStyle(
                              fontSize: 14,
                              fontFamily: 'monospace',
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // AI Chat section
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Chat header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.psychology,
                                  size: 16,
                                  color: Colors.purple[400],
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'AI Code Assistant',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                if (_aiChatHistory.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear_all, size: 16),
                                    onPressed: _clearAiHistory,
                                    tooltip: 'Clear Chat History',
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                              ],
                            ),
                          ),

                          // Chat history
                          Expanded(
                            child: _aiChatHistory.isEmpty
                                ? Center(
                                    child: Text(
                                      'Ask AI to help improve your script',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _aiChatHistory.length,
                                    itemBuilder: (context, index) {
                                      final message = _aiChatHistory[index];
                                      final isUser = message.role == 'user';

                                      return Align(
                                        alignment: isUser
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 2,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          constraints: BoxConstraints(
                                            maxWidth:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            message.content,
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          // Chat input
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _aiPromptController,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Ask AI to modify your script...',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 2,
                                    minLines: 1,
                                    enabled: !_isAiProcessing,
                                    onSubmitted: (_) => _processAiRequest(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    _isAiProcessing ? Icons.stop : Icons.send,
                                    size: 16,
                                  ),
                                  onPressed: _isAiProcessing
                                      ? _cancelAiRequest
                                      : _processAiRequest,
                                  tooltip: _isAiProcessing
                                      ? 'Cancel'
                                      : 'Send to AI',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  TextButton(
                    onPressed: _isAiProcessing
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isAiProcessing ? null : _saveScript,
                    child: Text(widget.script == null ? 'Add' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processAiRequest() async {
    final prompt = _aiPromptController.text.trim();
    if (prompt.isEmpty || _isAiProcessing) return;

    setState(() {
      _isAiProcessing = true;
      _currentAiRequest = prompt;
    });

    // Add user message to history
    _aiChatHistory.add(ChatMessage.text(role: 'user', text: prompt));
    _aiPromptController.clear();

    try {
      final currentCode = _codeController.text;
      final systemPrompt = _buildAiSystemPrompt();
      final userMessage = _buildAiUserMessage(prompt, currentCode);

      final messages = [
        ChatMessage.text(role: 'system', text: systemPrompt),
        ..._aiChatHistory.where((m) => m.role != 'system'),
        ChatMessage.text(role: 'user', text: userMessage),
      ];

      final response = await _aiService.complete(prompt, messages: messages);

      if (!mounted) return;

      // Add AI response to history
      _aiChatHistory.add(
        ChatMessage.text(role: 'assistant', text: response.content),
      );

      // Try to extract and apply code changes
      _applyAiCodeChanges(response.content);
    } catch (e) {
      if (mounted) {
        _aiChatHistory.add(
          ChatMessage.text(role: 'assistant', text: 'Error: $e'),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAiProcessing = false;
          _currentAiRequest = null;
        });
      }
    }
  }

  void _cancelAiRequest() {
    setState(() {
      _isAiProcessing = false;
      _currentAiRequest = null;
    });
    // Note: AIService should support cancellation if needed
  }

  void _clearAiHistory() {
    setState(() {
      _aiChatHistory.clear();
    });
    _aiService.clearHistory();
  }

  String _buildAiSystemPrompt() {
    return '''You are a JavaScript code assistant helping to improve and modify JavaScript tool scripts.

Current script type: ${_detectedType.name}
Current script name: $_detectedName
Current script description: $_detectedDescription

Your role:
1. Help improve, debug, and modify JavaScript code
2. Suggest best practices and optimizations  
3. Add comments and documentation
4. Fix syntax and logic errors
5. When providing code changes, wrap the complete updated code in ```javascript code blocks

Keep responses concise and focused on the requested changes.''';
  }

  String _buildAiUserMessage(String prompt, String currentCode) {
    return '''User request: $prompt

Current JavaScript code:
```javascript
$currentCode
```

Please help with the requested changes.''';
  }

  void _applyAiCodeChanges(String aiResponse) {
    // Extract JavaScript code blocks from AI response
    final codeBlockRegex = RegExp(
      r'```javascript\s*\n(.*?)\n```',
      multiLine: true,
      dotAll: true,
    );

    final matches = codeBlockRegex.allMatches(aiResponse);

    if (matches.isNotEmpty) {
      // Use the first (or largest) code block found
      String newCode = matches.first.group(1)?.trim() ?? '';

      if (newCode.isNotEmpty) {
        // Apply the new code
        _codeController.text = newCode;
        _updateDetectedInfo();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI changes applied to code'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _saveScript() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final scriptText = _codeController.text;

      // Test if script compiles by trying to create the actual tool
      try {
        if (_detectedType == JsScriptType.ai) {
          JsAiTool.fromScript(scriptText);
        } else {
          JsTool.fromScript(scriptText);
        }
      } catch (toolError) {
        rethrow;
      }

      // If we get here, script is valid - proceed with save
      JsScript script;
      if (widget.script == null) {
        script = JsScript.fromScript(
          scriptText,
          category: _categoryController.text.trim(),
        );
      } else {
        script = widget.script!;
        script.category = _categoryController.text.trim();
        script.updateScript(scriptText);
      }

      await JsScriptService.saveScript(script);
      widget.onSave(script);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.script == null
                ? 'Script added successfully'
                : 'Script updated successfully',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Script Error: $e'),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
