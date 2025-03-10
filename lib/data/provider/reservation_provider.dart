import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/reservation_repository.dart';
import '../models/reservation.dart';

// 提供 ReservationRepository
final reservationRepositoryProvider =
    Provider((ref) => ReservationRepository());

// 使用者預定狀態管理
final userReservationsProvider =
    StateNotifierProvider<ReservationsNotifier, List<Reservation>>((ref) {
  return ReservationsNotifier(ref.watch(reservationRepositoryProvider));
});

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
class ReservationsNotifier extends StateNotifier<List<Reservation>> {
  ReservationsNotifier(this._repository) : super([]);

  final ReservationRepository _repository;

  // 載入使用者的預定
  Future<void> loadUserReservations() async {
    try {
      final reservations = await _repository.getUserReservations();
      state = reservations;
    } catch (e) {
      print('載入預定失敗: $e');
      state = [];
    }
  }

  // 新增預定
  Future<void> addReservation(String eventId, IdentityType identity,
      {String? character}) async {
    try {
      await _repository.addReservation(eventId, identity, character: character);
      await loadUserReservations();
    } catch (e) {
      print('新增預定失敗: $e');
    }
  }

  // 更新預定狀態
  Future<void> updateStatus(
      String reservationId, ReservationStatus newStatus) async {
    try {
      await _repository.updateReservationStatus(reservationId, newStatus);
      await loadUserReservations();
    } catch (e) {
      print('更新預定狀態失敗: $e');
    }
  }

  // 取消預定
  Future<void> cancelReservation(String eventId) async {
    try {
      await _repository.removeReservation(eventId);
      await loadUserReservations();
    } catch (e) {
      print('取消預定失敗: $e');
    }
  }
}
