import '../../dashboard/models/insight_data.dart';

class AppUser {
  final String id;
  final String email;
  final String name;
  final String? casUrl;
  final String? casFileType;
  final List<InsightData>? insights;
  final DateTime? lastUpdated;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.casUrl,
    this.casFileType,
    this.insights,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'cas_url': casUrl ?? '',
      'cas_file_type': casFileType ?? 'pdf',
      'insights': insights?.map((i) => i.toFirestore()).toList(),
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      casUrl: map['cas_url'] ?? '',
      casFileType: map['cas_file_type'] ?? 'pdf',
      insights: map['insights'] != null 
          ? (map['insights'] as List).map((i) => InsightData.fromFirestore(i)).toList()
          : null,
      lastUpdated: map['last_updated'] != null 
          ? DateTime.tryParse(map['last_updated']) 
          : null,
    );
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? casUrl,
    String? casFileType,
    List<InsightData>? insights,
    DateTime? lastUpdated,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      casUrl: casUrl ?? this.casUrl,
      casFileType: casFileType ?? this.casFileType,
      insights: insights ?? this.insights,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
