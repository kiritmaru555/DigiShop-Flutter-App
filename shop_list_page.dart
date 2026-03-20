import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/shop_card.dart';

class ShopListPage extends StatefulWidget {
  final String title;
  final String category; // "Restaurant", "Shoes", etc.

  const ShopListPage({super.key, required this.title, required this.category});

  @override
  State<ShopListPage> createState() => _ShopListPageState();
}

class _ShopListPageState extends State<ShopListPage> {
  final TextEditingController searchController = TextEditingController();
  String search = "";

  Position? currentPos;
  bool locationLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => locationLoading = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => locationLoading = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentPos = pos;
        locationLoading = false;
      });
    } catch (_) {
      setState(() => locationLoading = false);
    }
  }

  double? _kmAway(Map<String, dynamic> shop) {
    final latValue = shop['latitude'] ?? shop['lat'];
    final lngValue = shop['longitude'] ?? shop['lng'];

    if (currentPos == null || latValue == null || lngValue == null) return null;

    final lat = (latValue as num).toDouble();
    final lng = (lngValue as num).toDouble();

    final meters = Geolocator.distanceBetween(
      currentPos!.latitude,
      currentPos!.longitude,
      lat,
      lng,
    );

    return meters / 1000;
  }

  Future<void> callShop(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse("tel:$phone");
    await launchUrl(uri);
  }

  Future<void> openMapLatLng(double? lat, double? lng) async {
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Location not available")));
      return;
    }

    final uri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void showShopDetails(Map<String, dynamic> shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final imageUrl = (shop['imageUrl'] ?? "").toString();
        final name = (shop['name'] ?? "Shop").toString();
        final address = (shop['address'] ?? shop['location'] ?? "").toString();
        final phone = (shop['phone'] ?? "").toString();

        final latValue = shop['latitude'] ?? shop['lat'];
        final lngValue = shop['longitude'] ?? shop['lng'];
        final lat = (latValue as num?)?.toDouble();
        final lng = (lngValue as num?)?.toDouble();

        final km = _kmAway(shop);

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.startsWith("http")
                      ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 250,
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(Icons.store, size: 60),
                            ),
                          ),
                        )
                      : Container(
                          height: 250,
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(Icons.store, size: 60),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(address)),
                  ],
                ),
                if (km != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    "${km.toStringAsFixed(2)} km away",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => callShop(phone),
                        icon: const Icon(Icons.call),
                        label: const Text("Call Now"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => openMapLatLng(lat, lng),
                        icon: const Icon(Icons.map),
                        label: const Text("View Map"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection("shops")
        .where("category", isEqualTo: widget.category);

    return Scaffold(
      appBar: AppBar(title: const Text("🔥 FIRESTORE SHOP LIST")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: (v) => setState(() => search = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search ${widget.title}",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (locationLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                "Getting your location...",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final docs = snapshot.data?.docs ?? [];

                final shops = docs
                    .map((d) => d.data() as Map<String, dynamic>)
                    .where((shop) {
                      final name = (shop['name'] ?? "")
                          .toString()
                          .toLowerCase();
                      return search.isEmpty || name.contains(search);
                    })
                    .toList();

                if (shops.isEmpty) {
                  return const Center(child: Text("No shops found"));
                }

                if (currentPos != null) {
                  shops.sort((a, b) {
                    final akm = _kmAway(a) ?? 999999;
                    final bkm = _kmAway(b) ?? 999999;
                    return akm.compareTo(bkm);
                  });
                }

                return ListView.builder(
                  itemCount: shops.length,
                  itemBuilder: (context, index) {
                    final shop = shops[index];

                    final address = (shop['address'] ?? shop['location'] ?? "")
                        .toString();
                    final km = _kmAway(shop);
                    final distanceText = km == null
                        ? "Distance unavailable"
                        : "${km.toStringAsFixed(2)} km away";

                    return ShopCard(
                      name: (shop['name'] ?? "").toString(),
                      address: address,
                      distanceText: distanceText,
                      imagePath: (shop['imageUrl'] ?? "").toString(),
                      onTap: () => showShopDetails(shop),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
