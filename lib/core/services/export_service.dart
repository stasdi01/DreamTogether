import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/wishlist/models/wishlist_item_model.dart';

/// Groups items by [WishlistItem.userId] so the PDF can render per-member sections.
typedef MemberItems = Map<String, List<WishlistItem>>;

class ExportService {
  /// Generates a PDF for [connectionName] grouped by member display names.
  ///
  /// [memberNames] maps userId → display name.
  /// [memberItems] maps userId → list of their items.
  static Future<Uint8List> generatePdf({
    required String connectionName,
    required Map<String, String> memberNames,
    required MemberItems memberItems,
  }) async {
    final doc = pw.Document();

    // Use built-in PDF font (avoids any asset requirement).
    final baseFont = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();
    final extraBoldFont = await PdfGoogleFonts.nunitoExtraBold();

    final theme = pw.ThemeData(
      defaultTextStyle: pw.TextStyle(font: baseFont, fontSize: 10),
    );

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              connectionName,
              style: pw.TextStyle(font: extraBoldFont, fontSize: 22),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Wishlist export · ${_formatDate(DateTime.now())}',
              style: pw.TextStyle(
                font: baseFont,
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
            pw.Divider(color: PdfColors.grey400, thickness: 0.5),
            pw.SizedBox(height: 4),
          ],
        ),
        build: (_) {
          final widgets = <pw.Widget>[];

          for (final userId in memberItems.keys) {
            final name = memberNames[userId] ?? 'Member';
            final raw = [...(memberItems[userId] ?? [])]
              ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
            final active = raw.where((i) => !i.isGifted).toList();
            final gifted = raw.where((i) => i.isGifted).toList();
            final items = [...active, ...gifted];
            if (items.isEmpty) continue;

            widgets.add(
              pw.Text(
                name,
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
            );
            widgets.add(pw.SizedBox(height: 6));

            for (final item in items) {
              widgets.add(_buildItemRow(item, baseFont, boldFont));
              widgets.add(pw.SizedBox(height: 4));
            }

            widgets.add(pw.SizedBox(height: 14));
          }

          return widgets;
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildItemRow(
    WishlistItem item,
    pw.Font baseFont,
    pw.Font boldFont,
  ) {
    final priceText =
        item.price != null ? '  ·  \$${item.price!.toStringAsFixed(2)}' : '';
    final statusText = item.isGifted
        ? '  ·  Gifted'
        : item.isClaimed
            ? '  ·  Claimed'
            : '';

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  item.title,
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
                if (item.notes != null && item.notes!.isNotEmpty)
                  pw.Text(
                    item.notes!,
                    style: pw.TextStyle(
                      font: baseFont,
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                if (item.linkUrl != null && item.linkUrl!.isNotEmpty)
                  pw.Text(
                    item.linkUrl!,
                    style: pw.TextStyle(
                      font: baseFont,
                      fontSize: 8,
                      color: PdfColors.blue,
                    ),
                  ),
              ],
            ),
          ),
          pw.Text(
            '${_categoryLabel(item.category)}$priceText$statusText',
            style: pw.TextStyle(
              font: baseFont,
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  static String _categoryLabel(ItemCategory cat) {
    switch (cat) {
      case ItemCategory.product:
        return 'Product';
      case ItemCategory.place:
        return 'Place';
      case ItemCategory.movie:
        return 'Movie';
      case ItemCategory.experience:
        return 'Experience';
    }
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Returns a CSV string for the connection.
  static String generateCsv({
    required Map<String, String> memberNames,
    required MemberItems memberItems,
  }) {
    final buf = StringBuffer();
    buf.writeln('Member,Title,Category,Priority,Price,Notes,Link,Status');

    for (final userId in memberItems.keys) {
      final name = _csvEscape(memberNames[userId] ?? 'Member');
      final raw = [...(memberItems[userId] ?? [])]
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      final items = [
        ...raw.where((i) => !i.isGifted),
        ...raw.where((i) => i.isGifted),
      ];
      for (final item in items) {
        final status = item.isGifted
            ? 'Gifted'
            : item.isClaimed
                ? 'Claimed'
                : 'Open';
        buf.writeln([
          name,
          _csvEscape(item.title),
          item.category.label,
          item.priority.name,
          item.price?.toStringAsFixed(2) ?? '',
          _csvEscape(item.notes ?? ''),
          _csvEscape(item.linkUrl ?? ''),
          status,
        ].join(','));
      }
    }

    return buf.toString();
  }

  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
