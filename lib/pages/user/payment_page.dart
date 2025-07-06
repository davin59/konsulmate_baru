import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PaymentPage extends StatefulWidget {
  final String orderId;
  final int totalAmount;

  const PaymentPage({
    super.key,
    required this.orderId,
    required this.totalAmount,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  File? _imageFile;
  Uint8List? _webImage; // Tambahkan ini
  bool _isUploading = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();
  
  bool _isKodeMode = false;
  final TextEditingController _kodeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
  }

  // Fungsi untuk memilih gambar dari gallery
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 1024,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        if (kIsWeb) {
          // Untuk web, baca bytes
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageFile = null;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _imageFile = File(pickedFile.path);
            _webImage = null;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memilih gambar: $e';
      });
    }
  }

  // Fungsi untuk upload bukti dan update Firestore
  Future<void> _submitPayment() async {
    if (!_isKodeMode && _imageFile == null && _webImage == null) {
      setState(() {
        _errorMessage = 'Silakan pilih bukti pembayaran terlebih dahulu';
      });
      return;
    }
    if (_isKodeMode && _kodeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Silakan masukkan kode pembayaran';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      String? downloadUrl;
      if (!_isKodeMode) {
        if (kIsWeb && _webImage != null) {
          // Untuk web, upload dari Uint8List
          final String fileName = 'bukti_${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('bukti_pembayaran')
              .child(fileName);
          
          final UploadTask uploadTask = storageRef.putData(_webImage!);
          final TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});
          downloadUrl = await taskSnapshot.ref.getDownloadURL();
        } else {
          // 1. Upload bukti ke Firebase Storage
          final String fileName = 'bukti_${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('bukti_pembayaran')
              .child(fileName);
          
          final UploadTask uploadTask = storageRef.putFile(_imageFile!);
          final TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});
          downloadUrl = await taskSnapshot.ref.getDownloadURL();
        }
      }
      
      // Simpan ke Firestore
      await FirebaseFirestore.instance
          .collection('detail_pesanan')
          .doc(widget.orderId)
          .update({
        'pembayaran': {
          if (!_isKodeMode && downloadUrl != null) 'bukti_url': downloadUrl,
          if (_isKodeMode) 'kode_pembayaran': _kodeController.text.trim(),
          'tanggal': FieldValue.serverTimestamp(),
        },
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      // Update status pesanan seperti biasa
      await FirebaseFirestore.instance
          .collection('pesanan')
          .doc(widget.orderId)
          .update({
        'status': 'menunggu_verifikasi_admin',
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      // 4. Tampilkan pesan sukses dan kembali ke halaman sebelumnya
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran berhasil disubmit!')),
        );
        Navigator.pop(context, true); // true menandakan sukses
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Gagal mengunggah bukti pembayaran: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: const Color(0xFF80C9FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header Informasi Pembayaran
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Detail Pembayaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order ID:'),
                        Text(
                          widget.orderId,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran:'),
                        Text(
                          'Rp ${widget.totalAmount}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF80C9FF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instruksi QRIS
            const Text(
              'Scan QRIS di bawah ini untuk melakukan pembayaran',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tampilkan QRIS
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(
                  'assets/images/qris.png',
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 250,
                    height: 250,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Text(
                        'QRIS tidak tersedia',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bagian Upload Bukti
            const Text(
              'Upload Bukti Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Pilihan metode pembayaran
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Upload Gambar'),
                  selected: !_isKodeMode,
                  onSelected: (val) {
                    setState(() {
                      _isKodeMode = false;
                    });
                  },
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Input Kode Pembayaran'),
                  selected: _isKodeMode,
                  onSelected: (val) {
                    setState(() {
                      _isKodeMode = true;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),
            
            // Ganti bagian preview/upload bukti:
            _isKodeMode
              ? TextField(
                  controller: _kodeController,
                  decoration: const InputDecoration(
                    labelText: 'Kode Pembayaran',
                    border: OutlineInputBorder(),
                    hintText: 'Masukkan kode pembayaran dari aplikasi bank/ewallet',
                  ),
                )
              : GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _imageFile == null && _webImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap untuk menambahkan bukti pembayaran',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          )
                        : kIsWeb && _webImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _webImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                  ),
                ),
            
            // Tampilkan error jika ada
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Tombol Submit Pembayaran
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF80C9FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'KONFIRMASI PEMBAYARAN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}