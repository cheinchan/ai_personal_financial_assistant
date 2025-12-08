import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:io';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ReportPage extends StatefulWidget {
  final DateTime selectedDate;

  const ReportPage({Key? key, required this.selectedDate}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final FirestoreService _firestoreService = FirestoreService();
  
  DateTime _currentDate = DateTime.now();
  String _selectedPeriod = 'Daily'; // ✅ Defaults to Daily
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate;
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final allTransactions = await _firestoreService.getTransactionsOnce();
      final range = _getDateRange();
      
      setState(() {
        _transactions = allTransactions.where((t) {
          final transactionDate = t.createdAt ?? DateTime.now();
          return transactionDate.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
                 transactionDate.isBefore(range.end.add(const Duration(days: 1)));
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  DateTimeRange _getDateRange() {
    switch (_selectedPeriod) {
      case 'Daily':
        return DateTimeRange(
          start: DateTime(_currentDate.year, _currentDate.month, _currentDate.day),
          end: DateTime(_currentDate.year, _currentDate.month, _currentDate.day, 23, 59, 59),
        );
      case 'Weekly':
        int weekday = _currentDate.weekday;
        DateTime startOfWeek = _currentDate.subtract(Duration(days: weekday - 1));
        DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
        return DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
        );
      case 'Monthly':
        return DateTimeRange(
          start: DateTime(_currentDate.year, _currentDate.month, 1),
          end: DateTime(_currentDate.year, _currentDate.month + 1, 0, 23, 59, 59),
        );
      case 'Year':
        return DateTimeRange(
          start: DateTime(_currentDate.year, 1, 1),
          end: DateTime(_currentDate.year, 12, 31, 23, 59, 59),
        );
      default:
        return DateTimeRange(
          start: DateTime(_currentDate.year, _currentDate.month, _currentDate.day),
          end: DateTime(_currentDate.year, _currentDate.month, _currentDate.day, 23, 59, 59),
        );
    }
  }

  double get _totalIncome {
    return _transactions
        .where((t) => (t.type ?? '').toLowerCase() == 'income')
        .fold(0.0, (sum, t) => sum + (t.amount ?? 0.0));
  }

  double get _totalExpenses {
    return _transactions
        .where((t) => (t.type ?? '').toLowerCase() == 'expense')
        .fold(0.0, (sum, t) => sum + (t.amount ?? 0.0));
  }

  Map<String, double> get _expensesByCategory {
    final expenses = _transactions.where((t) => (t.type ?? '').toLowerCase() == 'expense');
    Map<String, double> breakdown = {};
    
    for (var transaction in expenses) {
      final category = transaction.category ?? 'Other';
      final amount = transaction.amount ?? 0.0;
      breakdown[category] = (breakdown[category] ?? 0) + amount;
    }
    
    return breakdown;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2D9B8E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _currentDate) {
      setState(() => _currentDate = picked);
      await _loadTransactions();
    }
  }

  String _getDisplayDate() {
    switch (_selectedPeriod) {
      case 'Daily':
        return DateFormat('MMM dd, yyyy').format(_currentDate);
      case 'Weekly':
        int weekday = _currentDate.weekday;
        DateTime startOfWeek = _currentDate.subtract(Duration(days: weekday - 1));
        DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('MMM dd').format(startOfWeek)} - ${DateFormat('MMM dd, yyyy').format(endOfWeek)}';
      case 'Monthly':
        return DateFormat('MMMM yyyy').format(_currentDate);
      case 'Year':
        return DateFormat('yyyy').format(_currentDate);
      default:
        return DateFormat('MMM dd, yyyy').format(_currentDate);
    }
  }

  Future<void> _downloadReport() async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Storage permission required'), backgroundColor: Colors.red),
              );
            }
            return;
          }
        }
      }

      final pdf = pw.Document();
      final categories = _expensesByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Financial Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Period: $_selectedPeriod', style: const pw.TextStyle(fontSize: 14)),
                pw.Text('Date: ${_getDisplayDate()}', style: const pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Text('Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Income:'),
                    pw.Text('MYR ${_totalIncome.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Expenses:'),
                    pw.Text('MYR ${_totalExpenses.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Net Balance:'),
                    pw.Text('MYR ${(_totalIncome - _totalExpenses).toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Text('Expense Breakdown', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Percentage', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                      ],
                    ),
                    ...categories.map((entry) {
                      final percentage = _totalExpenses > 0 ? (entry.value / _totalExpenses * 100) : 0.0;
                      return pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(entry.key)),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('MYR ${entry.value.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${percentage.toStringAsFixed(1)}%', textAlign: pw.TextAlign.right)),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.Text('Generated on ${DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ],
            );
          },
        ),
      );

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final fileName = 'report_${_selectedPeriod.toLowerCase()}_${DateFormat('yyyyMMdd').format(_currentDate)}.pdf';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(await pdf.save());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to Downloads/$fileName'), backgroundColor: const Color(0xFF2D9B8E), duration: const Duration(seconds: 3)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
      'Other': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final sortedCategories = _expensesByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

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
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Period Tabs
          Container(
            color: const Color(0xFFD4E8E4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Daily', 'Weekly', 'Monthly', 'Year'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedPeriod = period);
                      _loadTransactions();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2D9B8E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        period,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Date Display - Clickable
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Color(0xFF2D9B8E)),
                      const SizedBox(width: 8),
                      Text(
                        _getDisplayDate(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D9B8E)))
                : _transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No transactions', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
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
                                    SizedBox(
                                      height: 200,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CustomPaint(
                                            size: const Size(180, 180),
                                            painter: PieChartPainter(
                                              categories: sortedCategories,
                                              total: _totalExpenses,
                                              getCategoryColor: _getCategoryColor,
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
                                        final percentage = (_totalExpenses > 0 ? (entry.value / _totalExpenses * 100) : 0).toInt();
                                        final color = _getCategoryColor(entry.key);
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                            ),
                                            const SizedBox(width: 6),
                                            Text('$percentage%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                                            const SizedBox(width: 4),
                                            Text(entry.key, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
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
                                  const Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                                  const SizedBox(height: 16),
                                  ...sortedCategories.map((entry) {
                                    final percentage = (_totalExpenses > 0 ? (entry.value / _totalExpenses * 100) : 0).toInt();
                                    final color = _getCategoryColor(entry.key);
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(entry.key, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                                              Text('${entry.value.toInt()} MYR', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
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
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _downloadReport,
        backgroundColor: const Color(0xFF2D9B8E),
        child: const Icon(Icons.download, color: Colors.white),
      ),
    );
  }
}

/// Custom Pie Chart Painter (Donut style)
class PieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> categories;
  final double total;
  final Color Function(String) getCategoryColor;

  PieChartPainter({
    required this.categories,
    required this.total,
    required this.getCategoryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    double startAngle = -math.pi / 2; // Start from top

    for (var entry in categories) {
      final sweepAngle = (entry.value / total) * 2 * math.pi;
      final color = getCategoryColor(entry.key);

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
}