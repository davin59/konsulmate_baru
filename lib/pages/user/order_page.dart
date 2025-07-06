// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/footer_user.dart';

class OrderPage extends StatefulWidget {
  final String userId;
  final String userName;
  final String asalKampus;
  final String mentorId;
  final String mentorName;
  final String mentorProdi;
  final String mentorKeahlian;
  final int hargaPerMeet;
  final String mentorImageUrl;

  const OrderPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.asalKampus,
    required this.mentorId,
    required this.mentorName,
    required this.mentorProdi,
    required this.mentorKeahlian,
    required this.hargaPerMeet,
    this.mentorImageUrl = '',
  });

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 30);
  int totalMeet = 1;
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController catatanController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    int totalHarga = widget.hargaPerMeet * totalMeet;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Konfirmasi Order',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Konfirmasi Mentor ?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Mentor Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(50),
                          spreadRadius: 5,
                          blurRadius: 5,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Mentor Image
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: widget.mentorImageUrl.isNotEmpty
                              ? NetworkImage(widget.mentorImageUrl)
                              : const AssetImage('assets/mentor_avatar.png') as ImageProvider,
                          backgroundColor: Colors.grey.shade200,
                        ),
                        const SizedBox(width: 16),
                        
                        // Mentor Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.mentorName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.mentorProdi,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                widget.mentorKeahlian,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rp. ${NumberFormat('#,###').format(widget.hargaPerMeet)}/meet',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Detail Pesanan Section
                  const Text(
                    'Detail Pesanan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Detail Pesanan Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(50),
                          spreadRadius: 5,
                          blurRadius: 5,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tanggal
                        _buildDetailRow(
                          'Tanggal',
                          DateFormat('dd/MM/yyyy').format(selectedDate),
                          onTap: _selectDate,
                        ),
                        const Divider(),
                        
                        // Jam
                        _buildDetailRow(
                          'Jam',
                          selectedTime.format(context),
                          onTap: _selectTime,
                        ),
                        const Divider(),
                        
                        // Total Meet
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Meet'),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: totalMeet > 1
                                      ? () => setState(() => totalMeet--)
                                      : null,
                                  color: Colors.blue.shade700,
                                ),
                                Text(
                                  '$totalMeet',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => setState(() => totalMeet++),
                                  color: Colors.blue.shade700,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '(1 meet 1 jam)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Divider(),
                        
                        // Total Harga
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Harga'),
                            Text(
                              'Rp.${NumberFormat('#,###').format(totalHarga)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Alamat Meets
                  const Text(
                    'Alamat Meets',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(50),
                          spreadRadius: 5,
                          blurRadius: 5,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: alamatController,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Warmindo Grombyangan',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Catatan 
                  const Text(
                    'Catatan Tambahan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(50),
                          spreadRadius: 5,
                          blurRadius: 5,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: catatanController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Tuliskan permintaan khusus atau catatan lainnya di sini',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _confirmOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
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

  Widget _buildDetailRow(String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: Colors.grey.shade700),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context, // Gunakan context dari state
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context, // Gunakan context dari state
      initialTime: selectedTime,
    );
    
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _confirmOrder() {
    if (alamatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat pertemuan harus diisi')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Pemesanan'),
          content: const Text(
            'Pesanan Anda akan dikirim ke mentor untuk disetujui. Pembayaran dilakukan setelah mentor menyetujui pesanan ini. Lanjutkan?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _submitOrder();
              },
              child: const Text('Lanjutkan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitOrder() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Buat dokumen pesanan baru
      final timestamp = Timestamp.now();
      
      // Format tanggal dan jam untuk field tanggal_konsultasi
      final tanggalKonsultasi = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      
      final totalHarga = widget.hargaPerMeet * totalMeet;
      
      // 1. Tambahkan data ke collection pesanan
      final pesananRef = FirebaseFirestore.instance.collection('pesanan').doc();
      final String pesananId = pesananRef.id;
      
      await pesananRef.set({
        'id_user': widget.userId,
        'nama_user': widget.userName,
        'id_mentor': widget.mentorId,
        'nama_mentor': widget.mentorName,
        'tanggal_pemesanan': timestamp,
        'tanggal_konsultasi': Timestamp.fromDate(tanggalKonsultasi),
        'jam_konsultasi': selectedTime.format(context),
        'total_meet': totalMeet,
        'total_harga': totalHarga,
        'status': 'menunggu_persetujuan_mentor',
        'rating': null,
        'created_at': timestamp,
      });
      
      // 2. Tambahkan data ke collection detail_pesanan
      await FirebaseFirestore.instance
          .collection('detail_pesanan')
          .doc(pesananId)
          .set({
        'alamat_meets': alamatController.text,
        'durasi_per_meet': 60, // 1 jam per meet
        'harga_per_meet': widget.hargaPerMeet,
        'catatan_user': catatanController.text,
        'persetujuan_mentor': {
          'status': 'pending',
          'tanggal': null,
          'catatan': null,
        },
        'pembayaran': {
          'metode': null,
          'status': 'unpaid',
          'bukti_url': null,
          'qris_url': null,
        },
        'persetujuan_admin': {
          'status': 'pending',
          'tanggal': null,
          'catatan': null,
        },
        'updated_at': timestamp,
      });
      
      // Tampilkan pesan sukses dan kembali ke halaman sebelumnya
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil dibuat dan menunggu persetujuan mentor')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      debugPrint('Error submitting order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}