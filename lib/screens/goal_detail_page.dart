import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/goal_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

/// Goal Detail Page
/// View and edit goal details with AUTOMATIC progress tracking
class GoalDetailPage extends StatefulWidget {
  final GoalModel goal;

  const GoalDetailPage({super.key, required this.goal});

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _targetAmountController;
  late TextEditingController _categoryController;
  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;
  
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal.name);
    _targetAmountController = TextEditingController(text: widget.goal.targetAmount.toString());
    _categoryController = TextEditingController(text: widget.goal.category);
    _selectedStartDate = widget.goal.startDate;
    _selectedEndDate = widget.goal.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _firestoreService.calculateGoalProgress(widget.goal), // ✅ Calculate live progress
      builder: (context, progressSnapshot) {
        // Use calculated progress or show loading
        final isLoading = progressSnapshot.connectionState == ConnectionState.waiting;
        final calculatedProgress = progressSnapshot.data ?? 0.0;
        final goalWithProgress = widget.goal.copyWithCalculatedAmount(calculatedProgress);
        
        final progress = goalWithProgress.progress.toInt();
        final currencyFormat = NumberFormat.currency(symbol: 'MYR ', decimalDigits: 2);

        return Scaffold(
          backgroundColor: const Color(0xFFD4E8E4),
          appBar: AppBar(
            backgroundColor: const Color(0xFFD4E8E4),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _isEditing ? 'Edit Goal' : 'Goal Details',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              // Refresh button to recalculate progress
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black87),
                onPressed: () {
                  setState(() {}); // Trigger rebuild to recalculate
                },
                tooltip: 'Refresh Progress',
              ),
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black87),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ✅ AUTO-TRACKING Progress Circle Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: progress >= 100
                              ? [const Color(0xFF10B981), const Color(0xFF059669)] // Green when complete
                              : [const Color(0xFF2D9B8E), const Color(0xFF1F7A6E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Auto-tracking indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Auto-Tracking Enabled',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Progress Circle
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: isLoading
                                    ? CircularProgressIndicator(
                                        strokeWidth: 10,
                                        backgroundColor: Colors.white.withOpacity(0.3),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      )
                                    : CircularProgressIndicator(
                                        value: (progress / 100).clamp(0.0, 1.0),
                                        strokeWidth: 10,
                                        backgroundColor: Colors.white.withOpacity(0.3),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    isLoading ? '...' : '$progress%',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    progress >= 100 ? 'Achieved!' : 'Complete',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Goal Name
                          Text(
                            goalWithProgress.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          // Achievement badge if goal is met
                          if (progress >= 100) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.emoji_events, color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Goal Achieved!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✅ How Auto-Tracking Works Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '💡 Smart Progress Tracking',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Progress is automatically calculated based on your net savings (income - expenses) between ${DateFormat('MMM d').format(widget.goal.startDate)} and ${DateFormat('MMM d, yyyy').format(widget.goal.endDate)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade800,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✅ Goal Details Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Goal Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Goal Name
                          _isEditing
                              ? TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Goal Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF2D9B8E)),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter goal name';
                                    }
                                    return null;
                                  },
                                )
                              : _buildDetailRow(
                                  'Goal Name',
                                  goalWithProgress.name,
                                  Icons.flag_outlined,
                                ),

                          const SizedBox(height: 16),

                          // Category
                          _isEditing
                              ? TextFormField(
                                  controller: _categoryController,
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF2D9B8E)),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter category';
                                    }
                                    return null;
                                  },
                                )
                              : _buildDetailRow(
                                  'Category',
                                  goalWithProgress.category,
                                  Icons.category,
                                ),

                          const SizedBox(height: 16),

                          // ✅ Current Savings (AUTO-CALCULATED - No manual editing!)
                          _buildDetailRowWithBadge(
                            'Current Savings',
                            isLoading 
                                ? 'Calculating...'
                                : currencyFormat.format(calculatedProgress),
                            Icons.account_balance_wallet,
                            'Auto-Calculated',
                          ),

                          const SizedBox(height: 16),

                          // Target Amount
                          _isEditing
                              ? TextFormField(
                                  controller: _targetAmountController,
                                  decoration: InputDecoration(
                                    labelText: 'Target Amount',
                                    prefixText: 'MYR ',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF2D9B8E)),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter target amount';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Please enter valid number';
                                    }
                                    return null;
                                  },
                                )
                              : _buildDetailRow(
                                  'Target Amount',
                                  currencyFormat.format(goalWithProgress.targetAmount),
                                  Icons.track_changes,
                                ),

                          const SizedBox(height: 16),

                          // Remaining Amount (only show if not editing)
                          if (!_isEditing) ...[
                            _buildDetailRow(
                              calculatedProgress >= goalWithProgress.targetAmount
                                  ? 'Exceeded By'
                                  : 'Remaining',
                              currencyFormat.format(
                                (goalWithProgress.targetAmount - calculatedProgress).abs()
                              ),
                              calculatedProgress >= goalWithProgress.targetAmount
                                  ? Icons.celebration
                                  : Icons.trending_up,
                              color: calculatedProgress >= goalWithProgress.targetAmount
                                  ? Colors.green
                                  : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Start Date
                          _isEditing
                              ? GestureDetector(
                                  onTap: () => _pickStartDate(),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[400]!),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, color: Color(0xFF2D9B8E)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Start Date',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                DateFormat('MMM d, yyyy').format(_selectedStartDate),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_drop_down),
                                      ],
                                    ),
                                  ),
                                )
                              : _buildDetailRow(
                                  'Start Date',
                                  DateFormat('MMM d, yyyy').format(goalWithProgress.startDate),
                                  Icons.calendar_today,
                                ),

                          const SizedBox(height: 16),

                          // End Date
                          _isEditing
                              ? GestureDetector(
                                  onTap: () => _pickEndDate(),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[400]!),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.event, color: Color(0xFF2D9B8E)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'End Date',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                DateFormat('MMM d, yyyy').format(_selectedEndDate),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_drop_down),
                                      ],
                                    ),
                                  ),
                                )
                              : _buildDetailRow(
                                  'End Date',
                                  DateFormat('MMM d, yyyy').format(goalWithProgress.endDate),
                                  Icons.event,
                                ),

                          const SizedBox(height: 16),

                          // Days Remaining
                          if (!_isEditing) ...[
                            _buildDetailRow(
                              'Days Remaining',
                              '${goalWithProgress.daysRemaining} days',
                              Icons.hourglass_empty,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Created Date (non-editable)
                          if (!_isEditing)
                            _buildDetailRow(
                              'Created',
                              DateFormat('MMM d, yyyy').format(goalWithProgress.createdAt),
                              Icons.access_time,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons
                    if (_isEditing)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  // Reset controllers
                                  _nameController.text = widget.goal.name;
                                  _targetAmountController.text = widget.goal.targetAmount.toString();
                                  _categoryController.text = widget.goal.category;
                                  _selectedStartDate = widget.goal.startDate;
                                  _selectedEndDate = widget.goal.endDate;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveGoal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2D9B8E),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _confirmDelete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Delete Goal',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ Standard detail row
  Widget _buildDetailRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? const Color(0xFF2D9B8E)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color ?? const Color(0xFF2D9B8E), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ Detail row with badge (for auto-calculated fields)
  Widget _buildDetailRowWithBadge(String label, String value, IconData icon, String badge) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2D9B8E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF2D9B8E), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 10, color: Colors.green.shade700),
                        const SizedBox(width: 2),
                        Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2D9B8E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedStartDate,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2D9B8E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      // ✅ Don't update currentAmount - it's auto-calculated!
      final updatedGoal = GoalModel(
        id: widget.goal.id,
        userId: user.uid,
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        targetAmount: double.parse(_targetAmountController.text),
        currentAmount: widget.goal.currentAmount, // Keep existing (will be recalculated)
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        createdAt: widget.goal.createdAt,
      );

      // Update goal in Firestore using goal ID
      await _firestoreService.updateGoal(widget.goal.id, updatedGoal.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal updated successfully!'),
            backgroundColor: Color(0xFF2D9B8E),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating goal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Goal?'),
        content: Text('Are you sure you want to delete "${widget.goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteGoal();
    }
  }

  Future<void> _deleteGoal() async {
    try {
      await _firestoreService.deleteGoal(widget.goal.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal deleted successfully!'),
            backgroundColor: Color(0xFF2D9B8E),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting goal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}