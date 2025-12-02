import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

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
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.spent / widget.budget.amount * 100).clamp(0, 100);
    final remaining = widget.budget.amount - widget.spent;
    final currencyFormat = NumberFormat.currency(symbol: 'MYR ', decimalDigits: 2);

    // Determine status
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (percentage >= 100) {
      statusColor = Colors.red;
      statusText = 'Over Budget';
      statusIcon = Icons.error;
    } else if (percentage >= 90) {
      statusColor = Colors.orange;
      statusText = 'Critical - Slow Down!';
      statusIcon = Icons.warning_amber_rounded;
    } else if (percentage >= 70) {
      statusColor = Colors.amber;
      statusText = 'Warning - Watch Spending';
      statusIcon = Icons.info;
    } else {
      statusColor = Colors.green;
      statusText = 'On Track';
      statusIcon = Icons.check_circle;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D9B8E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.budget.name ?? widget.budget.categories.join(' & '),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTransactions = snapshot.data ?? [];
          
          // Filter transactions for this budget's categories (current month)
          final now = DateTime.now();
          final budgetTransactions = allTransactions.where((t) {
            return t.type == 'expense' &&
                   t.category != null &&
                   widget.budget.categories.contains(t.category) &&
                   t.createdAt.year == now.year &&
                   t.createdAt.month == now.month;
          }).toList();

          // Sort by date (newest first)
          budgetTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Calculate per-category spending
          final Map<String, double> categorySpending = {};
          for (var transaction in budgetTransactions) {
            final category = transaction.category!;
            categorySpending[category] = (categorySpending[category] ?? 0) + transaction.amount;
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Status Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: statusColor,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currencyFormat.format(widget.spent),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'of ${currencyFormat.format(widget.budget.amount)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 12,
                          backgroundColor: Colors.white30,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${percentage.toInt()}% used',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            remaining >= 0
                                ? '${currencyFormat.format(remaining)} left'
                                : '${currencyFormat.format(remaining.abs())} over',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Budget Info Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Period',
                        '${DateFormat('MMM dd').format(widget.budget.startDate)} - ${DateFormat('MMM dd, yyyy').format(widget.budget.endDate)}',
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.receipt_long,
                        'Transactions',
                        '${budgetTransactions.length} expenses',
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.category,
                        'Categories',
                        widget.budget.categories.join(', '),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Per-Category Breakdown
                if (categorySpending.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...categorySpending.entries.map((entry) {
                          final categoryPercentage = (entry.value / widget.spent * 100);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(entry.value),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2D9B8E),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: categoryPercentage / 100,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF2D9B8E),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${categoryPercentage.toInt()}% of total spending',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Transaction History
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Transaction History',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${budgetTransactions.length} total',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (budgetTransactions.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: budgetTransactions.length,
                          separatorBuilder: (context, index) => const Divider(height: 24),
                          itemBuilder: (context, index) {
                            final transaction = budgetTransactions[index];
                            return _buildTransactionItem(transaction);
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2D9B8E), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
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
    };

    final icon = categoryIcons[transaction.category] ?? Icons.category;
    final currencyFormat = NumberFormat.currency(symbol: 'MYR ', decimalDigits: 2);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.red, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.category ?? 'Expense',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM dd, yyyy - hh:mm a').format(transaction.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          currencyFormat.format(transaction.amount),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}