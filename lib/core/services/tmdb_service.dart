import 'dart:convert';
import 'package:http/http.dart' as http;

class TmdbResult {
  final int id;
  final String title;
  final String mediaType; // 'movie' or 'tv'
  final String? posterPath;
  final String? overview;
  final String? year;
  final double? voteAverage;

  const TmdbResult({
    required this.id,
    required this.title,
    required this.mediaType,
    this.posterPath,
    this.overview,
    this.year,
    this.voteAverage,
  });

  /// Full-resolution poster (w500).
  String? get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : null;

  /// Small thumbnail for dropdown suggestions (w92).
  String? get thumbnailUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w92$posterPath' : null;

  factory TmdbResult.fromJson(Map<String, dynamic> json) {
    final mediaType = json['media_type'] as String? ?? 'movie';
    final isMovie = mediaType != 'tv';
    final title = isMovie
        ? (json['title'] as String? ?? json['name'] as String? ?? '')
        : (json['name'] as String? ?? json['title'] as String? ?? '');

    final releaseDate = isMovie
        ? (json['release_date'] as String?)
        : (json['first_air_date'] as String?);
    final year = releaseDate != null && releaseDate.length >= 4
        ? releaseDate.substring(0, 4)
        : null;

    return TmdbResult(
      id: json['id'] as int? ?? 0,
      title: title,
      mediaType: mediaType,
      posterPath: json['poster_path'] as String?,
      overview: (json['overview'] as String?)?.isNotEmpty == true
          ? json['overview'] as String
          : null,
      year: year,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
    );
  }
}

class TmdbService {
  // Get a free API key at: https://www.themoviedb.org/settings/api
  // Then replace the value below with your key.
  static const _apiKey = '8aeb8a3557e2fc9e964a479d760ab362';
  static const _baseUrl = 'https://api.themoviedb.org/3';

  Future<List<TmdbResult>> search(String query) async {
    if (_apiKey == 'YOUR_TMDB_API_KEY') return [];

    final uri = Uri.parse('$_baseUrl/search/multi').replace(
      queryParameters: {
        'api_key': _apiKey,
        'query': query,
        'include_adult': 'false',
        'language': 'en-US',
        'page': '1',
      },
    );

    final response =
        await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (data['results'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .where((r) => r['media_type'] == 'movie' || r['media_type'] == 'tv')
        .where((r) =>
            (r['title'] as String? ?? r['name'] as String? ?? '').isNotEmpty)
        .map(TmdbResult.fromJson)
        .take(8)
        .toList();

    return results;
  }
}
