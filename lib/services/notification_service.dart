import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'budget', 'goal', 'summary'
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Store notifications in memory
  final List<NotificationItem> _notifications = [];
  
  // Callback for UI updates
  VoidCallback? onNotificationAdded;

  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    print('✅ Notification service initialized');
  }

  /// Request permissions (always return true for in-app)
  Future<bool> requestPermissions() async {
    return true;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return true;
  }

  /// Get all notifications
  List<NotificationItem> getNotifications() {
    return List.from(_notifications);
  }

  /// Get unread count
  int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

// ============================================================================
// GOAL NOTIFICATIONS
// ============================================================================

/// ✅ NEW: Send congratulations when goal is completed
Future<void> sendGoalCompleted({
  required String goalName,
  required double amount,
  required int daysToComplete,
  required String category,
}) async {
  _addNotification(
    title: '🎊 CONGRATULATIONS! Goal Completed! 🎊',
    message: 'Amazing! You\'ve successfully completed your "$goalName" goal! '
        'You saved MYR ${amount.toStringAsFixed(0)} in $daysToComplete days. '
        'This is a huge achievement! 🏆',
    type: 'goal',
  );
}

Future<void> sendGoalMilestone({
  required String goalName,
  required int percentage,
  required double current,
  required double target,
}) async {
  String emoji = percentage >= 75 ? '🔥' : percentage >= 50 ? '💪' : '🎯';
  
  _addNotification(
    title: '$emoji Goal Progress Milestone!',
    message: 'You\'ve reached $percentage% of your "$goalName" goal! '
        'MYR ${current.toStringAsFixed(0)} saved out of MYR ${target.toStringAsFixed(0)}. Keep going!',
    type: 'goal',
  );
}

Future<void> sendGoalAchieved({
  required String goalName,
  required double amount,
}) async {
  _addNotification(
    title: '🎉 Goal Achieved!',
    message: 'Congratulations! You\'ve reached your "$goalName" goal '
        'of MYR ${amount.toStringAsFixed(0)}!',
    type: 'goal',
  );
}

Future<void> sendGoalDeadlineReminder({
  required String goalName,
  required int daysRemaining,
  required double remaining,
}) async {
  _addNotification(
    title: daysRemaining <= 7 ? '⏰ Goal Deadline Approaching!' : '📅 Goal Reminder',
    message: '$daysRemaining days left for "$goalName"! '
        'You need MYR ${remaining.toStringAsFixed(0)} more to reach your target.',
    type: 'goal',
  );
}
  /// Mark notification as read
  void markAsRead(String id) {
    final notification = _notifications.firstWhere(
      (n) => n.id == id,
      orElse: () => _notifications.first,
    );
    notification.isRead = true;
    onNotificationAdded?.call();
  }

  /// Mark all as read
  void markAllAsRead() {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    onNotificationAdded?.call();
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    onNotificationAdded?.call();
  }

  /// Add notification
  void _addNotification({
    required String title,
    required String message,
    required String type,
  }) {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );
    
    _notifications.insert(0, notification); // Add to beginning
    
    // Keep only last 50 notifications
    if (_notifications.length > 50) {
      _notifications.removeLast();
    }

    print('📱 NOTIFICATION: $title');
    onNotificationAdded?.call();
  }

  // ============================================================================
  // BUDGET NOTIFICATIONS
  // ============================================================================

  Future<void> sendBudgetWarning({
    required String budgetName,
    required double spent,
    required double limit,
    required int percentage,
  }) async {
    _addNotification(
      title: '⚠️ Budget Warning',
      message: '$budgetName: MYR ${spent.toStringAsFixed(0)} spent '
          '($percentage% of limit). You have MYR ${(limit - spent).toStringAsFixed(0)} remaining.',
      type: 'budget',
    );
  }

  Future<void> sendBudgetCritical({
    required String budgetName,
    required double spent,
    required double limit,
    required int percentage,
  }) async {
    _addNotification(
      title: '🔴 Budget Alert - Critical!',
      message: '$budgetName: You\'ve used $percentage% of your budget! '
          'Only MYR ${(limit - spent).toStringAsFixed(0)} left. Slow down spending!',
      type: 'budget',
    );
  }

  Future<void> sendBudgetExceeded({
    required String budgetName,
    required double spent,
    required double limit,
  }) async {
    final overAmount = spent - limit;
    _addNotification(
      title: '🚨 Budget Exceeded!',
      message: '$budgetName: You\'ve exceeded your budget by '
          'MYR ${overAmount.toStringAsFixed(0)}! Total spent: MYR ${spent.toStringAsFixed(0)}',
      type: 'budget',
    );
  }

  // ============================================================================
  // GOAL NOTIFICATIONS
  // ============================================================================



  // ============================================================================
  // SUMMARY NOTIFICATIONS
  // ============================================================================

  Future<void> scheduleDailySummary() async {
    print('✅ Daily summary enabled (in-app only)');
  }

  Future<void> scheduleWeeklySummary() async {
    print('✅ Weekly summary enabled (in-app only)');
  }

  Future<void> cancelDailySummary() async {
    print('✅ Daily summary cancelled');
  }

  Future<void> cancelWeeklySummary() async {
    print('✅ Weekly summary cancelled');
  }

  Future<void> cancelAllNotifications() async {
    clearAll();
  }
}