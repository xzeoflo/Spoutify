import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Inscription 
  Future<void> signUp(String email, String password) async {
    try {
      await Supabase.instance.client.auth.signOut();
      final AuthResponse res = await _supabase.auth.signUp(
        email: email, 
        password: password
      );
      
      final newUser = res.user;

      // inscription réussie = profil user 
      if (newUser != null) {
        await _supabase.from('profiles').insert({
          'id': newUser.id,
          'language': 'fr', 
          'spotify_connected': false,
        });
      }
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Connexion
  Future<void> signIn(String email, String password) async {
    try {
      await Supabase.instance.client.auth.signOut();
      await _supabase.auth.signInWithPassword(email: email, password: password);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    notifyListeners();
  }
}