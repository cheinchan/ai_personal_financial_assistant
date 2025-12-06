import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/goal_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_numeric_keypad.dart';

class AddGoalPage extends StatefulWidget {
  const AddGoalPage({super.key});

  @override
  State<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  String _amount = '0';
  final _nameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;
  String? _customCategory;
  String _selectedPriority = 'medium';
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _showKeypad = false;
  bool _showCustomCategoryInput = false;
  final _amountFocusNode = FocusNode();
  final _customCategoryController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.directions_car, 'color': const Color(0xFFF59E0B), 'label': 'Transport'},
    {'icon': Icons.restaurant, 'color': const Color(0xFF10B981), 'label': 'Food'},
    {'icon': Icons.card_giftcard, 'color': const Color(0xFF3B82F6), 'label': 'Shopping'},
    {'icon': Icons.monetization_on, 'color': const Color(0xFF06B6D4), 'label': 'Savings'},
    {'icon': Icons.nightlight_round, 'color': const Color(0xFFA855F7), 'label': 'Entertainment'},
    {'icon': Icons.home, 'color': const Color(0xFFF97316), 'label': 'Home'},
    {'icon': Icons.flight, 'color': const Color(0xFF8B5CF6), 'label': 'Travel'},
    {'icon': Icons.category, 'color': const Color(0xFF9CA3AF), 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(() {
      setState(() {
        _showKeypad = _amountFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _nameController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_amount == '0') {
        _amount = number;
      } else {
        _amount += number;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  IconData _getSmartIcon(String category) {
    final lowerCategory = category.toLowerCase();
    
    if (lowerCategory.contains('car') || lowerCategory.contains('vehicle') || 
        lowerCategory.contains('transport') || lowerCategory.contains('motorcycle')) {
      return Icons.directions_car;
    }
    
    if (lowerCategory.contains('food') || lowerCategory.contains('restaurant')) {
      return Icons.restaurant;
    }
    
    if (lowerCategory.contains('shop') || lowerCategory.contains('store') ||
        lowerCategory.contains('gift') || lowerCategory.contains('present')) {
      return Icons.card_giftcard;
    }
    
    if (lowerCategory.contains('saving') || lowerCategory.contains('emergency') ||
        lowerCategory.contains('money') || lowerCategory.contains('fund')) {
      return Icons.savings;
    }
    
    if (lowerCategory.contains('entertainment') || lowerCategory.contains('game') ||
        lowerCategory.contains('hobby') || lowerCategory.contains('fun')) {
      return Icons.nightlight_round;
    }
    
    if (lowerCategory.contains('home') || lowerCategory.contains('house') ||
        lowerCategory.contains('apartment') || lowerCategory.contains('furniture')) {
      return Icons.home;
    }
    
    if (lowerCategory.contains('travel') || lowerCategory.contains('vacation') ||
        lowerCategory.contains('holiday') || lowerCategory.contains('trip')) {
      return Icons.flight;
    }
    
    if (lowerCategory.contains('education') || lowerCategory.contains('school') ||
        lowerCategory.contains('course') || lowerCategory.contains('study')) {
      return Icons.school;
    }
    
    if (lowerCategory.contains('wedding') || lowerCategory.contains('marriage')) {
      return Icons.favorite;
    }
    
    if (lowerCategory.contains('baby') || lowerCategory.contains('child')) {
      return Icons.child_care;
    }
    
    if (lowerCategory.contains('phone') || lowerCategory.contains('laptop') ||
        lowerCategory.contains('computer') || lowerCategory.contains('gadget') ||
        lowerCategory.contains('electronic')) {
      return Icons.phone_android;
    }
    
    if (lowerCategory.contains('business') || lowerCategory.contains('startup')) {
      return Icons.business;
    }
    
    if (lowerCategory.contains('invest') || lowerCategory.contains('stock')) {
      return Icons.trending_up;
    }
    
    return Icons.flag;
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
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
          if (_endDate == null || _endDate!.isBefore(picked)) {
            _endDate = picked.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _confirmGoal() async {
    if (_amount == '0' || double.tryParse(_amount) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a goal name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? finalCategory = _selectedCategory;
    if (_selectedCategory == 'Other' && _customCategory != null && _customCategory!.trim().isNotEmpty) {
      finalCategory = _customCategory!.trim();
    }

    if (finalCategory == null || finalCategory == 'Other') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category or enter a custom category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final goal = GoalModel(
        id: '',
        userId: userId,
        name: _nameController.text.trim(),
        targetAmount: double.parse(_amount),
        startDate: _startDate!,
        endDate: _endDate!,
        category: finalCategory,
        createdAt: DateTime.now(),
        priority: _selectedPriority,
      );

      await _firestoreService.addGoal(goal);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goal added successfully!'),
          backgroundColor: Color(0xFF2D9B8E),
        ),
      );

      setState(() {
        _amount = '0';
        _nameController.clear();
        _startDate = null;
        _endDate = null;
        _selectedCategory = null;
        _customCategory = null;
        _selectedPriority = 'medium';
        _showCustomCategoryInput = false;
        _customCategoryController.clear();
        _showKeypad = false;
      });
      _amountFocusNode.unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_showKeypad) {
          _amountFocusNode.unfocus();
        }
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              GestureDetector(
                onTap: () {
                  _amountFocusNode.requestFocus();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _showKeypad ? const Color(0xFF2D9B8E) : Colors.grey[300]!,
                      width: _showKeypad ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _amount,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'MYR',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D9B8E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              const Text(
                'Goal Setting',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'goal name',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2D9B8E), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildDateButton(
                      label: 'start date',
                      date: _startDate,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateButton(
                      label: 'end date',
                      date: _endDate,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Goal Priority',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPriorityButton('High', 'high', Colors.red),
                  const SizedBox(width: 8),
                  _buildPriorityButton('Medium', 'medium', Colors.orange),
                  const SizedBox(width: 8),
                  _buildPriorityButton('Low', 'low', Colors.green),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'From category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['label'];
                  return _buildCategoryIcon(
                    category['icon'] as IconData,
                    category['color'] as Color,
                    category['label'] as String,
                    isSelected,
                  );
                },
              ),

              if (_showCustomCategoryInput) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2D9B8E)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _customCategory != null && _customCategory!.isNotEmpty
                                ? _getSmartIcon(_customCategory!)
                                : Icons.flag,
                            color: const Color(0xFF2D9B8E),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Enter custom goal category:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D9B8E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customCategoryController,
                        decoration: InputDecoration(
                          hintText: 'e.g., New Phone, Vacation, Emergency Fund',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _customCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The system will assign a matching icon automatically',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D9B8E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
              
              if (_showKeypad) ...[
                const SizedBox(height: 24),
                CustomNumericKeypad(
                  onNumberPressed: _onNumberPressed,
                  onBackspace: _onBackspace,
                ),
              ],

              Focus(
                focusNode: _amountFocusNode,
                child: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date == null ? label : DateFormat('MMM dd, yyyy').format(date),
                style: TextStyle(
                  fontSize: 14,
                  color: date == null ? Colors.grey[400] : Colors.black87,
                  fontWeight: date == null ? FontWeight.w400 : FontWeight.w500,
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

  Widget _buildPriorityButton(String label, String value, Color color) {
    final isSelected = _selectedPriority == value;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                const Icon(Icons.check, color: Colors.white, size: 16),
              if (isSelected) const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(IconData icon, Color color, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
          if (label == 'Other') {
            _showCustomCategoryInput = true;
            _customCategory = null;
            _customCategoryController.clear();
          } else {
            _showCustomCategoryInput = false;
            _customCategory = null;
          }
        });
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF2D9B8E) : Colors.grey[300]!,
                width: isSelected ? 3 : 1.5,
              ),
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
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? const Color(0xFF2D9B8E) : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}