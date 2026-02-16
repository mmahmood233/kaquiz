import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../../core/constants/app_constants.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await context.read<MapViewModel>().loadFriendsLocations();
    _updateMarkers();
  }

  void _updateMarkers() {
    final mapViewModel = context.read<MapViewModel>();
    final markers = <Marker>{};

    if (mapViewModel.currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('my_location'),
          position: LatLng(
            mapViewModel.currentPosition!.latitude,
            mapViewModel.currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'You'),
        ),
      );
    }

    for (var friend in mapViewModel.friendsWithLocations) {
      if (friend.location != null) {
        markers.add(
          Marker(
            markerId: MarkerId(friend.id),
            position: LatLng(
              friend.location!.latitude,
              friend.location!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: friend.email,
              snippet: 'Last updated: ${_formatTime(friend.location!.lastUpdated)}',
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
      builder: (context, mapViewModel, child) {
        if (mapViewModel.state == MapState.loading && _markers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (mapViewModel.currentPosition == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Location not available',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  onPressed: () {
                    mapViewModel.initializeLocation();
                  },
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  mapViewModel.currentPosition!.latitude,
                  mapViewModel.currentPosition!.longitude,
                ),
                zoom: AppConstants.defaultZoom,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                onPressed: () async {
                  await _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Locations refreshed'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Icon(Icons.refresh),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Blue: You • Red: Friends (${mapViewModel.friendsWithLocations.length})',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
