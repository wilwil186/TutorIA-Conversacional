// Web/unsupported fallback: no text-to-speech.
bool supported() => false;
Future<void> speak(String text) async {}
Future<void> stop() async {}
