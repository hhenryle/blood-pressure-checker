import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/database.dart';
import 'screens/home_shell.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notifications = NotificationService();
  await notifications.init();
  final state = AppState(AppDatabase(), notifications);
  state.load();
  runApp(
    ChangeNotifierProvider.value(value: state, child: const BpApp()),
  );
}

class BpApp extends StatelessWidget {
  const BpApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFFD64545),
          brightness: b,
        );
    return MaterialApp(
      title: 'BP Tracker',
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: const HomeShell(),
    );
  }
}
