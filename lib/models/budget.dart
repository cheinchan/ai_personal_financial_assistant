import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Collection reference
  CollectionReference get _budgetsCollection => _firestore.collection('budgets');

  /// FR2.1: Create a new budget for a specific category
  Future<String> createBudget({
    required String category,
    required double amount,
  }) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      if (amount <= 0) {
        throw Exception('Budget amount must be greater than 0');
      }

      if (category.trim().isEmpty) {
        throw Exception('Category cannot be empty');
      }

      // Check if budget already exists for this category
      final existingBudget = await getBudgetByCategory(category);
      if (existingBudget != null) {
        throw Exception('Budget already exists for category: $category');
      }

      final now = DateTime.now();
      final budget = Budget(
        id: '', // Will be set by Firestore
        userId: _userId!,
        category: category.trim(),
        amount: amount,
        spent: 0.0,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _budgetsCollection.add(budget.toMap());
      return docRef.id;
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// FR2.2: Update an existing budget
  Future<void> updateBudget({
    required String budgetId,
    String? category,
    double? amount,
  }) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      if (amount != null && amount <= 0) {
        throw Exception('Budget amount must be greater than 0');
      }

      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (category != null && category.trim().isNotEmpty) {
        // Check if another budget exists with this category
        final existingBudget = await getBudgetByCategory(category);
        if (existingBudget != null && existingBudget.id != budgetId) {
          throw Exception('Budget already exists for category: $category');
        }
        updateData['category'] = category.trim();
      }

      if (amount != null) {
        updateData['amount'] = amount;
      }

      await _budgetsCollection.doc(budgetId).update(updateData);
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// FR2.2: Reset budget (set spent to 0)
  Future<void> resetBudget(String budgetId) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      await _budgetsCollection.doc(budgetId).update({
        'spent': 0.0,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// FR2.2: Delete a budget
  Future<void> deleteBudget(String budgetId) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      await _budgetsCollection.doc(budgetId).delete();
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// FR2.3 & FR2.4: Get all budgets for current user (real-time)
  Stream<List<Budget>> getBudgetsStream() {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _budgetsCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('category')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Budget.fromFirestore(doc)).toList();
    });
  }

  /// Get a single budget by ID
  Future<Budget?> getBudgetById(String budgetId) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _budgetsCollection.doc(budgetId).get();
      if (!doc.exists) {
        return null;
      }

      final budget = Budget.fromFirestore(doc);
      if (budget.userId != _userId) {
        throw Exception('Unauthorized access to budget');
      }

      return budget;
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Get budget by category
  Future<Budget?> getBudgetByCategory(String category) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _budgetsCollection
          .where('userId', isEqualTo: _userId)
          .where('category', isEqualTo: category.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return Budget.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Update spent amount for a budget
  Future<void> updateSpentAmount({
    required String budgetId,
    required double amount,
  }) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      await _budgetsCollection.doc(budgetId).update({
        'spent': FieldValue.increment(amount),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Update spent amount by category
  Future<void> updateSpentByCategory({
    required String category,
    required double amount,
  }) async {
    try {
      final budget = await getBudgetByCategory(category);
      if (budget != null) {
        await updateSpentAmount(budgetId: budget.id, amount: amount);
      }
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Get total budget amount across all categories
  Future<double> getTotalBudgetAmount() async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _budgetsCollection
          .where('userId', isEqualTo: _userId)
          .get();

      double total = 0;
      for (var doc in querySnapshot.docs) {
        final budget = Budget.fromFirestore(doc);
        total += budget.amount;
      }

      return total;
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Get total spent amount across all categories
  Future<double> getTotalSpentAmount() async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _budgetsCollection
          .where('userId', isEqualTo: _userId)
          .get();

      double total = 0;
      for (var doc in querySnapshot.docs) {
        final budget = Budget.fromFirestore(doc);
        total += budget.spent;
      }

      return total;
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Get budgets that are exceeded
  Future<List<Budget>> getExceededBudgets() async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _budgetsCollection
          .where('userId', isEqualTo: _userId)
          .get();

      return querySnapshot.docs
          .map((doc) => Budget.fromFirestore(doc))
          .where((budget) => budget.isExceeded)
          .toList();
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Handle exceptions and return user-friendly error messages
  String _handleException(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to perform this action';
        case 'not-found':
          return 'Budget not found';
        case 'unavailable':
          return 'Service temporarily unavailable. Please try again';
        default:
          return 'An error occurred: ${error.message}';
      }
    }
    return error.toString();
  }
}