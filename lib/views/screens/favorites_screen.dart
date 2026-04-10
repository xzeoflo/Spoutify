import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/providers/music_provider.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/track_tile.dart';
import 'playlist_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  Future<List<Map<String, dynamic>>>? _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _refreshPlaylists();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicProvider>().fetchFavorites();
    });
  }

  void _refreshPlaylists() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _playlistsFuture = Supabase.instance.client
            .from('playlists')
            .select()
            .eq('user_id', user.id)
            .order('name');
      });
    }
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final TextEditingController playlistController = TextEditingController();
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text(loc.newPlaylist, style: TextStyle(color: theme.textTheme.titleLarge?.color)),
        content: TextField(
          controller: playlistController,
          autofocus: true,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: loc.playlistNameHint,
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1DB954))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel, style: TextStyle(color: theme.colorScheme.primary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954)),
            onPressed: () async {
              final name = playlistController.text.trim();
              if (name.isNotEmpty) {
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                  await Supabase.instance.client.from('playlists').insert({'user_id': user.id, 'name': name});
                  if (context.mounted) {
                    Navigator.pop(context);
                    _refreshPlaylists(); 
                  }
                }
              }
            },
            child: Text(loc.createButton, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.favoritesTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(loc.myPlaylists, 
                style: TextStyle(color: theme.textTheme.headlineSmall?.color, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _playlistsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
                  }
                  final playlists = snapshot.data ?? [];
                  if (playlists.isEmpty) {
                    return Center(child: Text(loc.noPlaylists, style: const TextStyle(color: Colors.grey)));
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final pl = playlists[index];
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: 1.2),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => PlaylistDetailsScreen(playlistId: pl['id'].toString(), playlistName: pl['name']),
                          )),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.playlist_play, color: Color(0xFF1DB954), size: 50),
                                    const SizedBox(height: 8),
                                    Text(pl['name'], style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 4, right: 4,
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () async {
                                    await musicProvider.deletePlaylist(pl['id'].toString());
                                    _refreshPlaylists();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: Text(loc.likedTracks, 
                style: TextStyle(color: theme.textTheme.headlineSmall?.color, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => TrackTile(track: musicProvider.favorites[index]),
              childCount: musicProvider.favorites.length,
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1DB954),
        onPressed: () => _showCreatePlaylistDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}