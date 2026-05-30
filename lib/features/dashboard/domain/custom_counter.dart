import 'package:flutter/material.dart';
import '../../../app/theme/color_schemes.dart';

class CustomCounter {
  final String id;
  final String label;
  final String value;
  final String unit;
  final int colorIndex;
  final int sortOrder;

  const CustomCounter({
    required this.id,
    required this.label,
    required this.value,
    this.unit = '',
    this.colorIndex = 0,
    this.sortOrder = 0,
  });

  factory CustomCounter.fromJson(Map<String, dynamic> j) => CustomCounter(
    id: j['id'] as String? ?? '',
    label: j['label'] as String? ?? '',
    value: j['value'] as String? ?? '',
    unit: j['unit'] as String? ?? '',
    colorIndex: j['colorIndex'] as int? ?? 0,
    sortOrder: j['sortOrder'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'value': value,
    'unit': unit,
    'colorIndex': colorIndex,
    'sortOrder': sortOrder,
  };

  CustomCounter copyWith({
    String? label,
    String? value,
    String? unit,
    int? colorIndex,
    int? sortOrder,
  }) => CustomCounter(
    id: id,
    label: label ?? this.label,
    value: value ?? this.value,
    unit: unit ?? this.unit,
    colorIndex: colorIndex ?? this.colorIndex,
    sortOrder: sortOrder ?? this.sortOrder,
  );

  static const List<Color> palette = [
    AppColors.blue600,
    AppColors.green600,
    AppColors.orange500,
    AppColors.red700,
    Color(0xFF7C4DFF),
    Color(0xFF00897B),
  ];

  Color get color => palette[colorIndex.clamp(0, palette.length - 1)];
}

// ── PCM default counters (imported on demand) ─────────────────────────────

const List<Map<String, dynamic>> kPcmDefaultCounters = [
  {
    'id': 'pcm_art9_residuo',
    'label': 'Art.9 da recuperare',
    'value': '00:00',
    'unit': 'h',
    'colorIndex': 2,
    'sortOrder': 0,
  },
  {
    'id': 'pcm_banca_ore',
    'label': 'Banca ore fruibile',
    'value': '00:00',
    'unit': 'h',
    'colorIndex': 1,
    'sortOrder': 1,
  },
  {
    'id': 'pcm_ferie_residue',
    'label': 'Ferie residue',
    'value': '0',
    'unit': 'gg',
    'colorIndex': 0,
    'sortOrder': 2,
  },
  {
    'id': 'pcm_permesso_breve',
    'label': 'Permesso breve residuo',
    'value': '00:00',
    'unit': 'h',
    'colorIndex': 4,
    'sortOrder': 3,
  },
  {
    'id': 'pcm_straord_liquidabili',
    'label': 'Straord. liquidabili',
    'value': '00:00',
    'unit': 'h',
    'colorIndex': 2,
    'sortOrder': 4,
  },
  {
    'id': 'pcm_buoni_pasto',
    'label': 'Buoni pasto mese',
    'value': '0',
    'unit': 'bp',
    'colorIndex': 5,
    'sortOrder': 5,
  },
];
