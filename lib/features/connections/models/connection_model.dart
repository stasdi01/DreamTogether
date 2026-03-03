class ConnectionModel {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final List<ConnectionMember> members;

  const ConnectionModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.members,
  });

  int get memberCount => members.length;

  factory ConnectionModel.fromMap(Map<String, dynamic> map) {
    final membersRaw = map['connection_members'] as List<dynamic>? ?? [];
    return ConnectionModel(
      id: map['id'] as String,
      name: map['name'] as String,
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      members: membersRaw
          .map((m) => ConnectionMember.fromMap(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ConnectionMember {
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final DateTime joinedAt;

  const ConnectionMember({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    required this.joinedAt,
  });

  factory ConnectionMember.fromMap(Map<String, dynamic> map) {
    final user = map['users'] as Map<String, dynamic>?;
    return ConnectionMember(
      userId: map['user_id'] as String,
      displayName: user?['display_name'] as String?,
      avatarUrl: user?['avatar_url'] as String?,
      joinedAt: DateTime.parse(map['joined_at'] as String),
    );
  }

  String get initials {
    final name = displayName ?? '';
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
