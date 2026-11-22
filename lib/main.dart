import 'package:flutter/material.dart';

void main() => runApp(const OurChat());

class OurChat extends StatelessWidget {
  const OurChat({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OurChat',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const Scaffold(
        body: Center(
          child: Text(
            'OurChat',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
