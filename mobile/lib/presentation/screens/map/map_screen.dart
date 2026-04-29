import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  bool _didFitBounds = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapViewModel>().loadFriendsLocations();
    });
  }

  // Markers are computed fresh on every Consumer rebuild — no stale state
  Set<Marker> _buildMarkers(MapViewModel vm) {
    final markers = <Marker>{};

    if (vm.currentPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('_me'),
        position: LatLng(
          vm.currentPosition!.latitude,
          vm.currentPosition!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: 'You',
          snippet: 'Your current location',
        ),
        zIndexInt: 2,
      ));
    }

    for (final friend in vm.friendsWithLocations) {
      final loc = friend.location;
      if (loc != null && (loc.latitude != 0.0 || loc.longitude != 0.0)) {
        markers.add(Marker(
          markerId: MarkerId(friend.id),
          position: LatLng(loc.latitude, loc.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: friend.email.split('@').first,
            snippet: _formatTime(loc.lastUpdated),
          ),
          zIndexInt: 1,
        ));
      }
    }

    return markers;
  }

  void _fitBoundsToMarkers(Set<Marker> markers) {
    if (_mapController == null || markers.isEmpty) return;

    if (markers.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(
          target: markers.first.position,
          zoom: AppConstants.defaultZoom,
        )),
      );
      return;
    }

    double? minLat, maxLat, minLng, maxLng;
    for (final m in markers) {
      final lat = m.position.latitude;
      final lng = m.position.longitude;
      minLat = minLat == null ? lat : (lat < minLat ? lat : minLat);
      maxLat = maxLat == null ? lat : (lat > maxLat ? lat : maxLat);
      minLng = minLng == null ? lng : (lng < minLng ? lng : minLng);
      maxLng = maxLng == null ? lng : (lng > maxLng ? lng : maxLng);
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat!, minLng!),
          northeast: LatLng(maxLat!, maxLng!),
        ),
        80,
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
      builder: (context, vm, _) {
        if (vm.currentPosition == null) {
          return _buildNoLocationView(vm);
        }

        final markers = _buildMarkers(vm);

        // Fit bounds once after first friends load
        if (!_didFitBounds && vm.state == MapState.loaded && markers.length > 1) {
          _didFitBounds = true;
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => _fitBoundsToMarkers(markers));
        }

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  vm.currentPosition!.latitude,
                  vm.currentPosition!.longitude,
                ),
                zoom: AppConstants.defaultZoom,
              ),
              markers: markers,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
                // Apply subtle map style
              },
            ),
            // Top status bar
            _buildStatusBar(vm),
            // Action buttons
            _buildActionButtons(vm, markers),
            // Bottom info card
            _buildBottomInfoCard(vm),
          ],
        );
      },
    );
  }

  Widget _buildNoLocationView(MapViewModel vm) {
    return Container(
      color: AppTheme.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_off_rounded,
                  size: 50,
                  color: AppTheme.primary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Location Unavailable',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enable location services to use the map and track your friends.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: 'Enable Location',
                icon: Icons.my_location_rounded,
                onPressed: () => vm.initializeLocation(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(MapViewModel vm) {
    final isTracking = vm.isInitialized;
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isTracking ? AppTheme.success : AppTheme.textHint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isTracking ? 'Live tracking active' : 'Tracking inactive',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isTracking ? AppTheme.success : AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            if (vm.state == MapState.loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              )
            else
              Text(
                '${vm.friendsWithLocations.length} online',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(MapViewModel vm, Set<Marker> markers) {
    return Positioned(
      right: 16,
      bottom: 130,
      child: Column(
        children: [
          _mapFab(
            icon: Icons.my_location_rounded,
            heroTag: 'my_location',
            onTap: () {
              if (vm.currentPosition != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(CameraPosition(
                    target: LatLng(
                      vm.currentPosition!.latitude,
                      vm.currentPosition!.longitude,
                    ),
                    zoom: 15,
                  )),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          _mapFab(
            icon: Icons.fit_screen_rounded,
            heroTag: 'fit_bounds',
            onTap: () => _fitBoundsToMarkers(markers),
          ),
          const SizedBox(height: 10),
          _mapFab(
            icon: Icons.refresh_rounded,
            heroTag: 'refresh',
            isPrimary: true,
            onTap: () async {
              _didFitBounds = false;
              await vm.loadFriendsLocations();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Friend locations refreshed'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _mapFab({
    required IconData icon,
    required String heroTag,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.12),
      borderRadius: BorderRadius.circular(14),
      color: isPrimary ? AppTheme.primary : AppTheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 22,
            color: isPrimary ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfoCard(MapViewModel vm) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (vm.friendsWithLocations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.people_outline_rounded,
                        color: AppTheme.textHint, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'No friends with location yet',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  itemCount: vm.friendsWithLocations.length,
                  itemBuilder: (context, i) =>
                      _friendChip(vm.friendsWithLocations[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _friendChip(UserModel friend) {
    final loc = friend.location;
    return GestureDetector(
      onTap: () {
        if (loc != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(CameraPosition(
              target: LatLng(loc.latitude, loc.longitude),
              zoom: 15,
            )),
          );
        }
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            UserAvatar(email: friend.email, radius: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    friend.email.split('@').first,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(loc?.lastUpdated),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
