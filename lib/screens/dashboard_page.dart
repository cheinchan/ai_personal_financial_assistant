import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedPeriod = 'Daily';
  
  // Sample data for demonstration
  final double totalIncome = 7783.00;
  final double totalExpenses = 1187.40;
  final Map<String, double> weeklyExpenses = {
    'Mon': 8,
    'Tue': 12,
    'Wed': 5,
    'Thu': 15,
    'Fri': 8,
    'Sat': 3,
    'Sun': 10,
  };

  @override
  Widget build(BuildContext context) {
    final double balance = totalIncome - totalExpenses;
    final double expensePercentage = (totalExpenses / totalIncome * 100);

    return Scaffold(
      backgroundColor: const Color(0xFFD4E8E4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 30),

                // Income and Expense Cards
                _buildFinancialSummary(balance, expensePercentage),
                const SizedBox(height: 25),

                // Period Selector
                _buildPeriodSelector(),
                const SizedBox(height: 20),

                // Chart
                _buildChart(),
                const SizedBox(height: 25),

                // Cash Flow and Goals Progress
                _buildBottomCards(),
                const SizedBox(height: 25),

                // Recent Transactions
                _buildRecentTransactions(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E1E1E),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Color(0xFF1E1E1E),
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummary(double balance, double expensePercentage) {
    return Row(
      children: [
        // Total Income Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D9B8E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_downward,
                        color: Color(0xFF2D9B8E),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Total Income',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '\$${NumberFormat('#,##0.00').format(totalIncome)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D9B8E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '30%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D9B8E),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '\$${NumberFormat('#,##0.00').format(20000.00)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2D9B8E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Color(0xFF2D9B8E),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '30% Of Your Expenses. Looks Good.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 15),

        // Total Expense Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        color: Color(0xFFEF4444),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Total Expense',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '-\$${NumberFormat('#,##0.00').format(totalExpenses)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D9B8E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '30%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D9B8E),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '\$${NumberFormat('#,##0.00').format(20000.00)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2D9B8E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Color(0xFF2D9B8E),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '30% Of Your Expenses. Looks Good.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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
              onTap: () {
                setState(() {
                  selectedPeriod = period;
                });
              },
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
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                'Expense Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.more_horiz,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            days[value.toInt()],
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}k',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFFF3F4F6),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  final day = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: weeklyExpenses[day]!,
                        color: const Color(0xFF2D9B8E),
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCards() {
    return Row(
      children: [
        // Cash Flow Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D9B8E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        color: Color(0xFF2D9B8E),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Cash Flow',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '\$4,120.00',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 15),

        // Goals Progress Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.flag_outlined,
                        color: Color(0xFF3B82F6),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Goals Progress',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      '30%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Car',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 20),
          _buildTransactionItem(
            icon: Icons.directions_car,
            iconColor: const Color(0xFFF59E0B),
            title: 'Car',
            date: '12 February 2022',
            amount: '-500 MYR',
            isExpense: true,
          ),
          const Divider(height: 24),
          _buildTransactionItem(
            icon: Icons.lightbulb_outline,
            iconColor: const Color(0xFFEF4444),
            title: 'Electric',
            date: '12 February 2022',
            amount: '-100 MYR',
            isExpense: true,
          ),
          const Divider(height: 24),
          _buildTransactionItem(
            icon: Icons.home_outlined,
            iconColor: const Color(0xFF3B82F6),
            title: 'Grandma\'s present',
            date: '12 February 2022',
            amount: '-1000 MYR',
            isExpense: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String date,
    required String amount,
    required bool isExpense,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
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
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF2D9B8E),
          ),
        ),
      ],
    );
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
              _buildNavItem(Icons.add_circle, '', false, isCenter: true),
              _buildNavItem(Icons.people_outline, 'Advices', false),
              _buildNavItem(Icons.person_outline, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, {bool isCenter = false}) {
    if (isCenter) {
      return Container(
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
      );
    }

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