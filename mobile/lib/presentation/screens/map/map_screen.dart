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
    
    _fitMapToMarkers();
  }

  void _fitMapToMarkers() {
    if (_mapController == null || _markers.isEmpty) return;

    final bounds = _calculateBounds(_markers);
    if (bounds != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    }
  }

  LatLngBounds? _calculateBounds(Set<Marker> markers) {
    if (markers.isEmpty) return null;

    double? minLat, maxLat, minLng, maxLng;

    for (var marker in markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = minLat == null ? lat : (lat < minLat ? lat : minLat);
      maxLat = maxLat == null ? lat : (lat > maxLat ? lat : maxLat);
      minLng = minLng == null ? lng : (lng < minLng ? lng : minLng);
      maxLng = maxLng == null ? lng : (lng > maxLng ? lng : maxLng);
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
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
              child: Column(
                children: [
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'refresh',
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
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'friends',
                    onPressed: () => _showFriendsList(context, mapViewModel),
                    child: const Icon(Icons.people),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 80,
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

  void _showFriendsList(BuildContext context, MapViewModel mapViewModel) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Friends Locations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (mapViewModel.friendsWithLocations.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('No friends with location available'),
                  ),
                ),
              ...mapViewModel.friendsWithLocations.map((friend) {
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(friend.email),
                  subtitle: Text(
                    'Last updated: ${_formatTime(friend.location?.lastUpdated)}',
                  ),
                  trailing: const Icon(Icons.location_on),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToFriend(friend);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _navigateToFriend(dynamic friend) {
    if (friend.location == null || _mapController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available for this friend'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            friend.location!.latitude,
            friend.location!.longitude,
          ),
          zoom: 15,
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing ${friend.email}\'s location'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
