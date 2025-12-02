import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/budget_model.dart';
import '../widgets/custom_numeric_keypad.dart';

class AddBudgetPage extends StatefulWidget {
  const AddBudgetPage({super.key});

  @override
  State<AddBudgetPage> createState() => _AddBudgetPageState();
}

class _AddBudgetPageState extends State<AddBudgetPage> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _budgetNameController = TextEditingController();

  String _amount = '0';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;  // ✅ CHANGED: Single category instead of list
  bool _showKeypad = false;

  // Categories - EXACTLY matching Add Transaction pages
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Transport',
      'icon': Icons.directions_car,
      'color': Color(0xFFFF9800),
    },
    {
      'name': 'Food',
      'icon': Icons.restaurant_menu,
      'color': Color(0xFF4CAF50),
    },
    {
      'name': 'Shopping',
      'icon': Icons.card_giftcard,
      'color': Color(0xFF2196F3),
    },
    {
      'name': 'Bills',
      'icon': Icons.attach_money,
      'color': Color(0xFF00BCD4),
    },
    {
      'name': 'Entertainment',
      'icon': Icons.nightlight_round,
      'color': Color(0xFF9C27B0),
    },
    {
      'name': 'Health',
      'icon': Icons.favorite,
      'color': Color(0xFFE91E63),
    },
    {
      'name': 'Fitness',
      'icon': Icons.fitness_center,
      'color': Color(0xFF616161),
    },
    {
      'name': 'Other',
      'icon': Icons.home,
      'color': Color(0xFF9E9E9E),
    },
  ];

  @override
  void initState() {
    super.initState();
    // Set default dates to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  @override
  void dispose() {
    _budgetNameController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_amount == '0') {
        _amount = number;
      } else if (_amount.length < 8) {
        _amount += number;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amount.isNotEmpty) {
        _amount = _amount.substring(0, _amount.length - 1);
        if (_amount.isEmpty) {
          _amount = '0';
        }
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _endDate;
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2D9B8E),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = DateTime(picked.year, picked.month + 1, 0);
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _startDate!.isAfter(picked)) {
            _startDate = DateTime(picked.year, picked.month, 1);
          }
        }
      });
    }
  }

  // ✅ CHANGED: Select only ONE category at a time (like Goal setting)
  void _selectCategory(String category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null;  // Deselect if tapping same category
      } else {
        _selectedCategory = category;  // Select new category
      }
    });
  }

  Future<void> _confirmBudget() async {
    // Validate amount
    if (_amount == '0' || double.parse(_amount) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid budget amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ CHANGED: Validate single category
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category to track'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate dates
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = _authService.currentUser;
    if (user == null) return;

    try {
      // ✅ FIXED: Generate proper budget ID (not empty string!)
      final budgetId = 'budget_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
      
      final budget = BudgetModel(
        id: budgetId,  // ✅ FIXED: Proper ID instead of empty string
        userId: user.uid,
        name: _budgetNameController.text.trim().isEmpty
            ? '$_selectedCategory Budget'  // ✅ CHANGED: Single category name
            : _budgetNameController.text.trim(),
        amount: double.parse(_amount),
        categories: [_selectedCategory!],  // ✅ CHANGED: Single category in list
        startDate: _startDate!,
        endDate: _endDate!,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addBudget(budget);

      if (!mounted) return;

      // ✅ CHANGED: Success message for single category
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Budget created! System will track $_selectedCategory expenses and notify you when approaching limit',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2D9B8E),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating budget: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_showKeypad) {
          setState(() => _showKeypad = false);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFD4E8E4),
        appBar: AppBar(
          backgroundColor: const Color(0xFFD4E8E4),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Add Budget',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Display
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showKeypad = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _showKeypad
                          ? const Color(0xFF2D9B8E)
                          : Colors.grey.shade300,
                      width: _showKeypad ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _amount,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'MYR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D9B8E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Budget Name
              const Text(
                'Budget Name (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _budgetNameController,
                decoration: InputDecoration(
                  hintText: 'e.g., Monthly Food Budget',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Budget Period
              const Text(
                'Budget Period',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDateButton('Start Date', _startDate,
                        () => _selectDate(context, true)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateButton('End Date', _endDate,
                        () => _selectDate(context, false)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ✅ CHANGED: Select ONE Category to Track (not multiple)
              const Text(
                'Select Category to Track',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose one expense category this budget will monitor',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),

              // Category Grid - SINGLE SELECTION ONLY
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['name'];  // ✅ CHANGED

                  return GestureDetector(
                    onTap: () => _selectCategory(category['name']),  // ✅ CHANGED
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon Container
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: const Color(0xFF2D9B8E),
                                    width: 3,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            category['icon'],
                            color: category['color'],
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Category Name
                        Text(
                          category['name'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF2D9B8E)
                                : Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Info Card - UPDATED MESSAGE
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'System will track expenses in the selected category and notify you at 70%, 90%, and when budget is exceeded',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _confirmBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D9B8E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Numeric Keypad
              if (_showKeypad) ...[
                CustomNumericKeypad(
                  onNumberPressed: _onNumberPressed,
                  onBackspace: _onBackspace,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null ? DateFormat('dd MMM').format(date) : 'Select',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF2D9B8E),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}