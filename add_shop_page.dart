import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'map_picker_page.dart';

class AdminAddShopPage extends StatefulWidget {
  final String? shopId;
  final Map<String, dynamic>? shopData;

  const AdminAddShopPage({super.key, this.shopId, this.shopData});

  @override
  State<AdminAddShopPage> createState() => _AdminAddShopPageState();
}

class _AdminAddShopPageState extends State<AdminAddShopPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final openTimeController = TextEditingController();
  final closeTimeController = TextEditingController();

  String selectedCategory = "Restaurant";

  File? shopImage;
  bool loading = false;
  String? existingImageUrl;

  double? latitude;
  double? longitude;

  final List<String> categories = [
    "Restaurant",
    "Clothes",
    "Hotel",
    "Shoes",
    "Grocery",
    "Mobile",
  ];

  @override
  void initState() {
    super.initState();

    if (widget.shopData != null) {
      nameController.text = widget.shopData!["name"] ?? "";
      phoneController.text = widget.shopData!["phone"] ?? "";
      addressController.text = widget.shopData!["address"] ?? "";
      openTimeController.text = widget.shopData!["openTime"] ?? "";
      closeTimeController.text = widget.shopData!["closeTime"] ?? "";

      selectedCategory = widget.shopData!["category"] ?? "Restaurant";

      existingImageUrl = widget.shopData!["imageUrl"];

      latitude = widget.shopData!["latitude"];
      longitude = widget.shopData!["longitude"];
    }
  }

  Future pickShopImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        shopImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadImageToStorage() async {
    if (shopImage == null) return existingImageUrl;

    String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    final storageRef = FirebaseStorage.instance.ref().child(
      "shopImages/$fileName.jpg",
    );

    await storageRef.putFile(shopImage!);

    return await storageRef.getDownloadURL();
  }

  Future addOrUpdateShop() async {
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        addressController.text.isEmpty ||
        openTimeController.text.isEmpty ||
        closeTimeController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick shop location from map")),
      );
      return;
    }

    setState(() => loading = true);

    String? imageUrl = await uploadImageToStorage();

    Map<String, dynamic> shopData = {
      "name": nameController.text.trim(),
      "phone": phoneController.text.trim(),
      "address": addressController.text.trim(),
      "category": selectedCategory,
      "openTime": openTimeController.text.trim(),
      "closeTime": closeTimeController.text.trim(),
      "imageUrl": imageUrl,
      "latitude": latitude,
      "longitude": longitude,
      "createdAt": Timestamp.now(),
    };

    if (widget.shopId == null) {
      await FirebaseFirestore.instance.collection("shops").add(shopData);
    } else {
      await FirebaseFirestore.instance
          .collection("shops")
          .doc(widget.shopId)
          .update(shopData);
    }

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.shopId == null
              ? "Shop Added Successfully ✅"
              : "Shop Updated Successfully ✅",
        ),
      ),
    );

    Navigator.pop(context);
  }

  Future pickLocationFromMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerPage()),
    );

    if (result != null) {
      setState(() {
        latitude = result["lat"];
        longitude = result["lng"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shopId == null ? "Add Shop" : "Edit Shop"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickShopImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(15),
                  image: shopImage != null
                      ? DecorationImage(
                          image: FileImage(shopImage!),
                          fit: BoxFit.cover,
                        )
                      : existingImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(existingImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: shopImage == null && existingImageUrl == null
                    ? const Center(child: Text("Tap to Pick Shop Image 📷"))
                    : null,
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Shop Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField(
              value: selectedCategory,
              items: categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Shop Address",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: openTimeController,
              decoration: const InputDecoration(
                labelText: "Opening Time (e.g. 9:00 AM)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: closeTimeController,
              decoration: const InputDecoration(
                labelText: "Closing Time (e.g. 10:00 PM)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: pickLocationFromMap,
              child: Text(
                latitude == null
                    ? "Pick Location From Map"
                    : "Location Selected ✅",
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: loading ? null : addOrUpdateShop,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: loading
                  ? const CircularProgressIndicator()
                  : Text(widget.shopId == null ? "Add Shop" : "Update Shop"),
            ),
          ],
        ),
      ),
    );
  }
}
