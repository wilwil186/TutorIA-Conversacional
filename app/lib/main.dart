import 'package:flutter/material.dart';

import 'config.dart';
import 'screens/level_screen.dart';
import 'screens/scenarios_screen.dart';
import 'storage.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Config.load();
  final level = await Storage.getLevel();
  runApp(TutorIAApp(initialLevel: level));
}

class TutorIAApp extends StatelessWidget {
  final String? initialLevel;
  const TutorIAApp({super.key, this.initialLevel});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TutorIA',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: initialLevel == null
          ? const LevelScreen()
          : ScenariosScreen(level: initialLevel!),
    );
  }
}
