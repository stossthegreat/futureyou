import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'HELLO',
          style: TextStyle(color: Colors.white, fontSize: 32),
        ),
      ),
    ),
  ));
}
