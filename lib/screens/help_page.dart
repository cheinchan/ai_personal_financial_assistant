import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D9B8E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Search functionality
              showSearch(
                context: context,
                delegate: HelpSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D9B8E), Color(0xFF1F7A6E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.help_outline, size: 48, color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'How can we help you?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Find answers to common questions and learn how to use the app',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Start
          _buildHelpSection(
            context,
            icon: Icons.play_circle_outline,
            title: 'Quick Start',
            color: const Color(0xFF10B981),
            items: [
              'Getting started with your financial journey',
              'Creating your first transaction',
              'Understanding the dashboard',
              'Setting up your profile',
            ],
            onTap: () => _showHelpDetail(context, _getQuickStartContent()),
          ),

          // Budgets
          _buildHelpSection(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Managing Budgets',
            color: const Color(0xFF3B82F6),
            items: [
              'Setting monthly budget limits',
              'Tracking category spending',
              'Understanding budget alerts',
              'Tips for staying on budget',
            ],
            onTap: () => _showHelpDetail(context, _getBudgetsContent()),
          ),

          // Goals
          _buildHelpSection(
            context,
            icon: Icons.flag_outlined,
            title: 'Setting Goals',
            color: const Color(0xFFF59E0B),
            items: [
              'Creating savings goals',
              'Setting realistic targets',
              'Tracking progress',
              'Completing your goals',
            ],
            onTap: () => _showHelpDetail(context, _getGoalsContent()),
          ),

          // AI Assistant
          _buildHelpSection(
            context,
            icon: Icons.lightbulb_outline,
            title: 'AI Financial Assistant',
            color: const Color(0xFFA855F7),
            items: [
              'Getting personalized advice',
              'Understanding recommendations',
              'Using the AI chat',
              'Improving financial health',
            ],
            onTap: () => _showHelpDetail(context, _getAssistantContent()),
          ),

          // Reports
          _buildHelpSection(
            context,
            icon: Icons.assessment_outlined,
            title: 'Reports & Analytics',
            color: const Color(0xFFEC4899),
            items: [
              'Viewing spending reports',
              'Understanding charts',
              'Exporting data',
              'Monthly summaries',
            ],
            onTap: () => _showHelpDetail(context, _getReportsContent()),
          ),

          // Notifications
          _buildHelpSection(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            color: const Color(0xFF06B6D4),
            items: [
              'Managing notification settings',
              'Budget alerts',
              'Goal reminders',
              'Email notifications',
            ],
            onTap: () => _showHelpDetail(context, _getNotificationsContent()),
          ),

          // Troubleshooting
          _buildHelpSection(
            context,
            icon: Icons.build_outlined,
            title: 'Troubleshooting',
            color: const Color(0xFFEF4444),
            items: [
              'Common issues and fixes',
              'Syncing problems',
              'Login difficulties',
              'Data not showing',
            ],
            onTap: () => _showHelpDetail(context, _getTroubleshootingContent()),
          ),

          const SizedBox(height: 24),

          // Contact Support
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Still need help?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Contact our support team for personalized assistance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Support contact feature coming soon!'),
                        backgroundColor: Color(0xFF2D9B8E),
                      ),
                    );
                  },
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Contact Support'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D9B8E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required List<String> items,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${items.length} articles',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpDetail(BuildContext context, Map<String, dynamic> content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HelpDetailPage(content: content),
      ),
    );
  }

  // Content Methods
  Map<String, dynamic> _getQuickStartContent() {
    return {
      'title': 'Quick Start Guide',
      'icon': Icons.play_circle_outline,
      'color': const Color(0xFF10B981),
      'sections': [
        {
          'title': 'Getting Started',
          'content':
              'Welcome to AI Personal Financial Assistant! This app helps you manage your finances, track expenses, set goals, and get AI-powered advice.\n\nStart by exploring the dashboard to see an overview of your financial situation.',
        },
        {
          'title': 'Creating Your First Transaction',
          'content':
              '1. Tap the + button at the bottom center\n2. Choose Income or Expense\n3. Enter the amount using the numeric keypad\n4. Select a category\n5. Tap Confirm to save\n\nYour transaction will appear on the dashboard immediately.',
        },
        {
          'title': 'Understanding the Dashboard',
          'content':
              'The dashboard shows:\n\n• Total Income and Expenses\n• Weekly spending chart\n• Recent transactions\n• Goal progress\n\nSwipe between "Cash Flow" and "Goals Progress" tabs to see different views.',
        },
        {
          'title': 'Setting Up Your Profile',
          'content':
              'Go to Profile → Edit Profile to:\n\n• Update personal information\n• Set your preferred currency\n• Configure notification preferences\n• Customize app settings',
        },
      ],
    };
  }

  Map<String, dynamic> _getBudgetsContent() {
    return {
      'title': 'Managing Budgets',
      'icon': Icons.account_balance_wallet_outlined,
      'color': const Color(0xFF3B82F6),
      'sections': [
        {
          'title': 'Setting Monthly Budget Limits',
          'content':
              'Budgets help you control spending in different categories:\n\n1. Go to Budget page\n2. View pre-set category limits\n3. Track your spending against these limits\n4. Adjust as needed for your lifestyle',
        },
        {
          'title': 'Tracking Category Spending',
          'content':
              'Each category shows:\n\n• Total budget limit\n• Amount spent so far\n• Remaining budget\n• Percentage used\n\nProgress bars change color:\n• Green: Under 70%\n• Yellow: 70-90%\n• Orange: 90-100%\n• Red: Over budget',
        },
        {
          'title': 'Understanding Budget Alerts',
          'content':
              'You\'ll receive alerts when:\n\n• Reaching 80% of category budget\n• Exceeding budget limits\n• Monthly budget reset\n• Unusual spending detected',
        },
        {
          'title': 'Tips for Staying on Budget',
          'content':
              '• Review your budget weekly\n• Set realistic limits\n• Track daily expenses\n• Use cash for problem categories\n• Adjust budgets seasonally\n• Celebrate when you stay under budget',
        },
      ],
    };
  }

  Map<String, dynamic> _getGoalsContent() {
    return {
      'title': 'Setting Financial Goals',
      'icon': Icons.flag_outlined,
      'color': const Color(0xFFF59E0B),
      'sections': [
        {
          'title': 'Creating Savings Goals',
          'content':
              'Set up goals to save for things that matter:\n\n1. Tap + button and select "New Goals"\n2. Enter goal name (e.g., "Vacation", "Emergency Fund")\n3. Set target amount\n4. Choose start and end dates\n5. Select a category\n6. Tap Confirm\n\nYour goal appears on the dashboard with a progress circle.',
        },
        {
          'title': 'Setting Realistic Targets',
          'content':
              'Tips for achievable goals:\n\n• Start with small goals to build confidence\n• Consider your monthly income\n• Account for fixed expenses\n• Set a reasonable timeline\n• Break large goals into milestones\n• Review and adjust as needed',
        },
        {
          'title': 'Tracking Progress',
          'content':
              'Monitor your goals:\n\n• View progress percentage on dashboard\n• Check days remaining until deadline\n• See how much you\'ve saved\n• Track contribution history\n• Get milestone notifications',
        },
        {
          'title': 'Completing Your Goals',
          'content':
              'When you reach a goal:\n\n• You\'ll receive a congratulations notification\n• Goal marked as complete\n• Option to set a new goal\n• View goal history in reports\n• Share your achievement',
        },
      ],
    };
  }

  Map<String, dynamic> _getAssistantContent() {
    return {
      'title': 'AI Financial Assistant',
      'icon': Icons.lightbulb_outline,
      'color': const Color(0xFFA855F7),
      'sections': [
        {
          'title': 'Getting Personalized Advice',
          'content':
              'The AI Assistant analyzes your spending patterns to provide:\n\n• Budget optimization tips\n• Savings suggestions\n• Spending warnings\n• Investment opportunities\n• Goal recommendations\n\nAdvice updates automatically as you use the app.',
        },
        {
          'title': 'Understanding Recommendations',
          'content':
              'Advice types:\n\n🟡 Warning: High spending alerts\n🟢 Tip: General financial advice\n🔵 Opportunity: Investment suggestions\n\nEach recommendation includes:\n• Category affected\n• Specific advice\n• Expected impact\n• Action steps',
        },
        {
          'title': 'Using the AI Chat',
          'content':
              'Chat with the AI Assistant to:\n\n• Ask financial questions\n• Get personalized guidance\n• Understand reports\n• Learn about features\n• Request specific advice\n\nTap "Ask AI" button on Advices page to start chatting.',
        },
        {
          'title': 'Improving Financial Health',
          'content':
              'The AI learns from your habits:\n\n• Follow weekly recommendations\n• Review monthly insights\n• Implement suggested changes\n• Track your progress\n• Adjust based on feedback\n\nBetter data = better advice!',
        },
      ],
    };
  }

  Map<String, dynamic> _getReportsContent() {
    return {
      'title': 'Reports & Analytics',
      'icon': Icons.assessment_outlined,
      'color': const Color(0xFFEC4899),
      'sections': [
        {
          'title': 'Viewing Spending Reports',
          'content':
              'Access detailed reports:\n\n• Go to Budget or Dashboard\n• View weekly, monthly, or yearly data\n• Filter by category\n• Compare time periods\n• Identify spending trends',
        },
        {
          'title': 'Understanding Charts',
          'content':
              'Chart types:\n\n• Bar Chart: Daily/weekly spending\n• Pie Chart: Category breakdown\n• Line Chart: Trends over time\n• Progress Bars: Budget usage\n\nTap charts for detailed information.',
        },
        {
          'title': 'Exporting Data',
          'content':
              'Export your financial data:\n\n1. Go to Profile\n2. Select "Export Data"\n3. Choose date range\n4. Select format (CSV, PDF)\n5. Choose categories\n6. Tap Export\n\nUse exported data for:\n• Tax preparation\n• Financial planning\n• Personal analysis\n• Backup purposes',
        },
        {
          'title': 'Monthly Summaries',
          'content':
              'At month-end, receive:\n\n• Total income and expenses\n• Category breakdowns\n• Budget performance\n• Goal progress\n• Spending insights\n• Next month recommendations\n\nSummaries are saved in your account.',
        },
      ],
    };
  }

  Map<String, dynamic> _getNotificationsContent() {
    return {
      'title': 'Notifications',
      'icon': Icons.notifications_outlined,
      'color': const Color(0xFF06B6D4),
      'sections': [
        {
          'title': 'Managing Notification Settings',
          'content':
              'Customize your notifications:\n\n1. Go to Profile → Edit Profile\n2. Scroll to Notifications section\n3. Toggle Push Notifications on/off\n4. Enable/disable Email Notifications\n5. Changes save automatically',
        },
        {
          'title': 'Budget Alerts',
          'content':
              'Receive alerts for:\n\n• Reaching 80% of budget\n• Exceeding budget limits\n• Unusual spending patterns\n• Weekly budget summaries\n\nTiming: Real-time push notifications',
        },
        {
          'title': 'Goal Reminders',
          'content':
              'Stay on track with:\n\n• Weekly contribution reminders\n• Milestone achievements\n• Approaching deadlines\n• Goal completion celebrations\n\nCustomize reminder frequency in settings.',
        },
        {
          'title': 'Email Notifications',
          'content':
              'Monthly email reports include:\n\n• Financial summary\n• Spending breakdown\n• Goal progress\n• AI recommendations\n• Upcoming bills\n\nEmails sent on the 1st of each month.',
        },
      ],
    };
  }

  Map<String, dynamic> _getTroubleshootingContent() {
    return {
      'title': 'Troubleshooting',
      'icon': Icons.build_outlined,
      'color': const Color(0xFFEF4444),
      'sections': [
        {
          'title': 'Common Issues and Fixes',
          'content':
              'Quick solutions:\n\n• App slow? Clear cache in settings\n• Missing data? Pull down to refresh\n• Can\'t add transaction? Check internet connection\n• Charts not updating? Restart the app\n• Settings not saving? Re-login',
        },
        {
          'title': 'Syncing Problems',
          'content':
              'If data isn\'t syncing:\n\n1. Check internet connection\n2. Verify you\'re logged in\n3. Pull down to refresh\n4. Force close and reopen app\n5. Log out and log back in\n6. Contact support if persists',
        },
        {
          'title': 'Login Difficulties',
          'content':
              'Can\'t log in?\n\n• Verify email and password\n• Check for typos\n• Use "Forgot Password" if needed\n• Ensure account is verified\n• Check email for verification link\n• Clear app cache\n• Reinstall app if necessary',
        },
        {
          'title': 'Data Not Showing',
          'content':
              'If transactions or goals don\'t appear:\n\n1. Pull down to refresh\n2. Check date filters\n3. Verify you\'re logged in correctly\n4. Ensure transaction was saved (check for success message)\n5. Check Firebase connection\n6. Contact support with screenshot',
        },
      ],
    };
  }
}

