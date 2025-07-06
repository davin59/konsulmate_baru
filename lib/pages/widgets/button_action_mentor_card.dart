import 'package:flutter/material.dart';

class ButtonActionMentorCard extends StatelessWidget {
  const ButtonActionMentorCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF87CEEB), // Warna biru muda
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Tombol Chat
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
            onPressed: () {
              // Fungsi chat akan diimplementasikan nanti
            },
          ),
          
          // Pembatas
          Container(
            height: 30,
            width: 1,
            color: Colors.white.withOpacity(0.5),
          ),
          
          // Tombol Add
          _buildActionButton(
            icon: Icons.add,
            label: 'Add',
            onPressed: () {
              // Fungsi add akan diimplementasikan nanti
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF87CEEB),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF87CEEB),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}