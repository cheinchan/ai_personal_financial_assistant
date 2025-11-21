import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final DateTime startDate;
  final DateTime endDate;
  final String category;
  final double currentAmount;
  final DateTime createdAt;

  GoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.startDate,
    required this.endDate,
    required this.category,
    this.currentAmount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'targetAmount': targetAmount,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'category': category,
      'currentAmount': currentAmount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory GoalModel.fromMap(String id, Map<String, dynamic> map) {
    return GoalModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0).toDouble(),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      category: map['category'] ?? '',
      currentAmount: (map['currentAmount'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;
}