// Help Detail Page
class HelpDetailPage extends StatelessWidget {
  final Map<String, dynamic> content;

  const HelpDetailPage({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
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
          content['title'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: content['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: content['color'].withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  content['icon'],
                  color: content['color'],
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    content['title'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: content['color'],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sections
          ...List<Widget>.generate(
            content['sections'].length,
            (index) {
              final section = content['sections'][index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: content['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: content['color'],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            section['title'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      section['content'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Was this helpful?
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Was this helpful?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thanks for your feedback!'),
                            backgroundColor: Color(0xFF2D9B8E),
                          ),
                        );
                      },
                      icon: const Icon(Icons.thumb_up_outlined),
                      label: const Text('Yes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D9B8E),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('We\'ll improve this article!'),
                            backgroundColor: Color(0xFF2D9B8E),
                          ),
                        );
                      },
                      icon: const Icon(Icons.thumb_down_outlined),
                      label: const Text('No'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Help Search Delegate
class HelpSearchDelegate extends SearchDelegate<String> {
  final List<String> searchTerms = [
    'budget',
    'goal',
    'transaction',
    'password',
    'notification',
    'report',
    'chart',
    'export',
    'sync',
    'login',
  ];

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Text('Search results for: $query'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = searchTerms
        .where((term) => term.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.search),
          title: Text(suggestions[index]),
          onTap: () {
            query = suggestions[index];
            showResults(context);
          },
        );
      },
    );
  }
}