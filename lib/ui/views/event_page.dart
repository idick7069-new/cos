import 'package:cos_connect/ui/dialogs/add_reservation_dialog.dart';
import 'package:cos_connect/ui/views/reservation_manage_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

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

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('活動行事曆'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReservationManagePage()),
            ),
            icon: const Icon(Icons.event_available),
            tooltip: '我的預定',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TableCalendar(
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
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: const TextStyle(color: Colors.red),
                holidayTextStyle: const TextStyle(color: Colors.red),
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final eventViewModel = events[index];
                if (_selectedDay.isAfter(eventViewModel.event.startDate) &&
                    _selectedDay.isBefore(eventViewModel.event.endDate)) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  eventViewModel.event.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: eventViewModel.isParticipating
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      eventViewModel.isParticipating
                                          ? Icons.check_circle
                                          : Icons.pending,
                                      size: 16,
                                      color: eventViewModel.isParticipating
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      eventViewModel.isParticipating
                                          ? '已參加'
                                          : '未參加',
                                      style: TextStyle(
                                        color: eventViewModel.isParticipating
                                            ? Colors.green
                                            : Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.people,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '參與者: ${eventViewModel.event.participants.length}人',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${_formatDateTime(eventViewModel.event.startDate)} - ${_formatDateTime(eventViewModel.event.endDate)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AddReservationDialog(
                                          onConfirm: (identity, character) {
                                            ref
                                                .read(userReservationsProvider
                                                    .notifier)
                                                .addReservation(
                                                  eventViewModel.event.id,
                                                  identity,
                                                  character: character,
                                                );
                                          ref
                                            .read(eventsNotifierProvider.notifier)
                                            .loadEvents();
                                          },
                                        );
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('參加'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              if (eventViewModel.isParticipating) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await ref
                                          .read(
                                              userReservationsProvider.notifier)
                                          .removeReservation(
                                              eventViewModel.event.id);
                                      ref
                                          .read(eventsNotifierProvider.notifier)
                                          .loadEvents();
                                    },
                                    icon: const Icon(Icons.cancel),
                                    label: const Text('取消參加'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      backgroundColor: Colors.red.shade50,
                                      foregroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
