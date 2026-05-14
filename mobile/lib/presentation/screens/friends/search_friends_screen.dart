// Search friends screen.
// It loads addable users from the backend and sends friend requests.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/friend_viewmodel.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';

// Users can see all addable accounts, filter by email, and tap Add.
class SearchFriendsScreen extends StatefulWidget {
  const SearchFriendsScreen({super.key});

  @override
  State<SearchFriendsScreen> createState() => _SearchFriendsScreenState();
}

class _SearchFriendsScreenState extends State<SearchFriendsScreen> {
  // Search input and focus control for the email search box.
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  // Debounce waits a short time before calling the backend while typing.
  Timer? _debounce;

  // Track request buttons during this screen session for instant UI feedback.
  final Set<String> _sentRequestEmails = {};
  final Set<String> _sendingEmails = {};

  // Cached ViewModel reference so dispose can clear results safely.
  late final FriendViewModel _friendViewModel;

  @override
  void initState() {
    super.initState();
    _friendViewModel = context.read<FriendViewModel>();

    // Empty search calls GET /api/friends/search and returns all addable users.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _friendViewModel.searchUsers('');
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    // Stop pending search timers and clear old results when leaving this screen.
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _friendViewModel.clearSearchResults();
    super.dispose();
  }

  // Called every time the user types.
  // The timer prevents too many backend requests for fast typing.
  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _friendViewModel.searchUsers(value.trim());
      }
    });
  }

  // Sends a friend request to this user through FriendViewModel.
  Future<void> _sendRequest(UserModel user) async {
    if (_sendingEmails.contains(user.email)) return;

    setState(() => _sendingEmails.add(user.email));

    // FriendViewModel calls POST /api/invites/{user_id} using this backend ID.
    final success = await _friendViewModel.sendFriendRequest(user.id);

    if (!mounted) return;

    setState(() {
      _sendingEmails.remove(user.email);
      if (success) _sentRequestEmails.add(user.email);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                success
                    ? 'Friend request sent to ${user.email}!'
                    : _friendViewModel.errorMessage ?? 'Failed to send request',
              ),
            ),
          ],
        ),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Main search screen: top search field and backend results below.
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Find Friends'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  // Search input at the top. Typing filters users by email from the backend.
  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.search,
        autocorrect: false,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search by email address...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // Results area listens to FriendViewModel search state.
  Widget _buildResults() {
    return Consumer<FriendViewModel>(
      builder: (context, vm, _) {
        if (vm.isSearchLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppTheme.primary),
            ),
          );
        }

        if (vm.searchResults.isEmpty) {
          return _searchController.text.trim().isEmpty
              ? _buildNoAvailableUsers()
              : _buildNoResults();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: vm.searchResults.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildResultsHeader(vm.searchResults.length);
            }
            return _buildUserCard(vm.searchResults[index - 1]);
          },
        );
      },
    );
  }

  // Header tells the user whether they are seeing all users or filtered matches.
  Widget _buildResultsHeader(int count) {
    final query = _searchController.text.trim();
    final label = query.isEmpty ? 'Available users' : 'Matches for "$query"';

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Empty state when backend says there are no users this account can add.
  Widget _buildNoAvailableUsers() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_rounded,
                size: 40,
                color: AppTheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No users available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create another account or remove a friend to see addable users here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty state when backend search returns no email matches.
  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_rounded,
              size: 64,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: 16),
            const Text(
              'No users found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No account found for "${_searchController.text}"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // One search result returned by the backend.
  Widget _buildUserCard(UserModel user) {
    final alreadySent = _sentRequestEmails.contains(user.email);
    final isSending = _sendingEmails.contains(user.email);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            UserAvatar(email: user.email, radius: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildActionButton(user, alreadySent, isSending),
          ],
        ),
      ),
    );
  }

  // Add button shows normal, loading, or sent state for one user.
  Widget _buildActionButton(UserModel user, bool alreadySent, bool isSending) {
    if (alreadySent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 16, color: AppTheme.success),
            const SizedBox(width: 4),
            Text(
              'Sent',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.success,
              ),
            ),
          ],
        ),
      );
    }

    if (isSending) {
      return Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(8),
        child: const CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(AppTheme.primary),
        ),
      );
    }

    return ElevatedButton.icon(
      icon: const Icon(Icons.person_add_rounded, size: 16),
      label: const Text('Add'),
      onPressed: () => _sendRequest(user),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }
}
