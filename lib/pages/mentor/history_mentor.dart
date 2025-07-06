import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/appbar_mentor.dart';
import '../widgets/footer_mentor.dart';

class HistoryMentor extends StatelessWidget {
  final String userName;
  final String userId;
  final String? bidangKeahlian;

  const HistoryMentor({
    super.key,//apa
    required this.userName,
    required this.userId,
    this.bidangKeahlian,
  });

  @override
  Widget build(BuildContext context) {
    return MentorHistoryPage(
      userName: userName,
      userId: userId,
      bidangKeahlian: bidangKeahlian,
    );
  }
}

class MentorHistoryPage extends StatefulWidget {
  final String userName;
  final String userId;
  final String? bidangKeahlian;

  const MentorHistoryPage({
    super.key,
    required this.userName,
    required this.userId,
    this.bidangKeahlian,
  });

  @override
  State<MentorHistoryPage> createState() => _MentorHistoryPageState();
}

class _MentorHistoryPageState extends State<MentorHistoryPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> historyOrders = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistoryOrders();
  }

  Future<void> _loadHistoryOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Ambil pesanan dengan status selesai atau dibatalkan untuk mentor ini
      final QuerySnapshot pesananSnapshot = await FirebaseFirestore.instance
          .collection('pesanan')
          .where('id_mentor', isEqualTo: widget.userId)
          .where('status', whereIn: ['selesai', 'dibatalkan'])
          .orderBy('updated_at', descending: true)
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
        historyOrders = orders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data: $e';
        isLoading = false;
      });
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    
    if (date is Timestamp) {
      final DateTime dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    
    return date.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarMentor(
        userName: widget.userName,
        userId: widget.userId,
        bidangKeahlian: widget.bidangKeahlian,
      ),
      body: Column(
        children: [
          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadHistoryOrders,
              child: isLoading
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
                            onPressed: _loadHistoryOrders,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF80C9FF),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    )
                  : historyOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada riwayat konsultasi',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: historyOrders.length,
                        itemBuilder: (context, index) => _buildHistoryItem(historyOrders[index]),
                      ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadHistoryOrders,
        backgroundColor: const Color(0xFF80C9FF),
        child: const Icon(Icons.refresh),
      ),
      bottomNavigationBar: FooterMentor(
        currentIndex: 2,
        userName: widget.userName,
        userId: widget.userId,
        bidangKeahlian: widget.bidangKeahlian,
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> order) {
    final userData = order['user_data'] as Map<String, dynamic>? ?? {};
    final detailData = order['detail_pesanan'] as Map<String, dynamic>? ?? {};
    final bool isCompleted = order['status'] == 'selesai';
    
    // Dapatkan informasi mata kuliah dari detail pesanan jika ada
    final String mataKuliah = detailData['mata_kuliah'] ?? 'Mata Kuliah';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Avatar client
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[300],
              backgroundImage: userData['foto_url'] != null && userData['foto_url'].toString().isNotEmpty
                  ? NetworkImage(userData['foto_url'])
                  : null,
              child: userData['foto_url'] == null || userData['foto_url'].toString().isEmpty
                  ? const Icon(Icons.person, size: 30, color: Colors.grey)
                  : null,
            ),
            
            const SizedBox(width: 12),
            
            // Informasi konsultasi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData['nama_lengkap'] ?? order['nama_user'] ?? 'Nama Client',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mataKuliah,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order['total_meet'] ?? 1} Jam (${order['durasi_jam'] ?? order['jam_konsultasi'] ?? "13.00-15.00"})',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(order['tanggal_konsultasi'] ?? order['created_at']),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isCompleted ? 'Berhasil' : 'Gagal',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}