import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../user/profilepage_user.dart';

class AppBarUser extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String asalKampus;
  final String? userId;

  const AppBarUser({
    super.key,
    required this.userName,
    this.asalKampus = "Asal Kampus",
    this.userId,
  });

  @override
  Size get preferredSize => const Size.fromHeight(100); // Samakan tinggi dengan AppBarMentor

  Future<String> _getAsalKampus() async {
    if (userId == null) return asalKampus;
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data()?['asal_kampus'] ?? asalKampus;
  }

  @override
  Widget build(BuildContext context) {
    // Jika asalKampus sudah diisi dari parent, tampilkan langsung
    if (asalKampus != "Asal Kampus" && asalKampus.isNotEmpty) {
      return _buildAppBar(context, asalKampus);
    }
    // Jika tidak, ambil dari Firestore berdasarkan userId
    return FutureBuilder<String>(
      future: _getAsalKampus(),
      builder: (context, snapshot) {
        final kampus = snapshot.data ?? asalKampus;
        return _buildAppBar(context, kampus);
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String kampus) {
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
                          builder: (context) => UserProfilePage(
                            userName: userName,
                            userId: userId!,
                            asalKampus: kampus,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User ID tidak tersedia')),
                      );
                    }
                  },
                  child: const CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage('assets/user_avatar.png'),
                    backgroundColor: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                // Name and campus (di sebelah kanan foto)
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
                        kampus,
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
