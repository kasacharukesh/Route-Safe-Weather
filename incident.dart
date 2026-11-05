class Incident {
  const Incident({
    required this.type,
    required this.location,
    required this.description,
    required this.createdAt,
  });

  final String type;
  final String location;
  final String description;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'type': type,
        'location': location,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
        type: json['type'] as String? ?? 'Other',
        location: json['location'] as String? ?? '',
        description: json['description'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
