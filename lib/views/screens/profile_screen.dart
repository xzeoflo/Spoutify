import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSpotifyConnected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Chargement des donnees supabase
  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _isSpotifyConnected = data['spotify_connected'] ?? false;
        });

        if (data['language'] != null) {
          context.read<LocaleProvider>().setLocale(Locale(data['language']));
        }
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement du profil: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Gestion de la connexion/déconnexion Spotify
  Future<void> _handleSpotifyToggle(bool connect) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      if (connect) {
        print("Ouverture de l'authentification Spotify pour : ${user.email}");
        
        await Supabase.instance.client.from('profiles').update({
          'spotify_connected': true,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);

        setState(() => _isSpotifyConnected = true);
      } else {
        // Déconnexion 
        await Supabase.instance.client.from('profiles').update({
          'spotify_connected': false,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);

        setState(() => _isSpotifyConnected = false);
      }
    } catch (e) {
      debugPrint("Erreur lors de la modification Spotify: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProv = context.watch<LocaleProvider>();
    final user = Supabase.instance.client.auth.currentUser;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.profileTitle),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF1DB954),
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 15),
                Text(
                  user?.email ?? "Utilisateur",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                
                
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      // Sélecteur de langue
                      ListTile(
                        leading: const Icon(Icons.language, color: Colors.blue),
                        title: Text(loc.languageLabel),
                        trailing: DropdownButton<String>(
                          value: localeProv.locale.languageCode,
                          underline: const SizedBox(),
                          onChanged: (String? newLang) async {
                            if (newLang != null) {
                              localeProv.setLocale(Locale(newLang));
                              await Supabase.instance.client.from('profiles').upsert({
                                'id': user!.id,
                                'language': newLang,
                                'updated_at': DateTime.now().toIso8601String(),
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'fr', child: Text("Français 🇫🇷")),
                            DropdownMenuItem(value: 'en', child: Text("English 🇺🇸")),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      //connectivité Spotify
                      SwitchListTile(
                        secondary: Image.network(
                          'https://storage.googleapis.com/pr-newsroom-wp/1/2018/11/Spotify_Logo_RGB_Green.png',
                          height: 20,
                        ),
                        title: Text(loc.useSpotifyLabel),
                        subtitle: Text(
                          _isSpotifyConnected 
                            ? "Compte Spotify lié" 
                            : "Lier mon compte pour mes playlists"
                        ),
                        value: _isSpotifyConnected,
                        activeThumbColor: const Color(0xFF1DB954),
                        onChanged: (val) => _handleSpotifyToggle(val),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),

                // Bouton de déconnexion 
                OutlinedButton.icon(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(loc.logout),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),

                const SizedBox(height: 20),
                
                Text(
                  "Les modifications sont enregistrées automatiquement",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
    );
  }
}