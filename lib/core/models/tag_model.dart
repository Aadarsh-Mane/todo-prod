import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class TagModel extends Equatable {
  final int id;
  final String name;
  final int
      color; // ARGB int for Color.fromARGB(0xFF000000 + color, r, g, b) but simplified

  const TagModel({
    required this.id,
    required this.name,
    required this.color,
  });

  factory TagModel.fromMap(Map<String, dynamic> map) {
    return TagModel(
      id: map['id'] as int,
      name: map['name'] as String,
      color: map['color'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }

  TagModel copyWith({
    int? id,
    String? name,
    int? color,
  }) {
    return TagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  // Validation
  bool get isValid =>
      name.trim().isNotEmpty &&
      name.trim().length <= 20; // Short names for chips

  Color get uiColor => Color(color); // Direct to Color for chips

  @override
  List<Object> get props => [id, name, color];

  @override
  bool get stringify => true;
}
