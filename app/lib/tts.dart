// Public TTS API. The implementation is chosen at compile time so the web
// build (no dart:io) still compiles — it just gets a no-op.
import 'tts_io.dart' if (dart.library.html) 'tts_noop.dart' as impl;

class Tts {
  static bool get supported => impl.supported();
  static Future<void> speak(String text) => impl.speak(text);
  static Future<void> stop() => impl.stop();
}
