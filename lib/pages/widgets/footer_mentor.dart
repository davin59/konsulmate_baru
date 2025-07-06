import 'package:flutter/material.dart';
import '../mentor/homepage_mentor.dart';
import '../mentor/listchat_mentor.dart';
import '../mentor/history_mentor.dart';

class FooterMentor extends StatelessWidget {
  final int currentIndex;
  final String userName;
  final String userId;
  final String? bidangKeahlian;

  const FooterMentor({
    super.key,
    required this.currentIndex,
    required this.userName,
    required this.userId,
    this.bidangKeahlian,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(context, index),
        selectedItemColor: const Color(0xFF80C9FF),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget page;
    
    switch (index) {
      case 0:
        page = HomepageMentor(userName: userName, userId: userId);
        break;
      case 1:
        page = ListChatMentor(userName: userName, userId: userId);
        break;
      case 2:
        page = HistoryMentor(userName: userName, userId: userId);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}