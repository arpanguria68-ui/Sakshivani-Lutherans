class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.itemType,
    required this.itemRef,
    required this.createdAt,
  });

  final String id;
  final String itemType;
  final String itemRef;
  final String createdAt;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'item_type': itemType,
      'item_ref': itemRef,
      'created_at': createdAt,
    };
  }

  factory FavoriteItem.fromMap(Map<String, Object?> map) {
    return FavoriteItem(
      id: map['id'] as String? ?? '',
      itemType: map['item_type'] as String? ?? '',
      itemRef: map['item_ref'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
