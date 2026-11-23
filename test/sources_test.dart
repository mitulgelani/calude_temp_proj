import 'package:flutter_test/flutter_test.dart';
import 'package:pluck/core/sources.dart';

void main() {
  test('detects every supported app from real-world share text', () {
    expect(Source.detect('Check this out! https://www.instagram.com/reel/C9x/?igsh=abc'), Source.instagram);
    expect(Source.detect('https://youtu.be/dQw4w9WgXcQ'), Source.youtube);
    expect(Source.detect('https://vm.tiktok.com/ZMabc/'), Source.tiktok);
    expect(Source.detect('https://fb.watch/abc/'), Source.facebook);
    expect(Source.detect('https://pin.it/3xyz'), Source.pinterest);
    expect(Source.detect('@natgeo'), Source.instagram);
    expect(Source.detect('https://example.com/video'), isNull);
  });

  test('labels what the link points at', () {
    expect(Source.instagram.kindOf('https://www.instagram.com/stories/user/123/'), 'Story');
    expect(Source.youtube.kindOf('https://youtube.com/shorts/abc'), 'Short');
    expect(LinkParser.normalize('@natgeo'), 'https://www.instagram.com/natgeo/');
  });
}
