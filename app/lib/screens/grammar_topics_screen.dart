import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import 'grammar_lesson_screen.dart';

/// List of grammar capsules available for the student's level.
class GrammarTopicsScreen extends StatefulWidget {
  final String level;
  const GrammarTopicsScreen({super.key, required this.level});

  @override
  State<GrammarTopicsScreen> createState() => _GrammarTopicsScreenState();
}

class _GrammarTopicsScreenState extends State<GrammarTopicsScreen> {
  final _api = TutorApi();
  late Future<List<GrammarTopic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getGrammarTopics(widget.level);
  }

  void _reload() => setState(() => _future = _api.getGrammarTopics(widget.level));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gramática')),
      body: FutureBuilder<List<GrammarTopic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48),
                    const SizedBox(height: 12),
                    Text('${snap.error}'.replaceFirst('Exception: ', ''),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: _reload, child: const Text('Reintentar')),
                  ],
                ),
              ),
            );
          }
          final topics = snap.data ?? [];
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: topics.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final t = topics[i];
              return Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1CB0F6),
                    child: Text(t.cefr,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(t.titleEs,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          GrammarLessonScreen(topic: t, level: widget.level),
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
