// RUBRIK: Relational Database - Model untuk tabel 'categories'
// Tabel ini berelasi dengan tabel 'items' melalui foreign key category_id
class Category {
  final int? id;
  final String name;

  const Category({
    this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name)';
}
