import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'add_transaction_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  String _selectedPeriod = 'Daily';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4E8E4),
      body: SafeArea(
        child: StreamBuilder<List<TransactionModel>>(
          stream: _firestoreService.getTransactions(),
          builder: (context, transactionSnapshot) {
            return StreamBuilder<List<GoalModel>>(
              stream: _firestoreService.getGoals(),
              builder: (context, goalSnapshot) {
                if (transactionSnapshot.connectionState == ConnectionState.waiting ||
                    goalSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D9B8E)),
                    ),
                  );
                }

                final transactions = transactionSnapshot.data ?? [];
                final goals = goalSnapshot.data ?? [];

                return _buildDashboard(transactions, goals);
              },
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDashboard(List<TransactionModel> transactions, List<GoalModel> goals) {
    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;

    for (var transaction in transactions) {
      if (transaction.type == 'income') {
        totalIncome += transaction.amount;
      } else if (transaction.type == 'expense') {
        totalExpense += transaction.amount;
      }
    }

    final expensePercentage = totalIncome > 0 ? (totalExpense / totalIncome * 100).round() : 0;
    final budget = 20000.0; // You can make this dynamic

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          _buildHeader(totalIncome, totalExpense, expensePercentage, budget),

          // Period Filter Buttons
          _buildPeriodFilter(),

          // Chart Section
          _buildChartSection(transactions),

          // Income & Expense Cards
          _buildIncomeExpenseCards(totalIncome, totalExpense),

          const SizedBox(height: 20),

          // Cash Flow & Goals Tabbed Section
          _buildTransactionsAndGoals(transactions, goals),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeader(double income, double expense, int percentage, double budget) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
                color: Colors.black87,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Income & Expense Display
          Row(
            children: [
              // Total Income
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_down, size: 16, color: Color(0xFF2D9B8E)),
                        const SizedBox(width: 4),
                        const Text(
                          'Total Income',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${NumberFormat('#,##0.00').format(income)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
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
                        const Icon(Icons.trending_up, size: 16, color: Colors.black54),
                        const SizedBox(width: 4),
                        const Text(
                          'Total Expense',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '-\$${NumberFormat('#,##0.00').format(expense)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${NumberFormat('#,##0.00').format(budget)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status Message
          Row(
            children: [
              const Icon(Icons.check_circle, size: 16, color: Color(0xFF2D9B8E)),
              const SizedBox(width: 8),
              Text(
                '$percentage% Of Your Expenses, Looks Good.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    final periods = ['Daily', 'Weekly', 'Monthly', 'Year'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2D9B8E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  period,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartSection(List<TransactionModel> transactions) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Chart Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '16k',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D9B8E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_month, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bar Chart
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 15000,
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
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
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
                      reservedSize: 32,
                      interval: 5000,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000).toInt()}k',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _getBarGroups(transactions),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups(List<TransactionModel> transactions) {
    // Calculate daily totals for the week
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    List<double> dailyTotals = List.filled(7, 0.0);
    
    for (var transaction in transactions) {
      final daysDiff = transaction.createdAt.difference(weekStart).inDays;
      if (daysDiff >= 0 && daysDiff < 7 && transaction.type == 'expense') {
        dailyTotals[daysDiff] += transaction.amount;
      }
    }

    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: dailyTotals[index],
            color: const Color(0xFF2D9B8E),
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildIncomeExpenseCards(double income, double expense) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D9B8E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.trending_down,
                          color: Color(0xFF2D9B8E),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Income',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${NumberFormat('#,##0.00').format(income)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.trending_up,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Expense',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${NumberFormat('#,##0.00').format(expense)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsAndGoals(List<TransactionModel> transactions, List<GoalModel> goals) {
    return _TabbedSection(transactions: transactions, goals: goals);
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
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddTransactionPage(initialTab: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D9B8E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
              _buildNavItem(Icons.people_outline, 'Advices', false),
              _buildNavItem(Icons.person_outline, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
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
    );
  }
}

// Tabbed Section Widget
class _TabbedSection extends StatefulWidget {
  final List<TransactionModel> transactions;
  final List<GoalModel> goals;

  const _TabbedSection({
    required this.transactions,
    required this.goals,
  });

  @override
  State<_TabbedSection> createState() => _TabbedSectionState();
}

class _TabbedSectionState extends State<_TabbedSection> {
  int _selectedTab = 0; // 0 = Cash Flow, 1 = Goals Progress

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Tab Headers
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD4E8E4).withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                        ),
                        border: _selectedTab == 0
                            ? const Border(
                                bottom: BorderSide(
                                  color: Color(0xFF2D9B8E),
                                  width: 3,
                                ),
                              )
                            : null,
                      ),
                      child: Text(
                        'Cash Flow',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedTab == 0 ? const Color(0xFF2D9B8E) : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                        ),
                        border: _selectedTab == 1
                            ? const Border(
                                bottom: BorderSide(
                                  color: Color(0xFF2D9B8E),
                                  width: 3,
                                ),
                              )
                            : null,
                      ),
                      child: Text(
                        'Goals Progress',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedTab == 1 ? const Color(0xFF2D9B8E) : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Container(
            padding: const EdgeInsets.all(20),
            child: _selectedTab == 0
                ? _buildCashFlowContent()
                : _buildGoalsProgressContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowContent() {
    final recentTransactions = widget.transactions.take(3).toList();

    if (recentTransactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            'No transactions yet',
            style: TextStyle(color: Colors.black38, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: recentTransactions.map((transaction) {
        final categoryMap = {
          'Transport': {'icon': Icons.directions_car, 'color': const Color(0xFFF59E0B)},
          'Food': {'icon': Icons.restaurant, 'color': const Color(0xFF10B981)},
          'Shopping': {'icon': Icons.card_giftcard, 'color': const Color(0xFF3B82F6)},
          'Bills': {'icon': Icons.monetization_on, 'color': const Color(0xFF06B6D4)},
          'Entertainment': {'icon': Icons.nightlight_round, 'color': const Color(0xFFA855F7)},
          'Health': {'icon': Icons.favorite, 'color': const Color(0xFFEC4899)},
          'Fitness': {'icon': Icons.fitness_center, 'color': const Color(0xFF6B7280)},
          'Home': {'icon': Icons.home, 'color': const Color(0xFFF97316)},
        };

        IconData icon = Icons.attach_money;
        Color iconColor = const Color(0xFFF59E0B);

        if (transaction.category != null && categoryMap.containsKey(transaction.category)) {
          icon = categoryMap[transaction.category]!['icon'] as IconData;
          iconColor = categoryMap[transaction.category]!['color'] as Color;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd MMMM yyyy').format(transaction.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaction.category ?? 'Transaction',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
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
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalsProgressContent() {
    final activeGoals = widget.goals.take(2).toList();

    if (activeGoals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            'No goals yet',
            style: TextStyle(color: Colors.black38, fontSize: 14),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: activeGoals.map((goal) {
        final progress = goal.progress / 100;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: Colors.white.withOpacity(0.5),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${goal.progress.toInt()}%',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                goal.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}