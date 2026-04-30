const sugarOptions = <Map<String, String>>[
  {'label': '无糖', 'value': 'no_sugar'},
  {'label': '少糖', 'value': 'less_sugar'},
  {'label': '半糖', 'value': 'half'},
  {'label': '全糖', 'value': 'full'},
];

const moodOptions = <String>['开心', '平静', '疲惫', '压力大'];

String estimateCalories({required String? sugarLevel, required int? sizeMl}) {
  final volume = (sizeMl ?? 350).clamp(100, 2000);
  final multiplier = switch (sugarLevel) {
    'no_sugar' => 0.08,
    'less_sugar' => 0.18,
    'half' => 0.28,
    'full' => 0.38,
    _ => 0.16,
  };
  final calories = (volume * multiplier).round();
  return '预计热量 $calories kcal';
}

String composeNote(String? moodTag, String note) {
  final trimmed = note.trim();
  final parts = <String>[];
  if (moodTag != null && moodTag.isNotEmpty) {
    parts.add('心情：$moodTag');
  }
  if (trimmed.isNotEmpty) {
    parts.add(trimmed);
  }
  return parts.join('\n');
}
