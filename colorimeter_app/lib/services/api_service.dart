import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/color_data.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client = http.Client();
  Timer? _pollingTimer;

  ApiService({required this.baseUrl});

  Future<ColorData> fetchColor() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/color'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ColorData.fromJson(json);
      } else {
        throw Exception('Failed to load color: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching color: $e');
    }
  }

  Future<ColorData> fetchTestColor() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/test-color'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ColorData.fromJson(json['color']);
      } else {
        throw Exception('Failed to load test color: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching test color: $e');
    }
  }

  void startPolling(Function(ColorData) onColorReceived, Duration interval) {
    stopPolling();
    _pollingTimer = Timer.periodic(interval, (_) async {
      try {
        final color = await fetchColor();
        onColorReceived(color);
      } catch (e) {
        // Silently handle polling errors
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void dispose() {
    stopPolling();
    _client.close();
  }
}
