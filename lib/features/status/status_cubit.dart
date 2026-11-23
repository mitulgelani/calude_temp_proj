import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models.dart';
import '../../data/native_bridge.dart';

enum StatusVariant { whatsapp, business }

enum StatusPhase { checking, needsAccess, loading, ready, error }

class StatusState extends Equatable {
  const StatusState({this.variant = StatusVariant.whatsapp, this.phase = StatusPhase.checking, this.items = const [], this.error, this.videosOnly});
  final StatusVariant variant;
  final StatusPhase phase;
  final List<StatusItem> items;
  final String? error;
  final bool? videosOnly; // null = all, true = videos, false = photos

  List<StatusItem> get visible => videosOnly == null ? items : items.where((i) => i.isVideo == videosOnly).toList();

  StatusState copyWith({StatusVariant? variant, StatusPhase? phase, List<StatusItem>? items, String? error, bool? videosOnly, bool resetFilter = false}) =>
      StatusState(
        variant: variant ?? this.variant,
        phase: phase ?? this.phase,
        items: items ?? this.items,
        error: error,
        videosOnly: resetFilter ? null : (videosOnly ?? this.videosOnly),
      );

  @override
  List<Object?> get props => [variant, phase, items, error, videosOnly];
}

class StatusCubit extends Cubit<StatusState> {
  StatusCubit(this._bridge, this._prefs) : super(const StatusState());
  final NativeBridge _bridge;
  final SharedPreferences _prefs;

  String get _key => 'status_tree_${state.variant.name}';

  Future<void> load() async {
    if (!_bridge.supported) {
      emit(state.copyWith(phase: StatusPhase.error, error: 'Status saving works on Android only.'));
      return;
    }
    final tree = _prefs.getString(_key);
    if (tree == null) {
      emit(state.copyWith(phase: StatusPhase.needsAccess, items: const []));
      return;
    }
    if (state.items.isEmpty) emit(state.copyWith(phase: StatusPhase.loading));
    try {
      final items = await _bridge.listStatuses(tree);
      items.sort((a, b) => b.modified.compareTo(a.modified));
      emit(state.copyWith(phase: StatusPhase.ready, items: items));
    } on PlatformException {
      await _prefs.remove(_key); // permission revoked or folder moved
      emit(state.copyWith(phase: StatusPhase.needsAccess, items: const []));
    }
  }

  Future<void> grant() async {
    try {
      final tree = await _bridge.pickStatusTree(state.variant.name);
      if (tree == null) return;
      await _prefs.setString(_key, tree);
      await load();
    } on PluckException catch (e) {
      emit(state.copyWith(phase: StatusPhase.error, error: e.message));
    }
  }

  Future<void> setVariant(StatusVariant v) async {
    if (v == state.variant) return;
    emit(StatusState(variant: v));
    await load();
  }

  void setFilter(bool? videosOnly) =>
      emit(videosOnly == null ? state.copyWith(resetFilter: true) : state.copyWith(videosOnly: videosOnly));
}
