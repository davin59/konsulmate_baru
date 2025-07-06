import 'package:flutter/material.dart';
import '../user/search_page.dart';

class CustomSearchBar extends StatelessWidget {
  final String userName;
  final String userId;
  final TextEditingController? controller;
  final Function(String)? onSearchChanged;
  final VoidCallback? onFilterTap;
  final bool isOnSearchPage;
  
  const CustomSearchBar({
    super.key,
    required this.userName,
    required this.userId,
    this.controller,
    this.onSearchChanged,
    this.onFilterTap,
    this.isOnSearchPage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: isOnSearchPage && controller != null
                  ? TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Cari mentor...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: onSearchChanged,
                    )
                  : InkWell(
                      onTap: () {
                        if (!isOnSearchPage) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchPage(
                                userName: userName,
                                userId: userId,
                              ),
                            ),
                          );
                        }
                      },
                      child: const Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                            child: Icon(Icons.search, color: Colors.grey),
                          ),
                          Text(
                            'Cari mentor...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isOnSearchPage ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.blue[700],
            ),
            onPressed: onFilterTap ?? () {
              if (!isOnSearchPage) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchPage(
                      userName: userName,
                      userId: userId,
                      showFilters: true,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}