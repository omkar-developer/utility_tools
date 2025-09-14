import 'package:flutter/material.dart';
import 'package:utility_tools/models/tool.dart';
import 'settings_editor.dart';

class ChainToolsPanel extends StatefulWidget {
  final List<ChainedTool> tools;
  final void Function(List<ChainedTool>) onChanged;
  final void Function(List<ChainedTool>) onExecute;
  final void Function(int, List<ChainedTool>) onExecuteUntil;
  final void Function(ChainedTool, Map<String, dynamic>) onToolSettingsChanged;
  final Map<String, List<Tool Function()>> toolCategories;

  const ChainToolsPanel({
    super.key,
    required this.tools,
    required this.onChanged,
    required this.onExecute,
    required this.onExecuteUntil,
    required this.onToolSettingsChanged,
    required this.toolCategories,
  });

  @override
  State<ChainToolsPanel> createState() => _ChainToolsPanelState();
}

class _ChainToolsPanelState extends State<ChainToolsPanel> {
  bool _collapsed = false;
  int? _selectedIndex;

  void _toggleCollapse() {
    setState(() => _collapsed = !_collapsed);
  }

  void _addTool(Tool tool) {
    final chainedTool = ChainedTool(
      tool: tool,
      id: '${DateTime.now().millisecondsSinceEpoch}_${tool.name}',
    );
    final newList = [...widget.tools, chainedTool];
    widget.onChanged(newList);
  }

  void _removeTool() {
    if (_selectedIndex == null) return;
    final newList = [...widget.tools]..removeAt(_selectedIndex!);
    widget.onChanged(newList);
    setState(() => _selectedIndex = null);
  }

  void _moveUp() {
    if (_selectedIndex == null || _selectedIndex == 0) return;
    final newList = [...widget.tools];
    final item = newList.removeAt(_selectedIndex!);
    newList.insert(_selectedIndex! - 1, item);
    widget.onChanged(newList);
    setState(() => _selectedIndex = _selectedIndex! - 1);
  }

  void _moveDown() {
    if (_selectedIndex == null || _selectedIndex == widget.tools.length - 1) {
      return;
    }
    final newList = [...widget.tools];
    final item = newList.removeAt(_selectedIndex!);
    newList.insert(_selectedIndex! + 1, item);
    widget.onChanged(newList);
    setState(() => _selectedIndex = _selectedIndex! + 1);
  }

  void _toggleTool() {
    if (_selectedIndex == null) return;
    final newList = [...widget.tools];
    final chainedTool = newList[_selectedIndex!];
    newList[_selectedIndex!] = chainedTool.copyWith(
      enabled: !chainedTool.enabled,
    );
    widget.onChanged(newList);
  }

  void _clearExecutionHistory() {
    if (_selectedIndex == null) return;
    final chainedTool = widget.tools[_selectedIndex!];
    chainedTool.executions.clear();
    setState(() {});
  }

  void _clearAllExecutionHistory() {
    for (final tool in widget.tools) {
      tool.executions.clear();
    }
    setState(() {});
  }

  void _showToolSettings() async {
    if (_selectedIndex == null) return;
    final chainedTool = widget.tools[_selectedIndex!];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SettingsDialog(
        title: '${chainedTool.tool.name} Settings',
        settingsHints: chainedTool.tool.settingsHints,
        settings: Map<String, dynamic>.from(chainedTool.tool.settings),
      ),
    );

