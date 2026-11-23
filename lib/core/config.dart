/// Build-time configuration. Everything runs on the device — no server, no API keys.
///   flutter build appbundle --dart-define=PLUCK_YOUTUBE=false   (Google Play build)
abstract final class Config {
  /// Google Play rejects YouTube downloaders. Ship Play builds with this set to false.
  static const youtubeEnabled = bool.fromEnvironment('PLUCK_YOUTUBE', defaultValue: true);

  /// Free self-update for the extraction engine (yt-dlp's official pure-Python release on GitHub).
  static const engineUpdateUrl = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp';

  static const albumName = 'Pluck';
  static const version = '1.0.0';
}
