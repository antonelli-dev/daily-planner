class Workspace {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final bool isPersonal;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Workspace({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.isPersonal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerId: json['ownerId'] as String,
      isPersonal: json['isPersonal'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'isPersonal': isPersonal,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Workspace copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    bool? isPersonal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      isPersonal: isPersonal ?? this.isPersonal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Workspace &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Workspace{id: $id, name: $name, isPersonal: $isPersonal}';
  }
}