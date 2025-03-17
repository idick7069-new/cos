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
  bool hasReservationForDay(String eventId) {
    return state.any((vm) => vm.event.id == eventId && vm.isParticipating);
  }

  // 檢查使用者是否已經預定了相關的任何一天
  bool hasAnyReservationForEvent(EventViewModel eventViewModel) {
    final relatedEvents = getRelatedEvents(eventViewModel);
    return relatedEvents.any((vm) => vm.isParticipating);
  }

  // 獲取使用者已預定的天數
  List<EventViewModel> getReservedDays(EventViewModel eventViewModel) {
    final relatedEvents = getRelatedEvents(eventViewModel);
    return relatedEvents.where((vm) => vm.isParticipating).toList();
  }

  // 獲取特定日期的活動
  List<EventViewModel> getEventsForDate(DateTime date) {
    final formattedDate =
        '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';


    final events = state.where((viewModel) {
      final event = viewModel.event;
      return event.date == formattedDate;
    }).toList();

    for (var e in events) {
      print('- ${e.event.displayTitle} (${e.event.date})');
    }

    return events;
  }

  // 獲取相關的多天活動
  List<EventViewModel> getRelatedEvents(EventViewModel eventViewModel) {
    final event = eventViewModel.event;
    if (event.parentEventId != null) {
      return state
          .where((vm) =>
              vm.event.parentEventId == event.parentEventId ||
              vm.event.id == event.parentEventId)
          .toList();
    }
    return state
        .where((vm) =>
            vm.event.id == event.id || vm.event.parentEventId == event.id)
        .toList();
  }

  // 獲取父活動
  EventViewModel? getParentEvent(EventViewModel eventViewModel) {
    final event = eventViewModel.event;
    if (event.parentEventId != null) {
      return state.firstWhere(
        (vm) => vm.event.id == event.parentEventId,
        orElse: () => eventViewModel,
      );
    }
    return eventViewModel;
  }

  // 獲取特定活動的所有天數
  List<EventViewModel> getAllDaysForEvent(EventViewModel eventViewModel) {
    final event = eventViewModel.event;
    final String targetId = event.parentEventId ?? event.id;
    return state
        .where((vm) =>
            vm.event.id == targetId || vm.event.parentEventId == targetId)
        .toList();
  }
}
