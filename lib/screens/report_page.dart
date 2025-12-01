import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';

/// Report Page
/// Shows monthly expense breakdown with pie chart and category details
class ReportPage extends StatefulWidget {
  final DateTime selectedDate;

  const ReportPage({super.key, required this.selectedDate});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _firestoreService = FirestoreService();
  late DateTime _displayDate;

  @override
  void initState() {
    super.initState();
    _displayDate = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4E8E4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4E8E4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report',
          style: TextStyle(
            color: Colors.black87,
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
          
          // Filter transactions for selected month
          final monthTransactions = allTransactions.where((t) {
            return t.type == 'expense' &&
                   t.createdAt.year == _displayDate.year &&
                   t.createdAt.month == _displayDate.month;
          }).toList();

          // Calculate category totals
          final categoryTotals = <String, double>{};
          double totalExpenses = 0;

          for (var transaction in monthTransactions) {
            final category = transaction.category ?? 'Other';
            categoryTotals[category] = (categoryTotals[category] ?? 0) + transaction.amount;
            totalExpenses += transaction.amount;
          }

          // Sort categories by amount (descending)
          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return SingleChildScrollView(
            child: Column(
              children: [
                // Month Display
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMMM').format(_displayDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        DateFormat('yyyy').format(_displayDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Pie Chart
                if (sortedCategories.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // Simple Pie Chart using Stack and positioned containers
                        SizedBox(
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pie chart visualization
                              CustomPaint(
                                size: const Size(180, 180),
                                painter: PieChartPainter(
                                  categories: sortedCategories,
                                  total: totalExpenses,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Legend
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: sortedCategories.take(6).map((entry) {
                            final percentage = (entry.value / totalExpenses * 100).toInt();
                            final color = _getCategoryColor(entry.key);
                            
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$percentage%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Categories List
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (sortedCategories.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No expenses for this month',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        ...sortedCategories.map((entry) {
                          final percentage = (entry.value / totalExpenses * 100).toInt();
                          final color = _getCategoryColor(entry.key);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      '${entry.value.toInt()} MYR',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    minHeight: 24,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Download report functionality can be added here
        },
        backgroundColor: const Color(0xFF2D9B8E),
        child: const Icon(Icons.download),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food': const Color(0xFFFFB84D),
      'Rent': const Color(0xFFFF9999),
      'Loans': const Color(0xFFFF9999),
      'Education': const Color(0xFFA3C1FF),
      'Clothing': const Color(0xFFD4A5D8),
      'Health': const Color(0xFFD4E8E4),
      'Transport': Colors.orange,
      'Shopping': Colors.blue,
      'Bills': Colors.red,
      'Entertainment': Colors.purple,
      'Fitness': Colors.teal,
      'Home': Colors.red.shade300,
      'Car': const Color(0xFFA3C1FF),
    };
    return colors[category] ?? Colors.grey;
  }
}

/// Custom Pie Chart Painter
class PieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> categories;
  final double total;

  PieChartPainter({required this.categories, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    double startAngle = -90 * 3.14159 / 180; // Start from top

    for (var entry in categories) {
      final sweepAngle = (entry.value / total) * 2 * 3.14159;
      final color = _getCategoryColor(entry.key);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Draw white circle in center for donut effect
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  Color _getCategoryColor(String category) {
    final colors = {
      'Food': const Color(0xFFFFB84D),
      'Rent': const Color(0xFFFF9999),
      'Loans': const Color(0xFFFF9999),
      'Education': const Color(0xFFA3C1FF),
      'Clothing': const Color(0xFFD4A5D8),
      'Health': const Color(0xFFD4E8E4),
      'Transport': Colors.orange,
      'Shopping': Colors.blue,
      'Bills': Colors.red,
      'Entertainment': Colors.purple,
      'Fitness': Colors.teal,
      'Home': Colors.red.shade300,
      'Car': const Color(0xFFA3C1FF),
    };
    return colors[category] ?? Colors.grey;
  }
}