import 'dart:ui';
import 'package:digishop/pages/login_page.dart';
import 'package:flutter/material.dart';

// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Pages
// import 'package:digishop/pages/clothes_shops.dart';
// import 'package:digishop/pages/grocery_page.dart';
// import 'package:digishop/pages/hotels_page.dart';
// import 'package:digishop/pages/mobile_page.dart';
// import 'package:digishop/pages/restaurant_page.dart';
// import 'package:digishop/pages/shoes_page.dart';
import 'package:digishop/pages/category_shops_page.dart';
import 'package:digishop/pages/edit_profile_page.dart';

class MyLogin extends StatefulWidget {
  const MyLogin({super.key});

  @override
  State<MyLogin> createState() => MyLoginState();
}

class MyLoginState extends State<MyLogin> {
  final TextEditingController searchController = TextEditingController();

  // --------------------------------------------------
  // ✅ Glass Profile Bottom Sheet
  // --------------------------------------------------
  void showUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    DocumentSnapshot userData = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    String name = userData["name"] ?? "User";
    String email = userData["email"] ?? "No Email";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // ✅ allows full height
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45, // opens 45%
          minChildSize: 0.30,
          maxChildSize: 0.80, // user can drag up
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: double.infinity, // ✅ FULL WIDTH
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),

                  // ✅ Scrollable content
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag Handle
                          Container(
                            height: 5,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Avatar
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.cyanAccent.withOpacity(
                              0.25,
                            ),
                            child: Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Greeting
                          Text(
                            "Hello, $name 👋",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Email
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.65),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Edit Profile Button
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context); // close bottom sheet

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfilePage(),
                                ),
                              );
                            },

                            icon: const Icon(Icons.edit),
                            label: const Text("Edit Profile"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.20),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Logout Button
                          ElevatedButton.icon(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();

                              Navigator.pop(context); // close bottom sheet

                              // ✅ Redirect to Login Page
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("✅ Logged Out Successfully"),
                                ),
                              );
                            },

                            icon: const Icon(Icons.logout),
                            label: const Text("Logout"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------
  // ✅ Category Card Widget
  // --------------------------------------------------
  Widget categoryCard(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 25,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 46, color: Colors.white),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // ✅ MAIN UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final query = searchController.text.toLowerCase();

    final categories = [
      {
        "title": "Restaurant",
        "icon": Icons.restaurant,
        "category": "restaurant",
      },
      {"title": "Clothes", "icon": Icons.checkroom, "category": "clothes"},
      {"title": "Hotel", "icon": Icons.hotel, "category": "hotel"},
      {"title": "Shoes", "icon": Icons.shopping_bag, "category": "shoes"},
      {"title": "Grocery", "icon": Icons.shopping_cart, "category": "grocery"},
      {"title": "Mobile", "icon": Icons.smartphone, "category": "mobile"},
    ];

    final filteredCategories = categories.where((cat) {
      return cat["title"].toString().toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          // ✅ Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/img/bg3.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF050B2C).withOpacity(0.7),
                  Color(0xFF090F3D).withOpacity(0.7),
                ],

                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --------------------------------------------------
                  // ✅ TOP HEADER ROW (Title + Profile Icon)
                  // --------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Digishop",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      // ✅ Glass Profile Button
                      GestureDetector(
                        onTap: showUserProfile,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Find Shops Near You ✨",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),

                  const SizedBox(height: 22),

                  // Search Bar
                  // ✅ Search Bar (Glass + Working)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: Colors.white.withOpacity(0.10),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: TextField(
                      controller: searchController,

                      // ✅ IMPORTANT: Makes Search Work
                      onChanged: (value) {
                        setState(() {}); // refresh UI when typing
                      },

                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search shops...",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white,
                        ),

                        // ✅ Optional Clear Button
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,

                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    "Categories",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Category Grid (Search Working)
                 Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      children: filteredCategories.map((cat) {
                        return categoryCard(
                          cat["icon"] as IconData,
                          cat["title"] as String,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryShopsPage(
                                  category: cat["category"] as String,
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
