import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/tokens.dart';
import 'data/downloader.dart';
import 'data/history_repo.dart';
import 'data/native_bridge.dart';
import 'features/home/link_cubit.dart';
import 'features/library/library_cubit.dart';
import 'features/status/status_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  final bridge = NativeBridge();
  final history = HistoryRepo(prefs);
  final downloader = Downloader(bridge: bridge, history: history, prefs: prefs);

  runApp(MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: prefs),
      RepositoryProvider.value(value: bridge),
      RepositoryProvider.value(value: history),
      RepositoryProvider.value(value: downloader),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LinkCubit(bridge)),
        BlocProvider(create: (_) => LibraryCubit(history)..load()),
        BlocProvider(create: (_) => StatusCubit(bridge, prefs)),
      ],
      child: MaterialApp(
        title: 'Pluck',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const Shell(),
      ),
    ),
  ));
}
