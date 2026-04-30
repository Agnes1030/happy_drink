import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;

  Future<Map<String, dynamic>> getStatsSummary({
    required String userId,
    String timeRange = 'last_7_days',
  }) async {
    final uri = Uri.parse(
      '$baseUrl/stats/summary?user_id=$userId&time_range=$timeRange',
    );
    final res = await http.get(uri);
    _ensureSuccess(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> askAi({
    required String userId,
    required String question,
  }) async {
    final uri = Uri.parse('$baseUrl/qa/ask');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'question': question}),
    );
    _ensureSuccess(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> parseRecordPhoto({
    required String userId,
    required File imageFile,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/records/photo-parse'));
    request.fields['user_id'] = userId;
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _ensureSuccess(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> confirmPhotoRecord(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/records/photo-confirm');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    _ensureSuccess(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createRecord(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/records');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    _ensureSuccess(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRecords({
    required String userId,
    String? drinkType,
    String? brand,
    int offset = 0,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'user_id': userId,
      'offset': '$offset',
      'limit': '$limit',
    };
    if (drinkType != null && drinkType.isNotEmpty) params['drink_type'] = drinkType;
    if (brand != null && brand.isNotEmpty) params['brand'] = brand;

    final uri = Uri.parse('$baseUrl/records').replace(queryParameters: params);
    final res = await http.get(uri);
    _ensureSuccess(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  void _ensureSuccess(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }
}
