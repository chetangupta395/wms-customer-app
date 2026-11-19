import 'package:flutter/material.dart';

import 'api/session.dart';
import 'screens/customer_shell.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = CustomerSession();
  await session.load();
  runApp(CustomerApp(session: session));
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key, required this.session});

  final CustomerSession session;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fieldora Customer',
      debugShowCheckedModeBanner: false,
      theme: customerTheme(),
      home: ListenableBuilder(
        listenable: session,
        builder: (_, _) => session.signedIn
            ? CustomerShell(session: session)
            : LoginScreen(session: session),
      ),
    );
  }
}
