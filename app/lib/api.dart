import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'models.dart';

class TutorApiException implements Exception {
  final String message;
  TutorApiException(this.message);
  @override
  String toString() => message;
}

class TutorApi {
  final http.Client _client;
  TutorApi([http.Client? client]) : _client = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('${Config.baseUrl}$path');

  Future<List<Scenario>> getScenarios() async {
    try {
      final res = await _client
          .get(_uri('/api/scenarios'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw TutorApiException('No se pudieron cargar los escenarios (${res.statusCode}).');
      }
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => Scenario.fromJson(e as Map<String, dynamic>)).toList();
    } on TutorApiException {
      rethrow;
    } catch (e) {
      throw TutorApiException('No se pudo conectar con el backend en ${Config.baseUrl}.');
    }
  }

  Future<TutorTurn> chat({
    required List<ChatMessage> history,
    required String level,
    String? scenario,
    LlmConfig? llm,
  }) async {
    final body = jsonEncode({
      'messages': history.map((m) => m.toApi()).toList(),
      'level': level,
      'scenario': scenario,
      if (llm != null) 'llm': llm.toJson(),
    });
    try {
      final res = await _client
          .post(
            _uri('/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 60));
      if (res.statusCode == 200) {
        return TutorTurn.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
      throw TutorApiException(_errorDetail(res));
    } on TutorApiException {
      rethrow;
    } catch (e) {
      throw TutorApiException('No se pudo conectar con el tutor en ${Config.baseUrl}.');
    }
  }

  String _errorDetail(http.Response res) {
    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['detail'] is String) return json['detail'] as String;
    } catch (_) {}
    return 'Error del servidor (${res.statusCode}).';
  }
}
