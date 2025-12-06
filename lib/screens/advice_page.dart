import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';

class AdvicePage extends StatefulWidget {
  const AdvicePage({super.key});

  @override
  State<AdvicePage> createState() => _AdvicePageState();
}

class _AdvicePageState extends State<AdvicePage> {
  final _geminiService = GeminiService();
  final _firestoreService = FirestoreService();
  final _questionController = TextEditingController();

  bool _isLoadingInsights = false;
  bool _isLoadingAnswer = false;
  bool? _connectionStatus; // Track connection silently
  String? _aiInsights;
  String? _currentAnswer;

  List<TransactionModel> _transactions = [];
  double _totalIncome = 0;
  double _totalExpenses = 0;
  Map<String, double> _categoryExpenses = {};

  @override
  void initState() {
    super.initState();
    _testAIConnection(); // Test silently in background
    _loadData();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  /// Test AI connection silently in background
  Future<void> _testAIConnection() async {
    try {
      final isConnected = await _geminiService.testConnection();
      setState(() {
        _connectionStatus = isConnected;
      });

      // Only show error if connection fails
      if (!isConnected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                      '⚠️ AI connection issue. Please check your API key.'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _connectionStatus = false;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      final transactions = await _firestoreService.getTransactionsOnce();

      double income = 0;
      double expenses = 0;
      Map<String, double> categories = {};

      for (var transaction in transactions) {
        if (transaction.type == 'income') {
          income += transaction.amount;
        } else if (transaction.type == 'expense') {
          expenses += transaction.amount;
          final category = transaction.category ?? 'Other';
          categories[category] =
              (categories[category] ?? 0) + transaction.amount;
        }
      }

      setState(() {
        _transactions = transactions;
        _totalIncome = income;
        _totalExpenses = expenses;
        _categoryExpenses = categories;
      });

      // Auto-generate insights
      _generateInsights();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _generateInsights() async {
    if (_totalIncome == 0 && _totalExpenses == 0) {
      setState(() {
        _aiInsights =
            'Add some transactions to get personalized financial insights!';
      });
      return;
    }

    setState(() {
      _isLoadingInsights = true;
    });

    try {
      final insights = await _geminiService.getFinancialAdvice(
        totalIncome: _totalIncome,
        totalExpenses: _totalExpenses,
        categoryExpenses: _categoryExpenses,
      );

      setState(() {
        _aiInsights = insights;
        _isLoadingInsights = false;
      });
    } catch (e) {
      setState(() {
        _aiInsights = 'Unable to generate insights. Please try again.';
        _isLoadingInsights = false;
      });
    }
  }

  Future<void> _askQuestion(String question) async {
    if (question.trim().isEmpty) return;

    setState(() {
      _isLoadingAnswer = true;
      _currentAnswer = null;
    });

    try {
      final answer = await _geminiService.askQuestion(
        question,
        totalIncome: _totalIncome,
        totalExpenses: _totalExpenses,
      );

      setState(() {
        _currentAnswer = answer;
        _isLoadingAnswer = false;
      });

      _questionController.clear();
    } catch (e) {
      setState(() {
        _currentAnswer = 'Unable to get answer. Please try again.';
        _isLoadingAnswer = false;
      });
    }
  }

  Future<void> _getCategoryAdvice(String category, double spent) async {
    setState(() {
      _isLoadingAnswer = true;
      _currentAnswer = null;
    });

    try {
      final budget = _totalIncome * 0.3; // Example: 30% of income as budget
      final answer = await _geminiService.getCategoryAdvice(
        category: category,
        spent: spent,
        budget: budget,
      );

      setState(() {
        _currentAnswer = answer;
        _isLoadingAnswer = false;
      });
    } catch (e) {
      setState(() {
        _currentAnswer = 'Unable to get advice. Please try again.';
        _isLoadingAnswer = false;
      });
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
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Financial Assistant',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Row(
                        children: [
                          // Refresh button with subtle connection indicator
                          IconButton(
                            onPressed: () async {
                              await _loadData();
                              await _testAIConnection();
                            },
                            icon: Icon(
                              Icons.refresh,
                              color: _connectionStatus == false
                                  ? Colors.orange
                                  : Colors.black,
                            ),
                            tooltip: _connectionStatus == false
                                ? 'AI connection issue - Tap to retry'
                                : 'Refresh',
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.more_vert),
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Financial Assistant Card
                  _buildFinancialAssistantCard(),
                  const SizedBox(height: 20),

                  // Insight Section
                  _buildInsightSection(),
                  const SizedBox(height: 20),

                  // Current Answer Section
                  if (_currentAnswer != null) ...[
                    _buildAnswerSection(),
                    const SizedBox(height: 20),
                  ],

                  // Ask the Assistant Section
                  _buildAskAssistantSection(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFB8E4DA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'How it Works',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildHowItWorksItem(
              '1. AI analyzes your budget, expenses, income & goals'),
          _buildHowItWorksItem('2. Learns your spending patterns over time'),
          _buildHowItWorksItem(
              '3. Predicts risks and nudges you before overspending'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _generateInsights,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2D9B8E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Got It',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 18,
            color: Color(0xFF2D9B8E),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insight',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoadingInsights)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D9B8E)),
                ),
              ),
            )
          else if (_aiInsights != null)
            Text(
              _aiInsights!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            )
          else
            const Text(
              'Loading insights...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

          const SizedBox(height: 16),

          // Category-specific insights
          if (_categoryExpenses.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 16),
            ..._categoryExpenses.entries.take(3).map((entry) {
              final percentage = _totalIncome > 0
                  ? (entry.value / _totalIncome * 100).round()
                  : 0;
              final isOverBudget = percentage > 30;
              final isWarning = percentage > 20 && percentage <= 30;

              Color iconColor;
              IconData icon;
              String status;

              if (isOverBudget) {
                iconColor = const Color(0xFFEF4444);
                icon = Icons.error_outline;
                status = 'Over budget';
              } else if (isWarning) {
                iconColor = const Color(0xFF3B82F6);
                icon = Icons.warning_amber_rounded;
                status = 'Close to limit';
              } else {
                iconColor = const Color(0xFF10B981);
                icon = Icons.check_circle_outline;
                status = 'On track';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildInsightCard(
                  icon: icon,
                  iconColor: iconColor,
                  title: '$status: ${entry.key}',
                  subtitle:
                      'You ${isOverBudget ? "have spent" : "are at"} $percentage% of recommended budget',
                  onTap: () => _getCategoryAdvice(entry.key, entry.value),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Row(
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
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2D9B8E),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text(
            'Try Advice',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D9B8E).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb,
                color: Color(0xFF2D9B8E),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Assistant',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D9B8E),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _currentAnswer = null),
                icon: const Icon(Icons.close, size: 18),
                color: Colors.grey[600],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currentAnswer!,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAskAssistantSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ask the Assistant',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // Example questions
          _buildExampleQuestion('What to contribute to hit a goal?'),
          _buildExampleQuestion('How to stop overspending?'),
          const SizedBox(height: 16),

          // Input field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    hintText: 'Ask for tips',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: _askQuestion,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF2D9B8E),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isLoadingAnswer
                      ? null
                      : () => _askQuestion(_questionController.text),
                  icon: _isLoadingAnswer
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExampleQuestion(String question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _askQuestion(question),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.help_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
