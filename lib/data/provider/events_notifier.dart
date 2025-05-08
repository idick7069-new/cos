import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/views/model/event_view_model.dart';
import '../models/event.dart';

final eventsNotifierProvider =
    StateNotifierProvider<EventsNotifier, List<EventViewModel>>((ref) {
  return EventsNotifier(FirebaseFirestore.instance);
});

class EventsNotifier extends StateNotifier<List<EventViewModel>> {
  EventsNotifier(this._firestore) : super([]);

  final FirebaseFirestore _firestore;

  Future<void> loadEvents() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // 1. 取得所有活動
    final eventSnapshot = await _firestore.collection('events').get();
    final events =
        eventSnapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();

    // 2. 處理活動
    final List<Event> processedEvents = [];
    for (var event in events) {
      if (!event.isMultiDayEvent) {
        processedEvents.add(event);
        continue;
      }

      // 處理多天活動
      final dateRange = event.date.split(" ~ ");
      if (dateRange.length != 2) {
        continue;
      }

      final startDateStr = dateRange[0].split("(")[0];
      final endDateStr = dateRange[1].split("(")[0];

      try {
        final startDate = DateTime.parse(startDateStr);
        final endDate = DateTime.parse(endDateStr);
        final daysDifference = endDate.difference(startDate).inDays + 1;

        for (var dayNumber = 1; dayNumber <= daysDifference; dayNumber++) {
          final currentDate = startDate.add(Duration(days: dayNumber - 1));
          final formattedDate =
              '${currentDate.year}/${currentDate.month.toString().padLeft(2, '0')}/${currentDate.day.toString().padLeft(2, '0')}';

          final dayEvent = event.generateDayEvent(dayNumber).copyWith(
                date: formattedDate,
                dayNumber: dayNumber,
                startDate: startDateStr.replaceAll("-", "/"),
                endDate: endDateStr.replaceAll("-", "/"),
              );

          processedEvents.add(dayEvent);
        }
      } catch (e) {
        print('處理日期範圍時發生錯誤 ${event.id}: $e');
        continue;
      }
    }

    // 3. 取得使用者預定
    final reservationSnapshot = await _firestore
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .get();

    final reservationMap = {
      for (var doc in reservationSnapshot.docs) doc['eventId'] as String: doc.id
    };

    // 4. 建立 ViewModels
    final eventViewModels = processedEvents
        .map((event) => EventViewModel(
              event: event,
              isParticipating: reservationMap.containsKey(event.id),
              reservationId: reservationMap[event.id],
            ))
        .toList();
    state = eventViewModels;
  }

  // 檢查使用者是否已經預定了某一天
  bool hasReservationForDay(String eventId, String day) {
    return state.any((vm) =>
        vm.event.id == eventId && vm.event.date == day && vm.isParticipating);
  }

  // 檢查使用者是否已經預定了相關的任何一天
  bool hasAnyReservationForEvent(EventViewModel eventViewModel) {
    final event = eventViewModel.event;
    return state.any((vm) => vm.event.id == event.id && vm.isParticipating);
  }

  // 獲取使用者已預定的天數
  List<EventViewModel> getReservedDays(EventViewModel eventViewModel) {
    final event = eventViewModel.event;
    return state
        .where((vm) => vm.event.id == event.id && vm.isParticipating)
        .toList();
  }

  // 獲取特定日期的活動
  List<EventViewModel> getEventsForDate(DateTime date) {
    final formattedDate =
        '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    return state
        .where((viewModel) => viewModel.event.date == formattedDate)
        .toList();
  }
}
