import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'verifikasi_detail.dart'; // Pastikan file ini dibuat;
import '../login_page.dart'; // Import LoginPage

class DashboardAdmin extends StatefulWidget {
  final String adminId;
  final String adminName;

  const DashboardAdmin({
    super.key,
    required this.adminId,
    required this.adminName,
  });

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  bool isLoading = true;
  List<Map<String, dynamic>> pendingPayments = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingPayments();
  }

  Future<void> _loadPendingPayments() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Ambil pesanan dengan status menunggu verifikasi admin
      final QuerySnapshot pesananSnapshot = await FirebaseFirestore.instance
          .collection('pesanan')
          .where('status', isEqualTo: 'menunggu_verifikasi_admin')
          .orderBy('updated_at', descending: true)
          .get();

      final List<Map<String, dynamic>> payments = [];

      for (var doc in pesananSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Ambil detail pesanan (termasuk bukti pembayaran)
        final detailDoc = await FirebaseFirestore.instance
            .collection('detail_pesanan')
            .doc(doc.id)
            .get();

        if (detailDoc.exists) {
          final detailData = detailDoc.data() as Map<String, dynamic>;
          // Menggunakan cara yang aman untuk mengakses nested map
          final pembayaran = detailData['pembayaran'];
          final kodePembayaran = pembayaran != null ? pembayaran['kode_pembayaran'] : null;
          final buktiUrl = pembayaran != null ? pembayaran['bukti_url'] : null;
          final tanggalBayar = pembayaran != null ? pembayaran['tanggal'] : null;

          // Hanya tambahkan jika ada bukti pembayaran atau kode pembayaran
          if (buktiUrl != null || kodePembayaran != null) {
            data['detail_pesanan'] = detailData;
            data['bukti_url'] = buktiUrl;
            data['kode_pembayaran'] = kodePembayaran;
            data['tanggal_bayar'] = tanggalBayar;
            payments.add(data);
          }
        }
      }

      setState(() {
        pendingPayments = payments;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: $e';
        isLoading = false;
      });
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    
    if (date is Timestamp) {
      final DateTime dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    
    return date.toString();
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifikasiDetail(
                paymentData: payment,
                adminId: widget.adminId,
                adminName: widget.adminName,
              ),
            ),
          ).then((_) => _loadPendingPayments()); // Refresh data setelah kembali
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${payment['id']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Menunggu Verifikasi',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('User: ${payment['nama_user'] ?? "Unknown"}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.school_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Mentor: ${payment['nama_mentor'] ?? "Unknown"}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Tanggal Bayar: ${_formatDate(payment['tanggal_bayar'])}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Total: Rp ${payment['total_harga'] ?? 0}'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.image, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('Bukti Pembayaran Tersedia', 
                    style: TextStyle(color: Colors.blue)),
                ],
              ),
              // Tampilkan kode pembayaran jika ada
              if (payment['kode_pembayaran'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.confirmation_number, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Kode Pembayaran: ${payment['kode_pembayaran']}',
                        style: const TextStyle(color: Colors.green)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red[700], fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadPendingPayments,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selamat Datang, ${widget.adminName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Pembayaran: ${pendingPayments.length}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: pendingPayments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 80,
                              color: Colors.green.shade300,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tidak ada pembayaran yang perlu diverifikasi',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: pendingPayments.length,
                        itemBuilder: (context, index) {
                          return _buildPaymentCard(pendingPayments[index]);
                        },
                      ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPendingPayments,
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}