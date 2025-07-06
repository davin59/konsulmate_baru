import 'package:flutter/material.dart';
import 'button_action_mentor_card.dart';

class MentorDetailCard extends StatelessWidget {
  final String mentorName;
  final String mentorImageUrl;
  final String expertise;
  final int pricePerHour;
  final List<String> skills;
  final List<String> technologies;
  final String university;
  final double rating;
  final int orderCount;
  final String about;
  final VoidCallback? onTentukanWaktuPressed; // Tambahkan parameter ini

  const MentorDetailCard({
    super.key,
    required this.mentorName,
    required this.mentorImageUrl,
    required this.expertise,
    required this.pricePerHour,
    required this.skills,
    required this.technologies,
    required this.university,
    required this.rating,
    required this.orderCount,
    required this.about,
    this.onTentukanWaktuPressed, // Tambahkan parameter ini
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header dengan foto dan tombol kembali
        Container(
          color: const Color(0xFF87CEEB),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              // Tombol back
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 16),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Foto profil
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                backgroundImage: mentorImageUrl.isNotEmpty
                    ? NetworkImage(mentorImageUrl)
                    : null,
                child: mentorImageUrl.isEmpty
                    ? const Icon(Icons.person, size: 60, color: Color(0xFF87CEEB))
                    : null,
              ),
            ],
          ),
        ),
        
        // Nama mentor dan tombol Tentukan Waktu
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  mentorName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: onTentukanWaktuPressed, // Gunakan callback
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Tentukan Waktu',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        
        // Card Informasi Mentor
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF87CEEB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bidang keahlian
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF87CEEB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Text(
                    expertise,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              ),
              
              // Detail info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Harga per jam
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                        children: [
                          const TextSpan(text: 'Rp. '),
                          TextSpan(
                            text: '${pricePerHour.toString()} ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: '/ meets'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Skills
                    _buildInfoRow(Icons.check_circle_outline, skills.join(', ')),
                    
                    // Technologies
                    _buildInfoRow(Icons.code, technologies.join(', ')),
                    
                    // University
                    _buildInfoRow(Icons.school, university),
                    
                    const Divider(color: Colors.white),
                    
                    // Rating and Orders
                    Row(
                      children: [
                        const Text(
                          'Rate: ',
                          style: TextStyle(color: Colors.white),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              rating.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.white
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'Order: $orderCount',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // About Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tentang Saya',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF87CEEB),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                about,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Button actions
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ButtonActionMentorCard(),
        ),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}