// ignore_for_file: use_build_context_synchronously

import 'dart:convert'; // Untuk mengkonversi JSON
import 'package:flutter/services.dart'
    show rootBundle; // Untuk mengambil file dari assets
import 'package:flutter/material.dart'; // Import UI toolkit Flutter
import 'user/homepage_user.dart'; // Import halaman utama untuk user
import 'mentor/homepage_mentor.dart'; // Import halaman utama untuk mentor
import 'mentor/regis_mentor.dart'; // Tambahkan import ini
import 'user/regis_user.dart'; // Tambahkan import ini
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin/dashboard_admin.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController =
      TextEditingController(); // Controller untuk input email
  final TextEditingController passwordController =
      TextEditingController(); // Controller untuk input password
  bool isMentorSelected =
      false; // Boolean untuk mengecek apakah login sebagai mentor atau user

  // Fungsi untuk memuat data dari file JSON lokal
  Future<Map<String, dynamic>> loadJsonData() async {
    String data = await rootBundle.loadString(
      'assets/data/dummy.json',
    ); // Membaca file JSON dari assets
    return json.decode(data); // Mengubah string JSON menjadi Map
  }

  // Fungsi ketika tombol Masuk ditekan
  void handleMasuk(BuildContext context) async {
    String email = emailController.text.trim(); // Ambil email dari input
    String password =
        passwordController.text.trim(); // Ambil password dari input
    final jsonData = await loadJsonData(); // Memuat data JSON

    String role =
        isMentorSelected
            ? 'mentor'
            : 'user'; // Menentukan role berdasarkan pilihan
    final dataList = jsonData[role] as List; // Ambil list user/mentor dari JSON
    final user = dataList.firstWhere(
      (u) =>
          u['email'] == email &&
          u['password'] ==
              password, // Cari user dengan email dan password sesuai
      orElse: () => null, // Jika tidak ditemukan, kembalikan null
    );

    if (user != null) {
      // Jika user ditemukan, arahkan ke halaman sesuai role
      final String userName = user['nama'] ?? '';
      final String userId = user['id'] ?? '';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  isMentorSelected
                      // Ganti MentorHomePage menjadi HomepageMentor
                      ? HomepageMentor(userName: userName, userId: userId)
                      : HomeUser(
                        userName: userName,
                        userId: userId,
                      ), // Kirim nama user yang sesuai
        ),
      );
    } else {
      // Jika user tidak ditemukan, tampilkan pesan kesalahan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email atau password salah!')),
      );
    }
  }

  // Fungsi login dengan Firebase Auth dan cek role di Firestore
  Future<void> handleFirebaseLogin(BuildContext context) async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    try {
      // Login ke Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      String uid = userCredential.user!.uid;

      // Cek di koleksi 'admin'
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc(uid)
          .get();
      if (adminDoc.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardAdmin(
              adminName: adminDoc['nama'] ?? 'Admin',
              adminId: uid,
            ),
          ),
        );
        return;
      }

      if (isMentorSelected) {
        // Cek di koleksi 'mentors'
        DocumentSnapshot mentorDoc = await FirebaseFirestore.instance
            .collection('mentors')
            .doc(uid)
            .get();
        if (mentorDoc.exists && mentorDoc['role'] == 'mentor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomepageMentor(
                userName: mentorDoc['nama_lengkap'] ?? '',
                userId: uid,
              ),
            ),
          );
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Akun ini tidak terdaftar sebagai mentor!')),
          );
          return;
        }
      } else {
        // Cek di koleksi 'users'
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (userDoc.exists && userDoc['role'] == 'user') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeUser(
                userName: userDoc['nama_lengkap'] ?? '',
                userId: uid,
                asalKampus: userDoc['asal_kampus'] ?? '',
              ),
            ),
          );
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Akun ini tidak terdaftar sebagai user!')),
          );
          return;
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Email atau password salah!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Atur latar belakang menjadi putih
      body: SingleChildScrollView(
        // Supaya bisa discroll jika layar kecil
        child: Column(
          children: <Widget>[
            // Bagian atas - Logo dan Tagline
            Container(
              padding: const EdgeInsets.only(
                top: 60.0,
                bottom: 20.0,
              ), // Padding atas dan bawah
              color: Colors.white,
              child: Column(
                children: [
                  const Text(
                    'KonsulMate', // Nama aplikasi
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'chewy',
                    ),
                  ),
                  const SizedBox(height: 10), // Spasi
                  const Text(
                    'Membantu Menemukan', // Tagline
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'chewy',
                    ),
                  ),
                  const SizedBox(height: 5),
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/images/illustration.png',
                    height: 200,
                  ), // Gambar ilustrasi
                  const Text(
                    'Mentor Terbaikmu', // Lanjutan tagline
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'chewy',
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Bagian bawah - Form Login
            Container(
              width: double.infinity, // Lebar penuh
              padding: const EdgeInsets.all(20.0), // Padding isi
              decoration: const BoxDecoration(
                color: Color(0xFF87CEEB), // Warna latar biru muda
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),

              // Pilihan login sebagai user atau mentor
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly, // Rata seimbang
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isMentorSelected =
                                  true; // Pilih login sebagai mentor
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isMentorSelected
                                    ? Colors.blue[900] // Warna jika dipilih
                                    : Colors
                                        .blue[400], // Warna jika tidak dipilih
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Login Mentor', // Teks tombol
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isMentorSelected =
                                  false; // Pilih login sebagai user
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                !isMentorSelected
                                    ? Colors.blue[900]
                                    : Colors.blue[400],
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Login User',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Kolom input email dan password
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController, // Input email
                    decoration: InputDecoration(
                      hintText: 'Email',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: passwordController, // Input password
                    obscureText: true, // Agar tidak terlihat
                    decoration: InputDecoration(
                      hintText: 'Password',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol daftar dan masuk
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (isMentorSelected) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const RegisterMentorScreen(),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const RegisterUserScreen(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800], // Warna tombol
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Daftar',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Ganti handleMasuk(context) menjadi handleFirebaseLogin(context)
                            handleFirebaseLogin(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Masuk',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    'Sign in with another method', // Teks login alternatif
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 15),

                  // Ikon login alternatif (dummy)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(
                          Icons.email,
                          size: 30,
                          color: Colors.black54,
                        ),
                        onPressed: () {
                          // login email
                        },
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(
                          Icons.facebook,
                          size: 30,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          // Login Facebook
                        },
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(
                          Icons.travel_explore,
                          size: 30,
                          color: Colors.lightBlueAccent,
                        ),
                        onPressed: () {
                          // login Twitter
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}