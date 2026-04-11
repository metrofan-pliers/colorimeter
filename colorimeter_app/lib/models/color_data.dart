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
    
    final h = json['hsv']?['h'] ?? 0;
    final s = json['hsv']?['s'] ?? 0;
    final v = json['hsv']?['v'] ?? 0;

    return ColorData(
      r: r,
      g: g,
      b: b,
      hex: json['hex'] ?? '#000000',
      hsv: json['hsv'] ?? {'h': h, 's': s, 'v': v},
      cmyk: ColorData.rgbToCmyk(r, g, b),
      timestamp: json['timestamp'],
      colorName: json['colorName'] ?? detectColorName(r, g, b, h, s, v),
    );
  }

  static String detectColorName(int r, int g, int b, int h, int s, int v) {
    final sNorm = s / 100;
    final vNorm = v / 100;

    if (vNorm < 0.10) return 'black';

    if (sNorm < 0.18) {
      if (vNorm > 0.80) return 'white';
      if (vNorm > 0.25) return 'gray';
      return 'black';
    }

    if (sNorm < 0.4 && vNorm > 0.4) {
      if (h >= 20 && h < 50) return 'beige';
      if (h >= 320 || h < 20) return 'pink';
    }

    if (h < 40 && vNorm < 0.20 && sNorm > 0.25) return 'brown';
    if (h >= 30 && h < 55) return 'yellow';
    if (h >= 5 && h < 25 && vNorm >= 0.35) return 'orange';
    
    if (h >= 0 && h < 15) return 'red';
    if (h >= 345 && h < 360) return 'red';
    if (h >= 15 && h < 45) return 'orange';
    if (h >= 45 && h < 75) return 'yellow';
    if (h >= 75 && h < 150) return 'green';
    if (h >= 150 && h < 195) return 'cyan';
    if (h >= 195 && h < 255) return 'blue';
    if (h >= 255 && h < 285) return 'purple';
    if (h >= 285 && h < 345) return 'magenta';

    return 'unknown';
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
