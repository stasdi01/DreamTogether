import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../connections/models/connection_model.dart';
import '../../movies/providers/movies_provider.dart';
import '../models/wishlist_item_model.dart';

// ── Read: all items for a connection ────────────────────────────────────────

final wishlistItemsProvider =
    FutureProvider.family<List<WishlistItem>, String>((ref, connectionId) async {
  final client = ref.watch(supabaseClientProvider);
  if (client.auth.currentUser == null) return [];

  final response = await client
      .from('wishlist_items')
      .select()
      .eq('connection_id', connectionId)
      .order('order_index');

  return (response as List)
      .map((item) => WishlistItem.fromMap(item as Map<String, dynamic>))
      .toList();
});

// ── Read: single connection with members (for detail screen) ────────────────

final connectionDetailProvider =
    FutureProvider.family<ConnectionModel?, String>((ref, connectionId) async {
  final client = ref.watch(supabaseClientProvider);
  if (client.auth.currentUser == null) return null;

  final response = await client.from('connections').select('''
      id, name, created_by, created_at,
      connection_members (
        user_id, joined_at,
        users (display_name, avatar_url)
      )
    ''').eq('id', connectionId).single();

  return ConnectionModel.fromMap(response as Map<String, dynamic>);
});

// ── Actions ─────────────────────────────────────────────────────────────────

final wishlistActionsProvider = Provider<WishlistActions>((ref) {
  return WishlistActions(
    client: ref.watch(supabaseClientProvider),
    ref: ref,
  );
});

class WishlistActions {
  final SupabaseClient client;
  final Ref ref;

  WishlistActions({required this.client, required this.ref});

  /// Adds a new wishlist item via SECURITY DEFINER RPC.
  Future<void> addItem({
    required String connectionId,
    required String title,
    required ItemCategory category,
    required ItemPriority priority,
    String? imageUrl,
    String? linkUrl,
    double? price,
    String? notes,
  }) async {
    await client.rpc('add_wishlist_item', params: {
      'p_connection_id': connectionId,
      'p_title': title,
      'p_category': category.name,
      'p_priority': priority.name,
      'p_image_url': imageUrl,
      'p_link_url': linkUrl,
      'p_price': price,
      'p_notes': notes,
    });
    ref.invalidate(wishlistItemsProvider(connectionId));
  }

  /// Deletes an item the current user owns via SECURITY DEFINER RPC.
  Future<void> deleteItem(String itemId, String connectionId) async {
    await client.rpc('delete_wishlist_item', params: {'p_item_id': itemId});
    ref.invalidate(wishlistItemsProvider(connectionId));
  }

  /// Updates an item the current user owns via SECURITY DEFINER RPC.
  Future<void> updateItem({
    required WishlistItem item,
    required String title,
    required ItemCategory category,
    required ItemPriority priority,
    String? imageUrl,
    String? linkUrl,
    double? price,
    String? notes,
  }) async {
    await client.rpc('update_wishlist_item', params: {
      'p_item_id': item.id,
      'p_title': title,
      'p_category': category.name,
      'p_priority': priority.name,
      'p_image_url': imageUrl,
      'p_link_url': linkUrl,
      'p_price': price,
      'p_notes': notes,
    });
    ref.invalidate(wishlistItemsProvider(item.connectionId));
  }

  /// Claims an item (signals intent to gift it to the owner).
  Future<void> claimItem(String itemId, String connectionId) async {
    await client.rpc('claim_wishlist_item', params: {'p_item_id': itemId});
    ref.invalidate(wishlistItemsProvider(connectionId));
    ref.invalidate(allMovieItemsProvider);
  }

  /// Removes a claim placed by the current user.
  Future<void> unclaimItem(String itemId, String connectionId) async {
    await client.rpc('unclaim_wishlist_item', params: {'p_item_id': itemId});
    ref.invalidate(wishlistItemsProvider(connectionId));
    ref.invalidate(allMovieItemsProvider);
  }
}
