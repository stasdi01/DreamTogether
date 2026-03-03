import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../connections/models/connection_model.dart';
import '../../connections/providers/connections_provider.dart';
import '../../wishlist/models/wishlist_item_model.dart';

/// A wishlist item enriched with the group name and owner's display info,
/// used for the Movies tab which shows movie items across all connections.
class MovieItemRow {
  final WishlistItem item;
  final String connectionId;
  final String connectionName;
  final String ownerDisplayName;
  final String ownerInitials;

  const MovieItemRow({
    required this.item,
    required this.connectionId,
    required this.connectionName,
    required this.ownerDisplayName,
    required this.ownerInitials,
  });
}

/// Fetches all movie-category items across every connection the user belongs to.
/// Reuses [connectionsProvider] (already loaded) for member info, then does a
/// single filtered query to `wishlist_items`.
final allMovieItemsProvider = FutureProvider<List<MovieItemRow>>((ref) async {
  // Re-run whenever auth state changes so the tab recovers after sign-in.
  ref.watch(authStateProvider);
  final client = ref.watch(supabaseClientProvider);
  if (client.auth.currentUser == null) return [];

  // Guard: if connections haven't loaded or errored, return empty instead of
  // propagating the error and locking the Movies tab in error state.
  List<ConnectionModel> connections;
  try {
    connections = await ref.watch(connectionsProvider.future);
  } catch (_) {
    return [];
  }

  if (connections.isEmpty) return [];

  // Build lookup maps from already-loaded connection data
  final connectionNameMap = <String, String>{};
  final memberMap = <String, ConnectionMember>{};
  for (final conn in connections) {
    connectionNameMap[conn.id] = conn.name;
    for (final m in conn.members) {
      memberMap['${conn.id}_${m.userId}'] = m;
    }
  }

  final connectionIds = connections.map((c) => c.id).toList();

  final response = await client
      .from('wishlist_items')
      .select()
      .eq('category', 'movie')
      .inFilter('connection_id', connectionIds)
      .order('created_at', ascending: false);

  return (response as List).map((data) {
    final item = WishlistItem.fromMap(data as Map<String, dynamic>);
    final member = memberMap['${item.connectionId}_${item.userId}'];
    return MovieItemRow(
      item: item,
      connectionId: item.connectionId,
      connectionName: connectionNameMap[item.connectionId] ?? 'Unknown',
      ownerDisplayName: member?.displayName ?? 'Member',
      ownerInitials: member?.initials ?? '?',
    );
  }).toList();
});
