import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../data/providers/music_provider.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  final String playlistId;
  final String playlistName;

  const PlaylistDetailsScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  State<PlaylistDetailsScreen> createState() => _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends State<PlaylistDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final musicProvider = context.read<MusicProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.playlistName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // On écoute les changements en temps réel sur la table
        stream: Supabase.instance.client
            .from('playlist_tracks')
            .stream(primaryKey: ['id'])
            .eq('playlist_id', widget.playlistId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
          }
          
          final tracks = snapshot.data ?? [];

          if (tracks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_off, color: Colors.grey, size: 64),
                  SizedBox(height: 16),
                  Text("Cette playlist est vide", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: tracks.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemBuilder: (context, index) {
              final track = tracks[index];
              final String trackId = track['track_id'].toString();

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: track['image_url'] != null
                      ? Image.network(
                          track['image_url'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white),
                        )
                      : const Icon(Icons.music_note, color: Colors.white),
                ),
                title: Text(
                  track['title'] ?? 'Titre inconnu',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  track['artist'] ?? 'Artiste inconnu',
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  onPressed: () async {
                    // 1. Appel de la suppression
                    await musicProvider.removeFromPlaylist(widget.playlistId, trackId);
                    
                    // 2. On force le rafraîchissement local pour l'UI
                    if (mounted) {
                      setState(() {}); 
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Musique retirée"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}