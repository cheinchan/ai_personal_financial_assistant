import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/transaction_model.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  // Budget categories with limits
  final Map<String, double> _budgetLimits = {
    'Transport': 500.0,
    'Food': 800.0,
    'Shopping': 600.0,
    'Bills': 1000.0,
    'Entertainment': 400.0,
    'Health': 300.0,
    'Fitness': 200.0,
    'Home': 700.0,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D9B8E),
        elevation: 0,
        title: const Text(
          'Budget Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () {
              // Add new budget category
              _showAddBudgetDialog();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D9B8E)),
              ),
            );
          }

          final transactions = snapshot.data ?? [];
          final categoryExpenses = _calculateCategoryExpenses(transactions);

          return SingleChildScrollView(
            child: Column(
              children: [
                // Monthly Budget Overview
                _buildMonthlyOverview(categoryExpenses),

                // Budget Categories List
                _buildBudgetCategories(categoryExpenses),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<String, double> _calculateCategoryExpenses(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    
    final Map<String, double> expenses = {};

    for (var transaction in transactions) {
      if (transaction.type == 'expense' &&
          transaction.category != null &&
          transaction.createdAt.year == currentMonth.year &&
          transaction.createdAt.month == currentMonth.month) {
        expenses[transaction.category!] = 
            (expenses[transaction.category!] ?? 0) + transaction.amount;
      }
    }

    return expenses;
  }

  Widget _buildMonthlyOverview(Map<String, double> categoryExpenses) {
    double totalBudget = _budgetLimits.values.fold(0, (sum, limit) => sum + limit);
    double totalSpent = categoryExpenses.values.fold(0, (sum, spent) => sum + spent);
    double remaining = totalBudget - totalSpent;
    double percentage = totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D9B8E), Color(0xFF1F7A6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D9B8E).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            DateFormat('MMMM yyyy').format(DateTime.now()),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewItem('Budget', totalBudget),
              Container(
                height: 40,
                width: 1,
                color: Colors.white30,
              ),
              _buildOverviewItem('Spent', totalSpent),
              Container(
                height: 40,
                width: 1,
                color: Colors.white30,
              ),
              _buildOverviewItem('Remaining', remaining),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.white30,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 90 ? Colors.red : Colors.white,
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}% of budget used',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, double amount) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'MYR ${NumberFormat('#,##0').format(amount)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCategories(Map<String, double> categoryExpenses) {
    final categoryIcons = {
      'Transport': {'icon': Icons.directions_car, 'color': const Color(0xFFF59E0B)},
      'Food': {'icon': Icons.restaurant, 'color': const Color(0xFF10B981)},
      'Shopping': {'icon': Icons.card_giftcard, 'color': const Color(0xFF3B82F6)},
      'Bills': {'icon': Icons.monetization_on, 'color': const Color(0xFF06B6D4)},
      'Entertainment': {'icon': Icons.nightlight_round, 'color': const Color(0xFFA855F7)},
      'Health': {'icon': Icons.favorite, 'color': const Color(0xFFEC4899)},
      'Fitness': {'icon': Icons.fitness_center, 'color': const Color(0xFF6B7280)},
      'Home': {'icon': Icons.home, 'color': const Color(0xFFF97316)},
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _budgetLimits.length,
          itemBuilder: (context, index) {
            final category = _budgetLimits.keys.elementAt(index);
            final limit = _budgetLimits[category]!;
            final spent = categoryExpenses[category] ?? 0;
            final percentage = limit > 0 ? (spent / limit * 100) : 0;
            final remaining = limit - spent;

            final iconData = categoryIcons[category];
            final icon = iconData?['icon'] as IconData? ?? Icons.category;
            final color = iconData?['color'] as Color? ?? Colors.grey;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'MYR ${NumberFormat('#,##0').format(spent)} of MYR ${NumberFormat('#,##0').format(limit)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: percentage > 90
                                  ? Colors.red
                                  : percentage > 70
                                      ? Colors.orange
                                      : const Color(0xFF2D9B8E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            remaining >= 0
                                ? 'MYR ${NumberFormat('#,##0').format(remaining)} left'
                                : 'MYR ${NumberFormat('#,##0').format(-remaining)} over',
                            style: TextStyle(
                              fontSize: 12,
                              color: remaining >= 0 ? Colors.grey[600] : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (percentage / 100).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage > 100
                            ? Colors.red
                            : percentage > 90
                                ? Colors.orange
                                : percentage > 70
                                    ? Colors.yellow[700]!
                                    : color,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAddBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Budget Category'),
        content: const Text(
          'This feature allows you to add custom budget categories. Coming soon!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF2D9B8E)),
            ),
          ),
        ],
      ),
    );
  }
}