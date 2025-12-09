import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // ⚠️ IMPORTANT: Replace this with YOUR actual Gemini API key
  // Get your key from: https://makersuite.google.com/app/apikey
  static const String _apiKey = 'AIzaSyAhAezMS7CB6cWrM1FqWj5dX0JqXU2ZlvE';

  late final GenerativeModel _model;
  bool _isInitialized = false;

  GeminiService() {
    try {
      // ✅ Use the correct model name: 'gemini-1.5-flash'
      _model = GenerativeModel(
        model: 'gemini-2.5-flash', // This is the correct model name!
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7, // Controls creativity (0.0-1.0)
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024, // Maximum response length
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        ],
      );
      _isInitialized = true;
    } catch (e) {
      print('❌ Error initializing Gemini: $e');
      _isInitialized = false;
    }
  }

  /// Test if the API is working
  Future<bool> testConnection() async {
    if (!_isInitialized) return false;

    try {
      final content = [Content.text('Say "Connected" if you can read this.')];
      final response = await _model.generateContent(content);
      return response.text != null && response.text!.isNotEmpty;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }

  /// Get financial advice based on user's financial data
  /// This analyzes income, expenses, and spending patterns
  Future<String> getFinancialAdvice({
    required double totalIncome,
    required double totalExpenses,
    required Map<String, double> categoryExpenses,
    String? specificQuestion,
  }) async {
    if (!_isInitialized) {
      return '⚠️ AI service is not properly initialized. Please check your API key.';
    }

    try {
      final prompt = _buildFinancialAdvicePrompt(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        categoryExpenses: categoryExpenses,
        specificQuestion: specificQuestion,
      );

      print('🤖 Sending request to Gemini...');
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        return '⚠️ Unable to generate advice. Please try again.';
      }

      print('✅ Received response from Gemini');
      return response.text!;
    } catch (e) {
      print('❌ Error getting financial advice: $e');

      // Provide helpful error messages
      if (e.toString().contains('API key')) {
        return '⚠️ API Key Error: Please check your Gemini API key in gemini_service.dart';
      } else if (e.toString().contains('quota')) {
        return '⚠️ API Quota Exceeded: You\'ve reached your API usage limit. Please try again later.';
      } else if (e.toString().contains('network')) {
        return '⚠️ Network Error: Please check your internet connection.';
      } else {
        return '⚠️ Error: ${e.toString()}';
      }
    }
  }

  /// Ask a specific financial question
  Future<String> askQuestion(
    String question, {
    double? totalIncome,
    double? totalExpenses,
  }) async {
    if (!_isInitialized) {
      return '⚠️ AI service is not properly initialized. Please check your API key.';
    }

    try {
      final prompt = _buildQuestionPrompt(
        question: question,
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
      );

      print('🤖 Asking question to Gemini...');
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        return 'Unable to generate answer. Please try again.';
      }

      print('✅ Received answer from Gemini');
      return response.text!;
    } catch (e) {
      print('❌ Error asking question: $e');
      return '⚠️ Unable to get answer: ${e.toString()}';
    }
  }

  /// Generate category-specific advice
  Future<String> getCategoryAdvice({
    required String category,
    required double spent,
    required double budget,
  }) async {
    if (!_isInitialized) {
      return '⚠️ AI service is not properly initialized.';
    }

    try {
      final percentage = (spent / budget * 100).round();
      final prompt = _buildCategoryAdvicePrompt(
        category: category,
        spent: spent,
        budget: budget,
        percentage: percentage,
      );

      print('🤖 Getting category advice from Gemini...');
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        return 'Monitor your $category spending carefully.';
      }

      return response.text!;
    } catch (e) {
      print('❌ Error getting category advice: $e');
      return 'Unable to get advice for $category at this time.';
    }
  }

  // ============================================================================
  // PROMPT ENGINEERING - This is where the magic happens!
  // ============================================================================

  /// Build a comprehensive prompt for financial advice
  /// Good prompts = Better AI responses
  String _buildFinancialAdvicePrompt({
    required double totalIncome,
    required double totalExpenses,
    required Map<String, double> categoryExpenses,
    String? specificQuestion,
  }) {
    final balance = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0
        ? ((balance / totalIncome) * 100).toStringAsFixed(1)
        : '0';

    // Find the highest spending category
    String topCategory = 'None';
    double topAmount = 0;
    if (categoryExpenses.isNotEmpty) {
      final sortedEntries = categoryExpenses.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topCategory = sortedEntries.first.key;
      topAmount = sortedEntries.first.value;
    }

    // Calculate spending percentage for top category
    final topCategoryPercentage = totalExpenses > 0
        ? ((topAmount / totalExpenses) * 100).toStringAsFixed(1)
        : '0';

    String prompt = '''
You are an expert personal financial advisor specializing in helping young adults and students manage their finances wisely. Analyze the following financial data and provide personalized, actionable advice.

📊 FINANCIAL DATA:
- Monthly Income: MYR ${totalIncome.toStringAsFixed(2)}
- Monthly Expenses: MYR ${totalExpenses.toStringAsFixed(2)}
- Current Balance: MYR ${balance.toStringAsFixed(2)}
- Savings Rate: $savingsRate%

💰 SPENDING BREAKDOWN:
''';

    // Add category breakdown
    if (categoryExpenses.isEmpty) {
      prompt += '- No expenses recorded yet\n';
    } else {
      final sortedCategories = categoryExpenses.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (var entry in sortedCategories) {
        final percentage = totalExpenses > 0
            ? ((entry.value / totalExpenses) * 100).toStringAsFixed(1)
            : '0';
        prompt +=
            '- ${entry.key}: MYR ${entry.value.toStringAsFixed(2)} ($percentage%)\n';
      }
    }

    prompt +=
        '\n🎯 HIGHEST SPENDING CATEGORY: $topCategory (MYR ${topAmount.toStringAsFixed(2)} - $topCategoryPercentage%)\n';

    if (specificQuestion != null && specificQuestion.isNotEmpty) {
      prompt += '\n❓ USER QUESTION: $specificQuestion\n';
    }

    prompt += '''

📝 PROVIDE YOUR ADVICE IN THIS FORMAT:

1. 💚 **Financial Health Status**
   Assess their overall financial situation in 1-2 sentences. Be encouraging if they're doing well, or provide constructive feedback if improvements are needed.

2. ⚠️ **Spending Alert** ${balance < 0 ? '(URGENT)' : ''}
   ${balance < 0 ? 'Address the overspending issue immediately with specific steps.' : 'Identify the highest spending category and provide practical tips to optimize it (if needed).'}

3. 💡 **Action Plan**
   Give ONE specific, actionable recommendation they can implement this week. Be very specific.

4. 🎯 **Savings Strategy**
   ${savingsRate.contains('-') || double.parse(savingsRate) < 10 ? 'Suggest a realistic savings goal based on their income and provide a simple strategy to achieve it.' : 'Congratulate them on their savings rate and suggest how to optimize or invest these savings.'}

IMPORTANT GUIDELINES:
- Keep each section brief (2-3 sentences maximum)
- Use friendly, encouraging language suitable for young adults
- Provide SPECIFIC numbers and percentages in your advice
- Make recommendations realistic and achievable
- Use emojis to make it engaging
- If income is 0, focus on expense tracking and budgeting basics
- If expenses are 0, encourage them to start tracking expenses

Keep the total response under 300 words.
''';

    return prompt;
  }

  /// Build prompt for specific user questions
  String _buildQuestionPrompt({
    required String question,
    double? totalIncome,
    double? totalExpenses,
  }) {
    String prompt = '''
You are a friendly personal financial advisor for young adults and students. Answer this question clearly and practically:

❓ QUESTION: $question
''';

    if (totalIncome != null && totalExpenses != null) {
      final balance = totalIncome - totalExpenses;
      prompt += '''

📊 USER'S FINANCIAL CONTEXT:
- Monthly Income: MYR ${totalIncome.toStringAsFixed(2)}
- Monthly Expenses: MYR ${totalExpenses.toStringAsFixed(2)}
- Current Balance: MYR ${balance.toStringAsFixed(2)}
''';
    }

    prompt += '''

📝 ANSWER REQUIREMENTS:
- Be specific and actionable
- Use simple language (suitable for beginners)
- Include practical examples if relevant
- Keep the answer under 150 words
- Use bullet points for clarity
- Be encouraging and positive

Provide your answer now:
''';

    return prompt;
  }

  /// Build prompt for category-specific advice
  String _buildCategoryAdvicePrompt({
    required String category,
    required double spent,
    required double budget,
    required int percentage,
  }) {
    String status = '';
    if (percentage >= 100) {
      status = '🔴 OVER BUDGET';
    } else if (percentage >= 90) {
      status = '🟠 CRITICAL WARNING';
    } else if (percentage >= 70) {
      status = '🟡 APPROACHING LIMIT';
    } else {
      status = '🟢 ON TRACK';
    }

    return '''
You are a financial advisor. Provide brief, specific advice for this spending situation:

📊 CATEGORY: $category
💰 SPENT: MYR ${spent.toStringAsFixed(2)}
🎯 BUDGET: MYR ${budget.toStringAsFixed(2)}
📈 USED: $percentage%
⚠️ STATUS: $status

Provide 2-3 specific, actionable tips to manage $category spending better. Focus on:
${percentage >= 90 ? '- Immediate actions to reduce spending' : '- Ways to optimize spending in this category'}
- Practical alternatives or cost-saving strategies
- One specific habit they should adopt

Keep the advice under 100 words, friendly, and actionable.
''';
  }
}
