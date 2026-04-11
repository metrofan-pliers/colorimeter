import 'dart:convert';
import 'package:flutter/material.dart';

class ColorData {
  final int r;
  final int g;
  final int b;
  final String hex;
  final Map<String, int> hsv;
  final Map<String, int> cmyk;
  final String? timestamp;
  final String? colorName;

  ColorData({
    required this.r,
    required this.g,
    required this.b,
    required this.hex,
    required this.hsv,
    required this.cmyk,
    this.timestamp,
    this.colorName,
  });

  Color get color => Color.fromRGBO(r, g, b, 1);

  String get rgbString => 'RGB($r, $g, $b)';
  String get hsvString => 'HSV(${hsv['h']}, ${hsv['s']}%, ${hsv['v']}%)';
  String get cmykString => 'CMYK(${cmyk['c']}%, ${cmyk['m']}%, ${cmyk['y']}%, ${cmyk['k']}%)';

  factory ColorData.fromJson(Map<String, dynamic> json) {
    final r = json['r'] ?? 0;
    final g = json['g'] ?? 0;
    final b = json['b'] ?? 0;

    return ColorData(
      r: r,
      g: g,
      b: b,
      hex: json['hex'] ?? '#000000',
      hsv: json['hsv'] ?? {'h': 0, 's': 0, 'v': 0},
      cmyk: ColorData.rgbToCmyk(r, g, b),
      timestamp: json['timestamp'],
      colorName: json['colorName'],
    );
  }

  static Map<String, int> rgbToCmyk(int r, int g, int b) {
    final rNorm = r / 255;
    final gNorm = g / 255;
    final bNorm = b / 255;

    final k = 1 - [rNorm, gNorm, bNorm].reduce((a, b) => a > b ? a : b);

    if (k == 1) {
      return {'c': 0, 'm': 0, 'y': 0, 'k': 100};
    }

    final c = ((1 - rNorm - k) / (1 - k) * 100).round();
    final m = ((1 - gNorm - k) / (1 - k) * 100).round();
    final y = ((1 - bNorm - k) / (1 - k) * 100).round();
    final kPercent = (k * 100).round();

    return {'c': c, 'm': m, 'y': y, 'k': kPercent};
  }

  Map<String, dynamic> toJson() => {
    'r': r,
    'g': g,
    'b': b,
    'hex': hex,
    'hsv': hsv,
    'cmyk': cmyk,
    'timestamp': timestamp,
    'colorName': colorName,
  };

  String toJsonString() => jsonEncode(toJson());

  factory ColorData.fromJsonString(String jsonString) {
    return ColorData.fromJson(jsonDecode(jsonString));
  }

  ColorData copyWith({
    int? r,
    int? g,
    int? b,
    String? hex,
    Map<String, int>? hsv,
    Map<String, int>? cmyk,
    String? timestamp,
    String? colorName,
  }) {
    return ColorData(
      r: r ?? this.r,
      g: g ?? this.g,
      b: b ?? this.b,
      hex: hex ?? this.hex,
      hsv: hsv ?? this.hsv,
      cmyk: cmyk ?? this.cmyk,
      timestamp: timestamp ?? this.timestamp,
      colorName: colorName ?? this.colorName,
    );
  }
}
