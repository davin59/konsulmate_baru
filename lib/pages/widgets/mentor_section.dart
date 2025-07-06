import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MentorCard extends StatelessWidget {
  final Map<String, dynamic> mentor;
  final Function()? onTap;
  
  const MentorCard({
    super.key,
    required this.mentor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(50),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue[200],
                  child: Text(
                    mentor['nama_lengkap'] != null && mentor['nama_lengkap'].toString().isNotEmpty
                        ? mentor['nama_lengkap'][0]
                        : "?",
                    style: const TextStyle(fontSize: 28, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mentor['nama_lengkap'] ?? "Tidak Ada Nama",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                mentor['asal_kampus'] ?? "Tidak Ada Kampus",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                mentor['prodi'] ?? "Tidak Ada Prodi",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                mentor['keahlian'] ?? "Tidak Ada Keahlian",
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  Text(
                    (mentor['rating'] ?? 0.0).toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MentorSection extends StatelessWidget {
  final String title;
  final String? kategori;
  final Function(String mentorId)? onMentorTap;  // Tambahkan ini
  
  const MentorSection({
    super.key,
    required this.title,
    this.kategori,
    this.onMentorTap,  // Tambahkan ini
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.lightBlue[300],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        _buildMentorList(),
      ],
    );
  }
  
  Widget _buildMentorList() {
    // Buat query dasar
    Query query = FirebaseFirestore.instance.collection('mentors');
    
    // Tambahkan filter berdasarkan kategori jika disediakan
    if (kategori != null && kategori!.isNotEmpty) {
      // Asumsi keahlian adalah string yang mengandung kata kunci
      query = query.where('keahlian', isEqualTo: kategori);
    }
    
    // Sortir berdasarkan rating tertinggi jika ada
    // Atau ambil default 5 mentor saja
    query = query.limit(5);
    
    return SizedBox(
      height: 220,
      child: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Tidak ada mentor'));
          }
          
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length > 5 ? 5 : docs.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              final mentor = docs[index].data() as Map<String, dynamic>;
              // Tambahkan ID document ke map untuk referensi
              mentor['id'] = docs[index].id;
              return MentorCard(
                mentor: mentor,
                onTap: () {
                  if (onMentorTap != null) {
                    onMentorTap!(mentor['id']);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Widget untuk filter keahlian lebih spesifik
class FilteredMentorSection extends StatelessWidget {
  final String title;
  final List<String> keywords;
  final Function(String mentorId)? onMentorTap;  // Tambahkan ini
  
  const FilteredMentorSection({
    super.key,
    required this.title,
    required this.keywords,
    this.onMentorTap,  // Tambahkan ini
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.lightBlue[300],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        _buildMentorList(context),
      ],
    );
  }
  
  Widget _buildMentorList(BuildContext context) {
    return SizedBox(
      height: 220,
      child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('mentors')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Tidak ada mentor'));
          }
          
          // Filter mentor berdasarkan keywords
          final filteredMentors = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final keahlian = data['keahlian'] ?? '';
            
            // Cek jika keahlian mengandung salah satu keyword
            return keywords.any((keyword) => 
                keahlian.toString().toLowerCase().contains(keyword.toLowerCase()));
          }).toList();
          
          if (filteredMentors.isEmpty) {
            return const Center(child: Text('Tidak ada mentor untuk kategori ini'));
          }
          
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filteredMentors.length > 5 ? 5 : filteredMentors.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              final mentor = filteredMentors[index].data() as Map<String, dynamic>;
              mentor['id'] = filteredMentors[index].id;
              return MentorCard(
                mentor: mentor,
                onTap: () {
                  if (onMentorTap != null) {
                    onMentorTap!(mentor['id']);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}