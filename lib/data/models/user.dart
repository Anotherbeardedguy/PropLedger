class User {
  final String id;
  final String email;
  final String? name;
  final DateTime created;
  final DateTime updated;

  User({
    required this.id,
    required this.email,
    this.name,
    required this.created,
    required this.updated,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      created: DateTime.parse(json['created'] as String),
      updated: DateTime.parse(json['updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? created,
    DateTime? updated,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
