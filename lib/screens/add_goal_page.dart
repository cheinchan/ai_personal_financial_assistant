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
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.directions_car, 'color': const Color(0xFFF59E0B), 'label': 'Transport'},
    {'icon': Icons.restaurant, 'color': const Color(0xFF10B981), 'label': 'Food'},
    {'icon': Icons.card_giftcard, 'color': const Color(0xFF3B82F6), 'label': 'Shopping'},
    {'icon': Icons.monetization_on, 'color': const Color(0xFF06B6D4), 'label': 'Bills'},
    {'icon': Icons.nightlight_round, 'color': const Color(0xFFA855F7), 'label': 'Entertainment'},
    {'icon': Icons.favorite, 'color': const Color(0xFFEC4899), 'label': 'Health'},
    {'icon': Icons.fitness_center, 'color': const Color(0xFF6B7280), 'label': 'Fitness'},
    {'icon': Icons.home, 'color': const Color(0xFFF97316), 'label': 'Home'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
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
          // Auto-set end date if not set
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

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
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
        category: _selectedCategory!,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addGoal(goal);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goal added successfully!'),
          backgroundColor: Color(0xFF2D9B8E),
        ),
      );

      // Reset form
      setState(() {
        _amount = '0';
        _nameController.clear();
        _startDate = null;
        _endDate = null;
        _selectedCategory = null;
      });
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // Amount Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _amount,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
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
            const SizedBox(height: 40),

            // Goal Setting Section
            const Text(
              'Goal Setting',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Goal Name Input
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

            // Date Pickers Row
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

            // From Category
            const Text(
              'From category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Category Grid
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
            const SizedBox(height: 32),

            // Confirm Button
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
            const SizedBox(height: 24),

            // Custom Numeric Keypad
            CustomNumericKeypad(
              onNumberPressed: _onNumberPressed,
              onBackspace: _onBackspace,
            ),
          ],
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

  Widget _buildCategoryIcon(IconData icon, Color color, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF2D9B8E) : Colors.grey[300]!,
            width: isSelected ? 3 : 1.5,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: color,
            size: 32,
          ),
        ),
      ),
    );
  }
}