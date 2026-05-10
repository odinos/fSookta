import 'package:flutter/material.dart';

void main() {
  runApp(const FSooktaApp());
}

class FSooktaApp extends StatelessWidget {
  const FSooktaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fSookta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('fSookta'),
        backgroundColor: colorScheme.surface,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 56,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Flutter starter is ready',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Android and iOS platform folders are included so this repo can be finalized with Flutter tooling.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

