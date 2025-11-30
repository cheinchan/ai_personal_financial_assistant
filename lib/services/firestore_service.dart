import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import '../models/budget_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // ============ TRANSACTIONS ============
  
  Future<void> addTransaction(TransactionModel transaction) async {
    if (_userId == null) throw 'User not authenticated';
    await _db.collection('transactions').add(transaction.toMap());
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
    await _db.collection('budgets').doc(budget.id).set(budget.toMap());
  }

  Stream<List<BudgetModel>> getBudgets() {
    if (_userId == null) return Stream.value([]);
    
    return _db
        .collection('budgets')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BudgetModel.fromMap(doc.data()))
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
        .map((doc) => BudgetModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> updateBudget(BudgetModel budget) async {
    await _db.collection('budgets').doc(budget.id).update(budget.toMap());
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
      if (categories.length > 10 && 
          !categories.contains(data['category'])) {
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