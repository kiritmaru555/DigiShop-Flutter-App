import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'location_picker_page.dart';

class TestPickLocation extends StatefulWidget {
  const TestPickLocation({super.key});

  @override
  State<TestPickLocation> createState() => _TestPickLocationState();
}

class _TestPickLocationState extends State<TestPickLocation> {
  LatLng? selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Owner Location Test")),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Pick Shop Location"),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationPickerPage()),
                );

                if (result != null) {
                  setState(() {
                    selected = result;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            if (selected != null)
              Text(
                "Lat: ${selected!.latitude}\nLng: ${selected!.longitude}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
