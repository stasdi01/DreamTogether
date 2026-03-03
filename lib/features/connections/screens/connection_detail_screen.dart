import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../wishlist/models/wishlist_item_model.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../models/connection_model.dart';
import '../providers/connections_provider.dart';

class ConnectionDetailScreen extends ConsumerStatefulWidget {
  final String connectionId;
  final ConnectionModel? initialConnection;

  const ConnectionDetailScreen({
    super.key,
    required this.connectionId,
    this.initialConnection,
  });

  @override
  ConsumerState<ConnectionDetailScreen> createState() =>
      _ConnectionDetailScreenState();
}

class _ConnectionDetailScreenState
    extends ConsumerState<ConnectionDetailScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  List<ConnectionMember> _sortedMembers = [];
  bool _isGeneratingCode = false;

  void _rebuildTabs(ConnectionModel connection, String? currentUserId) {
    final sorted = [...connection.members]
      ..sort((a, b) {
        if (a.userId == currentUserId) return -1;
        if (b.userId == currentUserId) return 1;
        return 0;
      });

    if (sorted.length == _sortedMembers.length) {
      _sortedMembers = sorted;
      return;
    }

    _tabController?.dispose();
    _tabController = TabController(length: sorted.length, vsync: this)
      ..addListener(() => setState(() {}));
    _sortedMembers = sorted;
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _generateAndShowInvite(
      BuildContext context, ConnectionModel connection) async {
    setState(() => _isGeneratingCode = true);
    try {
      final code = await ref
          .read(connectionActionsProvider)
          .generateInviteCode(widget.connectionId);
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _InviteCodeSheet(
            code: code,
            connectionName: connection.name,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingCode = false);
    }
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditItemSheet(connectionId: widget.connectionId),
    );
  }

  void _showEditSheet(BuildContext context, WishlistItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _AddEditItemSheet(connectionId: widget.connectionId, item: item),
    );
  }

  void _showItemDetail(BuildContext context, WishlistItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemDetailSheet(item: item),
    );
  }

  Future<void> _showLeaveDialog(
      BuildContext context, ConnectionModel connection) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave group?'),
        content: Text(
          'You\'ll be removed from "${connection.name}". '
          'Your items will remain on the list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Leave',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ref
          .read(connectionActionsProvider)
          .leaveConnection(widget.connectionId);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final connectionAsync =
        ref.watch(connectionDetailProvider(widget.connectionId));
    final itemsAsync = ref.watch(wishlistItemsProvider(widget.connectionId));

    final connection = connectionAsync.value ?? widget.initialConnection;
    if (connection != null) _rebuildTabs(connection, currentUserId);

    final isOnMyTab = _tabController != null &&
        _sortedMembers.isNotEmpty &&
        _sortedMembers[_tabController!.index].userId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          connection?.name ?? 'Loading...',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (connection != null) ...[
            _isGeneratingCode
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.person_add_outlined),
                    tooltip: 'Invite someone',
                    onPressed: () =>
                        _generateAndShowInvite(context, connection),
                  ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'leave') _showLeaveDialog(context, connection);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app_rounded,
                          color: Color(0xFFEF4444), size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Leave group',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
        bottom: _tabController != null && _sortedMembers.isNotEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: _sortedMembers.length > 3,
                tabs: _sortedMembers
                    .map((m) => Tab(
                          text: m.userId == currentUserId
                              ? 'My List'
                              : (m.displayName?.split(' ').first ?? 'Member'),
                        ))
                    .toList(),
              )
            : null,
      ),
      body: _buildBody(context, connection, itemsAsync, currentUserId),
      floatingActionButton: isOnMyTab
          ? FloatingActionButton.extended(
              onPressed: () => _showAddSheet(context),
              backgroundColor: AppTheme.primaryPurple,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Add item',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    ConnectionModel? connection,
    AsyncValue<List<WishlistItem>> itemsAsync,
    String? currentUserId,
  ) {
    if (connection == null || _tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error loading items: $e'),
        ),
      ),
      data: (items) => TabBarView(
        controller: _tabController,
        children: _sortedMembers.map((member) {
          final memberItems = items
              .where((item) => item.userId == member.userId)
              .toList()
            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
          final isMyTab = member.userId == currentUserId;

          if (memberItems.isEmpty) {
            return _EmptyItemsState(
              isMyTab: isMyTab,
              onAdd: isMyTab ? () => _showAddSheet(context) : null,
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 16, 16, isMyTab ? 100 : 16),
            itemCount: memberItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _ItemCard(
              item: memberItems[i],
              isOwner: isMyTab,
              onTap: isMyTab
                  ? () => _showEditSheet(context, memberItems[i])
                  : () => _showItemDetail(context, memberItems[i]),
              onDelete: isMyTab
                  ? () async {
                      await ref.read(wishlistActionsProvider).deleteItem(
                            memberItems[i].id,
                            widget.connectionId,
                          );
                    }
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Empty state per tab ───────────────────────────────────────────────────────

class _EmptyItemsState extends StatelessWidget {
  final bool isMyTab;
  final VoidCallback? onAdd;

  const _EmptyItemsState({required this.isMyTab, this.onAdd});

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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.brightPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMyTab
                    ? Icons.favorite_outline_rounded
                    : Icons.list_alt_outlined,
                color: AppTheme.brightPurple,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isMyTab ? 'Your list is empty' : 'Nothing here yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isMyTab
                  ? 'Tap "Add item" to start building your wishlist.'
                  : 'This member hasn\'t added anything yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (isMyTab && onAdd != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 180,
                child: ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add item'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Item card with swipe-to-delete ────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final WishlistItem item;
  final bool isOwner;
  final VoidCallback? onTap;
  final Future<void> Function()? onDelete;

  const _ItemCard({
    required this.item,
    required this.isOwner,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final card = Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Category icon bubble
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _categoryColor(item.category).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(item.category),
                  color: _categoryColor(item.category),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          item.category.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (item.price != null) ...[
                          Text(
                            ' · ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '\$${item.price!.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.linkUrl != null || item.notes != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (item.linkUrl != null)
                            _SmallChip(
                              icon: Icons.link_rounded,
                              label: 'Link',
                              color: AppTheme.brightPurple,
                            ),
                          if (item.linkUrl != null && item.notes != null)
                            const SizedBox(width: 6),
                          if (item.notes != null)
                            _SmallChip(
                              icon: Icons.notes_rounded,
                              label: 'Notes',
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              if (isOwner) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isOwner && onDelete != null) {
      return Dismissible(
        key: Key(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete item?'),
              content: Text('Remove "${item.title}" from your list?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Color(0xFFEF4444)),
                  ),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) => onDelete!(),
        child: card,
      );
    }

    return card;
  }

  IconData _categoryIcon(ItemCategory cat) {
    switch (cat) {
      case ItemCategory.product:
        return Icons.shopping_bag_outlined;
      case ItemCategory.place:
        return Icons.place_outlined;
      case ItemCategory.movie:
        return Icons.movie_outlined;
      case ItemCategory.experience:
        return Icons.auto_awesome_outlined;
    }
  }

  Color _categoryColor(ItemCategory cat) {
    switch (cat) {
      case ItemCategory.product:
        return AppTheme.brightPurple;
      case ItemCategory.place:
        return const Color(0xFF16A34A);
      case ItemCategory.movie:
        return const Color(0xFFEA580C);
      case ItemCategory.experience:
        return const Color(0xFF0EA5E9);
    }
  }
}

class _PriorityDot extends StatelessWidget {
  final ItemPriority priority;
  const _PriorityDot({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      margin: const EdgeInsets.only(left: 8, top: 1),
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

class _SmallChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SmallChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Add / Edit item bottom sheet ──────────────────────────────────────────────

class _AddEditItemSheet extends ConsumerStatefulWidget {
  final String connectionId;
  final WishlistItem? item;

  const _AddEditItemSheet({required this.connectionId, this.item});

  @override
  ConsumerState<_AddEditItemSheet> createState() => _AddEditItemSheetState();
}

class _AddEditItemSheetState extends ConsumerState<_AddEditItemSheet> {
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  ItemCategory _category = ItemCategory.product;
  ItemPriority _priority = ItemPriority.medium;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _titleCtrl.text = item.title;
      _priceCtrl.text = item.price?.toStringAsFixed(2) ?? '';
      _linkCtrl.text = item.linkUrl ?? '';
      _notesCtrl.text = item.notes ?? '';
      _category = item.category;
      _priority = item.priority;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _linkCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final actions = ref.read(wishlistActionsProvider);
      final price =
          double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.'));
      final link =
          _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim();
      final notes =
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

      if (widget.item == null) {
        await actions.addItem(
          connectionId: widget.connectionId,
          title: title,
          category: _category,
          priority: _priority,
          price: price,
          linkUrl: link,
          notes: notes,
        );
      } else {
        await actions.updateItem(
          item: widget.item!,
          title: title,
          category: _category,
          priority: _priority,
          price: price,
          linkUrl: link,
          notes: notes,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.item != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 20),

            Text(
              isEdit ? 'Edit item' : 'Add to list',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),

            // Title
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'What do you want?',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // Category
            Text(
              'Category',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _CategoryPicker(
              selected: _category,
              onChanged: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 20),

            // Priority
            Text(
              'Priority',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _PriorityPicker(
              selected: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
            const SizedBox(height: 20),

            // Price
            TextField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Price (optional)',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
            ),
            const SizedBox(height: 12),

            // Link
            TextField(
              controller: _linkCtrl,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Link (optional)',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 12),

            // Notes
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(isEdit ? 'Save changes' : 'Add to list'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category picker ───────────────────────────────────────────────────────────

class _CategoryPicker extends StatelessWidget {
  final ItemCategory selected;
  final ValueChanged<ItemCategory> onChanged;

  const _CategoryPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ItemCategory.values.map((cat) {
        return ChoiceChip(
          avatar: Icon(_icon(cat), size: 15),
          label: Text(cat.label),
          selected: cat == selected,
          onSelected: (_) => onChanged(cat),
        );
      }).toList(),
    );
  }

  IconData _icon(ItemCategory cat) {
    switch (cat) {
      case ItemCategory.product:
        return Icons.shopping_bag_outlined;
      case ItemCategory.place:
        return Icons.place_outlined;
      case ItemCategory.movie:
        return Icons.movie_outlined;
      case ItemCategory.experience:
        return Icons.auto_awesome_outlined;
    }
  }
}

// ── Priority picker ───────────────────────────────────────────────────────────

class _PriorityPicker extends StatelessWidget {
  final ItemPriority selected;
  final ValueChanged<ItemPriority> onChanged;

  const _PriorityPicker({required this.selected, required this.onChanged});

  static const _labels = ['Low', 'Medium', 'High'];
  static const _colors = [Colors.grey, Colors.orange, Color(0xFFEF4444)];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(ItemPriority.values.length, (i) {
        final p = ItemPriority.values[i];
        final isSelected = p == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(_labels[i]),
            selected: isSelected,
            selectedColor: (_colors[i] as Color).withValues(alpha: 0.2),
            onSelected: (_) => onChanged(p),
          ),
        );
      }),
    );
  }
}

// ── Item detail sheet (read-only, for non-owners) ────────────────────────────

class _ItemDetailSheet extends StatelessWidget {
  final WishlistItem item;
  const _ItemDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

          // Category + Priority row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _categoryColor(item.category).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_categoryIcon(item.category),
                        color: _categoryColor(item.category), size: 15),
                    const SizedBox(width: 5),
                    Text(
                      item.category.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _categoryColor(item.category),
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
          const SizedBox(height: 16),

          // Title
          Text(
            item.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),

          // Price
          if (item.price != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.attach_money_rounded,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                Text(
                  item.price!.toStringAsFixed(2),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],

          // Link
          if (item.linkUrl != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.link_rounded,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.linkUrl!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.brightPurple,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: theme.colorScheme.onSurfaceVariant,
                  tooltip: 'Copy link',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.linkUrl!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied')),
                    );
                  },
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(ItemCategory cat) {
    switch (cat) {
      case ItemCategory.product: return Icons.shopping_bag_outlined;
      case ItemCategory.place: return Icons.place_outlined;
      case ItemCategory.movie: return Icons.movie_outlined;
      case ItemCategory.experience: return Icons.auto_awesome_outlined;
    }
  }

  Color _categoryColor(ItemCategory cat) {
    switch (cat) {
      case ItemCategory.product: return AppTheme.brightPurple;
      case ItemCategory.place: return const Color(0xFF16A34A);
      case ItemCategory.movie: return const Color(0xFFEA580C);
      case ItemCategory.experience: return const Color(0xFF0EA5E9);
    }
  }

  Color _priorityColor(ItemPriority p) {
    switch (p) {
      case ItemPriority.low: return Colors.grey;
      case ItemPriority.medium: return Colors.orange;
      case ItemPriority.high: return const Color(0xFFEF4444);
    }
  }

  String _priorityLabel(ItemPriority p) {
    switch (p) {
      case ItemPriority.low: return 'Low priority';
      case ItemPriority.medium: return 'Medium priority';
      case ItemPriority.high: return 'High priority';
    }
  }
}

// ── Invite code bottom sheet (shown inline, avoids GoRouter conflicts) ────────

class _InviteCodeSheet extends StatefulWidget {
  final String code;
  final String connectionName;

  const _InviteCodeSheet({required this.code, required this.connectionName});

  @override
  State<_InviteCodeSheet> createState() => _InviteCodeSheetState();
}

class _InviteCodeSheetState extends State<_InviteCodeSheet> {
  bool _copied = false;

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.brightPurple.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.brightPurple.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.vpn_key_rounded,
                color: AppTheme.brightPurple, size: 28),
          ),
          const SizedBox(height: 16),

          Text(
            'Invite to "${widget.connectionName}"',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Share this code — single use, expires in 48 hours.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Digit boxes
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkSurfaceElevated
                  : AppTheme.lightSurfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.brightPurple.withValues(alpha: 0.3),
                  width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: widget.code.split('').map((digit) {
                return Container(
                  width: 36,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color:
                            AppTheme.brightPurple.withValues(alpha: 0.5)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    digit,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFF5F0FF)
                          : AppTheme.deeperPurple,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _copyCode,
            icon: Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 18,
            ),
            label: Text(_copied ? 'Copied!' : 'Copy code'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _copied ? const Color(0xFF16A34A) : null,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
