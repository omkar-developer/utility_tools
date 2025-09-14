import 'package:flutter/material.dart';
import 'package:utility_tools/models/saved_chain.dart';
import 'package:utility_tools/services/chain_persistence_service.dart';
import 'package:utility_tools/widgets/chain_save_dialog.dart';

class ChainLibraryDialog extends StatefulWidget {
  const ChainLibraryDialog({super.key});

  @override
  State<ChainLibraryDialog> createState() => _ChainLibraryDialogState();
}

class _ChainLibraryDialogState extends State<ChainLibraryDialog> {
  List<SavedChain> _chains = [];
  List<SavedChain> _filteredChains = [];
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChains();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadChains() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 100));
    final chains = ChainPersistenceService.getAllChains();
    setState(() {
      _chains = chains;
      _filteredChains = chains;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _applyFilters() {
    var filtered = _chains;

    if (_searchQuery.isNotEmpty) {
      filtered = ChainPersistenceService.searchChains(_searchQuery);
    }

    if (_selectedCategory != null) {
      filtered = filtered
          .where((chain) => chain.category == _selectedCategory)
          .toList();
    }

    setState(() => _filteredChains = filtered);
  }

  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  void _loadChain(SavedChain chain) {
    Navigator.of(context).pop(chain);
  }

  void _editChain(SavedChain chain) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ChainSaveDialog(existingChain: chain),
    );

    if (result != null) {
      chain.name = result['name'];
      chain.description = result['description'];
      chain.category = result['category'];
      chain.tags = result['tags'];

      await ChainPersistenceService.updateChain(chain);
      _loadChains();
    }
  }

  void _deleteChain(SavedChain chain) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chain'),
        content: Text(
          'Are you sure you want to delete "${chain.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ChainPersistenceService.deleteChain(chain.id);
      _loadChains();
    }
  }

  void _duplicateChain(SavedChain chain) async {
    final newChain = SavedChain(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${chain.name} (Copy)',
      description: chain.description,
      tools: chain.tools
          .map(
            (tool) => SavedTool(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              toolType: tool.toolType,
              settings: Map<String, dynamic>.from(tool.settings),
              enabled: tool.enabled,
              order: tool.order,
              category: tool.category,
            ),
          )
          .toList(),
      created: DateTime.now(),
      modified: DateTime.now(),
      category: chain.category,
      tags: chain.tags,
    );

    await ChainPersistenceService.saveChain(newChain);
    _loadChains();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ChainPersistenceService.getAllCategories();

    return AlertDialog(
      title: const Text('Chain Library'),
      content: SizedBox(
        width: 1000,
        height: 650,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search and filter bar
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                SizedBox(
                  width: 400,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search chains...',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategory,
                    hint: const Text('All Categories'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ...categories.map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: _selectCategory,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Statistics
            if (!_isLoading) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Total Chains', _chains.length.toString()),
                      _buildStat('Categories', categories.length.toString()),
                      _buildStat('Showing', _filteredChains.length.toString()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Chain list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredChains.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).disabledColor.withAlpha((0.6 * 255).round()),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No chains found matching "$_searchQuery"'
                                : 'No chains saved yet',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).disabledColor.withAlpha((0.6 * 255).round()),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filteredChains.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final chain = _filteredChains[index];
                        return _buildChainTile(chain);
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).disabledColor.withAlpha((0.8 * 255).round()),
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChainTile(SavedChain chain) {
    return InkWell(
      onTap: () => _loadChain(chain),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withAlpha((0.3 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.link,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chain.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (chain.description.isNotEmpty) ...[
                    Text(
                      chain.description,
                      style: TextStyle(
                        color: Theme.of(context).disabledColor,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '${chain.tools.length} tools',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (chain.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary
                                .withAlpha((0.5 * 255).round()),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            chain.category!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                      Text(
                        _formatDate(chain.modified),
                        style: TextStyle(
                          color: Theme.of(context).disabledColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (chain.tags != null && chain.tags!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: chain.tags!
                          .take(4)
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary
                                      .withAlpha((0.3 * 255).round()),
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  onPressed: () => _editChain(chain),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () => _duplicateChain(chain),
                  tooltip: 'Duplicate',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 16),
                  onPressed: () => _deleteChain(chain),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
