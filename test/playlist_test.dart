import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spoutify/data/providers/music_provider.dart';
import 'package:spoutify/data/models/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});

    await Supabase.initialize(
      url: 'https://placeholder.supabase.co',
      anonKey: 'placeholder-key',
    );
  });

  group('MusicProvider - Playlist Tests', () {
    test('addToPlaylist doit lancer une erreur si l\'utilisateur n\'est pas connecté', () async {
      final provider = MusicProvider(); 
      final track = Track(id: '1', title: 'Test', artist: 'Artist', imageUrl: '');

      expect(
        () => provider.addToPlaylist('playlist_123', track),
        throwsA('Veuillez vous connecter'),
      );
    });

    test('removeFromPlaylist ne doit pas planter', () async {
      final provider = MusicProvider();
      
      await provider.removeFromPlaylist('playlist_id', 'track_id');
      
      expect(true, true); 
    });
  });
}