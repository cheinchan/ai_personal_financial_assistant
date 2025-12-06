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
  final String priority;

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
    this.priority = 'medium',
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
      'priority': priority,
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
      priority: map['priority'] ?? 'medium',
    );
  }

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;

  double get suggestedMonthlyContribution {
    final remainingAmount = targetAmount - currentAmount;
    final now = DateTime.now();
    final remainingMonths = endDate.difference(now).inDays / 30;
    
    if (remainingMonths <= 0) return remainingAmount;
    if (remainingMonths < 1) return remainingAmount;
    return remainingAmount / remainingMonths;
  }
  
  bool get isOnTrack {
    final totalDays = endDate.difference(startDate).inDays;
    if (totalDays <= 0) return true;
    
    final elapsedDays = DateTime.now().difference(startDate).inDays;
    if (elapsedDays <= 0) return true;
    
    final expectedProgress = (elapsedDays / totalDays) * targetAmount;
    return currentAmount >= expectedProgress * 0.9;
  }

  int get daysRemaining {
    final remaining = endDate.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  GoalModel copyWithCalculatedAmount(double calculatedAmount) {
    return GoalModel(
      id: id,
      userId: userId,
      name: name,
      targetAmount: targetAmount,
      startDate: startDate,
      endDate: endDate,
      category: category,
      currentAmount: calculatedAmount,
      createdAt: createdAt,
      priority: priority,
    );
  }

  GoalModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? targetAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    double? currentAmount,
    DateTime? createdAt,
    String? priority,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      currentAmount: currentAmount ?? this.currentAmount,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
    );
  }
}