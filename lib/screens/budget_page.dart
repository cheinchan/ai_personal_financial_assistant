import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import 'add_budget_page.dart';
import 'budget_detail_page.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFFD4E8E4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4E8E4),
        elevation: 0,
        title: const Text(
          'Budget',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black87),
            onPressed: _showBudgetInfo,
          ),
        ],
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _firestoreService.getTransactions(),
        builder: (context, transactionSnapshot) {
          return StreamBuilder<List<BudgetModel>>(
            stream: _firestoreService.getBudgets(),
            builder: (context, budgetSnapshot) {
              if (budgetSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final budgets = budgetSnapshot.data ?? [];
              final transactions = transactionSnapshot.data ?? [];

              // Filter transactions for current month
              final now = DateTime.now();
              final monthTransactions = transactions.where((t) {
                return t.createdAt.year == now.year && 
                       t.createdAt.month == now.month;
              }).toList();

              // Calculate financial summary
              double totalIncome = 0;
              double totalExpense = 0;
              
              for (var transaction in monthTransactions) {
                if (transaction.type == 'income') {
                  totalIncome += transaction.amount;
                } else {
                  totalExpense += transaction.amount;
                }
              }

              final cash = totalIncome - totalExpense;
              final displayBudgets = _showAll ? budgets : budgets.take(5).toList();

              // Check for budget alerts
              final alerts = _checkBudgetAlerts(budgets, monthTransactions);

              return RefreshIndicator(
                color: const Color(0xFF2D9B8E),
                onRefresh: () async {
                  setState(() {});
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: Column(
                  children: [
                    // Month Indicator
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D9B8E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMMM yyyy').format(now),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Alerts Section (if any)
                    if (alerts.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, 
                                      color: Colors.orange.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Budget Alerts',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: alerts.length,
                              itemBuilder: (context, index) {
                                return _buildAlertItem(alerts[index]);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Summary Card
                    _buildSummaryCard(totalIncome, totalExpense, cash),
                    
                    const SizedBox(height: 16),
                    
                    // Budget Category Section
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Budget Category',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${budgets.length} budgets',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            Expanded(
                              child: budgets.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                      itemCount: displayBudgets.length,
                                      itemBuilder: (context, index) {
                                        return _buildBudgetItem(
                                          displayBudgets[index],
                                          monthTransactions,
                                        );
                                      },
                                    ),
                            ),
                            
                            if (budgets.length > 5 && !_showAll)
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() => _showAll = true);
                                  },
                                  child: const Text(
                                    'See all',
                                    style: TextStyle(
                                      color: Color(0xFF2D9B8E),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddBudgetPage(),
            ),
          );
        },
        backgroundColor: const Color(0xFF2D9B8E),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSummaryCard(double totalIncome, double totalExpense, double cash) {
    final currencyFormat = NumberFormat.currency(symbol: 'MYR ', decimalDigits: 2);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Total Savings:',
            currencyFormat.format(totalIncome),
            Colors.black87,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Current Transaction:',
            currencyFormat.format(totalExpense),
            Colors.red,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Cash:',
            currencyFormat.format(cash),
            const Color(0xFF2D9B8E),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetItem(BudgetModel budget, List<TransactionModel> transactions) {
    // Calculate spending for this budget's categories (current month only)
    double spent = 0;
    for (var transaction in transactions) {
      if (transaction.type == 'expense' &&
          transaction.category != null &&
          budget.categories.contains(transaction.category)) {
        spent += transaction.amount;
      }
    }

    final percentage = (spent / budget.amount * 100).clamp(0, 100).toInt();
    final remaining = budget.amount - spent;

    // Determine status color
    Color statusColor;
    Color bgColor;
    String statusText;
    IconData statusIcon;

    if (percentage >= 100) {
      statusColor = Colors.red;
      bgColor = Colors.red.shade50;
      statusText = 'Over Budget';
      statusIcon = Icons.error;
    } else if (percentage >= 90) {
      statusColor = Colors.orange;
      bgColor = Colors.orange.shade50;
      statusText = 'Critical';
      statusIcon = Icons.warning_amber_rounded;
    } else if (percentage >= 70) {
      statusColor = Colors.amber;
      bgColor = Colors.amber.shade50;
      statusText = 'Warning';
      statusIcon = Icons.info;
    } else {
      statusColor = Colors.green;
      bgColor = Colors.green.shade50;
      statusText = 'On Track';
      statusIcon = Icons.check_circle;
    }

    final categoryIcons = {
      'Transport': Icons.directions_car,
      'Food': Icons.restaurant,
      'Shopping': Icons.card_giftcard,
      'Bills': Icons.receipt_long,
      'Entertainment': Icons.movie,
      'Health': Icons.favorite,
      'Fitness': Icons.fitness_center,
      'Home': Icons.home,
      'Clothes': Icons.checkroom,
      'Baby': Icons.child_care,
      'Insurance': Icons.shield,
    };

    final categoryColors = {
      'Transport': Colors.orange,
      'Food': Colors.green,
      'Shopping': Colors.blue,
      'Bills': Colors.red,
      'Entertainment': Colors.purple,
      'Health': Colors.pink,
      'Fitness': Colors.teal,
      'Home': Colors.red.shade300,
      'Clothes': Colors.deepPurple,
      'Baby': Colors.pinkAccent,
      'Insurance': Colors.grey,
    };

    // Get primary category for display
    final primaryCategory = budget.categories.isNotEmpty ? budget.categories.first : 'Other';
    final icon = categoryIcons[primaryCategory] ?? Icons.category;
    final color = categoryColors[primaryCategory] ?? Colors.grey;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BudgetDetailPage(
              budget: budget,
              spent: spent,
            ),
          ),
        );
      },
      onLongPress: () => _showDeleteDialog(budget),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: percentage >= 90 ? statusColor.withOpacity(0.3) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.name ?? primaryCategory,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${spent.toInt()} / ${budget.amount.toInt()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'MYR',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$percentage% used',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  remaining >= 0 
                      ? 'Remaining: ${remaining.toInt()} MYR'
                      : 'Over by: ${remaining.abs().toInt()} MYR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: remaining >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Check for budget alerts
  List<Map<String, dynamic>> _checkBudgetAlerts(
    List<BudgetModel> budgets,
    List<TransactionModel> transactions,
  ) {
    List<Map<String, dynamic>> alerts = [];

    for (var budget in budgets) {
      double spent = 0;
      for (var transaction in transactions) {
        if (transaction.type == 'expense' &&
            transaction.category != null &&
            budget.categories.contains(transaction.category)) {
          spent += transaction.amount;
        }
      }

      final percentage = (spent / budget.amount * 100);

      if (percentage >= 100) {
        alerts.add({
          'type': 'critical',
          'budget': budget,
          'percentage': percentage.toInt(),
          'message': 'You\'ve exceeded your ${budget.name ?? budget.categories.first} budget!',
        });
      } else if (percentage >= 90) {
        alerts.add({
          'type': 'warning',
          'budget': budget,
          'percentage': percentage.toInt(),
          'message': 'Only ${(budget.amount - spent).toInt()} MYR left in ${budget.name ?? budget.categories.first}',
        });
      } else if (percentage >= 70) {
        alerts.add({
          'type': 'info',
          'budget': budget,
          'percentage': percentage.toInt(),
          'message': '${budget.name ?? budget.categories.first} is at $percentage%',
        });
      }
    }

    return alerts;
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    Color color;
    IconData icon;

    switch (alert['type']) {
      case 'critical':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'warning':
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;
      default:
        color = Colors.amber;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.orange.shade100),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['message'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  '${alert['percentage']}% of budget used',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No budgets yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first budget',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddBudgetPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Budget'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D9B8E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBudgetInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF2D9B8E)),
            SizedBox(width: 8),
            Text('How Budgets Work'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoItem(
                Icons.calendar_month,
                'Monthly Tracking',
                'Budgets track expenses for the current month only',
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                Icons.trending_up,
                'Real-Time Updates',
                'Progress updates automatically as you add expenses',
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                Icons.warning_amber_rounded,
                'Smart Alerts',
                '• 70% used: Info\n• 90% used: Warning\n• 100%+ used: Critical',
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                Icons.category,
                'Multiple Categories',
                'One budget can track multiple expense categories',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF2D9B8E), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showDeleteDialog(BudgetModel budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Budget'),
        content: Text(
          'Are you sure you want to delete "${budget.name ?? budget.categories.join(', ')}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteBudget(budget.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget deleted successfully'),
            backgroundColor: Color(0xFF2D9B8E),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting budget: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}