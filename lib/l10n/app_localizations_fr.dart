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
  String get saveSuccessMessage => 'Enregistré avec succès !';

  @override
  String get favoritesTitle => 'Mes Favoris';

  @override
  String get emptyFavoritesMessage => 'Rien ici... pour l\'instant ! 🎵';

  @override
  String get themeLight => 'Mode clair';

  @override
  String get themeDark => 'Mode sombre';

  @override
  String get logout => 'Déconnexion';

  @override
  String get cancel => 'Annuler';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'Inscription';

  @override
  String get myPlaylists => 'Mes playlists';

  @override
  String get likedTracks => 'Titres likés';

  @override
  String get noPlaylists => 'Aucune playlist pour le moment';

  @override
  String get newPlaylist => 'Nouvelle playlist';

  @override
  String get playlistNameHint => 'Entrez un nom...';

  @override
  String get createButton => 'Créer';

  @override
  String get emptyPlaylist => 'Cette playlist est vide';

  @override
  String get unknownTitle => 'Titre inconnu';

  @override
  String get unknownArtist => 'Artiste inconnu';

  @override
  String get trackRemoved => 'Titre supprimé';

  @override
  String get addToPlaylist => 'Ajouter à la playlist';

  @override
  String get noPlaylistsCreated => 'Aucune playlist créée';

  @override
  String get addedTo => 'Ajouté à';

  @override
  String get trackAlreadyInPlaylist =>
      'Cette musique est déjà dans la playlist !';

  @override
  String get searchHint => 'Artistes, titres ou albums';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String get welcomeSpoutify => 'Bienvenue sur Spoutify';

  @override
  String get madeForYou => 'Conçu pour vous';

  @override
  String get showAll => 'Tout afficher';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';
}
