import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_numeric_keypad.dart';

class AddIncomePage extends StatefulWidget {
  const AddIncomePage({super.key});

  @override
  State<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
  String _amount = '0';
  String _source = 'transaction'; // 'transaction' or 'cash'
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  bool _isLoading = false;

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

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final transaction = TransactionModel(
        id: '',
        userId: userId,
        amount: double.parse(_amount),
        type: 'income',
        source: _source,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addTransaction(transaction);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Income added successfully!'),
          backgroundColor: Color(0xFF2D9B8E),
        ),
      );

      // Reset form
      setState(() {
        _amount = '0';
        _source = 'transaction';
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
                  '+',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF2D9B8E),
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

            // From Section
            const Text(
              'From',
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
            const SizedBox(height: 40),

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
}