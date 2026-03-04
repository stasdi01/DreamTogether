import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;

class PlaceResult {
  final String placeId;
  final String name;
  final String? address;
  final double? rating;
  final String? photoUrl;

  const PlaceResult({
    required this.placeId,
    required this.name,
    this.address,
    this.rating,
    this.photoUrl,
  });
}

class PlacesService {
  // Get a key at: https://console.cloud.google.com → APIs → Places API
  // Enable "Places API" (legacy) for the key.
  static const _apiKey = 'AIzaSyB2rwTGK8-mw5afl0zdfbYML9mZ2-h9Y20';
  static const _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Returns up to 5 autocomplete suggestions for the given input.
  Future<List<PlaceResult>> autocomplete(String input) async {
    if (_apiKey == 'YOUR_GOOGLE_PLACES_API_KEY') return [];

    final uri = Uri.parse('$_baseUrl/autocomplete/json').replace(
      queryParameters: {
        'input': input,
        'language': 'en',
        'key': _apiKey,
      },
    );

    final response =
        await http.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) {
      dev.log('Places autocomplete HTTP error: ${response.statusCode}');
      return [];
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String? ?? '';
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      dev.log('Places autocomplete API error: $status — ${data['error_message'] ?? ''}');
      return [];
    }

    final predictions =
        (data['predictions'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return predictions.take(5).map((p) {
      final sf = p['structured_formatting'] as Map<String, dynamic>?;
      return PlaceResult(
        placeId: p['place_id'] as String,
        name: sf?['main_text'] as String? ??
            p['description'] as String? ??
            '',
        address: sf?['secondary_text'] as String?,
      );
    }).toList();
  }

  /// Fetches full details (address, rating, photo) for a place.
  Future<PlaceResult?> details(String placeId, String fallbackName) async {
    if (_apiKey == 'YOUR_GOOGLE_PLACES_API_KEY') return null;

    final uri = Uri.parse('$_baseUrl/details/json').replace(
      queryParameters: {
        'place_id': placeId,
        'fields': 'name,formatted_address,rating,photos',
        'key': _apiKey,
      },
    );

    final response =
        await http.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result = data['result'] as Map<String, dynamic>?;
    if (result == null) return null;

    final photos = result['photos'] as List<dynamic>?;
    final photoRef = photos != null && photos.isNotEmpty
        ? (photos.first as Map<String, dynamic>)['photo_reference'] as String?
        : null;

    final photoUrl = photoRef != null
        ? '$_baseUrl/photo?maxwidth=800&photo_reference=$photoRef&key=$_apiKey'
        : null;

    return PlaceResult(
      placeId: placeId,
      name: result['name'] as String? ?? fallbackName,
      address: result['formatted_address'] as String?,
      rating: (result['rating'] as num?)?.toDouble(),
      photoUrl: photoUrl,
    );
  }
}
