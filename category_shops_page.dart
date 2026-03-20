import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:geolocator/geolocator.dart';

class CategoryShopsPage extends StatefulWidget {
  final String category;

  const CategoryShopsPage({super.key, required this.category});

  @override
  State<CategoryShopsPage> createState() => _CategoryShopsPageState();
}

class _CategoryShopsPageState extends State<CategoryShopsPage> {
  final TextEditingController searchController = TextEditingController();
  String searchText = "";

  Position? userPosition;
  bool locationLoaded = false;

  @override
  void initState() {
    super.initState();
    getUserLocation();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ✅ Get User Location (safe)
  Future<void> getUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => locationLoaded = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => locationLoaded = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        userPosition = pos;
        locationLoaded = true;
      });
    } catch (_) {
      // location fail -> list still works
      if (!mounted) return;
      setState(() => locationLoaded = false);
    }
  }

  // ✅ Distance Calculator
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  // 📞 Call Shop
  Future<void> callShop(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) return;
    final Uri uri = Uri.parse("tel:$phoneNumber");
    await launchUrl(uri);
  }

  // 📍 Open Google Map (reliable)
  Future<void> openMap(double lat, double lng) async {
    if (lat == 0 || lng == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shop location not available")),
      );
      return;
    }

    final Uri uri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ❤️ Toggle Favorite
  Future<void> toggleFavorite(String shopId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to use favorites")),
      );
      return;
    }

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(shopId);

    final doc = await favRef.get();

    if (doc.exists) {
      await favRef.delete();
    } else {
      await favRef.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }

  // ⭐ Submit Rating (avg + count)
  Future<void> submitRating(String shopId, double newRating) async {
    final ref = FirebaseFirestore.instance.collection('shops').doc(shopId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;

      final double oldAvg = ((data['Rating'] ?? data['rating'] ?? 0) as num)
          .toDouble();
      final int oldCount = ((data['ratingCount'] ?? 0) as num).toInt();

      final int newCount = oldCount + 1;
      final double updatedAvg = ((oldAvg * oldCount) + newRating) / newCount;

      tx.update(ref, {
        'Rating': updatedAvg, // supports old DB
        'rating': updatedAvg, // supports new DB
        'ratingCount': newCount,
      });
    });
  }

  // ✅ Convert Firestore doc into safe fields (supports old + new)
  Map<String, dynamic> parseShop(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});

    String name = (data['Shop Name'] ?? data['name'] ?? 'Shop').toString();

    // ✅ supports: address (new) + Address + location (old)
    String location =
        (data['address'] ?? data['Address'] ?? data['location'] ?? '')
            .toString();

    String phone = (data['Phone'] ?? data['phone'] ?? '').toString();
    String openTime = (data['Open Time'] ?? data['openTime'] ?? '9 AM - 10 PM')
        .toString();

    String imageUrl = (data['imageUrl'] ?? data['image'] ?? '').toString();

    // category may be "Category" or "category"
    String category = (data['Category'] ?? data['category'] ?? '').toString();

    double lat = 0.0;
    double lng = 0.0;

    // ✅ support: latitude/longitude (new) + lat/lng + Lat/Lng (old)
    final latVal = data['latitude'] ?? data['lat'] ?? data['Lat'];
    final lngVal = data['longitude'] ?? data['lng'] ?? data['Lng'];

    if (latVal is num) lat = latVal.toDouble();
    if (lngVal is num) lng = lngVal.toDouble();

    double rating = 0.0;
    final rVal = data['Rating'] ?? data['rating'];
    if (rVal is num) rating = rVal.toDouble();

    return {
      'id': doc.id,
      'name': name,
      'location': location,
      'phone': phone,
      'openTime': openTime,
      'imageUrl': imageUrl,
      'category': category,
      'lat': lat,
      'lng': lng,
      'rating': rating,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.category.toUpperCase()} Shops"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: getUserLocation,
            icon: const Icon(Icons.my_location),
            tooltip: "Refresh location",
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase().trim();
                });
              },
              decoration: InputDecoration(
                hintText: "Search shop...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          if (!locationLoaded)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                "Location not available (distance will hide)",
                style: TextStyle(color: Colors.grey),
              ),
            ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // ✅ Better: filter by category in query (faster)
              stream: FirebaseFirestore.instance
                  .collection("shops")
                  .snapshots(),
              builder: (context, shopSnapshot) {
                if (shopSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (shopSnapshot.hasError) {
                  return Center(child: Text("Error: ${shopSnapshot.error}"));
                }

                final docs = shopSnapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text("No shops found"));
                }

                if (user == null) {
                  return buildShopList(docs, const []);
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('favorites')
                      .snapshots(),
                  builder: (context, favSnapshot) {
                    List<String> favoriteIds = [];
                    if (favSnapshot.hasData) {
                      favoriteIds = favSnapshot.data!.docs
                          .map((e) => e.id)
                          .toList();
                    }
                    return buildShopList(docs, favoriteIds);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildShopList(
    List<QueryDocumentSnapshot> docs,
    List<String> favoriteIds,
  ) {
    final targetCategory = widget.category.toLowerCase().trim();

    // ✅ parse + filter (search only, category already filtered in query)
    final shops = docs.map(parseShop).where((shop) {
      final dbCategory = (shop['category'] ?? '')
          .toString()
          .toLowerCase()
          .trim();
      final name = (shop['name'] ?? '').toString().toLowerCase();

      final categoryMatch = dbCategory == targetCategory;
      final searchMatch = searchText.isEmpty ? true : name.contains(searchText);

      return categoryMatch && searchMatch;
    }).toList();

    if (shops.isEmpty) {
      return const Center(child: Text("No shops found in this category"));
    }

    // ⭐ sort favorites first, then nearest (if location available)
    shops.sort((a, b) {
      final aFav = favoriteIds.contains(a['id']);
      final bFav = favoriteIds.contains(b['id']);

      if (aFav && !bFav) return -1;
      if (!aFav && bFav) return 1;

      if (locationLoaded && userPosition != null) {
        final double aLat = (a['lat'] ?? 0.0) as double;
        final double aLng = (a['lng'] ?? 0.0) as double;
        final double bLat = (b['lat'] ?? 0.0) as double;
        final double bLng = (b['lng'] ?? 0.0) as double;

        if (aLat != 0 && aLng != 0 && bLat != 0 && bLng != 0) {
          final da = calculateDistance(
            userPosition!.latitude,
            userPosition!.longitude,
            aLat,
            aLng,
          );
          final db = calculateDistance(
            userPosition!.latitude,
            userPosition!.longitude,
            bLat,
            bLng,
          );
          return da.compareTo(db);
        }
      }
      return 0;
    });

    return ListView.builder(
      itemCount: shops.length,
      itemBuilder: (context, index) {
        final shop = shops[index];
        final isFav = favoriteIds.contains(shop['id']);

        final String name = (shop['name'] ?? 'Shop').toString();
        final String location = (shop['location'] ?? '').toString();
        final String imageUrl = (shop['imageUrl'] ?? '').toString();
        final String phone = (shop['phone'] ?? '').toString();
        final String openTime = (shop['openTime'] ?? '9 AM - 10 PM').toString();

        final double lat = (shop['lat'] ?? 0.0) as double;
        final double lng = (shop['lng'] ?? 0.0) as double;

        double? distance;
        if (locationLoaded && userPosition != null && lat != 0 && lng != 0) {
          distance = calculateDistance(
            userPosition!.latitude,
            userPosition!.longitude,
            lat,
            lng,
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 4,
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 55,
                          height: 55,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.store),
                        ),
                      )
                    : Container(
                        width: 55,
                        height: 55,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.store),
                      ),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (location.isNotEmpty) Text(location),
                  if (distance != null)
                    Text(
                      "${distance.toStringAsFixed(2)} km away",
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : Colors.grey,
                ),
                onPressed: () => toggleFavorite(shop['id']),
              ),
              onTap: () {
                showShopDetailsBottomSheet(
                  context: context,
                  shopId: shop['id'],
                  name: name,
                  location: location,
                  phone: phone,
                  openTime: openTime,
                  imageUrl: imageUrl,
                  lat: lat,
                  lng: lng,
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ✅ Bottom Sheet UI (rating + rate + call + map)
  void showShopDetailsBottomSheet({
    required BuildContext context,
    required String shopId,
    required String name,
    required String location,
    required String phone,
    required String openTime,
    required String imageUrl,
    required double lat,
    required double lng,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.store, size: 60),
                          ),
                        )
                      : Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.store, size: 60),
                        ),
                ),

                const SizedBox(height: 15),

                // Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // Location
                if (location.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(child: Text(location)),
                    ],
                  ),

                const SizedBox(height: 10),

                // Open Time
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text("Open: $openTime"),
                  ],
                ),

                const SizedBox(height: 10),

                // Live Rating from Firestore
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('shops')
                      .doc(shopId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    final data =
                        (snapshot.data!.data() as Map<String, dynamic>? ?? {});
                    final double avgRating =
                        ((data['Rating'] ?? data['rating'] ?? 0) as num)
                            .toDouble();

                    return Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          "Rating: ${avgRating.toStringAsFixed(1)}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 15),

                const Text(
                  "Rate this shop",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                // Rating Bar
                RatingBar.builder(
                  initialRating: 0,
                  minRating: 1,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 30,
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) async {
                    await submitRating(shopId, rating);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Thanks for rating!")),
                      );
                    }
                  },
                ),

                const SizedBox(height: 25),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () => callShop(phone),
                        icon: const Icon(Icons.call),
                        label: const Text("Call"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () => openMap(lat, lng),
                        icon: const Icon(Icons.map),
                        label: const Text("Map"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
