import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8002';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8002';
    }
    return 'http://localhost:8002';
  }

  Future<dynamic> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body);
    } catch (e) {
      print('AiService health error: $e');
      return null;
    }
  }

  Future<List<dynamic>> searchByDescription(String query) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/search',
      ).replace(queryParameters: {'q': query});
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    } catch (e) {
      print('AiService search error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> buildDailyMixes(String userId) async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/mixes/$userId'))
          .timeout(const Duration(minutes: 2));
      if (response.statusCode != 200) {
        print('AiService mixes error: ${response.statusCode} ${response.body}');
        return null;
      }
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (e) {
      print('AiService mixes error: $e');
      return null;
    }
  }
}
