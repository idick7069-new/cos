import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/provider/friend_request_notifier.dart';

class FriendRequestsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendRequests = ref.watch(receivedFriendRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: Text("好友邀請")),
      body: friendRequests.when(
        data: (requests) {
          if (requests.isEmpty) {
            return Center(child: Text("目前沒有好友邀請"));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final requestId = request['id'];
              final fromUserId = request['fromUserId'];

              return ListTile(
                title: Text("來自 $fromUserId 的好友邀請"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                        ref
                            .read(friendRequestActionsProvider)
                            .acceptFriendRequest(requestId, fromUserId);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        ref
                            .read(friendRequestActionsProvider)
                            .declineFriendRequest(requestId, fromUserId);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, stackTrace) => Center(child: Text("發生錯誤")),
      ),
    );
  }
}
