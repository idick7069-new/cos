import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/reservation_repository.dart';
import '../models/reservation.dart';

// 提供 ReservationRepository
final reservationRepositoryProvider =
    Provider((ref) => ReservationRepository());

// 使用者預定狀態管理
final userReservationsProvider =
    StateNotifierProvider<ReservationsNotifier, AsyncValue<List<Reservation>>>(
  (ref) => ReservationsNotifier(ReservationRepository()),
);

// 特定活動的預定列表狀態管理
final eventReservationsProvider = StateNotifierProvider.family<
    EventReservationsNotifier, List<Reservation>, String>((ref, eventId) {
  return EventReservationsNotifier(
      ref.watch(reservationRepositoryProvider), eventId);
});

// 管理特定活動的預定列表
class EventReservationsNotifier extends StateNotifier<List<Reservation>> {
  EventReservationsNotifier(this._repository, this._eventId) : super([]) {
    // 初始化時開始監聽
    _startListening();
  }

  final ReservationRepository _repository;
  final String _eventId;
  Stream<List<Reservation>>? _subscription;

  void _startListening() {
    _subscription = _repository.getReservationsForEvent(_eventId);
    _subscription?.listen((reservations) {
      state = reservations;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// 管理使用者的預定
class ReservationsNotifier extends StateNotifier<AsyncValue<List<Reservation>>> {
  final ReservationRepository _repository;

  ReservationsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadUserReservations();
  }

  Future<void> loadUserReservations() async {
    try {
      state = const AsyncValue.loading();
      final reservations = await _repository.getUserReservations();
      state = AsyncValue.data(reservations);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addReservation(String eventId, IdentityType identity,
      {String? character}) async {
    try {
      await _repository.addReservation(eventId, identity, character: character);
      await loadUserReservations();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeReservation(String eventId) async {
    try {
      await _repository.removeReservation(eventId);
      await loadUserReservations();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
