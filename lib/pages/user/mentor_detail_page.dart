// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/mentor_card.dart';
import '../widgets/footer_user.dart';
import 'order_page.dart';

class MentorDetailPage extends StatefulWidget {
  final String mentorId;
  final String userId;
  final String userName;
  final String asalKampus;

  const MentorDetailPage({
    super.key,
    required this.mentorId,
    required this.userId,
    required this.userName,
    this.asalKampus = "",
  });

  @override
  State<MentorDetailPage> createState() => _MentorDetailPageState();
}

class _MentorDetailPageState extends State<MentorDetailPage> {
  // Tambahkan variabel state untuk menyimpan data tambahan
  bool isLoading = true;
  Map<String, dynamic> mentorData = {};
  double mentorRating = 0.0;
  int orderCount = 0;
  int pricePerMeet = 0;

  @override
  void initState() {
    super.initState();
    _loadAllMentorData();
  }

  Future<void> _loadAllMentorData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 1. Load data mentor dasar
      DocumentSnapshot mentorDoc = await FirebaseFirestore.instance
          .collection('mentors')
          .doc(widget.mentorId)
          .get();

      if (!mentorDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mentor tidak ditemukan')),
        );
        Navigator.pop(context);
        return;
      }

      mentorData = mentorDoc.data() as Map<String, dynamic>;

      // 2. Hitung jumlah pesanan untuk mentor ini
      QuerySnapshot pesananSnapshot = await FirebaseFirestore.instance
          .collection('pesanan')
          .where('id_mentor', isEqualTo: widget.mentorId)
          .get();
      
      orderCount = pesananSnapshot.docs.length;

      // 3. Hitung rating rata-rata
      double totalRating = 0;
      int ratingCount = 0;
      
      for (var doc in pesananSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['rating'] != null) {
          totalRating += (data['rating'] as num).toDouble();
          ratingCount++;
        }
      }
      
      if (ratingCount > 0) {
        mentorRating = totalRating / ratingCount;
      }

      // 4. Ambil harga per meet dari detail_pesanan (ambil yang terbaru)
      QuerySnapshot detailPesananSnapshot = await FirebaseFirestore.instance
          .collection('detail_pesanan')
          .where('id_mentor', isEqualTo: widget.mentorId)
          .orderBy('updated_at', descending: true)
          .limit(1)
          .get();

      if (detailPesananSnapshot.docs.isNotEmpty) {
        var detailData = detailPesananSnapshot.docs.first.data() as Map<String, dynamic>;
        pricePerMeet = detailData['harga_per_meet'] ?? 0;
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToOrderPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderPage(
          userId: widget.userId,
          userName: widget.userName,
          asalKampus: widget.asalKampus,
          mentorId: widget.mentorId,
          mentorName: mentorData['nama_lengkap'] ?? 'Nama Mentor',
          mentorProdi: mentorData['prodi'] ?? '',
          mentorKeahlian: mentorData['keahlian'] ?? '',
          hargaPerMeet: pricePerMeet, // Gunakan nilai yang sudah dihitung
          mentorImageUrl: '', // Gunakan string kosong atau URL jika tersedia
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: MentorDetailCard(
                mentorName: mentorData['nama_lengkap'] ?? 'Nama Mentor',
                mentorImageUrl: '',
                expertise: mentorData['prodi'] ?? 'Tidak ada data',
                pricePerHour: pricePerMeet,
                skills: mentorData['keahlian']?.toString().split(', ') ?? [],
                technologies: mentorData['tools']?.toString().split(', ') ?? [],
                university: mentorData['asal_kampus'] ?? 'Tidak ada data',
                rating: mentorRating,
                orderCount: orderCount,
                about: mentorData['deskripsi'] ?? 'Tidak ada deskripsi',
                onTentukanWaktuPressed: _navigateToOrderPage, // Tambahkan callback
              ),
            ),
      bottomNavigationBar: FooterUser(
        currentIndex: 0,
        userName: widget.userName,
        userId: widget.userId,
        asalKampus: widget.asalKampus,
      ),
    );
  }
}