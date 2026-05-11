// Home screen with tabs for map, friends, and requests.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/friend_viewmodel.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../friends/friends_list_screen.dart';
import '../friends/friend_requests_screen.dart';
import '../friends/search_friends_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../../../core/theme/app_theme.dart';

// Main screen shown after login.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Current bottom-tab index.
  int _currentIndex = 0;

  // Screens shown inside the IndexedStack.
  final List<Widget> _screens = const [
    MapScreen(),
    FriendsListScreen(),
    FriendRequestsScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Start loading app data after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  // Start location tracking and load pending requests.
  Future<void> _initialize() async {
    if (!mounted) return;
    context.read<MapViewModel>().initializeLocation();
    context.read<FriendViewModel>().loadPendingRequests();
  }

  // Open profile/settings screen.
  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // IndexedStack keeps tab state alive while switching tabs.
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _currentIndex == 0 ? null : _buildAppBar(),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Top app bar with title, add-friend button, and profile button.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Friend Finder',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
      actions: [
        if (_currentIndex == 1)
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchFriendsScreen()),
            ),
          ),
        Consumer<AuthViewModel>(
          builder: (_, authVm, _) => IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
            onPressed: _openProfile,
            tooltip: authVm.currentUser?.email ?? 'Profile',
          ),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE2E8F0)),
      ),
    );
  }

  // Custom bottom navigation bar.
  Widget _buildBottomNav() {
    return Consumer<FriendViewModel>(
      builder: (context, friendViewModel, _) {
        final pendingCount = friendViewModel.pendingRequestCount;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.98),
            border: const Border(
              top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  _navItem(0, Icons.map_outlined, Icons.map_rounded, 'Map'),
                  _navItem(
                    1,
                    Icons.people_outline_rounded,
                    Icons.people_rounded,
                    'Friends',
                  ),
                  _navItemWithBadge(
                    2,
                    Icons.notifications_outlined,
                    Icons.notifications_rounded,
                    'Requests',
                    pendingCount,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Standard nav item without badge.
  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onNavTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? AppTheme.secondary : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 24,
                color: isSelected ? AppTheme.primary : AppTheme.textHint,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nav item with pending request badge.
  Widget _navItemWithBadge(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    int badgeCount,
  ) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onNavTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? AppTheme.secondary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    size: 24,
                    color: isSelected ? AppTheme.primary : AppTheme.textHint,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: 0,
                    right: 8,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Change tab and refresh the data needed for that tab.
  void _onNavTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        context.read<MapViewModel>().loadFriendsLocations();
        break;
      case 1:
        context.read<FriendViewModel>().loadFriends();
        break;
      case 2:
        context.read<FriendViewModel>().loadPendingRequests();
        break;
    }
  }
}
