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
  // On passe le stream en nullable pour le réinitialiser si l'user change
  Stream<List<Map<String, dynamic>>>? _playlistStream;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initStream();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicProvider>().fetchFavorites();
    });

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        if (mounted) {
          final provider = context.read<MusicProvider>();
          provider.favorites = [];
          provider.notifyListeners();
          setState(() => _playlistStream = null);
        }
      } else if (data.event == AuthChangeEvent.signedIn) {
        _initStream();
      }
    });
  }

  // Initialisation du stream avec filtre user_id pour garantir la réactivité
  void _initStream() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _playlistStream = Supabase.instance.client
            .from('playlists')
            .stream(primaryKey: ['id'])
            .eq('user_id', user.id) // Filtrer par utilisateur
            .order('name');
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final TextEditingController playlistController = TextEditingController();
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
        title: Text(loc.newPlaylist, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
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
            child: Text(loc.cancel, style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954)),
            onPressed: () async {
              final name = playlistController.text.trim();
              if (name.isNotEmpty) {
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                  try {
                    await Supabase.instance.client.from('playlists').insert({
                      'user_id': user.id,
                      'name': name,
                    });
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    debugPrint("Erreur création playlist: $e");
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
      // On utilise les couleurs du thème au lieu de Colors.black
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.favoritesTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.iconTheme,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(loc.myPlaylists, 
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color, 
                  fontSize: 20, 
                  fontWeight: FontWeight.bold
                )
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: _playlistStream == null 
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<Map<String, dynamic>>>(
                stream: _playlistStream,
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
                      final playlistId = pl['id'].toString();

                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlaylistDetailsScreen(
                                  playlistId: playlistId,
                                  playlistName: pl['name'],
                                ),
                              ),
                            ),
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                // Couleur de carte adaptée au thème
                                color: isDark ? Colors.grey[900] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.playlist_play, color: Color(0xFF1DB954), size: 60),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      pl['name'],
                                      style: TextStyle(
                                        color: theme.textTheme.bodyLarge?.color, 
                                        fontWeight: FontWeight.bold
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 12,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                              onPressed: () async {
                                await musicProvider.deletePlaylist(playlistId);
                              },
                            ),
                          ),
                        ],
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
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color, 
                  fontSize: 20, 
                  fontWeight: FontWeight.bold
                )
              ),
            ),
          ),
          musicProvider.favorites.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(loc.emptyFavoritesMessage, style: const TextStyle(color: Colors.grey)),
                    ),
                  ),
                )
              : SliverList(
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
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}