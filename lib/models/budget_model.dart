import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id;
  final String userId;
  final String? name; // Optional budget name
  final double amount;
  final List<String> categories; // Can have multiple categories
  final DateTime? startDate; // Optional
  final DateTime? endDate; // Optional
  final DateTime createdAt;

  BudgetModel({
    required this.id,
    required this.userId,
    this.name,
    required this.amount,
    required this.categories,
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'amount': amount,
      'categories': categories,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'],
      amount: (map['amount'] ?? 0).toDouble(),
      categories: List<String>.from(map['categories'] ?? []),
      startDate: map['startDate'] != null 
          ? DateTime.parse(map['startDate']) 
          : null,
      endDate: map['endDate'] != null 
          ? DateTime.parse(map['endDate']) 
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  // Create a copy with some fields changed
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
}