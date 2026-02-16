import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/friend_viewmodel.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendViewModel>().loadFriends();
    });
  }

  Future<void> _handleDeleteFriend(String friendId, String friendEmail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove $friendEmail from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<FriendViewModel>().deleteFriend(friendId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Friend removed' : 'Failed to remove friend',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendViewModel>(
      builder: (context, friendViewModel, child) {
        if (friendViewModel.state == FriendState.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (friendViewModel.friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No friends yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add friends',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => friendViewModel.loadFriends(),
          child: ListView.builder(
            itemCount: friendViewModel.friends.length,
            itemBuilder: (context, index) {
              final friend = friendViewModel.friends[index];
              final hasLocation = friend.location != null &&
                  friend.location!.latitude != 0.0 &&
                  friend.location!.longitude != 0.0;

              return ListTile(
                leading: CircleAvatar(
                  child: Text(friend.email[0].toUpperCase()),
                ),
                title: Text(friend.email),
                subtitle: hasLocation
                    ? const Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text('Location available'),
                        ],
                      )
                    : const Row(
                        children: [
                          Icon(Icons.location_off, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('Location unavailable'),
                        ],
                      ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _handleDeleteFriend(friend.id, friend.email),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
