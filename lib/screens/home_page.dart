import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_navigation.dart';
import 'sign_in_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFD4E8E4),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D9B8E)),
              ),
            ),
          );
        }

        // User logged in → Show MainNavigation
        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigation();
        }

        // User not logged in → Show SignInPage
        return const SignInPage();
      },
    );
  }
}