import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import 'add_budget_page.dart';

class BudgetDetailPage extends StatefulWidget {
  final BudgetModel budget;
  final double spent;

  const BudgetDetailPage({
    super.key,
    required this.budget,
    required this.spent,
  });

  @override
  State<BudgetDetailPage> createState() => _BudgetDetailPageState();
}

class _BudgetDetailPageState extends State<BudgetDetailPage> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return const SizedBox();

    final percentage = (widget.spent / widget.budget.amount * 100).clamp(0, 100);
    final remaining = widget.budget.amount - widget.spent;

    Color progressColor;
    if (percentage < 70) {
      progressColor = Colors.green;
    } else if (percentage < 90) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D9B8E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.budget.name ?? widget.budget.categories.join(', '),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddBudgetPage(
                    existingBudget: widget.budget,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _showDeleteDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTransactions = snapshot.data ?? [];
          
          // Filter transactions for this budget
          final budgetTransactions = allTransactions.where((t) {
            if (t.type != 'expense') return false;
            if (t.category == null || !widget.budget.categories.contains(t.category)) return false;
            
            // Filter by date range
            if (widget.budget.startDate != null &&
                t.createdAt.isBefore(widget.budget.startDate!)) {
              return false;
            }
            if (widget.budget.endDate != null &&
                t.createdAt.isAfter(widget.budget.endDate!)) {
              return false;
            }
            
            return true;
          }).toList();

          return Column(
            children: [
              // Budget Overview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2D9B8E), Color(0xFF1F7A6E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildOverviewItem(
                          'Budget',
                          '${widget.budget.amount.toInt()} MYR',
                        ),
                        _buildOverviewItem(
                          'Spent',
                          '${widget.spent.toInt()} MYR',
                        ),
                        _buildOverviewItem(
                          remaining >= 0 ? 'Remaining' : 'Over Budget',
                          '${remaining.abs().toInt()} MYR',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 12,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          remaining >= 0 ? Colors.white : Colors.red.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${percentage.toInt()}% used',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Budget Info
              if (widget.budget.startDate != null || widget.budget.endDate != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
                      const Text(
                        'Period',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (widget.budget.startDate != null) ...[
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMM d, y').format(widget.budget.startDate!),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                          if (widget.budget.startDate != null && widget.budget.endDate != null)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('→'),
                            ),
                          if (widget.budget.endDate != null) ...[
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMM d, y').format(widget.budget.endDate!),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

              // Transactions List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${budgetTransactions.length} items',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: budgetTransactions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: budgetTransactions.length,
                        itemBuilder: (context, index) {
                          return _buildTransactionItem(budgetTransactions[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
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

    final categoryName = transaction.category ?? 'Other';
    final icon = categoryIcons[categoryName] ?? Icons.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D9B8E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2D9B8E),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, y • HH:mm').format(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-${transaction.amount.toInt()} MYR',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red,
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
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transactions in ${widget.budget.categories.join(', ')} will appear here',
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

  Future<void> _showDeleteDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Budget'),
        content: Text(
          'Are you sure you want to delete "${widget.budget.name ?? widget.budget.categories.join(', ')}"?',
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
        await _firestoreService.deleteBudget(widget.budget.id);
        if (!mounted) return;
        
        Navigator.of(context).pop(); // Go back to budget list
        
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