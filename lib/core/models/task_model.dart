import 'package:equatable/equatable.dart';
import 'package:todo/core/models/tag_model.dart';
import '../utils/constants.dart';

class TaskModel extends Equatable {
  final int id;
  final int listId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String priority;
  final String status;
  final DateTime createdAt;
  final List<TagModel> tags; // Populated in DAO via joins

  const TaskModel({
    required this.id,
    required this.listId,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = 'medium',
    this.status = 'todo',
    required this.createdAt,
    this.tags = const [],
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as int,
      listId: map['list_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      priority: map['priority'] as String? ?? 'medium',
      status: map['status'] as String? ?? 'todo',
      createdAt: DateTime.parse(map['created_at'] as String),
      tags: [], // Tags loaded separately in DAO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'list_id': listId,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'priority': priority,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      // Tags handled via separate inserts in DAO
    };
  }

  TaskModel copyWith({
    int? id,
    int? listId,
    String? title,
    String? description,
    DateTime? dueDate,
    String? priority,
    String? status,
    DateTime? createdAt,
    List<TagModel>? tags,
  }) {
    return TaskModel(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }

  // Validation helpers
  bool get isValid =>
      title.trim().isNotEmpty &&
      _isValidDueDate() &&
      _isValidPriority() &&
      _isValidStatus();
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now());
  bool get isDueSoon =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now().add(kDueSoonThreshold)) &&
      !isOverdue;

  bool _isValidDueDate() =>
      dueDate == null || !dueDate!.isBefore(DateTime.now());
  bool _isValidPriority() => kPriorities.contains(priority);
  bool _isValidStatus() => kStatuses.contains(status);

  @override
  List<Object?> get props => [
        id,
        listId,
        title,
        description,
        dueDate,
        priority,
        status,
        createdAt,
        tags
      ];

  @override
  bool get stringify => true;
}
