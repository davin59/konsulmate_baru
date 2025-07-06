// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../widgets/appbar_user.dart';
import '../widgets/footer_user.dart';
import '../widgets/mentor_section.dart';
import 'mentor_detail_page.dart';
import '../widgets/search_bar.dart';

class HomeUser extends StatefulWidget {
  final String userName;
  final String userId;
  final String asalKampus;
  const HomeUser({
    super.key,
    required this.userName,
    required this.userId,
    this.asalKampus = "",
  });

  @override
  State<HomeUser> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<HomeUser> {
  @override
  void initState() {
    super.initState();
  }

  // Tambahkan metode navigasi
  void _navigateToMentorDetail(String mentorId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MentorDetailPage(
          mentorId: mentorId,
          userId: widget.userId,
          userName: widget.userName,
          asalKampus: widget.asalKampus,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          AppBarUser(
            userName: widget.userName,
            userId: widget.userId,
            asalKampus: widget.asalKampus,
          ),
          
          // Tambahkan SearchBar di sini
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: CustomSearchBar(
              userName: widget.userName,
              userId: widget.userId,
            ),
          ),
          
          // Top Mentors
          MentorSection(
            title: 'Top Mentor',
            onMentorTap: _navigateToMentorDetail,
          ),
          
          // Raja Matematika - hapus const
          FilteredMentorSection(
            title: 'Raja Matematika',
            keywords: ['matematika', 'kalkulus', 'statistik'],
            onMentorTap: _navigateToMentorDetail,
          ),
          
          // Jago Ngoding - hapus const
          FilteredMentorSection(
            title: 'Jago Ngoding',
            keywords: ['programming', 'web', 'android', 'informatika'],
            onMentorTap: _navigateToMentorDetail,
          ),
          
          // Pebisnis - hapus const
          FilteredMentorSection(
            title: 'Pebisnis',
            keywords: ['bisnis', 'manajemen', 'wirausaha'],
            onMentorTap: _navigateToMentorDetail,
          ),
        ],
      ),
      bottomNavigationBar: FooterUser(
        currentIndex: 0,
        userName: widget.userName,
        userId: widget.userId, 
        asalKampus: widget.asalKampus,
      ),
    );
  }
}