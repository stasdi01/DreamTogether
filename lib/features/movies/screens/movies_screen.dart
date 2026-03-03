import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/home/screens/main_shell.dart';
import '../../../features/wishlist/models/wishlist_item_model.dart';
import '../../../features/wishlist/providers/wishlist_provider.dart';
import '../providers/movies_provider.dart';

class MoviesScreen extends ConsumerWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(allMovieItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Movies',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: const [ThemeToggleButton()],
      ),
      body: moviesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(allMovieItemsProvider),
        ),
        data: (movies) => movies.isEmpty
            ? _EmptyState(onGoToLists: () => context.go('/wishlist'))
            : _MovieList(movies: movies),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onGoToLists;
  const _EmptyState({required this.onGoToLists});

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
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.25)),
              ),
              child: const Icon(
                Icons.movie_outlined,
                color: Color(0xFFEA580C),
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No movies yet',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Add movies to your lists from the\nLists tab — they\'ll appear here.',
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
                onPressed: onGoToLists,
                icon: const Icon(Icons.list_alt_outlined, size: 18),
                label: const Text('Go to Lists'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(message,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Movie list ────────────────────────────────────────────────────────────────

class _MovieList extends StatelessWidget {
  final List<MovieItemRow> movies;
  const _MovieList({required this.movies});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: movies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _MovieCard(row: movies[i]),
    );
  }
}

// ── Movie card ────────────────────────────────────────────────────────────────

class _MovieCard extends StatelessWidget {
  final MovieItemRow row;
  const _MovieCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = row.item;

    return Card(
      child: InkWell(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _MovieDetailSheet(row: row),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Movie icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.movie_outlined,
                  color: Color(0xFFEA580C),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _PriorityDot(priority: item.priority),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Owner + group chips
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurfaceElevated
                                : AppTheme.lavender,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            row.ownerInitials.isNotEmpty
                                ? row.ownerInitials[0]
                                : '?',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.brightPurple,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          row.ownerDisplayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.brightPurple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            row.connectionName,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.brightPurple,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Notes preview
                    if (item.notes != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Priority dot ──────────────────────────────────────────────────────────────

class _PriorityDot extends StatelessWidget {
  final ItemPriority priority;
  const _PriorityDot({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      margin: const EdgeInsets.only(left: 8, top: 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color(priority),
      ),
    );
  }

  Color _color(ItemPriority p) {
    switch (p) {
      case ItemPriority.low:
        return Colors.grey;
      case ItemPriority.medium:
        return Colors.orange;
      case ItemPriority.high:
        return const Color(0xFFEF4444);
    }
  }
}

// ── Movie detail bottom sheet ─────────────────────────────────────────────────

class _MovieDetailSheet extends ConsumerStatefulWidget {
  final MovieItemRow row;
  const _MovieDetailSheet({required this.row});

  @override
  ConsumerState<_MovieDetailSheet> createState() => _MovieDetailSheetState();
}

class _MovieDetailSheetState extends ConsumerState<_MovieDetailSheet> {
  bool _linkCopied = false;
  bool _isClaiming = false;

  Future<void> _claim() async {
    setState(() => _isClaiming = true);
    try {
      await ref.read(wishlistActionsProvider).claimItem(
            widget.row.item.id,
            widget.row.connectionId,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  Future<void> _unclaim() async {
    setState(() => _isClaiming = true);
    try {
      await ref.read(wishlistActionsProvider).unclaimItem(
            widget.row.item.id,
            widget.row.connectionId,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = widget.row.item;
    final currentUserId =
        ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final isOwner = item.userId == currentUserId;
    final isClaimedByMe = item.isClaimed && item.claimedBy == currentUserId;
    final isClaimedByOther =
        item.isClaimed && item.claimedBy != currentUserId;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Category badge + priority
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.movie_outlined,
                        color: Color(0xFFEA580C), size: 14),
                    SizedBox(width: 5),
                    Text(
                      'Movie',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _priorityColor(item.priority),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _priorityLabel(item.priority),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _priorityColor(item.priority),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            item.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),

          // Added by + group
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurfaceElevated
                      : AppTheme.lavender,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.row.ownerInitials.isNotEmpty
                      ? widget.row.ownerInitials[0]
                      : '?',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.brightPurple,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.row.ownerDisplayName,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              Text('in',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.brightPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.row.connectionName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.brightPurple,
                  ),
                ),
              ),
            ],
          ),

          // Price
          if (item.price != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.attach_money_rounded,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                Text(
                  item.price!.toStringAsFixed(2),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],

          // Link
          if (item.linkUrl != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.link_rounded,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.linkUrl!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.brightPurple),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await Clipboard.setData(
                        ClipboardData(text: item.linkUrl!));
                    setState(() => _linkCopied = true);
                    await Future.delayed(const Duration(seconds: 2));
                    if (mounted) setState(() => _linkCopied = false);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      _linkCopied
                          ? Icons.check_rounded
                          : Icons.copy_rounded,
                      size: 16,
                      color: _linkCopied
                          ? const Color(0xFF16A34A)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Notes
          if (item.notes != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurfaceElevated
                    : AppTheme.lightSurfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.notes!,
                      style:
                          theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Claim section (only for non-owners)
          if (!isOwner) ...[
            const SizedBox(height: 20),
            if (isClaimedByOther)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          const Color(0xFF16A34A).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Already claimed',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else if (isClaimedByMe)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isClaiming ? null : _unclaim,
                  icon: _isClaiming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                  label: const Text('Unclaim'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF16A34A),
                    side: const BorderSide(color: Color(0xFF16A34A)),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isClaiming ? null : _claim,
                  icon: _isClaiming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(
                          Icons.volunteer_activism_rounded,
                          size: 18,
                        ),
                  label: const Text("I'll watch this"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],

          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(ItemPriority p) {
    switch (p) {
      case ItemPriority.low:
        return Colors.grey;
      case ItemPriority.medium:
        return Colors.orange;
      case ItemPriority.high:
        return const Color(0xFFEF4444);
    }
  }

  String _priorityLabel(ItemPriority p) {
    switch (p) {
      case ItemPriority.low:
        return 'Low priority';
      case ItemPriority.medium:
        return 'Medium priority';
      case ItemPriority.high:
        return 'High priority';
    }
  }
}
