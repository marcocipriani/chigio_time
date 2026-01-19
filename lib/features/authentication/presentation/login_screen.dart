import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Benvenuto in ChigioTime')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time_filled, size: 80, color: Colors.blue),
            SizedBox(height: 24),
            Text('Login Screen Placeholder'),
            // TODO: Implementare Login [cite: 79]
          ],
        ),
      ),
    );
  }
}