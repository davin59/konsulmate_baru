import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/pages/login_page.dart';

class ProfileMentor extends StatelessWidget {
  final String userName;
  final String userId;
  final String bidangKeahlian;

  const ProfileMentor({
    super.key,
    required this.userName,
    required this.userId,
    this.bidangKeahlian = "",
  });

  @override
  Widget build(BuildContext context) {
    return EditProfileMentor(
      userName: userName,
      userId: userId,
      bidangKeahlian: bidangKeahlian,
    );
  }
}

class EditProfileMentor extends StatefulWidget {
  final String userName;
  final String userId;
  final String bidangKeahlian;

  const EditProfileMentor({
    super.key,
    required this.userName,
    required this.userId,
    this.bidangKeahlian = "",
  });

  @override
  State<EditProfileMentor> createState() => _EditProfileMentorState();
}

class _EditProfileMentorState extends State<EditProfileMentor> {
  // Controllers for form fields
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _campusController = TextEditingController();
  final TextEditingController _prodiController = TextEditingController();
  final TextEditingController _keahlianController = TextEditingController();
  final TextEditingController _toolsController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _tarifController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool isLoading = true;
  String? profilePhotoUrl;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMentorData();
  }

  Future<void> _loadMentorData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final mentorDoc = await FirebaseFirestore.instance
          .collection('mentors')
          .doc(widget.userId)
          .get();

      if (!mounted) return;

      if (mentorDoc.exists) {
        final mentorData = mentorDoc.data() as Map<String, dynamic>;

        // Set controller values from Firebase data
        _fullNameController.text = mentorData['nama_lengkap'] ?? '';
        _genderController.text = mentorData['jenis_kelamin'] ?? 'Tidak diisi';
        _phoneController.text = mentorData['no_hp'] ?? '';
        _campusController.text = mentorData['asal_kampus'] ?? '';
        _prodiController.text = mentorData['prodi'] ?? '';
        _keahlianController.text = mentorData['keahlian'] ?? '';
        _toolsController.text = mentorData['tools'] ?? '';
        _deskripsiController.text = mentorData['deskripsi'] ?? '';
        _tarifController.text = mentorData['tarif']?.toString() ?? '0';
        _emailController.text = mentorData['email'] ?? '';

        // Get profile photo if exists
        profilePhotoUrl = mentorData['foto_profil'];
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

  Future<void> _saveMentorData() async {
    setState(() {
      isSaving = true;
    });

    try {
      // Update mentor data in Firestore
      await FirebaseFirestore.instance
          .collection('mentors')
          .doc(widget.userId)
          .update({
        'nama_lengkap': _fullNameController.text.trim(),
        'jenis_kelamin': _genderController.text.trim(),
        'no_hp': _phoneController.text.trim(),
        'asal_kampus': _campusController.text.trim(),
        'prodi': _prodiController.text.trim(),
        'keahlian': _keahlianController.text.trim(),
        'tools': _toolsController.text.trim(),
        'deskripsi': _deskripsiController.text.trim(),
        'tarif': int.tryParse(_tarifController.text.trim()) ?? 0,
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

  // Fungsi untuk handle logout secara terpisah
  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      // Navigate to login screen
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
    _prodiController.dispose();
    _keahlianController.dispose();
    _toolsController.dispose();
    _deskripsiController.dispose();
    _tarifController.dispose();
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
                                  'Edit Profile Mentor',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: isSaving ? null : _saveMentorData,
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
                              label: 'Asal Kampus',
                              icon: Icons.school,
                              controller: _campusController,
                            ),
                            _buildProfileField(
                              label: 'Program Studi',
                              icon: Icons.book,
                              controller: _prodiController,
                            ),
                            _buildProfileField(
                              label: 'Bidang Keahlian',
                              icon: Icons.star,
                              controller: _keahlianController,
                            ),
                            _buildProfileField(
                              label: 'Tools yang Dikuasai',
                              icon: Icons.build,
                              controller: _toolsController,
                              maxLines: 2,
                            ),
                            _buildProfileField(
                              label: 'Deskripsi Diri',
                              icon: Icons.description,
                              controller: _deskripsiController,
                              maxLines: 4,
                            ),
                            _buildProfileField(
                              label: 'Tarif per Meet (Rp)',
                              icon: Icons.attach_money,
                              controller: _tarifController,
                              keyboardType: TextInputType.number,
                            ),
                            _buildProfileField(
                              label: 'Email',
                              icon: Icons.email,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              readOnly: true, // Email biasanya tidak diubah
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Sticky Log Out Button
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