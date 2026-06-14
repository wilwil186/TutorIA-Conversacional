import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import 'home_screen.dart';

/// Onboarding: pick your CEFR level.
class LevelScreen extends StatelessWidget {
  const LevelScreen({super.key});

  static const _descriptions = {
    'A1': 'Principiante',
    'A2': 'Básico',
    'B1': 'Intermedio',
    'B2': 'Intermedio alto',
    'C1': 'Avanzado',
    'C2': 'Dominio',
  };

  Future<void> _choose(BuildContext context, String level) async {
    await Storage.setLevel(level);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(level: level)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text('¡Hola! 👋',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                '¿Cuál es tu nivel de inglés? (Marco Común Europeo)',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: cefrLevels.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final level = cefrLevels[i];
                    return Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: Text(level,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(_descriptions[level] ?? level),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _choose(context, level),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
