import 'package:flutter/material.dart';

class CustomNumericKeypad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onBackspace;
  final VoidCallback? onEquals;

  const CustomNumericKeypad({
    super.key,
    required this.onNumberPressed,
    required this.onBackspace,
    this.onEquals,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildRow(['1', '2', '3', '+']),
          const SizedBox(height: 8),
          _buildRow(['4', '5', '6', '-']),
          const SizedBox(height: 8),
          _buildRow(['7', '8', '9', '=']),
          const SizedBox(height: 8),
          _buildRow(['⌫', '0', '', '⌫']),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> buttons) {
    return Row(
      children: buttons.map((button) {
        if (button.isEmpty) {
          return const Expanded(child: SizedBox());
        }

        final isBackspace = button == '⌫';
        final isOperator = ['+', '-', '='].contains(button);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (isBackspace) {
                    onBackspace();
                  } else if (button == '=' && onEquals != null) {
                    onEquals!();
                  } else if (!isOperator) {
                    onNumberPressed(button);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      button,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: isOperator
                            ? const Color(0xFF2D9B8E)
                            : Colors.grey[800],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}