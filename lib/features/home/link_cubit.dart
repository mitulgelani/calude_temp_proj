import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config.dart';
import '../../core/sources.dart';
import '../../data/models.dart';
import '../../data/native_bridge.dart';

enum LinkPhase { idle, resolving, error }

class LinkState extends Equatable {
  const LinkState({this.input = '', this.source, this.kind, this.phase = LinkPhase.idle, this.error, this.autoToken = 0});
  final String input;
  final Source? source;
  final String? kind;
  final LinkPhase phase;
  final String? error;

  /// Bumped when a link arrives from the share sheet and should be resolved right away.
  final int autoToken;

  bool get resolving => phase == LinkPhase.resolving;

  @override
  List<Object?> get props => [input, source, kind, phase, error, autoToken];
}

class LinkCubit extends Cubit<LinkState> {
  LinkCubit(this._bridge) : super(const LinkState());
  final NativeBridge _bridge;

  void setInput(String raw, {bool auto = false}) {
    final found = LinkParser.extract(raw);
    final value = found ?? raw.trim();
    final src = Source.detect(value);
    emit(LinkState(
      input: value,
      source: src,
      kind: src?.kindOf(value),
      autoToken: auto ? state.autoToken + 1 : state.autoToken,
    ));
  }

  void clear() => emit(LinkState(autoToken: state.autoToken));

  /// Returns the media info, or null (with a friendly error in state).
  Future<MediaInfo?> resolve([String? raw]) async {
    final input = (raw ?? state.input).trim();
    if (raw != null && raw != state.input) setInput(raw);
    if (input.isEmpty) return _fail('Paste a link first.');
    final src = Source.detect(input);
    if (src == null) return _fail('That link isn’t from Instagram, TikTok, YouTube, Facebook or Pinterest.');
    if (src == Source.youtube && !Config.youtubeEnabled) return _fail('YouTube saving isn’t available in this version.');

    emit(LinkState(input: state.input, source: src, kind: src.kindOf(input), phase: LinkPhase.resolving, autoToken: state.autoToken));
    try {
      final info = await _bridge.resolve(LinkParser.normalize(input));
      if (info.items.isEmpty) return _fail('Nothing downloadable found in that link.');
      emit(LinkState(input: state.input, source: src, kind: info.kindLabel, autoToken: state.autoToken));
      return info;
    } on PluckException catch (e) {
      return _fail(e.message);
    }
  }

  MediaInfo? _fail(String message) {
    emit(LinkState(
      input: state.input,
      source: state.source,
      kind: state.kind,
      phase: LinkPhase.error,
      error: message,
      autoToken: state.autoToken,
    ));
    return null;
  }
}
