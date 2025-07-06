import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const RegisUser());
}

class RegisUser extends StatelessWidget {
  const RegisUser({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daftar Sebagai User',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const RegisterUserScreen(),
    );
  }
}

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  String? _selectedGender; // Tambahkan variabel untuk dropdown
  final TextEditingController _campusController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _campusController.dispose();
    _majorController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildInputField(
    TextEditingController controller,
    String labelText,
    IconData icon, {
    bool isPassword = false,
    int maxLines = 1,
    bool isEmail = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: Colors.blue,
          width: 1.0,
        ), // border biru lebih tipis
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(
              color: Colors.blue,
              width: 1.0,
            ), // border biru lebih tipis
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(
              color: Colors.blue,
              width: 1.0,
            ), // border biru lebih tipis
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(
              color: Colors.blue,
              width: 1.2,
            ), // border biru sedikit lebih tebal saat fokus
          ),
          filled: true,
          fillColor: Colors.white,
          // Use suffixIcon for consistency with the image (icon inside the field, not necessarily prefix)
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      isPassword && _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      setState(() {
                        if (labelText == 'Password') {
                          _isPasswordVisible = !_isPasswordVisible;
                        } else if (labelText == 'Konfirmasi Password') {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        }
                      });
                    },
                  )
                  : (isEmail
                      ? const Icon(Icons.send_outlined, color: Colors.blue)
                      : Icon(
                        icon,
                        color: Colors.blue,
                      )), // Specific icon for email
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15.0,
            horizontal: 10.0,
          ),
        ),
      ),
    );
  }

  // Ganti _buildGenderInputField dengan dropdown
  Widget _buildGenderDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: Colors.blue,
          width: 1.0,
        ), // border biru lebih tipis
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: const InputDecoration(
          labelText: 'Jenis Kelamin',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            borderSide: BorderSide(
              color: Colors.blue,
              width: 1.0,
            ), // border biru lebih tipis
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            borderSide: BorderSide(
              color: Colors.blue,
              width: 1.0,
            ), // border biru lebih tipis
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            borderSide: BorderSide(
              color: Colors.blue,
              width: 1.2,
            ), // border biru sedikit lebih tebal saat fokus
          ),
          suffixIcon: Icon(Icons.male, color: Colors.blue),
          filled: true,
          fillColor: Colors.white,
        ),
        items: const [
          DropdownMenuItem(value: 'laki-laki', child: Text('Laki-laki')),
          DropdownMenuItem(value: 'perempuan', child: Text('Perempuan')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedGender = value;
          });
        },
        validator: (value) => value == null ? 'Pilih jenis kelamin' : null,
      ),
    );
  }

  Future<void> _registerUser() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Simpan email dan password ke Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Simpan data tambahan ke Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'nama_lengkap': _fullNameController.text.trim(),
            'jenis_kelamin': _selectedGender,
            'asal_kampus': _campusController.text.trim(),
            'prodi': _majorController.text.trim(),
            'email': _emailController.text.trim(),
            'no_hp': _phoneController.text.trim(),
            'created_at': FieldValue.serverTimestamp(),
            'role': 'user', // Tambahkan field role
          });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Registrasi berhasil!')));
      }
      
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Maaf kamu gagal mendaftar')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Sebagai User',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true, // Allow content to go behind the app bar
      body: Stack(
        children: [
          // Background wave/liquid pattern at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF88D4EE), // Light blue
                      Color(0xFF3399FF), // Brighter blue
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 80), // Space for the app bar
                // Profile Picture Placeholder
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFADD8E6), // Light blue for the circle
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  _fullNameController,
                  'Nama Lengkap',
                  Icons.person_outline,
                ),
                _buildGenderDropdown(), // Ganti gender input dengan dropdown
                _buildInputField(
                  _campusController,
                  'Asal Kampus',
                  Icons.house_outlined,
                ),
                _buildInputField(_majorController, 'Prodi', Icons.school),
                _buildInputField(
                  _emailController,
                  'Email',
                  Icons.email,
                  isEmail: true,
                ), // Changed icon
                _buildInputField(
                  _phoneController,
                  'No Hp',
                  Icons.call,
                ), // Moved down
                _buildInputField(
                  _passwordController,
                  'Password',
                  Icons.remove_red_eye_outlined,
                  isPassword: true,
                ),
                _buildInputField(
                  _confirmPasswordController,
                  'Konfirmasi Password',
                  Icons.remove_red_eye_outlined,
                  isPassword: true,
                ),
                const SizedBox(height: 30),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Validasi sederhana sebelum daftar
                      if (_emailController.text.isEmpty ||
                          _passwordController.text.isEmpty ||
                          _confirmPasswordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email dan password wajib diisi'),
                          ),
                        );
                        return;
                      }
                      if (_passwordController.text !=
                          _confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password dan konfirmasi tidak sama'),
                          ),
                        );
                        return;
                      }
                      if (_passwordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password minimal 6 karakter'),
                          ),
                        );
                        return;
                      }
                      _registerUser();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Button background color
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Daftar',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 50,
                ), // Extra space at the bottom to avoid overlap with wave
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// Custom Clipper for the wave/liquid background (reused from previous example)
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.7); // Start from bottom-left, up a bit
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height * 0.8);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 3 / 4, size.height * 0.6);
    var secondEndPoint = Offset(size.width, size.height * 0.9);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0); // Line to top-right
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
