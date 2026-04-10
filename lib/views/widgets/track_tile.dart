import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/track.dart';
import '../../data/providers/music_provider.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  const TrackTile({super.key, required this.track});

  // Fonction pour afficher le sélecteur de playlist
  void _showPlaylistSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client.from('playlists').stream(primaryKey: ['id']),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final playlists = snapshot.data!;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Ajouter à la playlist", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final pl = playlists[index];
                      return ListTile(
                        leading: const Icon(Icons.playlist_add, color: Colors.white),
                        title: Text(pl['name'], style: const TextStyle(color: Colors.white)),
                        onTap: () async {
                          try {
                            // Appel au provider pour l'insertion
                            await context.read<MusicProvider>().addToPlaylist(pl['id'].toString(), track);
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Ajouté à ${pl['name']}"),
                                  backgroundColor: Colors.grey[800],
                                ),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            // Gestion de l'erreur (Doublon bloqué par la contrainte SQL)
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
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
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          errorBuilder: (_, __, ___) => Container(color: Colors.grey, width: 50, height: 50),
        ),
      ),
      title: Text(track.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(track.artist, style: const TextStyle(color: Colors.grey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton Favoris
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: const Color(0xFF1DB954)),
            onPressed: () => provider.toggleFavorite(track),
          ),
          // Bouton Ajouter à une playlist (Popup)
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () => _showPlaylistSelector(context),
          ),
        ],
      ),
    );
  }
}