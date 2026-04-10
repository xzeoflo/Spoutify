import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseKey => dotenv.env['SUPABASE_ANNON_KEY'] ?? '';

  static const String spotifyAuthUrl = 'https://accounts.spotify.com/authorize';
  static const String spotifyTokenUrl = 'https://accounts.spotify.com/api/token';
  static const String spotifyApiBaseUrl = 'https://api.spotify.com/v1';
  
  static String get spotifyClientId => dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  static String get spotifyClientSecret => dotenv.env['SPOTIFY_CLIENT_SECRET'] ?? '';
}