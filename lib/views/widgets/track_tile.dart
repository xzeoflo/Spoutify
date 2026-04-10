import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/track.dart';
import '../../data/providers/music_provider.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  const TrackTile({super.key, required this.track});

  // affichage du sélecteur de playlist
  void _showPlaylistSelector(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey[900] : theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client.from('playlists').stream(primaryKey: ['id']),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
            final playlists = snapshot.data!;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Ajouter à la playlist",
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (playlists.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text("Aucune playlist créée", style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                  ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final pl = playlists[index];
                      return ListTile(
                        leading: Icon(Icons.playlist_add, color: theme.iconTheme.color),
                        title: Text(
                          pl['name'],
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                        ),
                        onTap: () async {
                          try {
                            await context.read<MusicProvider>().addToPlaylist(pl['id'].toString(), track);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Ajouté à ${pl['name']}"),
                                  backgroundColor: isDark ? Colors.grey[800] : Colors.black87,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Déjà dans la playlist"),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<MusicProvider>();
    final isFav = context.watch<MusicProvider>().favorites.any((t) => t.id == track.id);

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          track.imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[300],
            width: 50,
            height: 50,
            child: const Icon(Icons.music_note, color: Colors.grey),
          ),
        ),
      ),
      // Couleur du titre
      title: Text(
        track.title,
        style: TextStyle(
          color: theme.textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Couleur du sous-titre
      subtitle: Text(
        track.artist,
        style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton Favoris
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: const Color(0xFF1DB954),
            ),
            onPressed: () => provider.toggleFavorite(track),
          ),
          // Bouton Ajouter à une playlist 
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: theme.iconTheme.color),
            onPressed: () => _showPlaylistSelector(context),
          ),
        ],
      ),
    );
  }
}