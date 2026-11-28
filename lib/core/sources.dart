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
  twitter('X / Twitter', 'X', Color(0xFFE7E9EA), 'Videos and GIFs from posts, in the best quality available.'),
  vimeo('Vimeo', 'VM', Color(0xFF1AB7EA), 'Public Vimeo videos in HD.'),
  dailymotion('Dailymotion', 'DM', Color(0xFF8C6CFF), 'Dailymotion videos up to 1080p.'),
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
    if (any(['x.com', 'twitter.com'])) return Source.twitter;
    if (any(['vimeo.com'])) return Source.vimeo;
    if (any(['dailymotion.com', 'dai.ly'])) return Source.dailymotion;
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
      case Source.twitter:
      case Source.vimeo:
      case Source.dailymotion:
        return 'Video';
      case Source.whatsapp:
        return 'Status';
    }
  }

  /// Where the in-app browser starts for this app.
  String get home => switch (this) {
        Source.instagram => 'https://www.instagram.com/reels/',
        Source.youtube => 'https://m.youtube.com/',
        Source.tiktok => 'https://www.tiktok.com/',
        Source.facebook => 'https://m.facebook.com/',
        Source.pinterest => 'https://www.pinterest.com/',
        Source.twitter => 'https://x.com/',
        Source.vimeo => 'https://vimeo.com/watch',
        Source.dailymotion => 'https://www.dailymotion.com/',
        Source.whatsapp => 'https://www.whatsapp.com/',
      };

  /// True when the URL points at one specific video/post (not a feed or profile).
  static bool isItem(String url) {
    final u = url.toLowerCase();
    final src = detect(url);
    if (src == null) return false;
    return switch (src) {
      Source.instagram => RegExp(r'/(p|reel|reels|tv)/[a-z0-9_-]{5,}|/stories/[^/]+/\d+').hasMatch(u),
      Source.youtube => u.contains('watch?') || u.contains('/shorts/') || u.contains('youtu.be/'),
      Source.tiktok => u.contains('/video/') || u.contains('/photo/') || u.contains('vm.tiktok') || u.contains('vt.tiktok'),
      Source.facebook => RegExp(r'/(reel|videos|watch|share/[rv])/|fb\.watch|story\.php|/posts/').hasMatch(u),
      Source.pinterest => u.contains('/pin/') || u.contains('pin.it'),
      Source.twitter => u.contains('/status/'),
      Source.vimeo => RegExp(r'vimeo\.com/(\d+|.*/\d+)').hasMatch(u),
      Source.dailymotion => u.contains('/video/') || u.contains('dai.ly'),
      Source.whatsapp => false,
    };
  }

  List<KindGuide> get guides {
    const tap = 'Tap the orange download button';
    switch (this) {
      case Source.instagram:
        return [
          KindGuide('Reels', ['Tap “Open Instagram” below', 'Scroll to the Reel — it starts playing by itself', tap]),
          KindGuide('Posts', ['Open Instagram and find the post', 'Photos and carousels work too', '$tap — pick one or all']),
          KindGuide('Stories', ['Open Instagram and log in (optional, stays on this phone)', 'Open the story you want', tap],
              note: 'Instagram only shows stories to logged-in accounts. Reels, posts and profile photos need no login.'),
          KindGuide('Profile photo', ['Type the username below', 'Get the full-size photo, not the tiny circle'], usernameMode: true),
        ];
      case Source.youtube:
        return [
          KindGuide('Videos', ['Tap “Open YouTube” below', 'Play the video you want', '$tap and pick a quality']),
          KindGuide('Shorts', ['Open YouTube and play a Short', tap]),
          KindGuide('Audio', ['Play any video', tap, 'Choose “Audio” to save just the sound']),
        ];
      case Source.tiktok:
        return [
          KindGuide('Videos', ['Tap “Open TikTok” below', 'Play the video you want', '$tap — saved without watermark']),
          KindGuide('Sounds', ['Play the video', tap, 'Choose “Audio”']),
        ];
      case Source.facebook:
        return [
          KindGuide('Videos', ['Tap “Open Facebook” below', 'Play the video', tap]),
          KindGuide('Reels', ['Open Facebook Reels', 'Scroll to the Reel', tap]),
        ];
      case Source.pinterest:
        return [
          KindGuide('Video pins', ['Tap “Open Pinterest” below', 'Open the pin', tap]),
          KindGuide('Image pins', ['Open the pin', '$tap — full resolution']),
        ];
      case Source.twitter:
        return [KindGuide('Videos', ['Tap “Open X” below', 'Open the post with the video', tap])];
      case Source.vimeo:
        return [KindGuide('Videos', ['Tap “Open Vimeo” below', 'Play the video', '$tap and pick a quality'])];
      case Source.dailymotion:
        return [KindGuide('Videos', ['Tap “Open Dailymotion” below', 'Play the video', '$tap and pick a quality'])];
      case Source.whatsapp:
        return [
          KindGuide('Statuses', ['Watch the status in WhatsApp first', 'Open the status saver', 'Tap any status to save it']),
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
