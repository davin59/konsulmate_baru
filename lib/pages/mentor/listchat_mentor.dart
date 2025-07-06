import 'package:flutter/material.dart';
import '../widgets/appbar_mentor.dart';
import '../widgets/footer_mentor.dart';

class ListChatMentor extends StatelessWidget {
  final String userName;
  final String userId;
  final String? bidangKeahlian;

  const ListChatMentor({
    super.key,
    required this.userName,
    required this.userId,
    this.bidangKeahlian,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarMentor(
        userName: userName,
        userId: userId,
        bidangKeahlian: bidangKeahlian,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            const Text(
              'Ini adalah halaman List Chat',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Selamat datang, $userName',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: FooterMentor(
        currentIndex: 1, // Karena ini adalah tab Chat
        userName: userName,
        userId: userId,
        bidangKeahlian: bidangKeahlian,
      ),
    );
  }
}