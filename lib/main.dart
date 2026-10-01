import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/notif.dart';
import 'data/repo.dart';
import 'screens/analytics_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/finance_screen.dart';

final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi');
  final sp = await SharedPreferences.getInstance();
  themeMode.value = ThemeMode.values[(sp.getInt('theme') ?? 0).clamp(0, 2)];
  try {
    await Notif.init();
    await Notif.rescheduleAll(await Repo.events());
  } catch (_) {}
  runApp(const LifeSyncApp());
}

class LifeSyncApp extends StatelessWidget {
  const LifeSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'LifeSync',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.dark,
        ),
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Shell(),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;
  static const _pages = [CalendarScreen(), FinanceScreen(), AnalyticsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _i, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Lịch'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Tài chính'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Thống kê'),
        ],
      ),
    );
  }
}
