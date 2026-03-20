import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  LatLng? pickedLocation;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  // ✅ Get User Current Location
  Future<void> getCurrentLocation() async {
    Location location = Location();

    // Service enabled?
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    // Permission granted?
    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission != PermissionStatus.granted) return;
    }

    // Current location
    final current = await location.getLocation();

    setState(() {
      pickedLocation = LatLng(current.latitude!, current.longitude!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Shop Location"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (pickedLocation != null) {
                Navigator.pop(context, pickedLocation);
              }
            },
          ),
        ],
      ),

      body: pickedLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: pickedLocation!,
                zoom: 15,
              ),

              // Tap to Pick Location
              onTap: (pos) {
                setState(() {
                  pickedLocation = pos;
                });
              },

              markers: {
                Marker(
                  markerId: const MarkerId("shopLocation"),
                  position: pickedLocation!,
                ),
              },
            ),
    );
  }
}
