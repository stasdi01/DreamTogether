class ActivityItem {
  final String id;
  final String connectionId;
  final String connectionName;
  final String? actorId;
  final String? actorName;
  final String type; // 'item_added' | 'item_claimed' | 'item_gifted' | 'member_joined'
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const ActivityItem({
    required this.id,
    required this.connectionId,
    required this.connectionName,
    this.actorId,
    this.actorName,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  factory ActivityItem.fromMap(Map<String, dynamic> map) {
    return ActivityItem(
      id: map['id'] as String,
      connectionId: map['connection_id'] as String,
      connectionName: map['connection_name'] as String? ?? '',
      actorId: map['actor_id'] as String?,
      actorName: map['actor_name'] as String?,
      type: map['type'] as String,
      payload: (map['payload'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  /// Short label for the actor: their display name or "Someone".
  String get actor => actorName ?? 'Someone';

  /// Human-readable sentence describing what happened.
  String get sentence {
    switch (type) {
      case 'item_added':
        final title = payload['item_title'] as String?;
        return title != null ? 'added "$title"' : 'added an item';
      case 'item_claimed':
        final title = payload['item_title'] as String?;
        return title != null ? 'claimed "$title"' : 'claimed an item';
      case 'item_gifted':
        final title = payload['item_title'] as String?;
        return title != null ? 'gifted "$title"' : 'gave a gift';
      case 'member_joined':
        return 'joined $connectionName';
      default:
        return 'did something';
    }
  }
}
