class Category {
  final int? id;
  final String name;
  final String color; // Stored as a hex string

  Category({this.id, required this.name, required this.color});

  // Convert a Category object into a Map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'name': name, 'color': color};

    // Only include id if it's not null (for updates)
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  // Create a Category object from a Map
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(id: map['id'], name: map['name'], color: map['color']);
  }

  // Create a copy of this Category with the given fields replaced with the new values
  Category copyWith({int? id, String? name, String? color}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }
}
