import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/upload_provider.dart';
import 'providers/login_provider.dart';
import 'upload_screen.dart';
import 'list_screen.dart';
import 'login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UploadProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String baseUrl =
      'https://pink-weasel-943417.hostingersite.com/silvar_leaf/api/students';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRUD Images & Usernames',
      home: FutureBuilder<bool>(
        future: Provider.of<LoginProvider>(context, listen: false).checkLogin(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == true) {
            return ListScreen(baseUrl: baseUrl);
          } else {
            return LoginScreen(baseUrl: baseUrl);
          }
        },
      ),
      routes: {
        '/list': (context) => ListScreen(baseUrl: baseUrl),
      },
    );
  }
}
