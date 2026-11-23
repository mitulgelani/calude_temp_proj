import 'package:flutter/material.dart';

import 'config.dart';

/// A "how to grab it" recipe for one content type of one app.
class KindGuide {
  const KindGuide(this.name, this.steps, {this.usernameMode = false, this.note});
  final String name;
  final List<String> steps;
  final bool usernameMode; // e.g. Instagram profile photo: type @username instead of a link
  final String? note;
}

/// Every app Pluck can save from. Brand colours are only used once a link is detected,
/// and monograms (not official logos) keep the app clear of trademark complaints.
enum Source {
  instagram('Instagram', 'IG', Color(0xFFFF4F8B), 'Reels, posts, carousels and full-size profile photos. No login.'),
  youtube('YouTube', 'YT', Color(0xFFFF4A3D), 'Videos and Shorts up to 1080p, or just the audio.'),
  tiktok('TikTok', 'TT', Color(0xFF2CF0E8), 'Clean videos without the watermark, plus the sound.'),
  facebook('Facebook', 'FB', Color(0xFF5B8CFF), 'Videos and Reels in HD from public posts.'),
  pinterest('Pinterest', 'PN', Color(0xFFFF3D5A), 'Video pins and full-resolution image pins.'),
  whatsapp('WhatsApp', 'WA', Color(0xFF34E08A), 'Statuses from your contacts — before they vanish.');

  const Source(this.label, this.mono, this.color, this.pitch);
  final String label;
  final String mono;
  final Color color;
  final String pitch;

  static List<Source> get visible =>
      values.where((s) => s != Source.youtube || Config.youtubeEnabled).toList();

  static Source? byName(String? name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return null;
  }

  /// Detects the app from any pasted text: a URL, a share message, or "@username".
  static Source? detect(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    if (RegExp(r'^@[A-Za-z0-9._]{1,30}$').hasMatch(text)) return Source.instagram;
    final uri = Uri.tryParse(LinkParser.normalize(text));
    final host = uri?.host.toLowerCase() ?? '';
    if (host.isEmpty) return null;
    bool any(List<String> hosts) => hosts.any((h) => host == h || host.endsWith('.$h'));
    if (any(['instagram.com', 'instagr.am', 'ig.me'])) return Source.instagram;
    if (any(['youtube.com', 'youtu.be', 'youtube-nocookie.com'])) return Source.youtube;
    if (any(['tiktok.com'])) return Source.tiktok;
    if (any(['facebook.com', 'fb.watch', 'fb.com'])) return Source.facebook;
    if (any(['pinterest.com', 'pin.it']) || host.contains('pinterest.')) return Source.pinterest;
    return null;
  }

  /// Human label for what the link points at — shown live as the user pastes.
  String kindOf(String raw) {
    final t = raw.toLowerCase();
    switch (this) {
      case Source.instagram:
        if (t.startsWith('@')) return 'Profile photo';
        if (t.contains('/reel')) return 'Reel';
        if (t.contains('/stories/')) return 'Story';
        if (t.contains('/p/')) return 'Post';
        if (t.contains('/tv/')) return 'Video';
        return 'Profile photo';
      case Source.youtube:
        return t.contains('/shorts/') ? 'Short' : 'Video';
      case Source.tiktok:
        return t.contains('/photo/') ? 'Photo post' : 'Video';
      case Source.facebook:
        if (t.contains('/reel')) return 'Reel';
        return 'Video';
      case Source.pinterest:
        return 'Pin';
      case Source.whatsapp:
        return 'Status';
    }
  }

  List<KindGuide> get guides {
    switch (this) {
      case Source.instagram:
        return const [
          KindGuide('Reels', ['Open the Reel', 'Tap the paper-plane icon', 'Tap “Copy link” and come back']),
          KindGuide('Posts', ['Open the post or carousel', 'Tap ··· then “Copy link”', 'Every photo and video in it is saved']),
          KindGuide('Stories', ['Open the story', 'Tap ··· then “Copy link”', 'Paste it here'],
              note: 'Instagram only shows stories to logged-in accounts, so Pluck can’t save them without one. Reels, posts and profile photos need no login.'),
          KindGuide('Profile photo', ['Type the username', 'Get the full-size photo, not the tiny circle'], usernameMode: true),
        ];
      case Source.youtube:
        return const [
          KindGuide('Videos', ['Open the video', 'Tap Share then “Copy link”', 'Pick a quality up to 1080p']),
          KindGuide('Shorts', ['Open the Short', 'Tap Share then “Copy link”', 'Saved as a vertical MP4']),
          KindGuide('Audio', ['Copy any video link', 'Choose “Audio” in the formats', 'Saved as M4A']),
        ];
      case Source.tiktok:
        return const [
          KindGuide('Videos', ['Open the video', 'Tap Share then “Copy link”', 'Saved without the watermark when available']),
          KindGuide('Sounds', ['Copy the video link', 'Choose “Audio” in the formats']),
        ];
      case Source.facebook:
        return const [
          KindGuide('Videos', ['Open the video', 'Tap Share then “Copy link”', 'Choose HD or SD']),
          KindGuide('Reels', ['Open the Reel', 'Tap Share then “Copy link”']),
        ];
      case Source.pinterest:
        return const [
          KindGuide('Video pins', ['Open the pin', 'Tap Share then “Copy link”']),
          KindGuide('Image pins', ['Open the pin', 'Tap Share then “Copy link”', 'Saved at original resolution']),
        ];
      case Source.whatsapp:
        return const [
          KindGuide('Statuses', ['Watch the status in WhatsApp first', 'Open the Statuses tab here', 'Tap any status to save it']),
        ];
    }
  }
}

abstract final class LinkParser {
  static final _url = RegExp(r'https?://[^\s<>"]+', caseSensitive: false);

  /// Share sheets send "Check out this reel! https://..." — pull the URL out.
  static String? extract(String text) => _url.firstMatch(text)?.group(0);

  static String normalize(String input) {
    var t = input.trim();
    final found = extract(t);
    if (found != null) return found;
    if (t.startsWith('@')) return 'https://www.instagram.com/${t.substring(1)}/';
    if (!t.contains('://') && t.contains('.')) t = 'https://$t';
    return t;
  }
}
