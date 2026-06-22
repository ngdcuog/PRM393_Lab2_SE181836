import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/main_navigation.dart';
import '../services/analytics_service.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Consumer<AuthViewModel>(
          builder: (context, authViewModel, _) {
            return Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/app_icon.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Journal Trend Analyzer',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to explore research trends\nand analyze academic publications.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 64),
                  if (authViewModel.isLoading)
                    const CircularProgressIndicator()
                  else
                    FilledButton.icon(
                      onPressed: () async {
                        final user = await authViewModel.signIn();
                        
                        if (!context.mounted) return;

                        if (user != null) {
                          // Log Analytics Event
                          await context.read<AnalyticsService>().logLogin();
                          
                          // Navigate to MainNavigation
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const MainNavigation(),
                              ),
                            );
                          }
                        } else if (authViewModel.errorMessage.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(authViewModel.errorMessage),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.login),
                      label: const Text(
                        'Sign in with Google',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
