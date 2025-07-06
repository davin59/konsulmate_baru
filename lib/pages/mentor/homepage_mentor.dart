import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/appbar_mentor.dart';
import '../widgets/footer_mentor.dart';

class HomepageMentor extends StatelessWidget {
  final String userName;
  final String userId;
  final String? bidangKeahlian;

  const HomepageMentor({
    super.key,
    required this.userName,
    required this.userId,
    this.bidangKeahlian,
  });

  @override
  Widget build(BuildContext context) {
    return MentorHomePage(
      userName: userName,
      userId: userId,
      bidangKeahlian: bidangKeahlian,
    );
  }
}

class MentorHomePage extends StatefulWidget {
  final String userName;
  final String userId;
  final String? bidangKeahlian;

  const MentorHomePage({
    super.key,
    required this.userName,
    required this.userId,
    this.bidangKeahlian,
  });

  @override
  State<MentorHomePage> createState() => _MentorHomePageState();
}

class _MentorHomePageState extends State<MentorHomePage> {
  bool isLoading = true;
  List<Map<String, dynamic>> activeOrders = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActiveOrders();
  }

  Future<void> _loadActiveOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Ambil pesanan aktif untuk mentor ini (status != 'selesai' dan != 'dibatalkan')
      final QuerySnapshot pesananSnapshot = await FirebaseFirestore.instance
          .collection('pesanan')
          .where('id_mentor', isEqualTo: widget.userId)
          .where('status', whereNotIn: ['selesai', 'dibatalkan'])
          .get();

      final List<Map<String, dynamic>> orders = [];

      for (var doc in pesananSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Ambil data user (client)
        if (data['id_user'] != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(data['id_user'])
              .get();
          if (userDoc.exists) {
            data['user_data'] = userDoc.data();
          }
        }

        // Ambil detail pesanan
        final detailDoc = await FirebaseFirestore.instance
            .collection('detail_pesanan')
            .doc(doc.id)
            .get();
        if (detailDoc.exists) {
          data['detail_pesanan'] = detailDoc.data();
        }

        orders.add(data);
      }

      setState(() {
        activeOrders = orders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _handleApproval(String orderId, bool isApproved) async {
    String? note;
    
    // Tampilkan dialog untuk catatan opsional
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApproved ? 'Terima Pesanan' : 'Tolak Pesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Catatan untuk client (opsional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => note = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproved ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        setState(() {
          isLoading = true;
        });
        
        try {
          // 1. Update detail_pesanan
          await FirebaseFirestore.instance
              .collection('detail_pesanan')
              .doc(orderId)
              .update({
            'persetujuan_mentor.status': isApproved ? 'approved' : 'rejected',
            'persetujuan_mentor.tanggal': FieldValue.serverTimestamp(),
            'persetujuan_mentor.catatan': note ?? '',
            'updated_at': FieldValue.serverTimestamp(),
          });
          
          // 2. Update pesanan status
          await FirebaseFirestore.instance
              .collection('pesanan')
              .doc(orderId)
              .update({
            'status': isApproved ? 'menunggu_pembayaran' : 'dibatalkan',
            'updated_at': FieldValue.serverTimestamp(),
          });
          
          // Refresh data setelah update
          _loadActiveOrders();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isApproved 
                ? 'Pesanan diterima, menunggu pembayaran dari client' 
                : 'Pesanan ditolak')),
            );
          }
        } catch (e) {
          setState(() {
            isLoading = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
      }
    });
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    
    if (date is Timestamp) {
      final DateTime dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    
    return date.toString();
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    );
  }

  Widget _buildClientCard(Map<String, dynamic> order) {
    final userData = order['user_data'] as Map<String, dynamic>? ?? {};
    final detailData = order['detail_pesanan'] as Map<String, dynamic>? ?? {};
    final String status = order['status'] ?? 'menunggu_persetujuan_mentor';
    
    // Tampilkan tombol aksi hanya untuk pesanan yang menunggu persetujuan
    final bool showActions = status == 'menunggu_persetujuan_mentor';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar client
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                
                const SizedBox(width: 16),
                
                // Info pesanan
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['nama_lengkap'] ?? order['nama_user'] ?? 'Nama Client',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order['total_meet'] ?? 1} Meet (${order['durasi_jam'] ?? order['total_meet'] ?? 1} Jam)',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(order['tanggal_konsultasi'])} ${order['jam_konsultasi'] ?? ""}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detailData['alamat_meets'] ?? 'Lokasi yang user pesan',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Tambahkan informasi catatan user jika ada
                      if (detailData['catatan_user'] != null && detailData['catatan_user'].toString().isNotEmpty) ...{
                        const SizedBox(height: 4),
                        const Text(
                          'Catatan:',
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          detailData['catatan_user'] ?? '',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      },
                    ],
                  ),
                ),
                
                // Harga
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Rp ${_formatPrice(order['total_harga'] ?? 0)}',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            // Status indicator if not waiting approval
            if (!showActions) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: status == 'menunggu_pembayaran' 
                      ? Colors.blue.shade50 
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status == 'menunggu_pembayaran'
                      ? 'Menunggu pembayaran dari client'
                      : status == 'menunggu_verifikasi_admin'
                          ? 'Menunggu verifikasi pembayaran oleh admin'
                          : status == 'terkonfirmasi'
                              ? 'Pesanan terkonfirmasi'
                              : 'Status: $status',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: status == 'menunggu_pembayaran'
                        ? Colors.blue.shade700
                        : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            
            // Action buttons (hanya jika menunggu persetujuan)
            if (showActions) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => _handleApproval(order['id'], false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Tolak'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _handleApproval(order['id'], true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Ambil'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar
      appBar: AppBarMentor(
        userName: widget.userName,
        userId: widget.userId,
        bidangKeahlian: widget.bidangKeahlian,
      ),
      
      // Body content
      body: RefreshIndicator(
        onRefresh: _loadActiveOrders,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadActiveOrders,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : activeOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/bingung.png',
                              width: 200,
                              height: 200,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.hourglass_empty,
                                size: 100,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Belum ada pesanan yang masuk',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 16, bottom: 16),
                        itemCount: activeOrders.length,
                        itemBuilder: (context, index) => _buildClientCard(activeOrders[index]),
                      ),
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: _loadActiveOrders,
        backgroundColor: const Color(0xFF80C9FF),
        child: const Icon(Icons.refresh),
      ),

      // Footer
      bottomNavigationBar: FooterMentor(
        currentIndex: 0,
        userName: widget.userName,
        userId: widget.userId,
        bidangKeahlian: widget.bidangKeahlian,
      ),
    );
  }
}
