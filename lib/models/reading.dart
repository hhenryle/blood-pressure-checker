class Reading {
  final int? id;
  final int systolic;
  final int diastolic;
  final int pulse;
  final DateTime measuredAt;
  final String? arm; // 'left' | 'right'
  final String? position; // 'sitting' | 'standing' | 'lying'
  final List<String> tags;
  final String? note;

  const Reading({
    this.id,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.measuredAt,
    this.arm,
    this.position,
    this.tags = const [],
    this.note,
  });

  Reading copyWith({
    int? id,
    int? systolic,
    int? diastolic,
    int? pulse,
    DateTime? measuredAt,
    String? arm,
    String? position,
    List<String>? tags,
    String? note,
  }) =>
      Reading(
        id: id ?? this.id,
        systolic: systolic ?? this.systolic,
        diastolic: diastolic ?? this.diastolic,
        pulse: pulse ?? this.pulse,
        measuredAt: measuredAt ?? this.measuredAt,
        arm: arm ?? this.arm,
        position: position ?? this.position,
        tags: tags ?? this.tags,
        note: note ?? this.note,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'systolic': systolic,
        'diastolic': diastolic,
        'pulse': pulse,
        'measured_at': measuredAt.millisecondsSinceEpoch,
        'arm': arm,
        'position': position,
        'tags': tags.join(','),
        'note': note,
      };

  factory Reading.fromMap(Map<String, Object?> m) => Reading(
        id: m['id'] as int?,
        systolic: m['systolic'] as int,
        diastolic: m['diastolic'] as int,
        pulse: m['pulse'] as int,
        measuredAt:
            DateTime.fromMillisecondsSinceEpoch(m['measured_at'] as int),
        arm: m['arm'] as String?,
        position: m['position'] as String?,
        tags: ((m['tags'] as String?) ?? '')
            .split(',')
            .where((t) => t.isNotEmpty)
            .toList(),
        note: m['note'] as String?,
      );
}
