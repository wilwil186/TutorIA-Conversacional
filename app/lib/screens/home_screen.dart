import 'package:flutter/material.dart';

import 'grammar_topics_screen.dart';
import 'scenarios_screen.dart';
import 'settings_screen.dart';

/// Home hub: choose between conversation practice and grammar capsules.
class HomeScreen extends StatelessWidget {
  final String level;
  const HomeScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TutorIA · $level'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text('¿Qué quieres practicar hoy?',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              Expanded(
                child: _BigCard(
                  icon: Icons.forum_rounded,
                  color: const Color(0xFF58CC02),
                  title: 'Conversar',
                  subtitle:
                      'Habla con el tutor en escenarios reales. Te corrige y te da consejos.',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => ScenariosScreen(level: level)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _BigCard(
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF1CB0F6),
                  title: 'Gramática',
                  subtitle:
                      'Cápsulas con explicación, ejemplos y ejercicios para practicar.',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => GrammarTopicsScreen(level: level)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BigCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 56),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
