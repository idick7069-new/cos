import 'package:cos_connect/ui/dialogs/add_reservation_dialog.dart';
import 'package:cos_connect/ui/views/reservation_manage_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/models/reservation.dart';
import '../../data/provider/events_notifier.dart';
import '../../data/provider/events_provider.dart';
import '../../data/provider/reservation_provider.dart';
import '../../data/repository/event_repository.dart';

class EventPage extends ConsumerStatefulWidget {
  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends ConsumerState<EventPage> {
  @override
  void initState() {
    super.initState();
    ref.read(eventsNotifierProvider.notifier).loadEvents();
  }

  DateTime _selectedDay = DateTime.now();
      DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsNotifierProvider);
    print('測試 events: $events');

  

    return Scaffold(
        appBar: AppBar(title: Text('活動行事曆'), actions: [
          IconButton(
            onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReservationManagePage()),
                ),
            icon: Icon(Icons.event_available),
          ),
        ]),
        body: Column(
          children: [
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              eventLoader: (day) {
                return events
                    .where((event) => isSameDay(event.event.startDate, day))
                    .toList();
              },
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay; // update `_focusedDay` here as well
                });
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final eventViewModel = events[index];
                  print('測試 時間 _selectedDay: $_selectedDay');
                  if (_selectedDay.isAfter(eventViewModel.event.startDate) &&
                      _selectedDay.isBefore(eventViewModel.event.endDate)) {
                    return Card(
                      child: Column(
                        children: [
                          Text(eventViewModel.event.title),
                          Text(
                              '參與者: ${eventViewModel.event.participants.length}人'),
                         ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AddReservationDialog(
                                    onConfirm: (identity, character) {
                                      ref.read(addReservationProvider)(
                                        eventViewModel.event.id,
                                        identity,
                                        character: character,
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Text('參加'),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                ref.read(cancelReservationProvider)(
                                    eventViewModel.reservationId!),
                            child: Text('取消參加'),
                          ),
                          eventViewModel.isParticipating
                              ? Icon(Icons.check, color: Colors.green)
                              : Icon(Icons.add, color: Colors.grey),
                        ],
                      ),
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ));
  }
}
