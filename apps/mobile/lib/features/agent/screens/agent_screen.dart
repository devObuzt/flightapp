import 'package:flutter/material.dart';

class AgentScreen extends StatelessWidget {
  const AgentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Travel Agent')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✈️', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('Your AI Travel Agent',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Chat or speak to search and book flights in any language.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            SizedBox(height: 16),
            Text('AI Chat — Milestone 3',
                style: TextStyle(color: Color(0xFF2563EB), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
