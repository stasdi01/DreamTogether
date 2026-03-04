import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/activity_item_model.dart';

final activityFeedProvider = FutureProvider<List<ActivityItem>>((ref) async {
  ref.watch(authStateProvider);
  final client = ref.watch(supabaseClientProvider);
  if (client.auth.currentUser == null) return [];

  final result = await client.rpc(
    'get_activity_feed',
    params: {'p_limit': 30},
  );

  return (result as List)
      .cast<Map<String, dynamic>>()
      .map(ActivityItem.fromMap)
      .toList();
});
