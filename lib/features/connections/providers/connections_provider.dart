import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../movies/providers/movies_provider.dart';
import '../models/connection_model.dart';
import 'activity_provider.dart';

// ── Fetch all connections for current user ──────────────────────────────────

final connectionsProvider =
    FutureProvider<List<ConnectionModel>>((ref) async {
  // Re-run whenever auth state changes (SIGNED_IN, SIGNED_OUT, etc.)
  // so the provider doesn't get stuck in error/empty state on sign-in.
  ref.watch(authStateProvider);
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final response = await client.from('connection_members').select('''
      connections (
        id, name, created_by, created_at,
        connection_members (
          user_id, joined_at,
          users (display_name, avatar_url)
        )
      )
    ''').eq('user_id', userId);

  return (response as List)
      .map((item) => ConnectionModel.fromMap(
          item['connections'] as Map<String, dynamic>))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

// ── Actions ─────────────────────────────────────────────────────────────────

final connectionActionsProvider = Provider<ConnectionActions>((ref) {
  return ConnectionActions(
    client: ref.watch(supabaseClientProvider),
    ref: ref,
  );
});

class ConnectionActions {
  final SupabaseClient client;
  final Ref ref;

  ConnectionActions({required this.client, required this.ref});

  /// Creates a connection via a Postgres function (SECURITY DEFINER).
  /// Returns the 6-digit invite code.
  Future<String> createConnection(String name) async {
    final result = await client.rpc(
      'create_connection_with_code',
      params: {'connection_name': name.trim()},
    );
    ref.invalidate(connectionsProvider);
    final data = result as Map<String, dynamic>;
    return data['invite_code'] as String;
  }

  /// Generates a fresh invite code for an existing connection.
  /// Returns the 6-digit code.
  Future<String> generateInviteCode(String connectionId) async {
    final result = await client.rpc(
      'generate_invite_code',
      params: {'p_connection_id': connectionId},
    );
    final data = result as Map<String, dynamic>;
    return data['invite_code'] as String;
  }

  /// Leaves a connection. The user's row is removed from connection_members.
  Future<void> leaveConnection(String connectionId) async {
    await client.rpc(
      'leave_connection',
      params: {'p_connection_id': connectionId},
    );
    ref.invalidate(connectionsProvider);
    ref.invalidate(allMovieItemsProvider);
    ref.invalidate(activityFeedProvider);
  }

  /// Joins a connection via a Postgres function (SECURITY DEFINER).
  /// Returns the connection name.
  Future<String> joinConnection(String code) async {
    final result = await client.rpc(
      'join_connection_with_code',
      params: {'p_code': code.trim()},
    );
    ref.invalidate(connectionsProvider);
    ref.invalidate(activityFeedProvider);
    final data = result as Map<String, dynamic>;
    return data['connection_name'] as String;
  }
}
