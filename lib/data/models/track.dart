class Track {
  final String id;
  final String title;
  final String artist;
  final String imageUrl;

  Track({required this.id, required this.title, required this.artist, required this.imageUrl});

  // Mapping depuis l'API Spotify
  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] ?? '',
      title: json['name'] ?? '',
      artist: (json['artists'] as List).map((a) => a['name']).join(', '),
      imageUrl: json['album']['images'].isNotEmpty ? json['album']['images'][0]['url'] : '',
    );
  }

  // Mapping depuis Supabase (les colonnes de ta table 'favorites')
  factory Track.fromSupabase(Map<String, dynamic> map) {
    return Track(
      id: map['track_id'],
      title: map['title'],
      artist: map['artist'],
      imageUrl: map['image_url'],
    );
  }

  Map<String, dynamic> toMap() => {
    'track_id': id,
    'title': title,
    'artist': artist,
    'image_url': imageUrl,
  };
}