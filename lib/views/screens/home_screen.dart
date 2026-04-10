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

  Future<void> _manualReload() async {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchResults = [];
    });
    await _checkSpotifyConnection();
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
    } else {
      if (mounted) setState(() => _isSpotifyConnected = false);
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

  void _showAddToPlaylistDialog(BuildContext context, dynamic track) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    final List<dynamic> playlists = await Supabase.instance.client
        .from('playlists')
        .select()
        .eq('user_id', user.id);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text(loc.addToPlaylist, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: SizedBox(
          width: double.maxFinite,
          child: playlists.isEmpty 
            ? Text(loc.noPlaylistsCreated, style: const TextStyle(color: Colors.grey))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length,
                itemBuilder: (context, i) {
                  return ListTile(
                    leading: const Icon(Icons.playlist_add, color: Color(0xFF1DB954)),
                    title: Text(playlists[i]['name'], style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
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
                              content: Text("${loc.addedTo} ${playlists[i]['name']}"),
                              backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.black87,
                            )
                          );
                        }
                      } on PostgrestException catch (e) {
                        if (e.code == '23505' && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.trackAlreadyInPlaylist),
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
    final theme = Theme.of(context);
    final userEmail = auth.currentUser?.email;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        title: Text("Spoutify", 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: theme.textTheme.bodyLarge?.color, letterSpacing: -1.5)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.iconTheme.color),
            onPressed: _manualReload,
            tooltip: 'Reload',
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: Color(0xFF1DB954)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
          ),
          _buildUserMenu(context, auth, themeProv, localeProv, loc, theme),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(loc, theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              auth.isAuthenticated ? "${loc.welcomeBack}, $userEmail" : loc.welcomeSpoutify,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
          ),
          Expanded(
            child: _isSearching ? _buildSearchResultsView(musicProv, theme) : _buildMainHome(loc, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations loc, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: loc.searchHint,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
          suffixIcon: _searchController.text.isNotEmpty 
              ? IconButton(
                  icon: Icon(Icons.clear, color: theme.iconTheme.color),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch("");
                  },
                )
              : null,
          filled: true,
          fillColor: theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildSearchResultsView(MusicProvider musicProv, ThemeData theme) {
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
              : Container(width: 50, height: 50, color: theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[300], child: Icon(Icons.music_note, color: theme.iconTheme.color)),
          ),
          title: Text(track['name'], style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          subtitle: Text(track['artists'][0]['name'], style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
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

  Widget _buildMainHome(AppLocalizations loc, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _manualReload,
      color: const Color(0xFF1DB954),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHorizontalSection(loc.madeForYou, loc.showAll, [
              {'title': 'Daily Mix 1', 'desc': 'Lumi Athena, ODECORE...', 'url': 'https://picsum.photos/seed/mix1/200'},
              {'title': 'Daily Mix 2', 'desc': 'ptasinski, KUTE...', 'url': 'https://picsum.photos/seed/mix2/200'},
              {'title': 'Daily Mix 3', 'desc': 'Anar, KSLV Noh...', 'url': 'https://picsum.photos/seed/mix3/200'},
            ], theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSection(String title, String showAllText, List<Map<String, String>> items, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
              Text(showAllText, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
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
                          height: 150, width: 150, color: theme.brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[300],
                          child: const Icon(Icons.music_note, color: Colors.grey, size: 50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(items[i]['title']!, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color), maxLines: 1),
                    Text(items[i]['desc']!, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 12), maxLines: 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMenu(BuildContext context, AuthProvider auth, ThemeProvider themeProv, LocaleProvider localeProv, AppLocalizations loc, ThemeData theme) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.account_circle_outlined, size: 28),
      color: theme.popupMenuTheme.color ?? theme.cardColor,
      onSelected: (value) async {
        if (value == 'theme') themeProv.toggleTheme();
        if (value == 'profile') Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        if (value == 'logout') {
          context.read<MusicProvider>().clearFavorites();
          await auth.signOut();
          _manualReload(); 
        }
        if (value == 'login') _showAuthDialog(context, true, loc, theme);
        if (value == 'register') _showAuthDialog(context, false, loc, theme);
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'theme', child: Row(children: [Icon(themeProv.isDarkMode ? Icons.light_mode : Icons.dark_mode, color: theme.iconTheme.color), const SizedBox(width: 10), Text(themeProv.isDarkMode ? loc.themeLight : loc.themeDark, style: TextStyle(color: theme.textTheme.bodyLarge?.color))])),
        const PopupMenuDivider(),
        if (auth.isAuthenticated) ...[
          PopupMenuItem(value: 'profile', child: Row(children: [Icon(Icons.person_outline, color: theme.iconTheme.color), const SizedBox(width: 10), Text(loc.profileTitle, style: TextStyle(color: theme.textTheme.bodyLarge?.color))])),
          PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: theme.iconTheme.color), const SizedBox(width: 10), Text(loc.logout, style: TextStyle(color: theme.textTheme.bodyLarge?.color))])),
        ] else ...[
          PopupMenuItem(value: 'login', child: Text(loc.login, style: TextStyle(color: theme.textTheme.bodyLarge?.color))),
          PopupMenuItem(value: 'register', child: Text(loc.register, style: TextStyle(color: theme.textTheme.bodyLarge?.color))),
        ],
      ],
    );
  }

  void _showAuthDialog(BuildContext context, bool isLogin, AppLocalizations loc, ThemeData theme) {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text(isLogin ? loc.login : loc.register, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailController, style: TextStyle(color: theme.textTheme.bodyLarge?.color), decoration: InputDecoration(labelText: loc.email, labelStyle: const TextStyle(color: Colors.grey))),
            TextField(controller: passController, style: TextStyle(color: theme.textTheme.bodyLarge?.color), decoration: InputDecoration(labelText: loc.password, labelStyle: const TextStyle(color: Colors.grey)), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel, style: const TextStyle(color: Color(0xFF1DB954)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954)),
            onPressed: () async {
              final authProv = context.read<AuthProvider>();
              try {
                if (isLogin) {
                  await authProv.signIn(emailController.text, passController.text);
                } else {
                  await authProv.signUp(emailController.text, passController.text);
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  _manualReload();
                }
              } on AuthApiException catch (e) {
                String errorMsg = e.message;
                if (e.code == 'user_already_exists') {
                  errorMsg = "Cet utilisateur est déjà inscrit.";
                } else if (e.code == 'invalid_credentials') {
                  errorMsg = "Email ou mot de passe incorrect.";
                }

                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Erreur"),
                      content: Text(errorMsg),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("OK", style: TextStyle(color: Color(0xFF1DB954))),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                debugPrint("Erreur auth: $e");
              }
            },
            child: Text(isLogin ? loc.login : loc.register, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}