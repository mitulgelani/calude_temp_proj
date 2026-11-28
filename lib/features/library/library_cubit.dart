import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/sources.dart';
import '../../data/history_repo.dart';
import '../../data/models.dart';

enum KindFilter { all, video, image, audio }

class LibraryState extends Equatable {
  const LibraryState({this.records = const [], this.kind = KindFilter.all, this.source});
  final List<DownloadRecord> records;
  final KindFilter kind;
  final Source? source;

  List<DownloadRecord> get visible => records.where((r) {
        if (source != null && r.source != source) return false;
        return switch (kind) {
          KindFilter.all => true,
          KindFilter.video => r.kind == 'video',
          KindFilter.image => r.kind == 'image',
          KindFilter.audio => r.kind == 'audio',
        };
      }).toList();

  int get totalBytes => records.fold(0, (a, r) => a + (r.bytes ?? 0));

  LibraryState copyWith({List<DownloadRecord>? records, KindFilter? kind, Source? source, bool clearSource = false}) =>
      LibraryState(
        records: records ?? this.records,
        kind: kind ?? this.kind,
        source: clearSource ? null : (source ?? this.source),
      );

  @override
  List<Object?> get props => [records, kind, source];
}

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._repo) : super(LibraryState());
  final HistoryRepo _repo;

  void load() => emit(state.copyWith(records: _repo.all()));
  void setKind(KindFilter k) => emit(state.copyWith(kind: k));
  void setSource(Source? s) => emit(s == null || s == state.source ? state.copyWith(clearSource: true) : state.copyWith(source: s));

  Future<void> remove(DownloadRecord r) async {
    await _repo.remove(r);
    load();
  }

  Future<void> clear() async {
    await _repo.clear();
    load();
  }
}
