import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/track.dart';

class MusicProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  List<Track> searchResults = [];
  List<Track> favorites = [];
  bool isLoading = false;
  String? _accessToken;

  // --- ÉTAT ---
  
  bool isFavorite(String trackId) {
    return favorites.any((t) => t.id == trackId);
  }

  // --- LOGIQUE SPOTIFY ---
  
  Future<void> _getSpotifyToken() async {
    const clientId = 'TON_CLIENT_ID';
    const clientSecret = 'TON_CLIENT_SECRET';

    try {
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: {'grant_type': 'client_credentials'},
      );

      if (response.statusCode == 200) {
        _accessToken = jsonDecode(response.body)['access_token'];
      }
    } catch (e) {
      debugPrint("Erreur Token Spotify: $e");
    }
  }

  Future<void> searchTracks(String query) async {
    if (query.isEmpty) return;
    isLoading = true;
    notifyListeners();

    try {
      if (_accessToken == null) await _getSpotifyToken();

      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/search?q=$query&type=track'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        searchResults = (data['tracks']['items'] as List)
            .map((i) => Track.fromJson(i.cast<String, dynamic>()))
            .toList();
      }
    } catch (e) {
      debugPrint("Erreur Spotify Search: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- LOGIQUE FAVORIS (Supabase) ---

  Future<void> fetchFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase.from('favorites').select().eq('user_id', user.id);
      favorites = (data as List).map((f) => Track.fromSupabase(f)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Erreur Supabase Fetch: $e");
    }
  }

  Future<void> toggleFavorite(dynamic trackData) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    Track track = (trackData is Map) 
        ? Track.fromJson(trackData.cast<String, dynamic>()) 
        : trackData;

    final isFav = isFavorite(track.id);

    try {
      if (isFav) {
        await _supabase.from('favorites').delete().eq('track_id', track.id).eq('user_id', user.id);
        favorites.removeWhere((t) => t.id == track.id);
      } else {
        await _supabase.from('favorites').insert({
          'track_id': track.id,
          'title': track.title,
          'artist': track.artist,
          'image_url': track.imageUrl,
          'user_id': user.id,
        });
        favorites.add(track);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Erreur Supabase Toggle: $e");
    }
  }

  // --- LOGIQUE PLAYLISTS (Supabase) ---

  Future<void> addToPlaylist(String playlistId, Track track) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) throw 'Veuillez vous connecter';

    try {
      // On tente l'insertion directe
      await _supabase.from('playlist_tracks').insert({
        'playlist_id': playlistId,
        'track_id': track.id,
        'title': track.title,
        'artist': track.artist,
        'image_url': track.imageUrl,
        'user_id': authUser.id, 
      });
      
      debugPrint("Titre ajouté avec succès !");
    } on PostgrestException catch (e) {
      // Détection de la contrainte UNIQUE (Code 23505 sur Postgres)
      if (e.code == '23505') {
        throw 'Cette musique est déjà dans la playlist !';
      } else {
        throw 'Erreur lors de l\'ajout : ${e.message}';
      }
    } catch (e) {
      throw 'Une erreur imprévue est survenue';
    }
  }

  Future<void> removeFromPlaylist(String playlistId, String trackId) async {
    try {
      await _supabase
          .from('playlist_tracks')
          .delete()
          .eq('playlist_id', playlistId)
          .eq('track_id', trackId);
      
      notifyListeners();
    } catch (e) {
      debugPrint("Erreur suppression musique : $e");
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _supabase.from('playlists').delete().eq('id', playlistId);
      notifyListeners();
    } catch (e) {
      debugPrint("Erreur suppression playlist : $e");
    }
  }
}