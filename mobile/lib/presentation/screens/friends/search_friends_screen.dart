import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/friend_viewmodel.dart';

class SearchFriendsScreen extends StatefulWidget {
  const SearchFriendsScreen({super.key});

  @override
  State<SearchFriendsScreen> createState() => _SearchFriendsScreenState();
}

class _SearchFriendsScreenState extends State<SearchFriendsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Friends'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by email',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<FriendViewModel>().clearSearchResults();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
                if (value.isNotEmpty) {
                  context.read<FriendViewModel>().searchUsers(value);
                } else {
                  context.read<FriendViewModel>().clearSearchResults();
                }
              },
            ),
          ),
          Expanded(
            child: Consumer<FriendViewModel>(
              builder: (context, friendViewModel, child) {
                if (friendViewModel.state == FriendState.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (friendViewModel.searchResults.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Search for friends by email'
                              : 'No users found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: friendViewModel.searchResults.length,
                  itemBuilder: (context, index) {
                    final user = friendViewModel.searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.email[0].toUpperCase()),
                      ),
                      title: Text(user.email),
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Add'),
                        onPressed: () async {
                          final success = await friendViewModel
                              .sendFriendRequest(user.email);
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Friend request sent!'
                                      : friendViewModel.errorMessage ??
                                          'Failed to send request',
                                ),
                                backgroundColor:
                                    success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
