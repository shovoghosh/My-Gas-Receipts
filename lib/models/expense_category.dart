import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomCategory {
  final String id;
  final String name;
  final String iconName;
  final int colorValue;

  CustomCategory({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'iconName': iconName,
    'colorValue': colorValue,
  };

  factory CustomCategory.fromMap(Map<String, dynamic> map) => CustomCategory(
    id: map['id'] as String,
    name: map['name'] as String,
    iconName: map['iconName'] as String,
    colorValue: map['colorValue'] as int,
  );

  IconData get icon {
    switch (iconName) {
      case 'local_gas_station': return Icons.local_gas_station;
      case 'build': return Icons.build;
      case 'shield': return Icons.shield;
      case 'toll': return Icons.toll;
      case 'local_parking': return Icons.local_parking;
      case 'receipt': return Icons.receipt;
      case 'car_repair': return Icons.car_repair;
      case 'local_car_wash': return Icons.local_car_wash;
      case 'ev_station': return Icons.ev_station;
      case 'card_membership': return Icons.card_membership;
      case 'wifi_tethering': return Icons.wifi_tethering;
      case 'directions_car': return Icons.directions_car;
      case 'home_repair_service': return Icons.home_repair_service;
      case 'medical_services': return Icons.medical_services;
      case 'restaurant': return Icons.restaurant;
      default: return Icons.receipt;
    }
  }

  Color get color => Color(colorValue);
}

class CategoryManager {
  static const String _key = 'custom_categories';

  static Future<List<CustomCategory>> loadCustom() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    final list = jsonDecode(jsonStr) as List;
    return list.map((e) => CustomCategory.fromMap(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveCustom(List<CustomCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(categories.map((c) => c.toMap()).toList());
    await prefs.setString(_key, jsonStr);
  }

  static Future<void> addCategory(CustomCategory category) async {
    final list = await loadCustom();
    list.add(category);
    await saveCustom(list);
  }

  static Future<void> updateCategory(CustomCategory updated) async {
    final list = await loadCustom();
    final idx = list.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      list[idx] = updated;
      await saveCustom(list);
    }
  }

  static Future<void> deleteCategory(String id) async {
    final list = await loadCustom();
    list.removeWhere((c) => c.id == id);
    await saveCustom(list);
  }

  static Future<List<String>> allCategoryIds() async {
    final custom = await loadCustom();
    return [
      'gas', 'maintenance', 'insurance', 'tolls', 'parking', 'other',
      ...custom.map((c) => c.id),
    ];
  }

  static String displayName(String id, List<CustomCategory> custom) {
    switch (id) {
      case 'gas': return 'Gas';
      case 'maintenance': return 'Maintenance';
      case 'insurance': return 'Insurance';
      case 'tolls': return 'Tolls';
      case 'parking': return 'Parking';
      case 'other': return 'Other';
      default:
        final c = custom.where((x) => x.id == id).firstOrNull;
        return c?.name ?? id;
    }
  }

  static IconData icon(String id, List<CustomCategory> custom) {
    switch (id) {
      case 'gas': return Icons.local_gas_station;
      case 'maintenance': return Icons.build;
      case 'insurance': return Icons.shield;
      case 'tolls': return Icons.toll;
      case 'parking': return Icons.local_parking;
      case 'other': return Icons.receipt;
      default:
        final c = custom.where((x) => x.id == id).firstOrNull;
        return c?.icon ?? Icons.receipt;
    }
  }

  static Color color(String id, List<CustomCategory> custom) {
    switch (id) {
      case 'gas': return Colors.green;
      case 'maintenance': return Colors.orange;
      case 'insurance': return Colors.blue;
      case 'tolls': return Colors.purple;
      case 'parking': return Colors.teal;
      case 'other': return Colors.grey;
      default:
        final c = custom.where((x) => x.id == id).firstOrNull;
        return c?.color ?? Colors.grey;
    }
  }

  static bool isBuiltIn(String id) =>
    ['gas', 'maintenance', 'insurance', 'tolls', 'parking', 'other'].contains(id);

  static String vendorLabel(String id) {
    switch (id) {
      case 'gas': return 'Station Name';
      case 'maintenance': return 'Service Provider';
      case 'insurance': return 'Insurance Company';
      case 'tolls': return 'Toll Road / Bridge';
      case 'parking': return 'Parking Location';
      case 'other': return 'Vendor / Merchant';
      default: return 'Vendor Name';
    }
  }

  static IconData vendorIcon(String id) {
    switch (id) {
      case 'gas': return Icons.local_gas_station;
      case 'maintenance': return Icons.car_repair;
      case 'insurance': return Icons.shield;
      case 'tolls': return Icons.toll;
      case 'parking': return Icons.local_parking;
      case 'other': return Icons.store;
      default: return Icons.business;
    }
  }

  static List<IconData> availableIcons = [
    Icons.local_gas_station,
    Icons.build,
    Icons.shield,
    Icons.toll,
    Icons.local_parking,
    Icons.receipt,
    Icons.car_repair,
    Icons.local_car_wash,
    Icons.ev_station,
    Icons.card_membership,
    Icons.wifi_tethering,
    Icons.directions_car,
    Icons.home_repair_service,
    Icons.medical_services,
    Icons.restaurant,
    Icons.store,
    Icons.hotel,
    Icons.flight,
    Icons.local_shipping,
    Icons.attach_money,
  ];

  static List<Color> availableColors = [
    Colors.green,
    Colors.orange,
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.red,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
    Colors.brown,
    Colors.lime,
  ];
}
