import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/theme_provider.dart';
import '../../data/providers/locale_provider.dart';
import '../../data/providers/music_provider.dart'; 
import '../../data/services/spotify_service.dart';
import '../../l10n/app_localizations.dart';
import 'profile_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpotifyService _spotifyService = SpotifyService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<dynamic> _searchResults = [];
  bool _isSpotifyConnected = false;

  @override
  void initState() {
    super.initState();
    _checkSpotifyConnection();
  }

  Future<void> _checkSpotifyConnection() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('spotify_connected')
            .eq('id', user.id)
            .maybeSingle();
        if (mounted && data != null) {
          setState(() => _isSpotifyConnected = data['spotify_connected'] ?? false);
        }
      } catch (e) {
        debugPrint("Erreur lors de la vérification Spotify : $e");
      }
    }
  }

  void _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await _spotifyService.search(query);
      if (mounted) {
        setState(() => _searchResults = results);
      }
    } catch (e) {
      debugPrint("Erreur recherche : $e");
    }
  }

  // --- LOGIQUE AJOUT PLAYLIST AVEC GESTION DOUBLON ---
  void _showAddToPlaylistDialog(BuildContext context, dynamic track) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final List<dynamic> playlists = await Supabase.instance.client
        .from('playlists')
        .select()
        .eq('user_id', user.id);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Ajouter à la playlist", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: playlists.isEmpty 
            ? const Text("Aucune playlist créée", style: TextStyle(color: Colors.grey))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length,
                itemBuilder: (context, i) {
                  return ListTile(
                    leading: const Icon(Icons.playlist_add, color: Color(0xFF1DB954)),
                    title: Text(playlists[i]['name'], style: const TextStyle(color: Colors.white)),
                    onTap: () async {
                      try {
                        await Supabase.instance.client.from('playlist_tracks').insert({
                          'playlist_id': playlists[i]['id'],
                          'track_id': track['id'],
                          'title': track['name'],
                          'artist': track['artists'][0]['name'],
                          'image_url': track['album']['images'].isNotEmpty ? track['album']['images'][0]['url'] : '',
                          'user_id': user.id,
                        });
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Ajouté à ${playlists[i]['name']}"),
                              backgroundColor: Colors.grey[800],
                            )
                          );
                        }
                      } on PostgrestException catch (e) {
                        // Capture de l'erreur de la contrainte UNIQUE (Code 23505)
                        if (e.code == '23505' && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Cette musique est déjà dans la playlist !"),
                              backgroundColor: Colors.redAccent,
                            )
                          );
                        }
                      } catch (e) {
                        debugPrint("Erreur ajout playlist: $e");
                      }
                    },
                  );
                },
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProv = context.watch<ThemeProvider>();
    final localeProv = context.read<LocaleProvider>();
    final musicProv = context.watch<MusicProvider>(); 
    final loc = AppLocalizations.of(context)!;
    final userEmail = auth.currentUser?.email;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        // Logo Spoutify mis à jour
        title: const Text("Spoutify", 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: Colors.white, letterSpacing: -1.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Color(0xFF1DB954)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
          ),
          _buildUserMenu(context, auth, themeProv, localeProv, loc),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              auth.isAuthenticated ? "Bon retour, $userEmail" : "Bienvenue sur Spoutify",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Expanded(
            child: _isSearching ? _buildSearchResultsView(musicProv) : _buildMainHome(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Artistes, titres ou albums",
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: _searchController.text.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch("");
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[900],
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildSearchResultsView(MusicProvider musicProv) {
    if (_searchResults.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final track = _searchResults[index];
        final imageUrl = track['album']['images'].isNotEmpty ? track['album']['images'][0]['url'] : null;
        final isLiked = musicProv.isFavorite(track['id']);

        return ListTile(
          onTap: () => debugPrint("Lecture de : ${track['name']}"),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: imageUrl != null 
              ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
              : Container(width: 50, height: 50, color: Colors.grey[900], child: const Icon(Icons.music_note)),
          ),
          title: Text(track['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          subtitle: Text(track['artists'][0]['name'], style: const TextStyle(color: Colors.grey)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? const Color(0xFF1DB954) : Colors.grey,
                ),
                onPressed: () => musicProv.toggleFavorite(track),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
                onPressed: () => _showAddToPlaylistDialog(context, track),
              ),
            ],
          ),
        );
      },
    );
  }

  // ... (Reste des widgets _buildMainHome, _buildHorizontalSection, etc. identiques)
  Widget _buildMainHome() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHorizontalSection("Conçu pour vous", [
            {'title': 'Daily Mix 1', 'desc': 'Lumi Athena, ODECORE...', 'url': 'https://picsum.photos/seed/mix1/200'},
            {'title': 'Daily Mix 2', 'desc': 'ptasinski, KUTE...', 'url': 'https://picsum.photos/seed/mix2/200'},
            {'title': 'Daily Mix 3', 'desc': 'Anar, KSLV Noh...', 'url': 'https://picsum.photos/seed/mix3/200'},
          ]),
        ],
      ),
    );
  }

  Widget _buildHorizontalSection(String title, List<Map<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text("Tout afficher", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, i) => InkWell(
              onTap: () => debugPrint("Clic sur ${items[i]['title']}"),
              child: Container(
                width: 155,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        items[i]['url']!,
                        height: 150, width: 150, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150, width: 150, color: Colors.grey[850],
                          child: const Icon(Icons.music_note, color: Colors.white54, size: 50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(items[i]['title']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1),
                    Text(items[i]['desc']!, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMenu(BuildContext context, AuthProvider auth, ThemeProvider themeProv, LocaleProvider localeProv, AppLocalizations loc) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.account_circle_outlined, size: 28),
      color: Colors.grey[900],
      onSelected: (value) async {
        if (value == 'theme') themeProv.toggleTheme();
        if (value == 'profile') Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        if (value == 'logout') await auth.signOut();
        if (value == 'login') _showAuthDialog(context, true);
        if (value == 'register') _showAuthDialog(context, false);
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'theme', child: Row(children: [Icon(themeProv.isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.white), const SizedBox(width: 10), Text(themeProv.isDarkMode ? loc.themeLight : loc.themeDark, style: const TextStyle(color: Colors.white))])),
        const PopupMenuDivider(),
        if (auth.isAuthenticated) ...[
          PopupMenuItem(value: 'profile', child: Row(children: [const Icon(Icons.person_outline, color: Colors.white), const SizedBox(width: 10), Text(loc.profileTitle, style: const TextStyle(color: Colors.white))])),
          PopupMenuItem(value: 'logout', child: Row(children: [const Icon(Icons.logout, color: Colors.white), const SizedBox(width: 10), Text(loc.logout, style: const TextStyle(color: Colors.white))])),
        ] else ...[
          PopupMenuItem(value: 'login', child: Text(loc.login, style: const TextStyle(color: Colors.white))),
          PopupMenuItem(value: 'register', child: Text(loc.register, style: const TextStyle(color: Colors.white))),
        ],
      ],
    );
  }

  void _showAuthDialog(BuildContext context, bool isLogin) {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(isLogin ? loc.login : loc.register, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Email", labelStyle: TextStyle(color: Colors.grey))),
            TextField(controller: passController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Mot de passe", labelStyle: TextStyle(color: Colors.grey)), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel, style: const TextStyle(color: Color(0xFF1DB954)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954)),
            onPressed: () async {
              final authProv = context.read<AuthProvider>();
              if (isLogin) {
                await authProv.signIn(emailController.text, passController.text);
              } else {
                await authProv.signUp(emailController.text, passController.text);
              }
              if (mounted) {
                _checkSpotifyConnection();
                Navigator.pop(context);
              }
            },
            child: Text(isLogin ? loc.login : loc.register, style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}