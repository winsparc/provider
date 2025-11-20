import 'package:flutter/material.dart';
import 'package:my_app/list_screen.dart';
import 'package:my_app/providers/login_provider.dart';
import 'package:provider/provider.dart';
import 'providers/upload_provider.dart';
import 'upload_screen.dart';
//import 'list_screen.dart';

void main() {
  runApp(

// MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => UploadProvider()),
//         ChangeNotifierProvider(create: (_) => LoginProvider()),
//       ],
//       child: MyApp(),
//     ),

    ChangeNotifierProvider(
      create: (context) => UploadProvider(),
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
      home: UploadScreen(baseUrl: baseUrl),
      routes: {
        '/list': (context) => ListScreen(baseUrl: baseUrl),
      },
    );
  }
}
