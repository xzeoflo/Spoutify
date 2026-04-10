// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get profileTitle => 'Profile';

  @override
  String get languageLabel => 'App Language';

  @override
  String get useSpotifyLabel => 'Use my Spotify account';

  @override
  String get clientIdLabel => 'Client ID';

  @override
  String get clientSecretLabel => 'Client Secret';

  @override
  String get saveButton => 'Save changes';

  @override
  String get saveSuccessMessage => 'Saved successfully!';

  @override
  String get favoritesTitle => 'My Favorites';

  @override
  String get emptyFavoritesMessage => 'Nothing here... for now! 🎵';

  @override
  String get themeLight => 'Light Mode';

  @override
  String get themeDark => 'Dark Mode';

  @override
  String get logout => 'Logout';

  @override
  String get cancel => 'Cancel';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';
}
