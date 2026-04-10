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

  @override
  String get myPlaylists => 'My Playlists';

  @override
  String get likedTracks => 'Liked Tracks';

  @override
  String get noPlaylists => 'No playlists yet';

  @override
  String get newPlaylist => 'New Playlist';

  @override
  String get playlistNameHint => 'Enter name...';

  @override
  String get createButton => 'Create';

  @override
  String get emptyPlaylist => 'This playlist is empty';

  @override
  String get unknownTitle => 'Unknown title';

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get trackRemoved => 'Track removed';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String get noPlaylistsCreated => 'No playlists created';

  @override
  String get addedTo => 'Added to';

  @override
  String get trackAlreadyInPlaylist => 'This track is already in the playlist!';

  @override
  String get searchHint => 'Artists, songs, or albums';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get welcomeSpoutify => 'Welcome to Spoutify';

  @override
  String get madeForYou => 'Made for you';

  @override
  String get showAll => 'Show all';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';
}
