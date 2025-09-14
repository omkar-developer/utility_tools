// services/chain_persistence_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:utility_tools/models/saved_chain.dart';

class ChainPersistenceService {
  static const String _boxName = 'tool_chains';
  static Box<SavedChain>? _box;

  // Default categories that are always available
  static const List<String> _defaultCategories = [
    'General',
    'Text Processing',
    'Data Transformation',
    'Utility',
    'Automation',
    'Custom',
  ];

  // Initialize Hive and register adapters
  static Future<void> initialize() async {
    // Register type adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SavedChainAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SavedToolAdapter());
    }

    _box = await Hive.openBox<SavedChain>(_boxName);
  }

  static Box<SavedChain> get box {
    if (_box == null) {
      throw Exception(
        'ChainPersistenceService not initialized. Call initialize() first.',
      );
    }
    return _box!;
  }

  // Save a chain
  static Future<void> saveChain(SavedChain chain) async {
    chain.modified = DateTime.now();
    await box.put(chain.id, chain);
  }

  // Load all chains
  static List<SavedChain> getAllChains() {
    return box.values.toList()
      ..sort((a, b) => b.modified.compareTo(a.modified));
  }

  // Load a specific chain
  static SavedChain? getChain(String id) {
    return box.get(id);
  }

  // Delete a chain
  static Future<void> deleteChain(String id) async {
    await box.delete(id);
  }

  // Update an existing chain
  static Future<void> updateChain(SavedChain chain) async {
    chain.modified = DateTime.now();
    await box.put(chain.id, chain);
  }

  // Export chain to JSON file
  static Future<File> exportChain(SavedChain chain, String filePath) async {
    final file = File(filePath);
    final jsonString = jsonEncode(chain.toJson());
    return await file.writeAsString(jsonString);
  }

  // Import chain from JSON file
  static Future<SavedChain> importChain(String filePath) async {
    final file = File(filePath);
    final jsonString = await file.readAsString();
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;

    final chain = SavedChain.fromJson(jsonMap);
    // Generate new ID to avoid conflicts
    chain.id = DateTime.now().millisecondsSinceEpoch.toString();
    chain.modified = DateTime.now();

    return chain;
  }

  // Export all chains to JSON file
  static Future<File> exportAllChains(String filePath) async {
    final chains = getAllChains();
    final jsonString = jsonEncode(chains.map((c) => c.toJson()).toList());
    final file = File(filePath);
    return await file.writeAsString(jsonString);
  }

  // Import multiple chains from JSON file
  static Future<List<SavedChain>> importAllChains(String filePath) async {
    final file = File(filePath);
    final jsonString = await file.readAsString();
    final jsonList = jsonDecode(jsonString) as List;

    final chains = jsonList.map((json) => SavedChain.fromJson(json)).toList();

    // Generate new IDs and update timestamps
    for (final chain in chains) {
      chain.id = DateTime.now().millisecondsSinceEpoch.toString();
      chain.modified = DateTime.now();
    }

    return chains;
  }

  // Search chains
  static List<SavedChain> searchChains(String query) {
    if (query.isEmpty) return getAllChains();

    return box.values.where((chain) {
      final searchText = query.toLowerCase();
      return chain.name.toLowerCase().contains(searchText) ||
          chain.description.toLowerCase().contains(searchText) ||
          (chain.category?.toLowerCase().contains(searchText) ?? false) ||
          (chain.tags?.any((tag) => tag.toLowerCase().contains(searchText)) ??
              false);
    }).toList()..sort((a, b) => b.modified.compareTo(a.modified));
  }

  // Get chains by category
  static List<SavedChain> getChainsByCategory(String category) {
    return box.values.where((chain) => chain.category == category).toList()
      ..sort((a, b) => b.modified.compareTo(a.modified));
  }

  // Get all categories - now includes default categories
  static List<String> getAllCategories() {
    // Get categories from existing chains
    final existingCategories = box.values
        .map((chain) => chain.category)
        .where((category) => category != null)
        .cast<String>()
        .toSet();

    // Combine default categories with existing ones
    final allCategories = <String>{
      ..._defaultCategories,
      ...existingCategories,
    }.toList();

    allCategories.sort();
    return allCategories;
  }

  // Get only user-created categories (excluding defaults)
  static List<String> getUserCategories() {
    final categories = box.values
        .map((chain) => chain.category)
        .where(
          (category) =>
              category != null && !_defaultCategories.contains(category),
        )
        .cast<String>()
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  // Get statistics
  static Map<String, int> getStatistics() {
    final chains = getAllChains();
    return {
      'totalChains': chains.length,
      'totalTools': chains.fold(0, (sum, chain) => sum + chain.tools.length),
      'categories': getAllCategories().length,
    };
  }

  // Close the database
  static Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
