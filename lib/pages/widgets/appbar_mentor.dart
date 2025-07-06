// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../mentor/profilepage_mentor.dart';

class AppBarMentor extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String? bidangKeahlian;
  final String? userId;

  const AppBarMentor({
    super.key,
    required this.userName,
    this.bidangKeahlian,
    this.userId,
  });

  @override
  Size get preferredSize => const Size.fromHeight(100); // Kurangi tinggi appbar

  Future<String> _getBidangKeahlian() async {
    if (userId == null) return bidangKeahlian ?? '';

    try {
      final doc = await FirebaseFirestore.instance.collection('mentors').doc(userId).get();
      if (doc.exists) {
        return doc['keahlian'] ?? bidangKeahlian ?? '';
      }
    } catch (e) {
      debugPrint('Error getting mentor data: $e');
    }
    return bidangKeahlian ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getBidangKeahlian(),
      builder: (context, snapshot) {
        String keahlian = snapshot.data ?? bidangKeahlian ?? 'Mentor';
        return _buildAppBar(context, keahlian);
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String keahlian) {
    return PreferredSize(
      preferredSize: preferredSize,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF80C9FF), // Biru di atas
              Colors.white,      // Putih di bawah
            ],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Kurangi padding vertikal
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile photo (di kiri pojok)
                GestureDetector(
                  onTap: () {
                    if (userId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileMentor(
                            userName: userName,
                            userId: userId!,
                            bidangKeahlian: keahlian,
                          ),
                        ),
                      );
                    }
                  },
                  child: const CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage('assets/mentor_avatar.png'),
                    backgroundColor: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                // Name and expertise (di sebelah kanan foto)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        keahlian,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}