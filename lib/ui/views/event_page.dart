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
  // 用於存儲事件ID和顏色的映射
  final Map<String, Color> _eventColors = {};

  // 生成隨機顏色
  Color _getRandomColor() {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[DateTime.now().millisecondsSinceEpoch % colors.length];
  }

  // 獲取事件的顏色
  Color _getEventColor(String eventId) {
    if (!_eventColors.containsKey(eventId)) {
      _eventColors[eventId] = _getRandomColor();
    }
    return _eventColors[eventId]!;
  }

  @override
  void initState() {
    super.initState();
    ref.read(eventsNotifierProvider.notifier).loadEvents();
  }

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd').format(dateTime);
  }

  bool _isEventInRange(
      DateTime selectedDate, String startDateStr, String endDateStr) {
    try {
      final startDate = DateTime.parse(startDateStr.replaceAll('/', '-'));
      final endDate = DateTime.parse(endDateStr.replaceAll('/', '-'));

      // 將選擇的日期設置為當天的開始時間
      final selectedDateTime =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

      // 將開始和結束日期設置為當天的開始時間
      final startDateTime =
          DateTime(startDate.year, startDate.month, startDate.day);
      final endDateTime = DateTime(endDate.year, endDate.month, endDate.day);

      return !selectedDateTime.isBefore(startDateTime) &&
          !selectedDateTime.isAfter(endDateTime);
    } catch (e) {
      return false;
    }
  }

  bool _isSameDay(DateTime day, String dateStr) {
    try {
      final eventDate = DateTime.parse(dateStr.replaceAll('/', '-'));
      return day.year == eventDate.year &&
          day.month == eventDate.month &&
          day.day == eventDate.day;
    } catch (e) {
      return false;
    }
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
                return events.where((event) {
                  // 檢查該日期是否在事件的開始和結束日期之間
                  return _isEventInRange(
                    day,
                    event.event.startDate,
                    event.event.endDate,
                  );
                }).toList();
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
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      bottom: 1,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: events.map((event) {
                          final eventId = (event as dynamic).event?.id;
                          if (eventId == null) return const SizedBox.shrink();

                          return Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 0.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getEventColor(eventId),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final eventViewModel = events[index];
                if (_isEventInRange(
                    _selectedDay,
                    eventViewModel.event.startDate,
                    eventViewModel.event.endDate)) {
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
                                  eventViewModel.event.date,
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
                                                .read(eventsNotifierProvider
                                                    .notifier)
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
