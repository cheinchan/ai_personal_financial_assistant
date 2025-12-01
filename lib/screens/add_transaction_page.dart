import 'package:flutter/material.dart';
import 'add_income_page.dart';
import 'add_expense_page.dart';
import 'add_goal_page.dart';

/// Add Transaction Page Content (No Scaffold, No Bottom Nav)
/// This will be embedded in MainNavigation at index 2
class AddTransactionPageContent extends StatefulWidget {
  const AddTransactionPageContent({super.key});

  @override
  State<AddTransactionPageContent> createState() => _AddTransactionPageContentState();
}

class _AddTransactionPageContentState extends State<AddTransactionPageContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: 1, // Default to "New Expenses"
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4E8E4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4E8E4),
        elevation: 0,
        automaticallyImplyLeading: false, // No back button!
        title: const Text(
          'Add transaction',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBar(
              controller: _tabController,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: Color(0xFF2D9B8E),
                  width: 3,
                ),
              ),
              labelColor: const Color(0xFF2D9B8E),
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'New income'),
                Tab(text: 'New Expenses'),
                Tab(text: 'New Goals'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AddIncomePage(),
          AddExpensePage(),
          AddGoalPage(),
        ],
      ),
    );
  }
}