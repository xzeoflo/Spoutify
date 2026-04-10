import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../data/providers/music_provider.dart';
import '../../l10n/app_localizations.dart'; 

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
    final theme = Theme.of(context); 
    final loc = AppLocalizations.of(context)!; 

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.playlistName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.music_off, color: Colors.grey, size: 64),
                  const SizedBox(height: 16),
                  Text(loc.emptyPlaylist, style: const TextStyle(color: Colors.grey, fontSize: 16)),
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
                          errorBuilder: (_, __, ___) => Icon(Icons.music_note, color: theme.iconTheme.color),
                        )
                      : Icon(Icons.music_note, color: theme.iconTheme.color),
                ),
                title: Text(
                  track['title'] ?? loc.unknownTitle, 
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w500
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  track['artist'] ?? loc.unknownArtist, 
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  onPressed: () async {
                    await musicProvider.removeFromPlaylist(widget.playlistId, trackId);
                    
                    if (mounted) {
                      setState(() {}); 
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.trackRemoved), 
                          duration: const Duration(seconds: 1),
                          backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.black87,
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