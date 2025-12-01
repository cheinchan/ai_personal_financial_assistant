import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import 'report_page.dart';
import 'goal_detail_page.dart';

/// Feature 5: Visual Dashboards and Analytics
/// 
/// This dashboard provides:
/// - Visual representation of spending trends
/// - Savings history tracking
/// - Category breakdowns
/// - Customizable views (Daily, Weekly, Monthly, Year)
/// - User-friendly visualizations for financial beginners
/// - Real-time data updates from Firebase
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  
  // Customizable period filter (Feature 5: Customizable views)
  String _selectedPeriod = 'Monthly';
  late TabController _tabController;
  
  // Cache for performance optimization
  Map<String, double>? _cachedSummary;
  List<TransactionModel>? _cachedFilteredTransactions;
  String? _lastPeriodCalculated;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          'Dashboard',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // AI-driven notifications indicator
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: _showAINotifications,
          ),
        ],
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _firestoreService.getTransactions(),
        builder: (context, transactionSnapshot) {
          if (transactionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = transactionSnapshot.data ?? [];
          
          // Cache filtered transactions to avoid recalculating
          if (_lastPeriodCalculated != _selectedPeriod || _cachedFilteredTransactions == null) {
            _cachedFilteredTransactions = _filterTransactionsByPeriod(transactions);
            _cachedSummary = _calculateFinancialSummary(_cachedFilteredTransactions!);
            _lastPeriodCalculated = _selectedPeriod;
          }

          return RefreshIndicator(
            color: const Color(0xFF2D9B8E),
            onRefresh: () async {
              // Clear cache to force recalculation
              setState(() {
                _cachedSummary = null;
                _cachedFilteredTransactions = null;
                _lastPeriodCalculated = null;
              });
              // Wait a bit for the StreamBuilder to rebuild with fresh data
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Period Indicator - Show which period the totals represent
                  _buildPeriodIndicator(),
                  
                  const SizedBox(height: 12),
                  
                  // Feature 2: Automated Financial Summary Card
                  _buildAutomatedFinancialSummary(_cachedSummary!),

                  const SizedBox(height: 20),

                  // Feature 5: Customizable Period Filter (Daily, Weekly, Monthly, Year)
                  _buildCustomizablePeriodFilter(),

                const SizedBox(height: 20),

                // Feature 5: Visual Spending Trends Chart
                _buildSpendingTrendsChart(_cachedFilteredTransactions!),

                const SizedBox(height: 20),

                // Tabbed Section: Cash Flow & Goals Progress
                _buildTabbedAnalytics(transactions),

                const SizedBox(height: 80),
              ],
            ),
          ),
          );
        },
      ),
    );
  }

  /// Period Indicator - Shows which period the totals represent
  /// Makes it user-friendly so users know "Total Income for December 2025"
  Widget _buildPeriodIndicator() {
    final now = DateTime.now();
    String periodText = '';
    String dateRangeText = '';

    switch (_selectedPeriod) {
      case 'Daily':
        periodText = 'Today';
        dateRangeText = DateFormat('MMM d, yyyy').format(now);
        break;
      case 'Weekly':
        final weekAgo = now.subtract(const Duration(days: 7));
        periodText = 'This Week';
        dateRangeText = '${DateFormat('MMM d').format(weekAgo)} - ${DateFormat('MMM d, yyyy').format(now)}';
        break;
      case 'Monthly':
        periodText = 'This Month';
        dateRangeText = DateFormat('MMMM yyyy').format(now); // e.g., "December 2025"
        break;
      case 'Year':
        periodText = 'This Year';
        dateRangeText = DateFormat('yyyy').format(now); // e.g., "2025"
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D9B8E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedPeriod == 'Daily' ? Icons.today :
            _selectedPeriod == 'Weekly' ? Icons.date_range :
            _selectedPeriod == 'Monthly' ? Icons.calendar_month :
            Icons.calendar_today,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                periodText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                dateRangeText,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Feature 1 & 2: Calculate real-time financial summary
  /// - Income, Expense, and Savings
  /// - Automated calculations without manual input
  Map<String, double> _calculateFinancialSummary(List<TransactionModel> filteredTransactions) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var transaction in filteredTransactions) {
      if (transaction.type == 'income') {
        totalIncome += transaction.amount;
      } else if (transaction.type == 'expense') {
        totalExpense += transaction.amount;
      }
    }

    final savings = totalIncome - totalExpense;
    
    return {
      'income': totalIncome,
      'expense': totalExpense,
      'savings': savings,
    };
  }

  /// Feature 2: Automated Financial Summary Display
  /// Shows income, expenditure, and savings with rule-based insights
  Widget _buildAutomatedFinancialSummary(Map<String, double> summary) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    
    final income = summary['income'] ?? 0;
    final expense = summary['expense'] ?? 0;
    final savings = summary['savings'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Income and Expense Display (Feature 1)
          Row(
            children: [
              Expanded(
                child: _buildFinancialMetric(
                  'Total Income',
                  currencyFormat.format(income),
                  Icons.arrow_downward,
                  Colors.grey[600]!,
                  Colors.black87,
                ),
              ),
              Expanded(
                child: _buildFinancialMetric(
                  'Total Expense',
                  '-${currencyFormat.format(expense)}',
                  Icons.arrow_upward,
                  Colors.grey[600]!,
                  const Color(0xFF2D9B8E),
                ),
              ),
            ],
          ),

          // Savings Display (Feature 1: Savings Logging)
          if (savings > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.savings_outlined, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Savings: ${currencyFormat.format(savings)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialMetric(String label, String value, IconData icon, Color iconColor, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  /// Feature 5: Customizable Period Filter
  /// Allows users to view data by Daily, Weekly, Monthly, or Year
  Widget _buildCustomizablePeriodFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildPeriodButton('Daily'),
          const SizedBox(width: 8),
          _buildPeriodButton('Weekly'),
          const SizedBox(width: 8),
          _buildPeriodButton('Monthly'),
          const SizedBox(width: 8),
          _buildPeriodButton('Year'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedPeriod != period) {
            setState(() {
              _selectedPeriod = period;
              // Invalidate cache to recalculate
              _cachedFilteredTransactions = null;
              _cachedSummary = null;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2D9B8E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2D9B8E).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  /// Feature 5: Visual Spending Trends Chart
  /// Represents spending trends at a glance for easy comprehension
  Widget _buildSpendingTrendsChart(List<TransactionModel> filteredTransactions) {
    final chartData = _getChartData(filteredTransactions);
    final labels = _getChartLabels();
    final maxValue = _getMaxY(chartData);

    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Trends ($_selectedPeriod)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: _showDatePickerForReport,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D9B8E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.calendar_month,
                        size: 18,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Report',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                chartData.length > 7 ? 7 : chartData.length,
                (index) {
                  final value = chartData[index];
                  final height = maxValue > 0 ? (value / maxValue * 150) : 0;
                  final displayIndex = chartData.length > 7 
                      ? (index * chartData.length ~/ 7) 
                      : index;
                  
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Bar
                          Container(
                            height: height.clamp(5.0, 150.0).toDouble(),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D9B8E),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Label
                          Text(
                            labels[displayIndex < labels.length ? displayIndex : 0],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Feature 5: Tabbed Analytics Section
  /// Cash Flow and Goals Progress for better organization
  Widget _buildTabbedAnalytics(List<TransactionModel> transactions) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF2D9B8E),
            indicatorWeight: 3,
            labelColor: const Color(0xFF2D9B8E),
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.swap_horiz, size: 20),
                text: 'Cash Flow',
              ),
              Tab(
                icon: Icon(Icons.flag_outlined, size: 20),
                text: 'Goals Progress',
              ),
            ],
          ),
          SizedBox(
            height: 280,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCashFlowTab(transactions),
                _buildGoalsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Separate goals tab with its own StreamBuilder
  Widget _buildGoalsTab() {
    return StreamBuilder<List<GoalModel>>(
      stream: _firestoreService.getGoals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        
        final goals = snapshot.data ?? [];
        return _buildGoalsProgressTab(goals);
      },
    );
  }

  /// Feature 1: Cash Flow Visualization
  /// Shows structured cash flow and spending priorities
  Widget _buildCashFlowTab(List<TransactionModel> allTransactions) {
    // Use cached filtered transactions if available
    final filteredTransactions = _cachedFilteredTransactions ?? _filterTransactionsByPeriod(allTransactions);
    
    double income = 0;
    double expense = 0;

    for (var transaction in filteredTransactions) {
      if (transaction.type == 'income') {
        income += transaction.amount;
      } else {
        expense += transaction.amount;
      }
    }

    // Show ALL transactions for the selected period
    final recentTransactions = filteredTransactions;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCashFlowCard(
                  'Income',
                  '\$${income.toInt()}',
                  Icons.arrow_downward,
                  const Color(0xFF2D9B8E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCashFlowCard(
                  'Expense',
                  '\$${expense.toInt()}',
                  Icons.arrow_upward,
                  const Color(0xFF2D9B8E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: recentTransactions.isEmpty
                ? Center(
                    child: Text(
                      'No transactions yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: recentTransactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionRow(recentTransactions[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowCard(String label, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Feature 1: Categorized Transaction Display
  /// Shows transactions with categories for better insight
  Widget _buildTransactionRow(TransactionModel transaction) {
    // Use const maps for better performance
    const categoryIcons = {
      'Transport': Icons.directions_car,
      'Food': Icons.restaurant,
      'Shopping': Icons.card_giftcard,
      'Bills': Icons.receipt_long,
      'Entertainment': Icons.movie,
      'Health': Icons.favorite,
      'Fitness': Icons.fitness_center,
      'Home': Icons.home,
    };

    // Use static color values
    final categoryColors = {
      'Transport': Colors.orange,
      'Food': Colors.green,
      'Shopping': Colors.blue,
      'Bills': Colors.red,
      'Entertainment': Colors.purple,
      'Health': Colors.pink,
      'Fitness': Colors.teal,
      'Home': Colors.red.shade300,
    };

    final category = transaction.category ?? 'Other';
    final icon = categoryIcons[category] ?? Icons.category;
    final color = categoryColors[category] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  DateFormat('MMM d').format(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${transaction.type == 'expense' ? '-' : '+'}\$${transaction.amount.toInt()}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: transaction.type == 'expense' ? Colors.red : const Color(0xFF2D9B8E),
            ),
          ),
        ],
      ),
    );
  }

  /// Feature 3: Goals Progress Visualization
  /// Shows savings goals with visual indicators (progress bars)
  Widget _buildGoalsProgressTab(List<GoalModel> goals) {
    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No goals yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Show ALL goals for the user in a scrollable grid
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: goals.map((goal) => _buildGoalProgressCard(goal)).toList(),
      ),
    );
  }

  /// Feature 3: Goal Progress Card with Visual Indicators
  /// Circular progress bars to enhance motivation
  Widget _buildGoalProgressCard(GoalModel goal) {
    final progress = (goal.currentAmount / goal.targetAmount * 100).clamp(0, 100).toInt();

    return GestureDetector(
      onTap: () => _navigateToGoalDetail(goal),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D9B8E), Color(0xFF1F7A6E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: progress / 100,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Text(
                  '$progress%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              goal.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to Goal Detail page for viewing and editing
  void _navigateToGoalDetail(GoalModel goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalDetailPage(goal: goal),
      ),
    );
  }

  // Helper methods for data filtering and chart generation
  
  List<TransactionModel> _filterTransactionsByPeriod(List<TransactionModel> transactions) {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'Daily':
        return transactions.where((t) {
          return t.createdAt.year == now.year &&
                 t.createdAt.month == now.month &&
                 t.createdAt.day == now.day;
        }).toList();
      case 'Weekly':
        final weekAgo = now.subtract(const Duration(days: 7));
        return transactions.where((t) => t.createdAt.isAfter(weekAgo)).toList();
      case 'Monthly':
        return transactions.where((t) {
          return t.createdAt.year == now.year && t.createdAt.month == now.month;
        }).toList();
      case 'Year':
        return transactions.where((t) => t.createdAt.year == now.year).toList();
      default:
        return transactions;
    }
  }

  List<double> _getChartData(List<TransactionModel> transactions) {
    // Simplified chart data for memory efficiency
    if (_selectedPeriod == 'Daily') {
      // Show only 7 hours instead of 24
      final hourlyData = List<double>.filled(7, 0.0);
      for (var t in transactions) {
        if (t.type == 'expense') {
          final hourIndex = (t.createdAt.hour ~/ 4).clamp(0, 6);
          hourlyData[hourIndex] += t.amount;
        }
      }
      return hourlyData;
    } else if (_selectedPeriod == 'Weekly') {
      final dailyData = List<double>.filled(7, 0.0);
      final now = DateTime.now();
      for (var t in transactions) {
        if (t.type == 'expense') {
          final daysDiff = now.difference(t.createdAt).inDays;
          if (daysDiff >= 0 && daysDiff < 7) {
            dailyData[6 - daysDiff] += t.amount;
          }
        }
      }
      return dailyData;
    } else if (_selectedPeriod == 'Monthly') {
      final weeklyData = List<double>.filled(4, 0.0);
      for (var t in transactions) {
        if (t.type == 'expense') {
          final weekIndex = ((t.createdAt.day - 1) ~/ 7).clamp(0, 3);
          weeklyData[weekIndex] += t.amount;
        }
      }
      return weeklyData;
    } else {
      // Year view - show only 6 months for memory
      final monthlyData = List<double>.filled(6, 0.0);
      final now = DateTime.now();
      for (var t in transactions) {
        if (t.type == 'expense' && t.createdAt.year == now.year) {
          final monthIndex = ((t.createdAt.month - 1) ~/ 2).clamp(0, 5);
          monthlyData[monthIndex] += t.amount;
        }
      }
      return monthlyData;
    }
  }

  List<String> _getChartLabels() {
    switch (_selectedPeriod) {
      case 'Daily':
        return ['0h', '4h', '8h', '12h', '16h', '20h', '24h'];
      case 'Weekly':
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case 'Monthly':
        return ['W1', 'W2', 'W3', 'W4'];
      case 'Year':
        return ['Jan-Feb', 'Mar-Apr', 'May-Jun', 'Jul-Aug', 'Sep-Oct', 'Nov-Dec'];
      default:
        return [];
    }
  }

  double _getMaxY(List<double> data) {
    if (data.isEmpty) return 20;
    final max = data.reduce((a, b) => a > b ? a : b);
    return max == 0 ? 20 : max + (max * 0.2);
  }

  /// Feature 4: AI-Driven Notifications
  /// Shows alerts and suggestions based on spending patterns
  void _showAINotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Color(0xFF2D9B8E)),
            SizedBox(width: 8),
            Text('AI Insights'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature 4: AI-Driven Advice',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D9B8E),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This feature will provide:\n'
              '• Personalized financial insights\n'
              '• Spending limit alerts\n'
              '• Suggestions based on past behavior\n'
              '• Pattern detection\n'
              '• Alternative behavior recommendations',
              style: TextStyle(fontSize: 14),
            ),
          ],
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

  /// Navigate to Report Page with date picker
  void _showDatePickerForReport() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

    if (picked != null) {
      // Navigate to Report Page with selected date
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportPage(selectedDate: picked),
        ),
      );
    }
  }
}