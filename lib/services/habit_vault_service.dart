import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vault_item.dart';

/// Local-first service for managing Habit Vault items
/// No backend dependency - all stored in SharedPreferences
class HabitVaultService {
  static const String _vaultKey = 'habit_vault_items';

  /// Save an item to the vault
  static Future<bool> saveItem(HabitVaultItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await getAllItems();
      
      // Add new item to the beginning
      items.insert(0, item);
      
      // Convert to JSON and save
      final jsonList = items.map((i) => i.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await prefs.setString(_vaultKey, jsonString);
      return true;
    } catch (e) {
      print('Error saving to vault: $e');
      return false;
    }
  }

  /// Get all vault items
  static Future<List<HabitVaultItem>> getAllItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_vaultKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final jsonList = json.decode(jsonString) as List;
      return jsonList.map((j) => HabitVaultItem.fromJson(j)).toList();
    } catch (e) {
      print('Error loading vault items: $e');
      return [];
    }
  }

  /// Delete an item from the vault
  static Future<bool> deleteItem(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await getAllItems();
      
      items.removeWhere((item) => item.id == id);
      
      final jsonList = items.map((i) => i.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await prefs.setString(_vaultKey, jsonString);
      return true;
    } catch (e) {
      print('Error deleting vault item: $e');
      return false;
    }
  }

  /// Clear all vault items
  static Future<bool> clearVault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_vaultKey);
      return true;
    } catch (e) {
      print('Error clearing vault: $e');
      return false;
    }
  }

  /// Get items by type
  static Future<List<HabitVaultItem>> getItemsByType(String type) async {
    final allItems = await getAllItems();
    return allItems.where((item) => item.goalType == type).toList();
  }

  /// Search items
  static Future<List<HabitVaultItem>> searchItems(String query) async {
    final allItems = await getAllItems();
    final lowerQuery = query.toLowerCase();
    
    return allItems.where((item) {
      return item.title.toLowerCase().contains(lowerQuery) ||
          (item.summary?.toLowerCase().contains(lowerQuery) ?? false) ||
          item.sections.any((s) => 
              s.title.toLowerCase().contains(lowerQuery) ||
              s.content.toLowerCase().contains(lowerQuery)
          );
    }).toList();
  }

  /// Get vault item count
  static Future<int> getItemCount() async {
    final items = await getAllItems();
    return items.length;
  }
}

