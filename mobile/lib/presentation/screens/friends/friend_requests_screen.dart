// Friend requests screen with received and sent tabs.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/friend_viewmodel.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/friend_request_model.dart';

// Shows incoming requests users can accept/decline and outgoing requests they sent.
class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen>
    with SingleTickerProviderStateMixin {
  // Controls the Received/Sent tabs.
  late TabController _tabController;

  // Tracks request IDs currently being accepted/declined.
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load requests after first render.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendViewModel>().loadPendingRequests();
    });
  }

  @override
  void dispose() {
    // Dispose tab controller to avoid leaks.
    _tabController.dispose();
    super.dispose();
  }

  // Accept or deny a friend request.
  Future<void> _handleResponse(
      BuildContext context, String senderUserId, String action) async {
    if (_processingIds.contains(senderUserId)) return;

    setState(() => _processingIds.add(senderUserId));

    final messenger = ScaffoldMessenger.of(context);
    final vm = context.read<FriendViewModel>();
    // Pass senderUserId — swagger: POST /invites/{user_id}/accept|decline
    final success = await vm.respondToRequest(senderUserId, action);

    if (mounted) {
      setState(() => _processingIds.remove(senderUserId));
      final isAccept = action == 'accept';
      messenger.showSnackBar(SnackBar(
        content: Row(children: [
          Icon(
            isAccept ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(success
              ? (isAccept ? 'Friend added!' : 'Request declined')
              : 'Failed to respond'),
        ]),
        backgroundColor: success
            ? (isAccept ? AppTheme.success : AppTheme.textSecondary)
            : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Top tabs and tab content.
    return Column(
      children: [
        Container(
          color: AppTheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              Consumer<FriendViewModel>(
                builder: (_, vm, _) => Tab(
                  text: vm.pendingRequests.isEmpty
                      ? 'Received'
                      : 'Received (${vm.pendingRequests.length})',
                ),
              ),
              Consumer<FriendViewModel>(
                builder: (_, vm, _) => Tab(
                  text: vm.outgoingRequests.isEmpty
                      ? 'Sent'
                      : 'Sent (${vm.outgoingRequests.length})',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildIncomingTab(),
              _buildOutgoingTab(),
            ],
          ),
        ),
      ],
    );
  }

  // Received requests tab.
  Widget _buildIncomingTab() {
    return Consumer<FriendViewModel>(
      builder: (context, vm, _) {
        if (vm.state == FriendState.loading && vm.pendingRequests.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.primary)));
        }
        if (vm.pendingRequests.isEmpty) {
          return _emptyState(
            icon: Icons.notifications_none_rounded,
            title: 'No Incoming Requests',
            subtitle: 'Friend requests you receive will appear here',
          );
        }
        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () => vm.loadPendingRequests(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: vm.pendingRequests.length,
            itemBuilder: (ctx, i) =>
                _incomingCard(ctx, vm.pendingRequests[i]),
          ),
        );
      },
    );
  }

  // Sent requests tab.
  Widget _buildOutgoingTab() {
    return Consumer<FriendViewModel>(
      builder: (context, vm, _) {
        if (vm.state == FriendState.loading && vm.outgoingRequests.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.primary)));
        }
        if (vm.outgoingRequests.isEmpty) {
          return _emptyState(
            icon: Icons.send_rounded,
            title: 'No Sent Requests',
            subtitle: 'Invites you\'ve sent will appear here',
          );
        }
        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () => vm.loadPendingRequests(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: vm.outgoingRequests.length,
            itemBuilder: (ctx, i) => _outgoingCard(vm.outgoingRequests[i]),
          ),
        );
      },
    );
  }

  // Card for a received request with accept/decline buttons.
  Widget _incomingCard(BuildContext context, FriendRequestModel request) {
    final senderUserId = request.sender.id;
    final isProcessing = _processingIds.contains(senderUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            UserAvatar(email: request.sender.email, radius: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.sender.displayName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(request.sender.email,
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Wants to be your friend',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textHint)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Pending',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warning)),
            ),
          ]),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          if (isProcessing)
            const Center(
                child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation(AppTheme.primary))))
          else
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Decline'),
                  onPressed: () =>
                      _handleResponse(context, senderUserId, 'deny'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side:
                        BorderSide(color: AppTheme.error.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Accept'),
                  onPressed: () =>
                      _handleResponse(context, senderUserId, 'accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
        ]),
      ),
    );
  }

  // Card for a sent request.
  Widget _outgoingCard(FriendRequestModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          UserAvatar(email: request.receiver.email, radius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.receiver.displayName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(request.receiver.email,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.schedule_rounded,
                  size: 12, color: AppTheme.info),
              const SizedBox(width: 4),
              Text('Pending',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.info)),
            ]),
          ),
        ]),
      ),
    );
  }

  // Shared empty-state UI for either tab.
  Widget _emptyState(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppTheme.primary.withValues(alpha: 0.1),
                AppTheme.secondary.withValues(alpha: 0.1)
              ]),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 50, color: AppTheme.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary, height: 1.5)),
        ]),
      ),
    );
  }
}
