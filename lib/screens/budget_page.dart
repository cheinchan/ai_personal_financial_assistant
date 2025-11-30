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

              // Calculate financial summary
              double totalIncome = 0;
              double totalExpense = 0;
              
              for (var transaction in transactions) {
                if (transaction.type == 'income') {
                  totalIncome += transaction.amount;
                } else {
                  totalExpense += transaction.amount;
                }
              }

              final cash = totalIncome - totalExpense;
              final displayBudgets = _showAll ? budgets : budgets.take(5).toList();

              return Column(
                children: [
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
                          const Text(
                            'Budget Category',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
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
                                        transactions,
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
    // Calculate spending for this budget's categories
    double spent = 0;
    for (var transaction in transactions) {
      if (transaction.category != null &&
          budget.categories.contains(transaction.category)) {
        // Filter by date if budget has date range
        if (budget.startDate != null && 
            transaction.createdAt.isBefore(budget.startDate!)) {
          continue;
        }
        if (budget.endDate != null && 
            transaction.createdAt.isAfter(budget.endDate!)) {
          continue;
        }
        spent += transaction.amount;
      }
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
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
                    DateFormat('d MMMM y').format(budget.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    budget.name ?? primaryCategory,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${budget.amount.toInt()} MYR',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
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
        ],
      ),
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