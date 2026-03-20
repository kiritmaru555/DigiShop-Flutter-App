import 'package:flutter/material.dart';

import 'package:digishop/pages/demo_shops.dart';
class Testpage extends StatefulWidget {
  const Testpage({super.key});

  @override
  State<Testpage> createState() => _TestpageState();
}

class _TestpageState extends State<Testpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                await DemoShops.deleteAllShops();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ All shops deleted")),
                );
              },
              child: const Text("Delete ALL Shops"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                // 5 cities × 6 categories × 15 = 450 shops
                await DemoShops.addCityWiseDemoShops(
                  perCityPerCategory: 15,
                  useCities: 5,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ City-wise demo shops added (450)"),
                  ),
                );
              },
              child: const Text("Insert City-wise Shops (450)"),
            ),
          ],
        ),
      ),
    );
  }
}
