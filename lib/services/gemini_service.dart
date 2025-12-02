import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyAGYBvEPUum8RhmY0mwDrAlIRGQNs-3VlQ'; // Replace with your actual key
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
    );
  }

  /// Get financial advice based on user's financial data
  Future<String> getFinancialAdvice({
    required double totalIncome,
    required double totalExpenses,
    required Map<String, double> categoryExpenses,
    String? specificQuestion,
  }) async {
    try {
      final prompt = _buildPrompt(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        categoryExpenses: categoryExpenses,
        specificQuestion: specificQuestion,
      );

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? 'Unable to generate advice at this time.';
    } catch (e) {
      throw 'Failed to get advice: ${e.toString()}';
    }
  }

  /// Ask a specific financial question
  Future<String> askQuestion(String question, {
    double? totalIncome,
    double? totalExpenses,
  }) async {
    try {
      String prompt = 'You are a personal financial advisor. Answer this question concisely and practically:\n\n$question';
      
      if (totalIncome != null && totalExpenses != null) {
        prompt += '\n\nContext: User has monthly income of MYR $totalIncome and expenses of MYR $totalExpenses.';
      }

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? 'Unable to generate answer at this time.';
    } catch (e) {
      throw 'Failed to get answer: ${e.toString()}';
    }
  }

  /// Generate category-specific advice
  Future<String> getCategoryAdvice({
    required String category,
    required double spent,
    required double budget,
  }) async {
    try {
      final percentage = (spent / budget * 100).round();
      final prompt = '''
You are a personal financial advisor. Provide brief, actionable advice (2-3 sentences) for this situation:

Category: $category
Spent: MYR $spent
Budget: MYR $budget
Percentage used: $percentage%

Give practical tips to manage spending in this category.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? 'Monitor your $category spending carefully.';
    } catch (e) {
      throw 'Failed to get category advice: ${e.toString()}';
    }
  }

  String _buildPrompt({
    required double totalIncome,
    required double totalExpenses,
    required Map<String, double> categoryExpenses,
    String? specificQuestion,
  }) {
    final balance = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0 ? ((balance / totalIncome) * 100).toStringAsFixed(1) : '0';

    String prompt = '''
You are a personal financial advisor. Analyze this financial data and provide 3-4 key insights with actionable advice.

Financial Summary:
- Monthly Income: MYR $totalIncome
- Monthly Expenses: MYR $totalExpenses
- Balance: MYR $balance
- Savings Rate: $savingsRate%

Expense Breakdown:
${categoryExpenses.entries.map((e) => '- ${e.key}: MYR ${e.value.toStringAsFixed(2)}').join('\n')}

''';

    if (specificQuestion != null) {
      prompt += '\nSpecific Question: $specificQuestion\n';
    }

    prompt += '''
Provide insights in this format:
1. Overall financial health assessment
2. Top spending category concern (if any)
3. Specific actionable recommendation
4. Savings or goal-setting tip

Keep each point brief (1-2 sentences) and practical.
''';

    return prompt;
  }
}