    if (result != null) {
      chainedTool.tool.settings
        ..clear()
        ..addAll(result);
      widget.onToolSettingsChanged(chainedTool, result);
    }
  }

  void _showExecutionHistory() {
    if (_selectedIndex == null) return;
    final chainedTool = widget.tools[_selectedIndex!];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${chainedTool.tool.name} - Execution History'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: chainedTool.executions.isEmpty
              ? const Center(child: Text('No executions yet'))
              : ListView.builder(
                  itemCount: chainedTool.executions.length,
                  itemBuilder: (context, index) {
                    final execution = chainedTool.executions[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: execution.success
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: execution.success ? Colors.green : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Execution #${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${execution.timestamp.hour}:${execution.timestamp.minute.toString().padLeft(2, '0')}:${execution.timestamp.second.toString().padLeft(2, '0')}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Duration: ${execution.executionTime.inMilliseconds}ms',
                          ),
                          Text(
                            'Status: ${execution.status ?? (execution.success ? 'Success' : 'Error')}',
                          ),
                          if (execution.errorMessage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Error: ${execution.errorMessage}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Input: ${execution.input.length > 100 ? '${execution.input.substring(0, 100)}...' : execution.input}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Output: ${execution.output.length > 100 ? '${execution.output.substring(0, 100)}...' : execution.output}',
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearExecutionHistory();
              Navigator.of(context).pop();
            },
            child: const Text('Clear History'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddToolDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Tool to Chain"),
        content: SizedBox(
          width: 450,
          height: 350,
          child: widget.toolCategories.isEmpty
              ? const Center(child: Text("No tool categories available"))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select a tool to add to the chain:"),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children: widget.toolCategories.entries.map((category) {
                          return ExpansionTile(
                            title: Text(category.key),
                            children: category.value.map((toolFactory) {
                              final tool = toolFactory();
                              return ListTile(
                                leading: Icon(tool.icon),
                                title: Text(tool.name),
                                subtitle: Text(
                                  tool.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                onTap: () {
                                  _addTool(tool);
                                  Navigator.of(context).pop();
                                },
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _collapsed ? 60 : 320,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(_collapsed ? 8 : 12),
            child: _collapsed
                ? Center(
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _toggleCollapse,
                      iconSize: 20,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Tool Chain",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (widget.tools.isNotEmpty)
                              Text(
                                "${widget.tools.where((t) => t.enabled).length}/${widget.tools.length} enabled",
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (widget.tools.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_all, size: 16),
                              onPressed: _clearAllExecutionHistory,
                            ),
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _toggleCollapse,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const Divider(),

          if (!_collapsed)
            Expanded(
              child: widget.tools.isEmpty
                  ? Center(
                      child: Text(
                        "No tools added\nClick + to add tools",
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.tools.length,
                      itemBuilder: (context, index) {
                        final chainedTool = widget.tools[index];
                        final tool = chainedTool.tool;
                        final isSelected = index == _selectedIndex;

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () => setState(() {
                              _selectedIndex = isSelected ? null : index;
                            }),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  // Leading icon with status indicator
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Icon(
                                          tool.icon,
                                          size: 20,
                                          color: chainedTool.enabled
                                              ? null
                                              : Theme.of(context).disabledColor,
                                        ),
                                        if (chainedTool.hasExecuted)
                                          Positioned(
                                            right: -4,
                                            top: -4,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color:
                                                    chainedTool
                                                        .lastExecutionSuccess
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.error,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Theme.of(
                                                    context,
                                                  ).scaffoldBackgroundColor,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tool.name,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: chainedTool.enabled
                                                ? null
                                                : Theme.of(
                                                    context,
                                                  ).disabledColor,
                                          ),
                                        ),
                                        Text(
                                          "#${index + 1}${chainedTool.enabled ? '' : ' (disabled)'}",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        if (chainedTool.hasExecuted) ...[
                                          Text(
                                            "Last: ${chainedTool.lastExecution!.executionTime.inMilliseconds}ms",
                                            style: TextStyle(
                                              color:
                                                  chainedTool
                                                      .lastExecutionSuccess
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.error,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            "Runs: ${chainedTool.executions.length}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(fontSize: 12),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          if (!_collapsed)
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  if (_selectedIndex != null &&
                      _selectedIndex! < widget.tools.length)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed:
                              _selectedIndex != null &&
                                  _selectedIndex! < widget.tools.length
                              ? _showToolSettings
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.history),
                          onPressed: _selectedIndex != null
                              ? _showExecutionHistory
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_upward),
                          onPressed:
                              (_selectedIndex != null && _selectedIndex! > 0)
                              ? _moveUp
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward),
                          onPressed:
                              (_selectedIndex != null &&
                                  _selectedIndex! < widget.tools.length - 1)
                              ? _moveDown
                              : null,
                        ),
                        IconButton(
                          icon: Icon(
                            widget.tools[_selectedIndex!].enabled
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          onPressed: _toggleTool,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: _removeTool,
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.tools.any((t) => t.enabled)
                              ? () => widget.onExecute(widget.tools)
                              : null,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow, size: 16),
                              SizedBox(width: 4),
                              Text("Run All"),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_selectedIndex != null &&
                          _selectedIndex! < widget.tools.length)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => widget.onExecuteUntil(
                              _selectedIndex!,
                              widget.tools,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fast_forward, size: 16),
                                SizedBox(width: 4),
                                Text("Run Until"),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddToolDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("Add Tool"),
                    ),
                  ),
                ],
              ),
            ),

          if (_collapsed && widget.tools.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: widget.tools.any((t) => t.enabled)
                        ? () => widget.onExecute(widget.tools)
                        : null,
                    iconSize: 20,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  Text(
                    "${widget.tools.where((t) => t.enabled).length}/${widget.tools.length}",
                    style: const TextStyle(fontSize: 10),
                  ),
                  if (widget.tools.any((t) => t.hasExecuted))
                    Icon(
                      widget.tools.any(
                            (t) => t.hasExecuted && !t.lastExecutionSuccess,
                          )
                          ? Icons.error
                          : Icons.check,
                      size: 12,
                      color:
                          widget.tools.any(
                            (t) => t.hasExecuted && !t.lastExecutionSuccess,
                          )
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
