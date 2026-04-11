import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/color_data.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class ColorProvider extends ChangeNotifier {
  final ApiService _apiService;
  final NotificationService _notificationService;

  ColorData? _currentColor;
  List<ColorData> _colorHistory = [];
  bool _isLoading = false;
  String? _error;
  bool _notificationsEnabled = true;
  static const int maxHistorySize = 30;

  ColorProvider({
    required ApiService apiService,
    required NotificationService notificationService,
  })  : _apiService = apiService,
        _notificationService = notificationService {
    _loadHistory();
  }

  ColorData? get currentColor => _currentColor;
  List<ColorData> get colorHistory => _colorHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('color_history') ?? [];
      _colorHistory = historyJson
          .map((json) => ColorData.fromJson(jsonDecode(json)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = _colorHistory
          .map((color) => jsonEncode(color.toJson()))
          .toList();
      await prefs.setStringList('color_history', historyJson);
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  Future<void> fetchColor() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final color = await _apiService.fetchColor();
      _updateColor(color);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTestColor() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final color = await _apiService.fetchTestColor();
      _updateColor(color);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateColor(ColorData color) {
    final isNewColor = _currentColor?.hex != color.hex;
    
    _currentColor = color;
    
    if (isNewColor) {
      _colorHistory.insert(0, color);
      if (_colorHistory.length > maxHistorySize) {
        _colorHistory = _colorHistory.sublist(0, maxHistorySize);
      }
      _saveHistory();

      if (_notificationsEnabled) {
        _notificationService.showColorNotification(
          colorName: color.colorName ?? 'Unknown',
          hex: color.hex,
          rgb: color.rgbString,
        );
      }
    }
    
    notifyListeners();
  }

  void startPolling({Duration interval = const Duration(seconds: 2)}) {
    _apiService.startPolling(_updateColor, interval);
  }

  void stopPolling() {
    _apiService.stopPolling();
  }

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
  }

  void clearHistory() {
    _colorHistory = [];
    _saveHistory();
    notifyListeners();
  }

  void selectColorFromHistory(ColorData color) {
    _currentColor = color;
    notifyListeners();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
