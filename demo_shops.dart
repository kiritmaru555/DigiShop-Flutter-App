import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class DemoShops {
  static final _db = FirebaseFirestore.instance;

  static const List<String> categories = [
    "Restaurant",
    "Clothes",
    "Hotel",
    "Shoes",
    "Grocery",
    "Mobile",
  ];

  // ✅ Cities you want for demo
  static const List<Map<String, dynamic>> cities = [
    {"name": "Rajkot", "lat": 22.3039, "lng": 70.8022},
    {"name": "Junagadh", "lat": 21.5222, "lng": 70.4579},
    {"name": "Porbandar", "lat": 21.6417, "lng": 69.6293},
    {"name": "Ahmedabad", "lat": 23.0225, "lng": 72.5714},
    {"name": "Surat", "lat": 21.1702, "lng": 72.8311},
    // add more if you want (just keep total under your target)
  ];

  /// ✅ Deletes ALL documents in "shops" collection (safe for demo reset)
  /// Runs in batches of 450 deletes
  static Future<void> deleteAllShops() async {
    final col = _db.collection("shops");

    while (true) {
      final snap = await col.limit(450).get();
      if (snap.docs.isEmpty) break;

      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }

    // Also remove guard so you can insert again
    await _db.collection("meta").doc("demoShops_citywise_v1").delete().catchError((_) {});
  }

  /// ✅ Creates city-wise demo shops
  /// Example: 15 per city per category => 5 cities * 6 categories * 15 = 450 shops
  static Future<void> addCityWiseDemoShops({
    int perCityPerCategory = 15,
    int useCities = 5, // use first N cities from list
  }) async {
    final guardRef = _db.collection("meta").doc("demoShops_citywise_v1");
    final guardSnap = await guardRef.get();
    if (guardSnap.exists && (guardSnap.data()?["inserted"] == true)) {
      return; // already inserted
    }

    final selectedCities = cities.take(useCities).toList();
    final total = selectedCities.length * categories.length * perCityPerCategory;

    // We'll write in chunks under 450 to stay far from 500 limit
    final rand = Random(7);

    const imageUrl = {
      "Restaurant": "https://images.unsplash.com/photo-1552566626-52f8b828add9",
      "Clothes": "https://images.unsplash.com/photo-1521334884684-d80222895322",
      "Hotel": "https://images.unsplash.com/photo-1566073771259-6a8506099945",
      "Shoes": "https://images.unsplash.com/photo-1542291026-7eec264c27ff",
      "Grocery": "https://images.unsplash.com/photo-1542838132-92c53300491e",
      "Mobile": "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9",
    };

    const prefix = {
      "Restaurant": ["Spice", "Taste", "Royal", "Curry", "Tandoor"],
      "Clothes": ["Style", "Fashion", "Urban", "Classic", "Trendy"],
      "Hotel": ["Royal", "Grand", "Elite", "City", "Sunrise"],
      "Shoes": ["Foot", "Sole", "Step", "Run", "Walk"],
      "Grocery": ["Fresh", "Daily", "Mart", "Basket", "Choice"],
      "Mobile": ["Tech", "Smart", "Mobile", "Gadget", "Phone"],
    };

    int writeCount = 0;
    WriteBatch batch = _db.batch();

    Future<void> commitAndNewBatch() async {
      await batch.commit();
      batch = _db.batch();
      writeCount = 0;
    }

    for (final city in selectedCities) {
      final cityName = city["name"] as String;
      final baseLat = city["lat"] as double;
      final baseLng = city["lng"] as double;

      for (final cat in categories) {
        for (int i = 1; i <= perCityPerCategory; i++) {
          // keep within ~450 writes per batch
          if (writeCount >= 450) {
            await commitAndNewBatch();
          }

          final word = prefix[cat]![rand.nextInt(prefix[cat]!.length)];
          final shopName = "$word $cat $cityName $i";

          // small variation around city center
          final latitude = baseLat + (rand.nextDouble() * 0.03);
          final longitude = baseLng + (rand.nextDouble() * 0.03);

          final rating = 3.8 + rand.nextDouble() * 1.2;

          // stable unique docId (no duplicates)
          final docId =
              "${cat.toLowerCase()}_${cityName.toLowerCase()}_${i.toString().padLeft(2, '0')}";

          final docRef = _db.collection("shops").doc(docId);

          final data = <String, dynamic>{
            "name": shopName,
            "phone": "+91 90000${(10000 + rand.nextInt(89999)).toString()}",
            "address": "$cityName, Gujarat",
            "category": cat,
            "openTime": cat == "Hotel" ? "00:00 AM" : "10:00 AM",
            "closeTime": cat == "Hotel" ? "11:59 PM" : "09:30 PM",
            "imageUrl": imageUrl[cat],
            "latitude": double.parse(latitude.toStringAsFixed(6)),
            "longitude": double.parse(longitude.toStringAsFixed(6)),
            "createdAt": Timestamp.now(),
            "rating": double.parse(rating.toStringAsFixed(1)),
            "isActive": true,
            "city": cityName, // ✅ extra helpful field for filtering by city
          };

          batch.set(docRef, data, SetOptions(merge: true));
          writeCount++;
        }
      }
    }

    // final commit
    if (writeCount > 0) {
      await batch.commit();
    }

    // mark inserted
    await guardRef.set({
      "inserted": true,
      "total": total,
      "updatedAt": Timestamp.now(),
      "citiesUsed": selectedCities.map((e) => e["name"]).toList(),
      "perCityPerCategory": perCityPerCategory,
    }, SetOptions(merge: true));
  }
}