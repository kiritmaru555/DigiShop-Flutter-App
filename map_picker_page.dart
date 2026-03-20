import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng selectedLocation = const LatLng(21.1702, 72.8311);
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick Location")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: selectedLocation,
              zoom: 14,
            ),
            onTap: (latLng) {
              setState(() {
                selectedLocation = latLng;
              });
            },
            onMapCreated: (controller) {
              debugPrint("Map created successfully");
            },
            markers: {
              Marker(
                markerId: const MarkerId("selected"),
                position: selectedLocation,
              ),
            },
          ),

          if (errorMessage != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red,
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, {
            "lat": selectedLocation.latitude,
            "lng": selectedLocation.longitude,
          });
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
