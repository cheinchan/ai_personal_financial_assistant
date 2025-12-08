import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import '../models/budget_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // ============ TRANSACTIONS ============



  Future<void> addTransaction(TransactionModel transaction) async {
    if (_userId == null) throw 'User not authenticated';
    await _db.collection('transactions').add(transaction.toMap());
  }
  

  /// Calculate goal progress based on transactions between goal start and end dates
  /// Returns the net savings (income - expenses) for the goal period
  Future<double> calculateGoalProgress(GoalModel goal) async {
    if (_userId == null) {
      print('❌ No user ID found');
      return 0;
    }

    try {
      print('🔍 Calculating progress for goal: ${goal.name}');
      print('📅 Period: ${goal.startDate} to ${goal.endDate}');

      // Get all transactions for this user
      final snapshot = await _db
          .collection('transactions')
          .where('userId', isEqualTo: _userId)
          .get();

      print('📊 Total transactions found: ${snapshot.docs.length}');

      double income = 0;
      double expenses = 0;
      int incomeCount = 0;
      int expenseCount = 0;

      // Filter transactions within goal period
      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Handle both Timestamp and String date formats
        DateTime createdAt;
        final createdAtData = data['createdAt'];

        if (createdAtData is Timestamp) {
          createdAt = createdAtData.toDate();
        } else if (createdAtData is String) {
          createdAt = DateTime.parse(createdAtData);
        } else {
          print('⚠️ Unknown date format for transaction ${doc.id}');
          continue;
        }

        // Check if transaction is within goal period
        final isWithinPeriod = (createdAt.isAfter(goal.startDate) ||
                createdAt.isAtSameMomentAs(goal.startDate)) &&
            (createdAt.isBefore(goal.endDate) ||
                createdAt.isAtSameMomentAs(goal.endDate));

        if (!isWithinPeriod) continue;

        final amount = (data['amount'] ?? 0).toDouble();
        final type = data['type'] ?? '';

        print(
            '✅ Transaction in period: $type - MYR $amount on ${createdAt.toString().substring(0, 10)}');

        if (type == 'income') {
          income += amount;
          incomeCount++;
        } else if (type == 'expense') {
          expenses += amount;
          expenseCount++;
        }
      }

      // Calculate net savings
      final savings = income - expenses;

      print('💰 Summary:');
      print('   Income: MYR $income ($incomeCount transactions)');
      print('   Expenses: MYR $expenses ($expenseCount transactions)');
      print('   Net Savings: MYR $savings');

      return savings > 0 ? savings : 0;
    } catch (e) {
      print('❌ Error calculating goal progress: $e');
      return 0;
    }
  }

  /// Get all goals with calculated progress (with debugging)
  Future<List<GoalModel>> getGoalsWithProgress() async {
  if (_userId == null) {
    print('❌ No user ID for goals');
    return [];
  }

  try {
    print('🎯 Fetching goals for user: $_userId');

    final snapshot = await _db
        .collection('goals')
        .where('userId', isEqualTo: _userId)
        .where('status', isNotEqualTo: 'completed')  // ✅ Filter out completed
        .orderBy('status')  // ✅ Required when using isNotEqualTo
        .orderBy('createdAt', descending: true)
        .get();

    print('📋 Found ${snapshot.docs.length} active goals');

    final goals = snapshot.docs
        .map((doc) => GoalModel.fromMap(doc.id, doc.data()))
        .toList();

    final goalsWithProgress = <GoalModel>[];
    for (var goal in goals) {
      print('\n🎯 Processing goal: ${goal.name}');
      final calculatedAmount = await calculateGoalProgress(goal);
      print('✅ Calculated amount: MYR $calculatedAmount\n');
      goalsWithProgress.add(goal.copyWithCalculatedAmount(calculatedAmount));
    }

    return goalsWithProgress;
  } catch (e) {
    print('❌ Error fetching goals with progress: $e');
    return [];
  }
}
// ✅ Add this method to your existing FirestoreService class

  /// Update goal status (mark as completed/achieved)
  Future<void> updateGoalStatus({
    required String goalId,
    required String status,
    DateTime? completedAt,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add completedAt timestamp if provided
      if (completedAt != null) {
        updateData['completedAt'] = Timestamp.fromDate(completedAt);
      }

      await _db
          .collection('goals')
          .doc(goalId)
          .update(updateData);
      print('✅ Goal status updated: $goalId → $status');
    } catch (e) {
      throw Exception('Failed to update goal status: $e');
    }
  }

  Stream<List<TransactionModel>> getTransactions() {
    if (_userId == null) return Stream.value([]);

    return _db
        .collection('transactions')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Get transactions once (no real-time updates)
  Future<List<TransactionModel>> getTransactionsOnce() async {
    if (_userId == null) return [];

    final snapshot = await _db
        .collection('transactions')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> deleteTransaction(String id) async {
    await _db.collection('transactions').doc(id).delete();
  }

  // ============ GOALS ============

  Future<void> addGoal(GoalModel goal) async {
    if (_userId == null) throw 'User not authenticated';
    await _db.collection('goals').add(goal.toMap());
  }

  Stream<List<GoalModel>> getGoals() {
    if (_userId == null) return Stream.value([]);

    return _db
        .collection('goals')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GoalModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Get goals once (no real-time updates)
  Future<List<GoalModel>> getGoalsOnce() async {
    if (_userId == null) return [];

    final snapshot = await _db
        .collection('goals')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => GoalModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> updateGoal(String id, Map<String, dynamic> data) async {
    await _db.collection('goals').doc(id).update(data);
  }

  Future<void> deleteGoal(String id) async {
    await _db.collection('goals').doc(id).delete();
  }

  // ============ BUDGETS ============

  Future<void> addBudget(BudgetModel budget) async {
    if (_userId == null) throw 'User not authenticated';
    await _db.collection('budgets').doc(budget.id).set(budget.toJson());
  }

  Stream<List<BudgetModel>> getBudgets() {
    if (_userId == null) return Stream.value([]);

    return _db
        .collection('budgets')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BudgetModel.fromJson(doc.data()))
            .toList());
  }

  // Get budgets once (no real-time updates)
  Future<List<BudgetModel>> getBudgetsOnce() async {
    if (_userId == null) return [];

    final snapshot = await _db
        .collection('budgets')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => BudgetModel.fromJson(doc.data()))
        .toList();
  }

  Future<void> updateBudget(BudgetModel budget) async {
    await _db.collection('budgets').doc(budget.id).update(budget.toJson());
  }

  Future<void> deleteBudget(String id) async {
    await _db.collection('budgets').doc(id).delete();
  }

  // Get spending for specific categories (for budget tracking)
  Future<double> getCategorySpending(
    List<String> categories, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_userId == null) return 0;

    // Base query for user's expense transactions
    Query query = _db
        .collection('transactions')
        .where('userId', isEqualTo: _userId)
        .where('type', isEqualTo: 'expense');

    // Note: Firestore has limitations with 'in' queries (max 10 items)
    // For more than 10 categories, we'll filter in code
    if (categories.isNotEmpty && categories.length <= 10) {
      query = query.where('category', whereIn: categories);
    }

    final snapshot = await query.get();
    double total = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // If we have more than 10 categories, filter here
      if (categories.length > 10 && !categories.contains(data['category'])) {
        continue;
      }

      // Parse date from Firestore
      final createdAtStr = data['createdAt'] as String?;
      if (createdAtStr != null) {
        final transactionDate = DateTime.parse(createdAtStr);

        // Filter by date if provided
        if (startDate != null && transactionDate.isBefore(startDate)) {
          continue;
        }
        if (endDate != null && transactionDate.isAfter(endDate)) {
          continue;
        }
      }

      final amount = (data['amount'] ?? 0).toDouble();
      total += amount;
    }

    return total;
  }

  // ============ ANALYTICS ============

  Future<Map<String, double>> getFinancialSummary() async {
    if (_userId == null) return {'income': 0, 'expenses': 0, 'balance': 0};

    final transactions = await _db
        .collection('transactions')
        .where('userId', isEqualTo: _userId)
        .get();

    double income = 0;
    double expenses = 0;

    for (var doc in transactions.docs) {
      final data = doc.data();
      final amount = (data['amount'] ?? 0).toDouble();
      final type = data['type'] ?? '';

      if (type == 'income') {
        income += amount;
      } else if (type == 'expense') {
        expenses += amount;
      }
    }

    return {
      'income': income,
      'expenses': expenses,
      'balance': income - expenses,
    };
  }
}
