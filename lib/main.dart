import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/crossy_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Force landscape + hide system UI for full-screen TV experience
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const CrossyRoadApp());
}

class CrossyRoadApp extends StatelessWidget {
  const CrossyRoadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crossy Road TV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const Scaffold(
        backgroundColor: Colors.black,
        body: CrossyGame(),
      ),
    );
  }
}
