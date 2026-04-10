// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get profileTitle => 'Profil';

  @override
  String get languageLabel => 'Langue de l\'application';

  @override
  String get useSpotifyLabel => 'Utiliser mon compte Spotify';

  @override
  String get clientIdLabel => 'Client ID';

  @override
  String get clientSecretLabel => 'Client Secret';

  @override
  String get saveButton => 'Enregistrer les modifications';

  @override
  String get saveSuccessMessage => 'Sauvegardé avec succès !';

  @override
  String get favoritesTitle => 'Mes Favoris';

  @override
  String get emptyFavoritesMessage => 'Rien ici... pour l\'instant ! 🎵';

  @override
  String get themeLight => 'Mode Clair';

  @override
  String get themeDark => 'Mode Sombre';

  @override
  String get logout => 'Déconnexion';

  @override
  String get cancel => 'Annuler';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'Inscription';
}
