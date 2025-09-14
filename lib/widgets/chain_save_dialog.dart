import 'package:flutter/material.dart';
import 'package:utility_tools/models/saved_chain.dart';
import 'package:utility_tools/services/chain_persistence_service.dart';

class ChainSaveDialog extends StatefulWidget {
  final SavedChain? existingChain;

  const ChainSaveDialog({super.key, this.existingChain});

  @override
  State<ChainSaveDialog> createState() => _ChainSaveDialogState();
}

class _ChainSaveDialogState extends State<ChainSaveDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _tagsController;

  String? _nameError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingChain?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existingChain?.description ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.existingChain?.category ?? '',
    );
    _tagsController = TextEditingController(
      text: widget.existingChain?.tags?.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _validateAndSave() async {
    setState(() {
      _nameError = null;
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Chain name is required';
        _isLoading = false;
      });
      return;
    }

    final existingChains = ChainPersistenceService.getAllChains();
    final duplicateExists = existingChains.any(
      (chain) =>
          chain.name == name && chain.id != (widget.existingChain?.id ?? ''),
    );

    if (duplicateExists) {
      setState(() {
        _nameError = 'A chain with this name already exists';
        _isLoading = false;
      });
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final chainData = {
      'name': name,
      'description': _descriptionController.text.trim(),
      'category': _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      'tags': tags.isEmpty ? null : tags,
    };

    Navigator.of(context).pop(chainData);
  }

  @override
  Widget build(BuildContext context) {
    final existingCategories = ChainPersistenceService.getAllCategories();
    final hasExistingCategories = existingCategories.isNotEmpty;

    String? dropdownValue =
        hasExistingCategories &&
            existingCategories.contains(_categoryController.text)
        ? _categoryController.text
        : null;

    return AlertDialog(
      title: Text(widget.existingChain == null ? 'Save Chain' : 'Edit Chain'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              const Text(
                'Chain Name *',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter chain name',
                  errorText: _nameError,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Category
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        hintText: 'Enter category (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  hasExistingCategories
                      ? DropdownButton<String>(
                          value: dropdownValue,
                          hint: const Text('Existing'),
                          items: existingCategories
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _categoryController.text = value;
                                dropdownValue = value;
                              });
                            }
                          },
                        )
                      : ElevatedButton(
                          onPressed: null,
                          child: const Text('No categories'),
                        ),
                ],
              ),
              const SizedBox(height: 16),

              // Tags
              const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  hintText: 'Enter tags separated by commas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Example: text processing, automation, workflow',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _validateAndSave,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.existingChain == null ? 'Save' : 'Update'),
        ),
      ],
    );
  }
}
