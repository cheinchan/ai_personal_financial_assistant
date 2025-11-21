import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Transactions
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

  // Goals
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

  // Analytics
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