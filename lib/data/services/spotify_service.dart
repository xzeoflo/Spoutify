import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';

class SpotifyService {
  String? _accessToken;

  // Récupère un token d'accès temporaire via Client ID et Secret
  Future<void> _authenticate() async {
    final authStr = base64Encode(utf8.encode('${AppConstants.spotifyClientId}:${AppConstants.spotifyClientSecret}'));
    
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization': 'Basic $authStr',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials'},
    );

    if (response.statusCode == 200) {
      _accessToken = json.decode(response.body)['access_token'];
    }
  }

  // Recherche des titres ou artistes
  Future<List<dynamic>> search(String query) async {
    if (_accessToken == null) await _authenticate();

    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/search?q=$query&type=track&limit=10'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['tracks']['items'];
    }
    return [];
  }
}