import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // in minutes
  final String status; // 'draft' | 'open' | 'closed'
  final DateTime createdAt;

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.status,
    required this.createdAt,
  });

  factory QuizModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return QuizModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      creatorId: map['creatorId'] ?? '',
      startTime: parseDateTime(map['startTime']),
      endTime: parseDateTime(map['endTime']),
      duration: map['duration'] is int ? map['duration'] : (int.tryParse(map['duration']?.toString() ?? '') ?? 0),
      status: map['status'] ?? 'draft',
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'duration': duration,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // To map for local storage / mock (which doesn't support Timestamp easily)
  Map<String, dynamic> toMockMap() {
    return {
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration': duration,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  QuizModel copyWith({
    String? title,
    String? description,
    String? creatorId,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    String? status,
    DateTime? createdAt,
  }) {
    return QuizModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isDraft => status == 'draft';
  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';

  bool get isTimeValid {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }
}
