import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/reservation_repository.dart';
import '../models/reservation.dart';

// 提供 ReservationRepository
final reservationRepositoryProvider =
    Provider((ref) => ReservationRepository());

// 參加活動 Provider（呼叫 addReservation）
final addReservationProvider = Provider((ref) {
  final repository = ref.watch(reservationRepositoryProvider);
  return repository.addReservation;
});

// 監聽某個活動的預定列表
final reservationsForEventProvider =
    StreamProvider.family<List<Reservation>, String>((ref, eventId) {
  final repository = ref.watch(reservationRepositoryProvider);
  return repository.getReservationsForEvent(eventId);
});

// 更新預定狀態 Provider
final updateReservationStatusProvider = Provider((ref) {
  final repository = ref.watch(reservationRepositoryProvider);
  return repository.updateReservationStatus;
});

// 取消預定 Provider
final cancelReservationProvider = Provider((ref) {
  final repository = ref.watch(reservationRepositoryProvider);
  return repository.removeReservation;
});

// 監聽使用者的所有預定
final userReservationsProvider =
    StateNotifierProvider<ReservationsNotifier, List<Reservation>>((ref) {
  return ReservationsNotifier(ref.watch(reservationRepositoryProvider));
});

class ReservationsNotifier extends StateNotifier<List<Reservation>> {
  ReservationsNotifier(this._repository) : super([]);

  final ReservationRepository _repository;

  Future<void> loadUserReservations() async {
    final reservations = await _repository.getUserReservations();
    state = reservations;
  }

  Future<void> addReservation(String eventId, IdentityType identity,
      {String? character}) async {
    await _repository.addReservation(eventId, identity, character: character);
    loadUserReservations();
  }

  Future<void> updateStatus(
      String reservationId, ReservationStatus newStatus) async {
    await _repository.updateReservationStatus(reservationId, newStatus);
    loadUserReservations();
  }

  Future<void> cancelReservation(String eventId) async {
    await _repository.removeReservation(eventId);
    loadUserReservations();
  }
}
