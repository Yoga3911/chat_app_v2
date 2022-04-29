import 'package:chat/service/auth_provider.dart';
import 'package:chat/service/user_provider.dart';
import 'package:chat/view/login.dart';
import 'package:chat/view/wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final pref = await SharedPreferences.getInstance();
  if (pref.getString("id") == null) {
    runApp(
      const MyApp(
        route: LoginPage(),
      ),
    );
  } else if (pref.getString("id") != null) {
    runApp(
      MyApp(
        route: Wrapper(id: pref.getString("id").toString()),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.route}) : super(key: key);
  final Widget route;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: route,
      ),
    );
  }
}
