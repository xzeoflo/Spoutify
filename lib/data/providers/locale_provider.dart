import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr');

  Locale get locale => _locale;

  // Définit la langue localement et notifie l'app
  void setLocale(Locale locale) {
    if (!['en', 'fr'].contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners(); 
  }

  // Charge la langue depuis la base de données Supabase au démarrage
  Future<void> loadUserLanguage() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('language')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && data['language'] != null) {
        _locale = Locale(data['language']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erreur chargement langue : $e");
    }
  }
}