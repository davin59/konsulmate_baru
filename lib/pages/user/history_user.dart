// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/footer_user.dart';
import 'payment_page.dart'; 
import 'order_page.dart';

class HistoryUser extends StatefulWidget {
  final String userName;
  final String userId;
  final String asalKampus;

  const HistoryUser({
    super.key, 
    required this.userName, 
    required this.userId,
    this.asalKampus = '',
  });

  @override
  State<HistoryUser> createState() => _UserHistoryPageState();
}

class _UserHistoryPageState extends State<HistoryUser> {
  List<Map<String, dynamic>> userOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserOrders();
  }

  Future<void> loadUserOrders() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Ambil data dari Firestore
      final QuerySnapshot pesananSnapshot = await FirebaseFirestore.instance
          .collection('pesanan')
          .where('id_user', isEqualTo: widget.userId)
          .orderBy('created_at', descending: true)
          .get();

      final List<Map<String, dynamic>> orders = [];

      for (var doc in pesananSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Ambil detail_pesanan untuk pesanan ini
        final detailSnapshot = await FirebaseFirestore.instance
            .collection('detail_pesanan')
            .doc(doc.id)
            .get();

        if (detailSnapshot.exists) {
          data['detail_pesanan'] = detailSnapshot.data();
        }

        orders.add(data);
      }

      setState(() {
        userOrders = orders;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB), // putih pudar
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadUserOrders,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                height: 80,
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
                child: const Padding(
                  padding: EdgeInsets.only(left: 24.0, top: 0,),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'History Konsultasi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (userOrders.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Belum ada riwayat konsultasi',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...userOrders.map((order) => _buildOrderCard(order)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadUserOrders,
        backgroundColor: const Color(0xFF80C9FF),
        child: const Icon(Icons.refresh),
      ),
      bottomNavigationBar: FooterUser(
        currentIndex: 3,
        userName: widget.userName,
        userId: widget.userId,
        asalKampus: widget.asalKampus,
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    // Tentukan warna dan teks berdasarkan status
    Color statusColor;
    Color statusBgColor;
    String statusText = order['status'] ?? 'pending';
    String displayStatus;

    // Konversi status dari database ke teks yang lebih user-friendly
    switch (statusText) {
      case 'menunggu_persetujuan_mentor':
        statusColor = Colors.orange;
        statusBgColor = Colors.orange.shade50;
        displayStatus = 'Menunggu Persetujuan';
        break;
      case 'menunggu_pembayaran':
        statusColor = Colors.blue;
        statusBgColor = Colors.blue.shade50;
        displayStatus = 'Menunggu Pembayaran';
        break;
      case 'menunggu_verifikasi_admin':
        statusColor = Colors.purple;
        statusBgColor = Colors.purple.shade50;
        displayStatus = 'Verifikasi Pembayaran';
        break;
      case 'terkonfirmasi':
        statusColor = Colors.teal;
        statusBgColor = Colors.teal.shade50;
        displayStatus = 'Terkonfirmasi';
        break;
      case 'selesai':
        statusColor = Colors.green;
        statusBgColor = Colors.green.shade50;
        displayStatus = 'Selesai';
        break;
      case 'dibatalkan':
        statusColor = Colors.red;
        statusBgColor = Colors.red.shade50;
        displayStatus = 'Dibatalkan';
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.shade50;
        displayStatus = 'Sedang Diproses';
    }

    // Format tanggal konsultasi
    String tanggalKonsultasi = '';
    if (order['tanggal_konsultasi'] != null) {
      if (order['tanggal_konsultasi'] is Timestamp) {
        final date = order['tanggal_konsultasi'].toDate();
        tanggalKonsultasi = '${date.day}/${date.month}/${date.year}';
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar mentor
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),

                const SizedBox(width: 12),

                // Info mentor
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Nama mentor
                          Expanded(
                            child: Text(
                              order['nama_mentor'] ?? 'Nama Mentor',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Status label
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              displayStatus,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Mata kuliah - Menggunakan prodi dari mentor
                      Text(
                        order['prodi'] ?? 'Mata Kuliah',
                        style: const TextStyle(fontSize: 14),
                      ),

                      const SizedBox(height: 4),

                      // Jadwal dan total pertemuan
                      Text(
                        'Jadwal: $tanggalKonsultasi ${order['jam_konsultasi'] ?? ""}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      
                      // Total meet
                      Text(
                        'Total Meet: ${order['total_meet'] ?? 0} (1 meet 1 jam)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      
                      // Total harga
                      Text(
                        'Total Harga: Rp ${_formatPrice(order['total_harga'] ?? 0)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons berdasarkan status
            _buildActionButtons(order, statusText),
          ],
        ),
      ),
    );
  }

  // Fungsi helper untuk memformat harga
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    );
  }

  // Widget untuk tombol aksi berdasarkan status
  Widget _buildActionButtons(Map<String, dynamic> order, String status) {
    // Ambil detail pesanan untuk akses catatan
    final detail = order['detail_pesanan'] ?? {};
    final persetujuanMentor = detail['persetujuan_mentor'] ?? {};
    final verifikasiAdmin = detail['verifikasi_admin'] ?? {};
    
    // Catatan dari mentor (jika ada)
    final String? catatanMentor = persetujuanMentor['catatan'];
    // Catatan dari admin (jika ada)
    final String? catatanAdmin = verifikasiAdmin['catatan'];

    switch (status) {
      case 'menunggu_pembayaran':
        // Tombol Upload Bukti Pembayaran setelah disetujui mentor
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tampilkan catatan mentor jika ada
            if (catatanMentor != null && catatanMentor.toString().isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catatan dari Mentor:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      catatanMentor,
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                    ),
                  ],
                ),
              ),
            ],
            
            // Tombol pembayaran
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigasi ke halaman pembayaran
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentPage(
                          orderId: order['id'],
                          totalAmount: order['total_harga'] ?? 0,
                        ),
                      ),
                    ).then((_) => loadUserOrders());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload Bukti Pembayaran'),
                ),
              ],
            ),
          ],
        );
    
      case 'menunggu_verifikasi_admin':
        // Status menunggu verifikasi admin dengan info bukti pembayaran
        final buktiUrl = detail['bukti_pembayaran']?['url'];
        final tanggalBayar = detail['bukti_pembayaran']?['tanggal'];
        
        String tanggalPembayaran = '';
        if (tanggalBayar != null && tanggalBayar is Timestamp) {
          final date = tanggalBayar.toDate();
          tanggalPembayaran = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bukti Pembayaran:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        tanggalPembayaran,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pembayaran sedang diverifikasi oleh admin',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            
            if (buktiUrl != null && buktiUrl.toString().isNotEmpty) 
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 150,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    buktiUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      const Center(child: Text('Tidak dapat menampilkan bukti')),
                  ),
                ),
              ),
          ],
        );
    
      case 'terkonfirmasi':
        // Tampilkan detail lokasi pertemuan dan tombol Selesai
        final alamat = detail['alamat_meets'] ?? 'Lokasi tidak tersedia';
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Catatan dari admin (jika ada)
            if (catatanAdmin != null && catatanAdmin.toString().isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catatan dari Admin:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      catatanAdmin,
                      style: TextStyle(fontSize: 13, color: Colors.teal.shade800),
                    ),
                  ],
                ),
              ),
            ],

            // Informasi lokasi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lokasi Pertemuan:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(alamat),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Tombol Tandai Selesai
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _markAsComplete(order['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Tandai Selesai'),
                ),
              ],
            ),
          ],
        );
    
      case 'selesai':
        // Kode untuk status selesai sama seperti sebelumnya
        // Cek apakah sudah dirating
        final bool alreadyRated = order['rating'] != null;
        
        return alreadyRated 
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Star rating
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      final int rating = order['rating'] ?? 0;
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      '${order['rating'] ?? 0}/5',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // Pesan lagi
                ElevatedButton.icon(
                  onPressed: () => _orderAgain(order['id_mentor'], order['nama_mentor']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF80C9FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Pesan lagi'),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showRatingDialog(order['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.star, size: 18),
                  label: const Text('Beri Rating'),
                ),
              ],
            );
    
      case 'dibatalkan':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Pesanan dibatalkan',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            
            // Tampilkan catatan mentor jika pesanan ditolak
            if (catatanMentor != null && catatanMentor.toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alasan Penolakan:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      catatanMentor,
                      style: TextStyle(fontSize: 13, color: Colors.red.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
        
      default:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Menunggu Konfirmasi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
    }
  }

  // Tandai pesanan sebagai selesai
  Future<void> _markAsComplete(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('pesanan')
          .doc(orderId)
          .update({
        'status': 'selesai',
      });
      
      // Reload data
      loadUserOrders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan ditandai selesai')),
        );
      }
    } catch (e) {
      debugPrint('Error marking as complete: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  // Dialog untuk memberikan rating
  void _showRatingDialog(String orderId) {
    int selectedRating = 5;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Beri Rating'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Bagaimana pengalaman konsultasi Anda?'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          size: 32,
                        ),
                        color: Colors.amber,
                        onPressed: () {
                          setState(() {
                            selectedRating = index + 1;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitRating(orderId, selectedRating);
              },
              child: const Text('Kirim'),
            ),
          ],
        );
      },
    );
  }

  // Submit rating ke Firestore
  Future<void> _submitRating(String orderId, int rating) async {
    try {
      await FirebaseFirestore.instance
          .collection('pesanan')
          .doc(orderId)
          .update({
        'rating': rating,
      });
      
      // Reload data
      loadUserOrders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terima kasih atas penilaian Anda')),
        );
      }
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  // Pesan mentor lagi
  void _orderAgain(String mentorId, String mentorName) async {
    try {
      setState(() {
        isLoading = true;
      });
      
      // Ambil data mentor dari Firestore
      DocumentSnapshot mentorDoc = await FirebaseFirestore.instance
          .collection('mentors')
          .doc(mentorId)
          .get();
      
      if (!mentorDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mentor tidak ditemukan')),
          );
        }
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      Map<String, dynamic> mentorData = mentorDoc.data() as Map<String, dynamic>;
      
      // Cari harga per meet terbaru
      int hargaPerMeet = 0;
      QuerySnapshot detailPesananSnapshot = await FirebaseFirestore.instance
          .collection('detail_pesanan')
          .where('id_mentor', isEqualTo: mentorId)
          .orderBy('updated_at', descending: true)
          .limit(1)
          .get();
      
      if (detailPesananSnapshot.docs.isNotEmpty) {
        var detailData = detailPesananSnapshot.docs.first.data() as Map<String, dynamic>;
        hargaPerMeet = detailData['harga_per_meet'] ?? 0;
      }
      
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        // Navigasi langsung ke halaman order
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderPage(
              userId: widget.userId,
              userName: widget.userName,
              asalKampus: widget.asalKampus,
              mentorId: mentorId,
              mentorName: mentorName,
              mentorProdi: mentorData['prodi'] ?? '',
              mentorKeahlian: mentorData['keahlian'] ?? '',
              hargaPerMeet: hargaPerMeet,
              mentorImageUrl: '', // Gunakan string kosong karena belum ada foto
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to order: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka halaman order: $e')),
        );
      }
    }
  }
}
