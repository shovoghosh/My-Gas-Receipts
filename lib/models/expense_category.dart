import 'package:flutter/material.dart';

class ExpenseCategory {
  static const String gas = 'gas';
  static const String maintenance = 'maintenance';
  static const String insurance = 'insurance';
  static const String tolls = 'tolls';
  static const String parking = 'parking';
  static const String other = 'other';

  static const List<String> all = [
    gas,
    maintenance,
    insurance,
    tolls,
    parking,
    other,
  ];

  static String displayName(String category) {
    switch (category) {
      case gas:
        return 'Gas';
      case maintenance:
        return 'Maintenance';
      case insurance:
        return 'Insurance';
      case tolls:
        return 'Tolls';
      case parking:
        return 'Parking';
      case other:
        return 'Other';
      default:
        return category;
    }
  }

  static IconData icon(String category) {
    switch (category) {
      case gas:
        return Icons.local_gas_station;
      case maintenance:
        return Icons.build;
      case insurance:
        return Icons.shield;
      case tolls:
        return Icons.toll;
      case parking:
        return Icons.local_parking;
      case other:
      default:
        return Icons.receipt;
    }
  }

  static Color color(String category) {
    switch (category) {
      case gas:
        return Colors.green;
      case maintenance:
        return Colors.orange;
      case insurance:
        return Colors.blue;
      case tolls:
        return Colors.purple;
      case parking:
        return Colors.teal;
      case other:
      default:
        return Colors.grey;
    }
  }
}
