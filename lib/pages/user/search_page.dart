import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/appbar_user.dart';
import '../widgets/footer_user.dart';
import '../widgets/mentor_section.dart';
import '../widgets/search_bar.dart';
import 'mentor_detail_page.dart'; 
class SearchPage extends StatefulWidget {
  final String userName;
  final String userId;
  final String asalKampus;
  final bool showFilters;

// Ubah constructor SearchPage

const SearchPage({
  super.key,  
  required this.userName,
  required this.userId,
  this.asalKampus = "",
  this.showFilters = false,
});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredMentors = [];
  String activeFilter = 'Semua';
  bool isLoading = true;
  bool showAllFilters = false;

  // Daftar semua filter yang tersedia
  final List<String> allFilters = [
    'Semua',
    'Matematika',
    'Bisnis',
    'Coding',
    'Manajemen',
    'Ilmu Komputer',
    'Arduino',
    'Ekonomi',
    'Kotlin',
  ];

  // Filter yang ditampilkan secara default
  List<String> get defaultFilters => ['Semua', 'Matematika', 'Bisnis'];

  // Filter yang akan ditampilkan
  List<String> get visibleFilters =>
      showAllFilters ? allFilters : defaultFilters;

  @override
  void initState() {
    super.initState();
    // Set showAllFilters berdasarkan parameter
    if (widget.showFilters) {
      showAllFilters = true;
    }
    loadMentorsFromFirebase();
  }

  Future<void> loadMentorsFromFirebase({String searchQuery = ''}) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Base query dari Firebase
      Query mentorsQuery = FirebaseFirestore.instance.collection('mentors');

      // Ambil semua data untuk client-side filtering
      final QuerySnapshot snapshot = await mentorsQuery.get();

      // Konversi snapshot ke list of maps
      List<Map<String, dynamic>> mentorList = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Tambahkan document ID ke data
        return data;
      }).toList();

      // Filter berdasarkan pencarian teks jika ada
      if (searchQuery.isNotEmpty) {
        final lowercaseQuery = searchQuery.toLowerCase();
        mentorList = mentorList.where((mentor) {
          final name = mentor['nama_lengkap']?.toString().toLowerCase() ?? '';
          final expertise = mentor['keahlian']?.toString().toLowerCase() ?? '';
          final campus = mentor['asal_kampus']?.toString().toLowerCase() ?? '';
          final prodi = mentor['prodi']?.toString().toLowerCase() ?? '';

          return name.contains(lowercaseQuery) ||
              expertise.contains(lowercaseQuery) ||
              campus.contains(lowercaseQuery) ||
              prodi.contains(lowercaseQuery);
        }).toList();
      }

      // Filter berdasarkan kategori yang dipilih
      if (activeFilter != 'Semua') {
        mentorList = filterByCategory(mentorList, activeFilter);
      }

      setState(() {
        filteredMentors = mentorList;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading mentor data: $e');
      setState(() {
        isLoading = false;
        filteredMentors = [];
      });
    }
  }

  List<Map<String, dynamic>> filterByCategory(
      List<Map<String, dynamic>> mentors, String category) {
    return mentors.where((mentor) {
      final expertise = mentor['keahlian']?.toString().toLowerCase() ?? '';
      final prodi = mentor['prodi']?.toString().toLowerCase() ?? '';
      final tools = mentor['tools']?.toString().toLowerCase() ?? '';

      switch (category) {
        case 'Matematika':
          return expertise.contains('matematika') ||
              expertise.contains('statistik') ||
              expertise.contains('kalkulus') ||
              prodi.contains('matematika');
        case 'Bisnis':
          return expertise.contains('bisnis') ||
              prodi.contains('bisnis') ||
              expertise.contains('startup');
        case 'Coding':
          return expertise.contains('coding') ||
              expertise.contains('programming') ||
              expertise.contains('development');
        case 'Manajemen':
          return expertise.contains('manajemen') ||
              prodi.contains('manajemen');
        case 'Ilmu Komputer':
          return prodi.contains('ilmu komputer') ||
              prodi.contains('informatika');
        case 'Arduino':
          return expertise.contains('arduino') ||
              expertise.contains('iot') ||
              tools.contains('arduino');
        case 'Ekonomi':
          return prodi.contains('ekonomi') ||
              expertise.contains('ekonomi') ||
              expertise.contains('keuangan');
        case 'Kotlin':
          return expertise.contains('kotlin') ||
              expertise.contains('android') ||
              tools.contains('kotlin');
        default:
          return false;
      }
    }).toList();
  }

  void applyFilters() {
    loadMentorsFromFirebase(searchQuery: searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            AppBarUser(
              userName: widget.userName,
              userId: widget.userId,
              asalKampus: widget.asalKampus,
            ),

            // Ganti search input dengan CustomSearchBar
            CustomSearchBar(
              userName: widget.userName,
              userId: widget.userId,
              controller: searchController,
              isOnSearchPage: true,
              onSearchChanged: (value) {
                // Delay pencarian untuk mengurangi query yang terlalu sering
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (value == searchController.text) {
                    applyFilters();
                  }
                });
              },
              onFilterTap: () {
                setState(() {
                  showAllFilters = !showAllFilters;
                });
              },
            ),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children:
                    visibleFilters
                        .map((filter) => _buildFilterChip(filter))
                        .toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Mentor grid
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (filteredMentors.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Tidak ada mentor yang sesuai dengan pencarian',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filteredMentors.length,
                  itemBuilder: (context, index) {
                    return MentorCard(
                      mentor: filteredMentors[index],
                      onTap: () {
                        // Navigate to mentor detail page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MentorDetailPage(
                              mentorId: filteredMentors[index]['id'],
                              userId: widget.userId,
                              userName: widget.userName,
                              asalKampus: widget.asalKampus,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: FooterUser(
        currentIndex: 2,
        userName: widget.userName,
        userId: widget.userId,
        asalKampus: widget.asalKampus,
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isActive = activeFilter == label;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            activeFilter = label;
            applyFilters();
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.blue : Colors.blue.shade200,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Text(label),
      ),
    );
  }
}