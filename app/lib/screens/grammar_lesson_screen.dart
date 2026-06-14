import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../storage.dart';
import '../tts.dart';

/// Loads and shows one grammar capsule: explanation + examples + exercises.
class GrammarLessonScreen extends StatefulWidget {
  final GrammarTopic topic;
  final String level;
  const GrammarLessonScreen({super.key, required this.topic, required this.level});

  @override
  State<GrammarLessonScreen> createState() => _GrammarLessonScreenState();
}

class _GrammarLessonScreenState extends State<GrammarLessonScreen> {
  final _api = TutorApi();
  late Future<GrammarLesson> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<GrammarLesson> _load() async {
    final llm = await Storage.getLlmConfig();
    return _api.getGrammarLesson(
        topicId: widget.topic.id, level: widget.level, llm: llm);
  }

  void _reload() => setState(() => _future = _load());

  @override
  void dispose() {
    Tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.topic.titleEs)),
      body: FutureBuilder<GrammarLesson>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Preparando la cápsula…'),
                ],
              ),
            );
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
          return _LessonView(lesson: snap.data!);
        },
      ),
    );
  }
}

class _LessonView extends StatefulWidget {
  final GrammarLesson lesson;
  const _LessonView({required this.lesson});

  @override
  State<_LessonView> createState() => _LessonViewState();
}

class _LessonViewState extends State<_LessonView> {
  late final List<TextEditingController> _controllers;
  late final List<bool?> _results; // null = not checked, true/false = result

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(widget.lesson.exercises.length, (_) => TextEditingController());
    _results = List.filled(widget.lesson.exercises.length, null);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _check(int i) {
    final ex = widget.lesson.exercises[i];
    setState(() => _results[i] = ex.isCorrect(_controllers[i].text));
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lesson;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.title,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(l.explanation, style: const TextStyle(fontSize: 15, height: 1.35)),
        const SizedBox(height: 20),
        if (l.examples.isNotEmpty) ...[
          const Text('Ejemplos', style: _sectionStyle),
          const SizedBox(height: 8),
          for (final e in l.examples) _ExampleRow(example: e),
          const SizedBox(height: 20),
        ],
        const Text('Practica', style: _sectionStyle),
        const SizedBox(height: 8),
        for (int i = 0; i < l.exercises.length; i++)
          _ExerciseCard(
            exercise: l.exercises[i],
            controller: _controllers[i],
            result: _results[i],
            onCheck: () => _check(i),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

const _sectionStyle =
    TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

class _ExampleRow extends StatelessWidget {
  final GrammarExample example;
  const _ExampleRow({required this.example});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (Tts.supported)
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              icon: const Icon(Icons.volume_up_rounded),
              tooltip: 'Escuchar',
              onPressed: () => Tts.speak(example.english),
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(example.english,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                Text(example.spanish,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final GrammarExercise exercise;
  final TextEditingController controller;
  final bool? result;
  final VoidCallback onCheck;

  const _ExerciseCard({
    required this.exercise,
    required this.controller,
    required this.result,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercise.prompt, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onCheck(),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Tu respuesta…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: onCheck, child: const Text('Comprobar')),
              ],
            ),
            if (result != null) ...[
              const SizedBox(height: 8),
              if (result == true)
                const Row(children: [
                  Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
                  SizedBox(width: 6),
                  Text('¡Correcto!',
                      style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold)),
                ])
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 6),
                      Text('Respuesta correcta: ${exercise.answer}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 2),
                    Text('💡 ${exercise.hint}',
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
