// Map screen that shows current user and friends on Google Maps.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';

// Displays friend locations on a map.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Google Maps controller is used to move/zoom the map.
  GoogleMapController? _mapController;

  // Prevents auto-fitting markers over and over.
  bool _didFitBounds = false;

  // Avatar marker icons are generated once and cached.
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  final Set<String> _markerIconRequests = {};

  @override
  void initState() {
    super.initState();

    // Load latest friend locations when the map appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapViewModel>().loadFriendsLocations();
    });
  }

  // Build markers for current user and friends.
  Set<Marker> _buildMarkers(MapViewModel vm) {
    final markers = <Marker>{};

    if (vm.currentPosition != null) {
      _ensureAvatarMarker('_me', 'you@example.com', isMe: true);
      markers.add(
        Marker(
          markerId: const MarkerId('_me'),
          position: LatLng(
            vm.currentPosition!.latitude,
            vm.currentPosition!.longitude,
          ),
          icon:
              _markerIconCache['_me'] ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          infoWindow: const InfoWindow(
            title: 'You',
            snippet: 'Your current location',
          ),
          zIndexInt: 2,
        ),
      );
    }

    for (final friend in vm.friendsWithLocations) {
      final loc = friend.location;
      if (loc != null && (loc.latitude != 0.0 || loc.longitude != 0.0)) {
        final markerKey = 'friend_${friend.id}';
        _ensureAvatarMarker(markerKey, friend.email);
        markers.add(
          Marker(
            markerId: MarkerId(friend.id),
            position: LatLng(loc.latitude, loc.longitude),
            icon:
                _markerIconCache[markerKey] ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueViolet,
                ),
            infoWindow: InfoWindow(
              title: friend.email.split('@').first,
              snippet: 'Saved spot',
            ),
            zIndexInt: 1,
          ),
        );
      }
    }

    return markers;
  }

  // Generate a cartoon avatar marker if it is not already cached.
  void _ensureAvatarMarker(String key, String seed, {bool isMe = false}) {
    if (_markerIconCache.containsKey(key) ||
        _markerIconRequests.contains(key)) {
      return;
    }

    _markerIconRequests.add(key);
    _createAvatarMarker(seed, isMe: isMe)
        .then((icon) {
          if (!mounted) return;
          setState(() {
            _markerIconCache[key] = icon;
            _markerIconRequests.remove(key);
          });
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() => _markerIconRequests.remove(key));
        });
  }

  // Draw a Bitmoji-inspired marker as a PNG for Google Maps.
  Future<BitmapDescriptor> _createAvatarMarker(
    String seed, {
    bool isMe = false,
  }) async {
    const width = 128.0;
    const height = 150.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;
    final center = Offset(width / 2, 58);
    final color = isMe
        ? AppTheme.secondary
        : AppTheme.avatarColorForEmail(seed);

    paint.color = Colors.black.withValues(alpha: 0.18);
    canvas.drawOval(const Rect.fromLTWH(30, 112, 68, 18), paint);

    final pin = Path()
      ..addOval(Rect.fromCircle(center: center, radius: 46))
      ..moveTo(center.dx - 16, 94)
      ..quadraticBezierTo(center.dx, 132, center.dx + 16, 94)
      ..close();
    paint.color = Colors.white;
    canvas.drawPath(pin, paint);

    paint.color = color;
    canvas.drawCircle(center, 39, paint);

    paint.color = const Color(0xFFFFD7B5);
    canvas.drawCircle(Offset(center.dx, center.dy - 2), 25, paint);

    paint.color = AppTheme.textPrimary;
    final hair = Path()
      ..moveTo(center.dx - 25, center.dy - 4)
      ..quadraticBezierTo(
        center.dx - 5,
        center.dy - 38,
        center.dx + 26,
        center.dy - 12,
      )
      ..quadraticBezierTo(
        center.dx + 8,
        center.dy - 26,
        center.dx - 25,
        center.dy - 4,
      )
      ..close();
    canvas.drawPath(hair, paint);

    paint.color = AppTheme.textPrimary;
    canvas.drawCircle(Offset(center.dx - 8, center.dy + 2), 2.2, paint);
    canvas.drawCircle(Offset(center.dx + 8, center.dy + 2), 2.2, paint);

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 9),
        width: 18,
        height: 12,
      ),
      0.2,
      2.75,
      false,
      paint,
    );
    paint.style = PaintingStyle.fill;

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      width: 64,
      height: 75,
    );
  }

  // Move the map camera so all markers are visible.
  void _fitBoundsToMarkers(Set<Marker> markers) {
    if (_mapController == null || markers.isEmpty) return;

    if (markers.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: markers.first.position,
            zoom: AppConstants.defaultZoom,
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    // Rebuild map whenever MapViewModel changes.
    return Consumer<MapViewModel>(
      builder: (context, vm, _) {
        if (vm.currentPosition == null) {
          return _buildNoLocationView(vm);
        }

        final markers = _buildMarkers(vm);

        // Fit bounds once after first friends load
        if (!_didFitBounds &&
            vm.state == MapState.loaded &&
            markers.length > 1) {
          _didFitBounds = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _fitBoundsToMarkers(markers),
          );
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

  // View shown when location services/permission are unavailable.
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
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_off_rounded,
                  size: 50,
                  color: AppTheme.primary.withValues(alpha: 0.5),
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

  // Top status bar showing location sharing and visible friend locations.
  Widget _buildStatusBar(MapViewModel vm) {
    final isTracking = vm.isInitialized;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
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
                boxShadow: isTracking
                    ? [
                        BoxShadow(
                          color: AppTheme.success.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isTracking ? 'Location sharing on' : 'Location sharing off',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isTracking
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            if (vm.state == MapState.loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${vm.friendsWithLocations.length} saved',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Floating map action buttons.
  Widget _buildActionButtons(MapViewModel vm, Set<Marker> markers) {
    return Positioned(
      right: 16,
      bottom: 126,
      child: Column(
        children: [
          _mapFab(
            icon: Icons.my_location_rounded,
            heroTag: 'my_location',
            onTap: () {
              if (vm.currentPosition != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(
                        vm.currentPosition!.latitude,
                        vm.currentPosition!.longitude,
                      ),
                      zoom: 15,
                    ),
                  ),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Reusable round map button.
  Widget _mapFab({
    required IconData icon,
    required String heroTag,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(22),
      color: isPrimary ? AppTheme.secondary : AppTheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          child: Icon(icon, size: 24, color: AppTheme.textPrimary),
        ),
      ),
    );
  }

  // Bottom horizontal list of friends with locations.
  Widget _buildBottomInfoCard(MapViewModel vm) {
    return Positioned(
      bottom: 12,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (vm.friendsWithLocations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: AppTheme.textPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Add friends to see their spots here.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 74,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
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

  // Small friend chip that recenters map on tap.
  Widget _friendChip(UserModel friend) {
    final loc = friend.location;
    return GestureDetector(
      onTap: () {
        if (loc != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(loc.latitude, loc.longitude),
                zoom: 15,
              ),
            ),
          );
        }
      },
      child: Container(
        width: 176,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white),
        ),
        child: Row(
          children: [
            UserAvatar(email: friend.email, radius: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                friend.email.split('@').first,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose map controller when screen is destroyed.
    _mapController?.dispose();
    super.dispose();
  }
}
