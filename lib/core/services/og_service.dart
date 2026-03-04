import 'package:http/http.dart' as http;

class OgResult {
  final String? title;
  final String? imageUrl;
  final String? description;
  final String domain;

  const OgResult({
    this.title,
    this.imageUrl,
    this.description,
    required this.domain,
  });
}

class OgService {
  /// Fetches a URL and extracts OpenGraph / Twitter card metadata.
  /// Returns null on any network or parse error.
  Future<OgResult?> fetch(String rawUrl) async {
    final url = _normalizeUrl(rawUrl);
    if (url == null) return null;

    try {
      final uri = Uri.parse(url);
      final domain = uri.host.replaceFirst('www.', '');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (compatible; DreamTogether/1.0; +https://dreamtogether.app)',
          'Accept': 'text/html',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return OgResult(domain: domain);
      }

      final html = response.body;

      return OgResult(
        title: _extractMeta(html, ['og:title', 'twitter:title']) ??
            _extractTag(html, 'title'),
        imageUrl: _extractMeta(html, ['og:image', 'twitter:image']),
        description: _extractMeta(html, ['og:description', 'twitter:description']),
        domain: domain,
      );
    } catch (_) {
      return null;
    }
  }

  String? _normalizeUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return 'https://$trimmed';
    }
    return trimmed;
  }

  /// Extracts content from <meta property="..." content="..."> or
  /// <meta name="..." content="..."> for any of the given property names.
  String? _extractMeta(String html, List<String> properties) {
    for (final prop in properties) {
      // property="..."
      final regexes = [
        RegExp(
          'property=["\']$prop["\'][^>]+content=["\']([^"\']+)["\']',
          caseSensitive: false,
        ),
        RegExp(
          'content=["\']([^"\']+)["\'][^>]+property=["\']$prop["\']',
          caseSensitive: false,
        ),
        RegExp(
          'name=["\']$prop["\'][^>]+content=["\']([^"\']+)["\']',
          caseSensitive: false,
        ),
        RegExp(
          'content=["\']([^"\']+)["\'][^>]+name=["\']$prop["\']',
          caseSensitive: false,
        ),
      ];
      for (final re in regexes) {
        final match = re.firstMatch(html);
        if (match != null) {
          final val = match.group(1)?.trim();
          if (val != null && val.isNotEmpty) return _decodeEntities(val);
        }
      }
    }
    return null;
  }

  /// Extracts content of a simple HTML tag like <title>.
  String? _extractTag(String html, String tag) {
    final re = RegExp('<$tag[^>]*>([^<]+)</$tag>', caseSensitive: false);
    final match = re.firstMatch(html);
    return match?.group(1)?.trim();
  }

  String _decodeEntities(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ');
}

/// Extracts just the display domain from a URL string.
String domainFromUrl(String url) {
  try {
    return Uri.parse(url).host.replaceFirst('www.', '');
  } catch (_) {
    return url;
  }
}
