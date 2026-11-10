import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'screens/home.dart';
import 'screens/import.dart';
import 'screens/preview.dart';
import 'screens/results.dart';
import 'screens/study.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = RecallState();
  await state.load();
  runApp(ChangeNotifierProvider.value(value: state, child: const RecallApp()));
}

class RecallApp extends StatelessWidget {
  const RecallApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<RecallState, ThemeMode>((s) => s.themeMode);
    return MaterialApp(
      title: 'Recall',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: mode,
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
    );
  }
}

/// Named routes with a subtle fade + rise transition.
Route<dynamic> _onGenerateRoute(RouteSettings settings) {
  final Widget page;
  switch (settings.name) {
    case '/import':
      page = const ImportScreen();
      break;
    case '/preview':
      page = const PreviewScreen();
      break;
    case '/study':
      page = StudyScreen(deckId: settings.arguments as String);
      break;
    case '/results':
      page = ResultsScreen(args: settings.arguments as ResultsArgs);
      break;
    default:
      page = const HomeScreen();
  }
  return PageRouteBuilder<void>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, .02), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}
