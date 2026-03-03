import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/connections/models/connection_model.dart';
import '../../../features/connections/providers/connections_provider.dart';
import '../../../features/home/screens/main_shell.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(connectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lists',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: const [ThemeToggleButton()],
      ),
      body: connectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (connections) => connections.isEmpty
            ? _EmptyListsState()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: connections.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _ListConnectionCard(connection: connections[i]),
              ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyListsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.brightPurple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.brightPurple.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.favorite_outline_rounded,
                  color: AppTheme.brightPurple, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'No groups yet',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Create or join a group from the\nHome tab to start your wishlists.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 200,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.people_outline_rounded, size: 18),
                label: const Text('Go to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Connection card for Lists tab ─────────────────────────────────────────────

class _ListConnectionCard extends StatelessWidget {
  final ConnectionModel connection;

  const _ListConnectionCard({required this.connection});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: InkWell(
        onTap: () => context.push(
          '/connection/${connection.id}',
          extra: connection,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with initials
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.brightPurple, AppTheme.primaryPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    connection.name.isNotEmpty
                        ? connection.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connection.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${connection.memberCount} '
                          '${connection.memberCount == 1 ? 'member' : 'members'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ...connection.members.take(3).map((m) => Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: isDark
                                    ? AppTheme.darkSurfaceElevated
                                    : AppTheme.lavender,
                                child: Text(
                                  m.initials.isNotEmpty ? m.initials[0] : '?',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.brightPurple,
                                  ),
                                ),
                              ),
                            )),
                      ],
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
