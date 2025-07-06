import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/pages/login_page.dart';

class UserProfilePage extends StatelessWidget {
  final String userName;
  final String userId;
  final String asalKampus;

  const UserProfilePage({
    super.key,
    required this.userName,
    required this.userId,
    this.asalKampus = "",
  });

  @override
  Widget build(BuildContext context) {
    return EditProfileScreen(
      userName: userName,
      userId: userId,
      asalKampus: asalKampus,
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final String userName;
  final String userId;
  final String asalKampus;

  const EditProfileScreen({
    super.key,
    required this.userName,
    required this.userId,
    this.asalKampus = "",
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _campusController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool isLoading = true;
  String? profilePhotoUrl;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        _fullNameController.text = userData['nama_lengkap'] ?? '';
        _genderController.text = userData['jenis_kelamin'] ?? 'Tidak diisi';
        _phoneController.text = userData['no_hp'] ?? '';
        _campusController.text = userData['asal_kampus'] ?? '';
        _majorController.text = userData['prodi'] ?? '';
        _emailController.text = userData['email'] ?? '';

        profilePhotoUrl = userData['foto_profil'];
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil data: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _saveUserData() async {
    setState(() {
      isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'nama_lengkap': _fullNameController.text.trim(),
        'jenis_kelamin': _genderController.text.trim(),
        'no_hp': _phoneController.text.trim(),
        'asal_kampus': _campusController.text.trim(),
        'prodi': _majorController.text.trim(),
        'email': _emailController.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error menyimpan data: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: ${e.toString()}')),
      );
    }
  }

  Future<void> _selectGender() async {
    final String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Pilih Jenis Kelamin'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Laki-laki'),
              child: const Text('Laki-laki'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Perempuan'),
              child: const Text('Perempuan'),
            ),
          ],
        );
      },
    );

    if (selected != null) {
      setState(() {
        _genderController.text = selected;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _genderController.dispose();
    _phoneController.dispose();
    _campusController.dispose();
    _majorController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Widget _buildProfileField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool readOnly = false,
    VoidCallback? onTap,
    int? maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: onTap,
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              maxLines: maxLines,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                suffixIcon: Icon(icon, color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                isDense: true,
              ),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    // Blue Header with Profile Picture and App Bar elements
                    Container(
                      height: MediaQuery.of(context).size.height * 0.35,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF80C9FF), Color(0xFF007BFF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 40,
                            left: 10,
                            right: 10,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                const Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: isSaving ? null : _saveUserData,
                                  child: isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Save',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      image: profilePhotoUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(profilePhotoUrl!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: profilePhotoUrl == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 80,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildProfileField(
                              label: 'Nama Lengkap',
                              icon: Icons.person_outline,
                              controller: _fullNameController,
                            ),
                            _buildProfileField(
                              label: 'Jenis Kelamin',
                              icon: Icons.wc,
                              controller: _genderController,
                              readOnly: true,
                              onTap: _selectGender,
                            ),
                            _buildProfileField(
                              label: 'No Hp',
                              icon: Icons.call,
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                            ),
                            _buildProfileField(
                              label: 'Kampus/ Asal Kampus',
                              icon: Icons.school,
                              controller: _campusController,
                            ),
                            _buildProfileField(
                              label: 'Prodi',
                              icon: Icons.book,
                              controller: _majorController,
                            ),
                            _buildProfileField(
                              label: 'Email',
                              icon: Icons.email,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              readOnly: true,
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 10,
                        ),
                        width: double.infinity,
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _handleLogout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, // Initial background color
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 5,
                              foregroundColor: Colors.red, // Initial text color
                            ).copyWith(
                              foregroundColor: MaterialStateProperty.resolveWith((states) {
                                if (states.contains(MaterialState.pressed)) {
                                  return Colors.white; // Text color when pressed
                                }
                                return Colors.red; // Default text color
                              }),
                              backgroundColor: MaterialStateProperty.resolveWith((states) {
                                if (states.contains(MaterialState.pressed)) {
                                  return Colors.red; // Background color when pressed
                                }
                                return Colors.white; // Default background color
                              }),
                            ),
                            child: const Text(
                              'Log Out',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
