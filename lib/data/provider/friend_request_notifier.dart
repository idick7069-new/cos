import 'package:cos_connect/data/repository/friend_request_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final friendRequestNotifierProvider =
StateNotifierProvider<FriendRequestNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(friendRequestRepositoryProvider);
  return FriendRequestNotifier(repository);
});

class FriendRequestNotifier extends StateNotifier<AsyncValue<void>> {
  final FriendRequestRepository _repository;

  FriendRequestNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> sendFriendRequest(String targetUserId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.sendFriendRequest(targetUserId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final receivedFriendRequestsProvider =
StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(friendRequestRepositoryProvider);
  return repository.getReceivedFriendRequests();
});

final friendRequestActionsProvider =
Provider<FriendRequestActions>((ref) {
  final repository = ref.watch(friendRequestRepositoryProvider);
  return FriendRequestActions(repository);
});

class FriendRequestActions {
  final FriendRequestRepository _repository;

  FriendRequestActions(this._repository);

  Future<void> acceptFriendRequest(String requestId, String fromUserId) async {
    await _repository.acceptFriendRequest(requestId, fromUserId);
  }

  Future<void> declineFriendRequest(String requestId, String fromUserId) async {
    await _repository.declineFriendRequest(requestId, fromUserId);
  }
}