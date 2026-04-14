import 'package:flutter/material.dart';

class FlightSearchScreen extends StatelessWidget {
  const FlightSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Flights')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔍', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('Flight Search', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Manual search — Milestone 2', style: TextStyle(color: Color(0xFF2563EB), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
