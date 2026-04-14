import 'package:flutter/material.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎫', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('My Bookings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Booking history — Milestone 4', style: TextStyle(color: Color(0xFF2563EB), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
