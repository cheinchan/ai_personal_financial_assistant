import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/budget_model.dart';

class AddBudgetPage extends StatefulWidget {
  final BudgetModel? existingBudget;
  
  const AddBudgetPage({super.key, this.existingBudget});

  @override
  State<AddBudgetPage> createState() => _AddBudgetPageState();
}

class _AddBudgetPageState extends State<AddBudgetPage> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _nameController = TextEditingController();
  
  String _amount = '0';
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<String> _selectedCategories = {};
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Transport', 'icon': Icons.directions_car, 'color': Colors.orange},
    {'name': 'Food', 'icon': Icons.restaurant, 'color': Colors.green},
    {'name': 'Shopping', 'icon': Icons.card_giftcard, 'color': Colors.blue},
    {'name': 'Health', 'icon': Icons.favorite, 'color': Colors.teal},
    {'name': 'Clothes', 'icon': Icons.checkroom, 'color': Colors.deepPurple},
    {'name': 'Baby', 'icon': Icons.child_care, 'color': Colors.pinkAccent},
    {'name': 'Insurance', 'icon': Icons.shield, 'color': Colors.grey},
    {'name': 'Home', 'icon': Icons.home, 'color': Colors.red.shade300},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingBudget != null) {
      _amount = widget.existingBudget!.amount.toInt().toString();
      _nameController.text = widget.existingBudget!.name ?? '';
      _startDate = widget.existingBudget!.startDate;
      _endDate = widget.existingBudget!.endDate;
      _selectedCategories.addAll(widget.existingBudget!.categories);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.existingBudget != null ? 'Edit Budget' : 'Add Budget',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Display
                    _buildAmountDisplay(),
                    
                    const SizedBox(height: 24),
                    
                    // Budget Setting Section
                    const Text(
                      'Budget Setting',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Budget Name
                    _buildTextField(
                      controller: _nameController,
                      hint: 'budget name',
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Date Fields
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            hint: 'start date',
                            date: _startDate,
                            onTap: () => _selectDate(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            hint: 'end date',
                            date: _endDate,
                            onTap: () => _selectDate(false),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Category Selection
                    const Text(
                      'From category',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildCategoryGrid(),
                    
                    const SizedBox(height: 24),
                    
                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D9B8E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Confirm',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Custom Numeric Keypad
          _buildNumericKeypad(),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _amount,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 16),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'MYR',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D9B8E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String hint,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('MMM d, y').format(date)
                    : hint,
                style: TextStyle(
                  fontSize: 14,
                  color: date != null ? Colors.black87 : Colors.grey.shade400,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 18,
              color: const Color(0xFF2D9B8E),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final isSelected = _selectedCategories.contains(category['name']);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedCategories.remove(category['name']);
              } else {
                _selectedCategories.add(category['name']);
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected 
                    ? category['color'] 
                    : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: category['color'].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              category['icon'],
              color: category['color'],
              size: 32,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumericKeypad() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          _buildKeypadRow(['1', '2', '3', '+']),
          const SizedBox(height: 8),
          _buildKeypadRow(['4', '5', '6', '-']),
          const SizedBox(height: 8),
          _buildKeypadRow(['7', '8', '9', '=']),
          const SizedBox(height: 8),
          _buildKeypadRow(['clear', '0', 'backspace']),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        if (key == 'clear') {
          return Expanded(
            child: _buildKeyButton(
              onTap: () => setState(() => _amount = '0'),
              child: Icon(
                Icons.clear,
                color: Colors.grey.shade600,
                size: 24,
              ),
            ),
          );
        } else if (key == 'backspace') {
          return Expanded(
            child: _buildKeyButton(
              onTap: _handleBackspace,
              child: Icon(
                Icons.backspace_outlined,
                color: Colors.grey.shade600,
                size: 24,
              ),
            ),
          );
        } else if (key == '+' || key == '-' || key == '=') {
          return Expanded(
            child: _buildKeyButton(
              onTap: () {}, // Operators not functional in this version
              child: Text(
                key,
                style: TextStyle(
                  fontSize: 24,
                  color: const Color(0xFF2D9B8E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        } else {
          return Expanded(
            child: _buildKeyButton(
              onTap: () => _handleNumberPress(key),
              child: Text(
                key,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  Widget _buildKeyButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 50,
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }

  void _handleNumberPress(String number) {
    setState(() {
      if (_amount == '0') {
        _amount = number;
      } else {
        _amount += number;
      }
    });
  }

  void _handleBackspace() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2D9B8E),
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
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _handleConfirm() async {
    // Validation
    if (_amount == '0' || _amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a budget amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final budget = BudgetModel(
        id: widget.existingBudget?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        amount: double.parse(_amount),
        categories: _selectedCategories.toList(),
        startDate: _startDate,
        endDate: _endDate,
        createdAt: widget.existingBudget?.createdAt ?? DateTime.now(),
      );

      if (widget.existingBudget != null) {
        await _firestoreService.updateBudget(budget);
      } else {
        await _firestoreService.addBudget(budget);
      }

      if (!mounted) return;
      
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingBudget != null
                ? 'Budget updated successfully'
                : 'Budget created successfully',
          ),
          backgroundColor: const Color(0xFF2D9B8E),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving budget: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}