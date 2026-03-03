import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser;
});

final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref.watch(supabaseClientProvider));
});

class AuthActions {
  final SupabaseClient _client;
  AuthActions(this._client);

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': displayName},
    );
    if (response.user != null) {
      try {
        await _upsertProfile(response.user!, displayName: displayName);
      } catch (_) {}
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user != null) {
      // Best-effort profile upsert — don't let a DB hiccup surface as a
      // sign-in error since the auth itself succeeded.
      try {
        await _upsertProfile(response.user!);
      } catch (_) {}
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Ensures the user profile row exists in public.users.
  /// Called after every sign-in/sign-up as a safety net.
  Future<void> _upsertProfile(User user, {String? displayName}) async {
    final name = displayName ??
        user.userMetadata?['full_name'] as String? ??
        user.userMetadata?['name'] as String? ??
        user.email?.split('@').first ??
        'User';

    await _client.from('users').upsert(
      {
        'id': user.id,
        'email': user.email ?? '',
        'display_name': name,
        'avatar_url': user.userMetadata?['avatar_url'] as String?,
      },
      onConflict: 'id',
    );
  }
}
