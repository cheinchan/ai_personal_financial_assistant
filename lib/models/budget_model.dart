import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id;
  final String userId;
  final String? name;
  final double amount;
  final List<String> categories;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  BudgetModel({
    required this.id,
    required this.userId,
    this.name,
    required this.amount,
    required this.categories,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  /// Convert BudgetModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'amount': amount,
      'categories': categories,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create BudgetModel from Firestore JSON
  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'],
      amount: (json['amount'] ?? 0).toDouble(),
      categories: List<String>.from(json['categories'] ?? []),
      startDate: _parseDateTime(json['startDate']),
      endDate: _parseDateTime(json['endDate']),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  /// Helper method to parse DateTime from both String and Timestamp
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is Timestamp) {
      return value.toDate();
    } else {
      return DateTime.now();
    }
  }

  /// Create a copy of this budget with modified fields
  BudgetModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    List<String>? categories,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categories: categories ?? this.categories,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if this budget is for the current month
  bool isCurrentMonth() {
    final now = DateTime.now();
    return startDate.year == now.year && startDate.month == now.month;
  }

  /// Check if this budget is active (current date is within start and end date)
  bool isActive() {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Get the number of days remaining in this budget period
  int getDaysRemaining() {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Get the total number of days in this budget period
  int getTotalDays() {
    return endDate.difference(startDate).inDays + 1;
  }

  @override
  String toString() {
    return 'BudgetModel(id: $id, name: $name, amount: $amount, categories: $categories)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetModel &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.amount == amount &&
        _listEquals(other.categories, categories) &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      name,
      amount,
      categories,
      startDate,
      endDate,
      createdAt,
    );
  }

  /// Helper method for list comparison
  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}