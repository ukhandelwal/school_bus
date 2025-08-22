import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/websocket_service.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('School Bus Tracker - Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // For POC, use simple authentication
                if (_usernameController.text.isNotEmpty &&
                    _passwordController.text.isNotEmpty) {
                  // Connect to WebSocket
                  final wsService = Provider.of<WebSocketService>(context, listen: false);
                  wsService.connect('ws://your-websocket-server.com:8080');

                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}