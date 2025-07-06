import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifikasiDetail extends StatefulWidget {
  final Map<String, dynamic> paymentData;
  final String adminId;
  final String adminName;

  const VerifikasiDetail({
    super.key,
    required this.paymentData,
    required this.adminId,
    required this.adminName,
  });

  @override
  State<VerifikasiDetail> createState() => _VerifikasiDetailState();
}

class _VerifikasiDetailState extends State<VerifikasiDetail> {
  final TextEditingController _catatanController = TextEditingController();
  bool isVerifying = false;

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _verifyPayment(bool isApproved) async {
    final String catatan = _catatanController.text.trim();
    
    // Konfirmasi keputusan admin
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApproved ? 'Verifikasi Pembayaran' : 'Tolak Pembayaran'),
        content: Text(
          isApproved
              ? 'Anda yakin pembayaran ini valid dan akan dikonfirmasi?'
              : 'Anda yakin akan menolak pembayaran ini?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproved ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isApproved ? 'Konfirmasi' : 'Tolak'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      isVerifying = true;
    });

    try {
      final String orderId = widget.paymentData['id'];
      
      // 1. Update detail_pesanan
      await FirebaseFirestore.instance
          .collection('detail_pesanan')
          .doc(orderId)
          .update({
        'verifikasi_admin': {
          'status': isApproved ? 'approved' : 'rejected',
          'tanggal': FieldValue.serverTimestamp(),
          'catatan': catatan,
          'admin_id': widget.adminId,
          'admin_name': widget.adminName,
        },
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      // 2. Update status pesanan
      await FirebaseFirestore.instance
          .collection('pesanan')
          .doc(orderId)
          .update({
        'status': isApproved ? 'terkonfirmasi' : 'dibatalkan',
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApproved 
              ? 'Pembayaran berhasil diverifikasi' 
              : 'Pembayaran ditolak'),
            backgroundColor: isApproved ? Colors.green : Colors.red,
          ),
        );
        Navigator.of(context).pop(true); // Kembali dengan result true
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isVerifying = false;
        });
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    
    if (date is Timestamp) {
      final DateTime dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
    }
    
    return date.toString();
  }

  @override
  Widget build(BuildContext context) {
    final buktiUrl = widget.paymentData['bukti_url'];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pembayaran'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: isVerifying
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informasi Order
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Order',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _buildInfoRow('Order ID', widget.paymentData['id']),
                          _buildInfoRow('User', widget.paymentData['nama_user'] ?? '-'),
                          _buildInfoRow('Mentor', widget.paymentData['nama_mentor'] ?? '-'),
                          _buildInfoRow('Total Harga', 'Rp ${widget.paymentData['total_harga'] ?? 0}'),
                          _buildInfoRow('Tanggal Order', _formatDate(widget.paymentData['created_at'])),
                          _buildInfoRow('Tanggal Bayar', _formatDate(widget.paymentData['tanggal_bayar'])),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Bukti Pembayaran
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bukti Pembayaran',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          if (buktiUrl != null && buktiUrl.toString().isNotEmpty)
                            Container(
                              constraints: const BoxConstraints(maxHeight: 300),
                              width: double.infinity,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  buktiUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.broken_image,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Error loading image: $error',
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            )
                          else
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  'Bukti pembayaran tidak tersedia',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Catatan Admin
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Catatan Verifikasi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          TextField(
                            controller: _catatanController,
                            decoration: const InputDecoration(
                              hintText: 'Catatan untuk user dan mentor (opsional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Tombol Verifikasi
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _verifyPayment(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.close),
                          label: const Text('TOLAK'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _verifyPayment(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('VERIFIKASI'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}