import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import 'add_transaction_page.dart';
import 'report_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedPeriod = 'Daily';
  final _firestoreService = FirestoreService();
  
  // Data variables
  List<TransactionModel> transactions = [];
  List<GoalModel> goals = [];
  double totalIncome = 0;
  double totalExpenses = 0;
  double balance = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch transactions and goals
      final fetchedTransactions = await _firestoreService.getTransactionsOnce();
      final fetchedGoals = await _firestoreService.getGoalsOnce();
      
      // Calculate totals
      double income = 0;
      double expenses = 0;
      
      for (var transaction in fetchedTransactions) {
        if (transaction.type == 'income') {
          income += transaction.amount;
        } else if (transaction.type == 'expense') {
          expenses += transaction.amount;
        }
      }

      setState(() {
        transactions = fetchedTransactions;
        goals = fetchedGoals;
        totalIncome = income;
        totalExpenses = expenses;
        balance = income - expenses;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4E8E4),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF2D9B8E),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D9B8E)),
                  ),
                )
              : _buildContent(),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildContent() {
    final recentTransactions = transactions.take(3).toList();
    final weeklyExpenses = _calculateWeeklyExpenses(transactions);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),

            // Income and Expense Cards with Progress
            _buildFinancialSummaryCards(totalIncome, totalExpenses),
            const SizedBox(height: 24),

            // Empty state or content
            if (transactions.isEmpty)
              _buildEmptyState()
            else ...[
              // Period Selector
              _buildPeriodSelector(),
              const SizedBox(height: 20),

              // Chart
              _buildExpenseChart(weeklyExpenses),
              const SizedBox(height: 20),

              // Income/Expense Summary Cards
              _buildIncomeExpenseCards(balance, totalExpenses),
              const SizedBox(height: 20),

              // Cash Flow and Goals Progress
              _buildCashFlowAndGoals(balance),
              const SizedBox(height: 20),

              // Recent Transactions
              if (recentTransactions.isNotEmpty)
                _buildRecentTransactions(recentTransactions),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateWeeklyExpenses(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    final Map<String, double> weeklyExpenses = {
      'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0,
    };

    for (var transaction in transactions) {
      if (transaction.type == 'expense') {
        final daysDiff = transaction.createdAt.difference(startOfWeek).inDays;
        if (daysDiff >= 0 && daysDiff < 7) {
          final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][daysDiff];
          weeklyExpenses[dayName] = (weeklyExpenses[dayName] ?? 0) + (transaction.amount / 1000);
        }
      }
    }

    return weeklyExpenses;
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ReportPage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Colors.black,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummaryCards(double totalIncome, double totalExpenses) {
    final expensePercentage = totalIncome > 0 ? (totalExpenses / totalIncome * 100).toInt() : 0;
    final targetBudget = 20000.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Income and Expense Row
          Row(
            children: [
              // Total Income
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          'Total Income',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${NumberFormat('#,##0.00').format(totalIncome)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              // Total Expense
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          'Total Expense',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '-\$${NumberFormat('#,##0.00').format(totalExpenses)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$expensePercentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (expensePercentage / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D9B8E),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '\$${NumberFormat('#,##0.00').format(targetBudget)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status Message
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                '$expensePercentage% Of Your Expenses, Looks Good.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'No Transactions Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start tracking your finances by adding your first transaction',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddTransactionPage(initialTab: 0),
                ),
              );
              // Refresh data when returning
              _loadData();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Transaction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D9B8E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['Daily', 'Weekly', 'Monthly', 'Year'].map((period) {
          final isSelected = selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedPeriod = period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2D9B8E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpenseChart(Map<String, double> weeklyExpenses) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '15k',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D9B8E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.bar_chart, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 15,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              days[value.toInt()],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == 5 || value == 10 || value == 15) {
                          return Text(
                            '${value.toInt()}k',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200],
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _createBarGroups(weeklyExpenses),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _createBarGroups(Map<String, double> weeklyExpenses) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return List.generate(7, (index) {
      final day = days[index];
      final value = weeklyExpenses[day] ?? 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value.clamp(0, 15),
            color: const Color(0xFF2D9B8E),
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildIncomeExpenseCards(double balance, double expenses) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D9B8E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: Color(0xFF2D9B8E),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Income',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${NumberFormat('#,##0.00').format(balance)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_downward,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Expense',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${NumberFormat('#,##0.00').format(expenses)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCashFlowAndGoals(double balance) {
    return Column(
      children: [
        // Cash Flow and Goals Progress Headers
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cash Flow',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${NumberFormat('#,##0.00').format(balance)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goals Progress',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Track your goals',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // Goals Circular Progress Indicators
        if (goals.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: goals.take(2).map((goal) {
                final progress = goal.targetAmount > 0 
                    ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
                    : 0.0;
                return _buildCircularGoalProgress(
                  goal.name,
                  progress,
                  goal.category ?? 'Other',
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCircularGoalProgress(String name, double progress, String category) {
    final percentage = (progress * 100).round();
    final color = _getCategoryColor(category);
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            // Progress circle
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            // Percentage text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'travel':
        return const Color(0xFF60A5FA); // Light blue
      case 'car':
        return const Color(0xFF3B82F6); // Blue
      case 'home':
        return const Color(0xFF10B981); // Green
      case 'education':
        return const Color(0xFF8B5CF6); // Purple
      case 'health':
        return const Color(0xFFEC4899); // Pink
      case 'shopping':
        return const Color(0xFFF59E0B); // Orange
      default:
        return const Color(0xFF2D9B8E); // Teal (default)
    }
  }

  Widget _buildRecentTransactions(List<TransactionModel> transactions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all transactions page
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2D9B8E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...transactions.asMap().entries.map((entry) {
            final index = entry.key;
            final transaction = entry.value;
            return Column(
              children: [
                if (index > 0) const Divider(height: 20),
                _buildTransactionItem(transaction),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final isExpense = transaction.type == 'expense';
    final categoryIcon = _getCategoryIcon(transaction.category);
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: categoryIcon['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            categoryIcon['icon'],
            color: categoryIcon['color'],
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.category ?? transaction.type.toUpperCase(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMMM yyyy').format(transaction.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          '${isExpense ? '-' : '+'}${NumberFormat('#,##0').format(transaction.amount)} MYR',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF2D9B8E),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'car':
      case 'transport':
        return {'icon': Icons.directions_car, 'color': const Color(0xFF60A5FA)};
      case 'electric':
      case 'electricity':
      case 'utilities':
      case 'bills':
        return {'icon': Icons.bolt, 'color': const Color(0xFFEAB308)};
      case 'gift':
      case 'present':
      case 'grandma\'s present':
        return {'icon': Icons.card_giftcard, 'color': const Color(0xFFEC4899)};
      case 'food':
      case 'restaurant':
        return {'icon': Icons.restaurant, 'color': const Color(0xFF10B981)};
      case 'shopping':
        return {'icon': Icons.shopping_bag, 'color': const Color(0xFF3B82F6)};
      case 'entertainment':
        return {'icon': Icons.movie, 'color': const Color(0xFFA855F7)};
      case 'health':
      case 'medical':
        return {'icon': Icons.favorite, 'color': const Color(0xFFEF4444)};
      case 'fitness':
      case 'gym':
        return {'icon': Icons.fitness_center, 'color': const Color(0xFF6B7280)};
      case 'home':
      case 'rent':
        return {'icon': Icons.home, 'color': const Color(0xFFF97316)};
      case 'education':
      case 'school':
        return {'icon': Icons.school, 'color': const Color(0xFF8B5CF6)};
      case 'travel':
        return {'icon': Icons.flight, 'color': const Color(0xFF06B6D4)};
      default:
        return {'icon': Icons.attach_money, 'color': const Color(0xFF2D9B8E)};
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.grid_view_rounded, 'Dashboard', true),
              _buildNavItem(Icons.bar_chart_rounded, 'Budget', false),
              _buildNavItem(Icons.add_circle, '', false, isCenter: true, onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionPage(initialTab: 1),
                  ),
                );
                // Refresh data when returning
                _loadData();
              }),
              _buildNavItem(Icons.people_outline, 'Advices', false),
              _buildNavItem(Icons.person_outline, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive,
      {bool isCenter = false, VoidCallback? onTap}) {
    if (isCenter) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFF2D9B8E),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF2D9B8E) : const Color(0xFF9CA3AF),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? const Color(0xFF2D9B8E) : const Color(0xFF9CA3AF),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}