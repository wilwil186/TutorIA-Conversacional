import 'dart:io';

/// Linux text-to-speech via `spd-say` (speech-dispatcher), present on most
/// desktops. Other native platforms fall through to no-op.
bool supported() {
  try {
    return Platform.isLinux;
  } catch (_) {
    return false;
  }
}

Future<void> speak(String text) async {
  if (!supported() || text.trim().isEmpty) return;
  try {
    await Process.run('spd-say', ['-C']); // cancel anything in progress
    await Process.start('spd-say', ['-l', 'en-US', '-r', '-10', text]);
  } catch (_) {
    // speech-dispatcher not installed — ignore silently.
  }
}

Future<void> stop() async {
  if (!supported()) return;
  try {
    await Process.run('spd-say', ['-C']);
  } catch (_) {}
}
