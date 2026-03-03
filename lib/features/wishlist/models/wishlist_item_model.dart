enum ItemCategory {
  product,
  place,
  movie,
  experience;

  String get label {
    switch (this) {
      case ItemCategory.product:
        return 'Product';
      case ItemCategory.place:
        return 'Place';
      case ItemCategory.movie:
        return 'Movie';
      case ItemCategory.experience:
        return 'Experience';
    }
  }
}

enum ItemPriority { low, medium, high }

class WishlistItem {
  final String id;
  final String userId;
  final String connectionId;
  final String title;
  final ItemCategory category;
  final ItemPriority priority;
  final String? imageUrl;
  final String? linkUrl;
  final double? price;
  final String? notes;
  final bool isClaimed;
  final String? claimedBy;
  final int orderIndex;
  final DateTime createdAt;

  const WishlistItem({
    required this.id,
    required this.userId,
    required this.connectionId,
    required this.title,
    required this.category,
    required this.priority,
    this.imageUrl,
    this.linkUrl,
    this.price,
    this.notes,
    required this.isClaimed,
    this.claimedBy,
    required this.orderIndex,
    required this.createdAt,
  });

  factory WishlistItem.fromMap(Map<String, dynamic> map) {
    return WishlistItem(
      id: map['id'] as String,
      userId: map['owner_id'] as String,
      connectionId: map['connection_id'] as String,
      title: map['title'] as String,
      category: ItemCategory.values.firstWhere(
        (e) => e.name == (map['category'] as String? ?? 'product'),
        orElse: () => ItemCategory.product,
      ),
      priority: ItemPriority.values.firstWhere(
        (e) => e.name == (map['priority'] as String? ?? 'medium'),
        orElse: () => ItemPriority.medium,
      ),
      imageUrl: map['image_url'] as String?,
      linkUrl: map['link_url'] as String?,
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
      notes: map['notes'] as String?,
      isClaimed: map['is_claimed'] as bool? ?? false,
      claimedBy: map['claimed_by'] as String?,
      orderIndex: map['order_index'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
