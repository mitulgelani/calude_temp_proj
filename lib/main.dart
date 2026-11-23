import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/tokens.dart';
import 'data/downloader.dart';
import 'data/history_repo.dart';
import 'data/native_bridge.dart';
import 'data/web_store.dart';
import 'features/downloads/download_manager.dart';
import 'features/home/link_cubit.dart';
import 'features/library/library_cubit.dart';
import 'features/status/status_cubit.dart';
import 'features/tabs/tabs_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  BrowserTab.script = await rootBundle.loadString('assets/pluck_page.js');
  final prefs = await SharedPreferences.getInstance();
  final bridge = NativeBridge();
  final history = HistoryRepo(prefs);
  final downloader = Downloader(bridge: bridge, history: history, prefs: prefs);
  final webStore = WebStore(prefs);
  final tabs = TabsController(webStore);
  final library = LibraryCubit(history)..load();
  final manager = DownloadManager(downloader, bridge, library.load);

  runApp(MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: prefs),
      RepositoryProvider.value(value: bridge),
      RepositoryProvider.value(value: history),
      RepositoryProvider.value(value: downloader),
      RepositoryProvider.value(value: webStore),
      RepositoryProvider.value(value: tabs),
      RepositoryProvider.value(value: manager),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LinkCubit(bridge)),
        BlocProvider.value(value: library),
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
