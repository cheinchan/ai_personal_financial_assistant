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
  String? _customCategory;
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
    {'icon': Icons.monetization_on, 'color': const Color(0xFF06B6D4), 'label': 'Bills'},
    {'icon': Icons.nightlight_round, 'color': const Color(0xFFA855F7), 'label': 'Entertainment'},
    {'icon': Icons.favorite, 'color': const Color(0xFFEC4899), 'label': 'Health'},
    {'icon': Icons.fitness_center, 'color': const Color(0xFF6B7280), 'label': 'Fitness'},
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

  // Smart icon assignment based on category keywords
  IconData _getSmartIcon(String category) {
    final lowerCategory = category.toLowerCase();
    
    // Transportation keywords
    if (lowerCategory.contains('car') || lowerCategory.contains('gas') || 
        lowerCategory.contains('fuel') || lowerCategory.contains('transport') ||
        lowerCategory.contains('uber') || lowerCategory.contains('grab') ||
        lowerCategory.contains('taxi') || lowerCategory.contains('parking')) {
      return Icons.directions_car;
    }
    
    // Food keywords
    if (lowerCategory.contains('food') || lowerCategory.contains('restaurant') ||
        lowerCategory.contains('lunch') || lowerCategory.contains('dinner') ||
        lowerCategory.contains('breakfast') || lowerCategory.contains('cafe') ||
        lowerCategory.contains('coffee') || lowerCategory.contains('meal')) {
      return Icons.restaurant;
    }
    
    // Shopping keywords
    if (lowerCategory.contains('shop') || lowerCategory.contains('store') ||
        lowerCategory.contains('mall') || lowerCategory.contains('clothes') ||
        lowerCategory.contains('clothing') || lowerCategory.contains('fashion')) {
      return Icons.shopping_bag;
    }
    
    // Bills/Utilities keywords
    if (lowerCategory.contains('bill') || lowerCategory.contains('utility') ||
        lowerCategory.contains('electric') || lowerCategory.contains('water') ||
        lowerCategory.contains('internet') || lowerCategory.contains('phone') ||
        lowerCategory.contains('rent') || lowerCategory.contains('mortgage')) {
      return Icons.receipt_long;
    }
    
    // Entertainment keywords
    if (lowerCategory.contains('entertainment') || lowerCategory.contains('movie') ||
        lowerCategory.contains('game') || lowerCategory.contains('music') ||
        lowerCategory.contains('concert') || lowerCategory.contains('show')) {
      return Icons.movie;
    }
    
    // Health keywords
    if (lowerCategory.contains('health') || lowerCategory.contains('medical') ||
        lowerCategory.contains('doctor') || lowerCategory.contains('hospital') ||
        lowerCategory.contains('medicine') || lowerCategory.contains('pharmacy')) {
      return Icons.local_hospital;
    }
    
    // Fitness keywords
    if (lowerCategory.contains('gym') || lowerCategory.contains('fitness') ||
        lowerCategory.contains('sport') || lowerCategory.contains('exercise') ||
        lowerCategory.contains('yoga') || lowerCategory.contains('workout')) {
      return Icons.fitness_center;
    }
    
    // Education keywords
    if (lowerCategory.contains('education') || lowerCategory.contains('school') ||
        lowerCategory.contains('course') || lowerCategory.contains('book') ||
        lowerCategory.contains('study') || lowerCategory.contains('tuition')) {
      return Icons.school;
    }
    
    // Home keywords
    if (lowerCategory.contains('home') || lowerCategory.contains('house') ||
        lowerCategory.contains('furniture') || lowerCategory.contains('decor')) {
      return Icons.home;
    }
    
    // Gift keywords
    if (lowerCategory.contains('gift') || lowerCategory.contains('present')) {
      return Icons.card_giftcard;
    }
    
    // Pet keywords
    if (lowerCategory.contains('pet') || lowerCategory.contains('dog') ||
        lowerCategory.contains('cat') || lowerCategory.contains('animal')) {
      return Icons.pets;
    }
    
    // Travel keywords
    if (lowerCategory.contains('travel') || lowerCategory.contains('vacation') ||
        lowerCategory.contains('hotel') || lowerCategory.contains('flight')) {
      return Icons.flight;
    }
    
    // Default icon
    return Icons.category;
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

    // Determine final category
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

      final transaction = TransactionModel(
        id: '',
        userId: userId,
        amount: double.parse(_amount),
        type: 'expense',
        source: _source,
        category: finalCategory,
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
        _customCategory = null;
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
        // Dismiss keypad when tapping outside
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
              
              // Amount Display - Now clickable
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
                      const Text(
                        '−',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 16),
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

              // Custom Category Input (shows when "Other" is selected)
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
                                : Icons.category,
                            color: const Color(0xFF2D9B8E),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Enter custom category:',
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
                          hintText: 'e.g., Coffee, Groceries, Gaming',
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
              
              // Show keypad only when amount field is focused
              if (_showKeypad) ...[
                const SizedBox(height: 24),
                CustomNumericKeypad(
                  onNumberPressed: _onNumberPressed,
                  onBackspace: _onBackspace,
                ),
              ],

              // Hidden FocusNode
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