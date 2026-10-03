class Person {
  final int? id;
  final String name;
  final String phone;
  final String? email;
  final String type;
  final DateTime createdAt;

  Person({
    this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      type: map['type'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Person copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? type,
    DateTime? createdAt,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
