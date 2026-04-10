import 'track.dart';

class Playlist {
  final String? id;
  final String name;
  final String? userId;
  final List<Track> tracks;

  Playlist({
    this.id,
    required this.name,
    this.userId,
    this.tracks = const [],
  });
}