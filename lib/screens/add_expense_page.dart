import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_numeric_keypad.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  String _amount = '0';
  String _source = 'transaction';
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

  Future<void> _confirmTransaction() async {
    if (_amount == '0' || double.tryParse(_amount) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
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

      final transaction = TransactionModel(
        id: '',
        userId: userId,
        amount: double.parse(_amount),
        type: 'expense',
        source: _source,
        category: _selectedCategory,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addTransaction(transaction);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense added successfully!'),
          backgroundColor: Color(0xFF2D9B8E),
        ),
      );

      // Reset form
      setState(() {
        _amount = '0';
        _source = 'transaction';
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
                const Text(
                  '−',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 16),
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

            // Used Section
            const Text(
              'Used',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Transaction/Cash Toggle
            Row(
              children: [
                _buildSourceButton('Transaction', 'transaction'),
                const SizedBox(width: 12),
                _buildSourceButton('Cash', 'cash'),
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
                onPressed: _isLoading ? null : _confirmTransaction,
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

  Widget _buildSourceButton(String label, String value) {
    final isSelected = _source == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _source = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2D9B8E) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF2D9B8E) : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              if (isSelected) const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
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