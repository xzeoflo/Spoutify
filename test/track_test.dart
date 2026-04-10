import 'package:flutter_test/flutter_test.dart';
import 'package:spoutify/data/models/track.dart';

void main() {
  group('Track Model Tests', () {
    test('doit créer une instance Track valide à partir d\'un JSON Spotify', () {
      final json = {
        'id': '4cOdK2wGqykiM0vU0qR0bd',
        'name': 'Hells Bells',
        'artists': [
          {'name': 'AC/DC'}
        ],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b273'}
          ]
        }
      };

      final track = Track.fromJson(json);

      expect(track.id, '4cOdK2wGqykiM0vU0qR0bd');
      expect(track.title, 'Hells Bells');
      expect(track.artist, 'AC/DC');
      expect(track.imageUrl, 'https://i.scdn.co/image/ab67616d0000b273');
    });

    test('doit gérer les JSON de Supabase (fromSupabase)', () {
      final supabaseData = {
        'track_id': '123',
        'title': 'Test Title',
        'artist': 'Test Artist',
        'image_url': 'http://image.com'
      };

      final track = Track.fromSupabase(supabaseData);

      expect(track.id, '123');
      expect(track.title, 'Test Title');
      expect(track.imageUrl, 'http://image.com');
    });
  });
}