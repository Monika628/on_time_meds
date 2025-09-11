class PillModel {
  final int id;
  final String pillName;
  final DateTime time;
  final String? dosage;
  final List<String>? types;
  final int interval;
  final String? alarmTone;
  final String? ringtone; // ✅ New field added

  PillModel({
    required this.id,
    required this.pillName,
    required this.time,
    required this.interval,
    this.dosage,
    this.types,
    this.alarmTone,
    this.ringtone, // ✅ Added to constructor
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'pillName': pillName,
    'time': time.toIso8601String(),
    'dosage': dosage,
    'types': types,
    'interval': interval,
    'alarmTone': alarmTone,
    'ringtone': ringtone, // ✅ Included in JSON
  };

  factory PillModel.fromJson(Map<String, dynamic> json) => PillModel(
    id: json['id'],
    pillName: json['pillName'],
    time: DateTime.parse(json['time']),
    dosage: json['dosage'],
    types: json['types'] != null ? List<String>.from(json['types']) : null,
    interval: json['interval'],
    alarmTone: json['alarmTone'],
    ringtone: json['ringtone'], // ✅ Parsed from JSON
  );

  // CopyWith method for updating specific fields
  PillModel copyWith({
    int? id,
    String? pillName,
    DateTime? time,
    String? dosage,
    List<String>? types,
    int? interval,
    String? alarmTone,
    String? ringtone,
  }) {
    return PillModel(
      id: id ?? this.id,
      pillName: pillName ?? this.pillName,
      time: time ?? this.time,
      dosage: dosage ?? this.dosage,
      types: types ?? this.types,
      interval: interval ?? this.interval,
      alarmTone: alarmTone ?? this.alarmTone,
      ringtone: ringtone ?? this.ringtone,
    );
  }
}