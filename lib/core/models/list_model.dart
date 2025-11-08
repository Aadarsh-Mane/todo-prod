import 'package:equatable/equatable.dart';

class ListModel extends Equatable {
  final int id;
  final String name;
  final DateTime createdAt;

  const ListModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory ListModel.fromMap(Map<String, dynamic> map) {
    return ListModel(
      id: map['id'] as int,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ListModel copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  }) {
    return ListModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Validation helper (used in repo/UI)
  bool get isValid => name.trim().isNotEmpty && name.trim().length <= 100;

  @override
  List<Object> get props => [id, name, createdAt];

  @override
  bool get stringify => true;
}
