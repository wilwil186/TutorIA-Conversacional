import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

/// Pick a practice scenario.
class ScenariosScreen extends StatefulWidget {
  final String level;
  const ScenariosScreen({super.key, required this.level});

  @override
  State<ScenariosScreen> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends State<ScenariosScreen> {
  final _api = TutorApi();
  late Future<List<Scenario>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getScenarios();
  }

  void _reload() => setState(() => _future = _api.getScenarios());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Practicar · ${widget.level}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _reload();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Scenario>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorView(
              message: '${snap.error}'.replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }
          final scenarios = snap.data ?? [];
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: scenarios.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = scenarios[i];
              return Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  title: Text(s.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(s.description),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(level: widget.level, scenario: s),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
