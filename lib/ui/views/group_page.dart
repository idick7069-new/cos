import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class GroupPage extends StatefulWidget {
  final String groupId;
  const GroupPage({required this.groupId, Key? key}) : super(key: key);

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  DocumentSnapshot? groupDoc;
  List<DocumentSnapshot> events = [];
  List<DocumentSnapshot> reservations = [];
  bool loading = true;
  bool notFound = false;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    final groupSnap = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();
    if (!groupSnap.exists) {
      setState(() {
        notFound = true;
        loading = false;
      });
      return;
    }
    // 取得 group 內 events
    final eventSnaps =
        await FirebaseFirestore.instance.collection('events').get();
    // 取得 reservations
    final reservationSnaps = await FirebaseFirestore.instance
        .collection('reservations')
        .where('groupId', isEqualTo: widget.groupId)
        .get();

    setState(() {
      groupDoc = groupSnap;
      events = eventSnaps.docs;
      reservations = reservationSnaps.docs;
      loading = false;
    });
  }

  /// 取得該天有哪些 event（根據 event.days）
  List<DocumentSnapshot> getEventsForDay(DateTime day) {
    final dayStr =
        "${day.year}/${day.month.toString().padLeft(2, '0')}/${day.day.toString().padLeft(2, '0')}";
    return events.where((e) {
      final data = e.data() as Map<String, dynamic>;
      final days = (data['days'] as List?)?.cast<String>() ?? [];
      return days.contains(dayStr);
    }).toList();
  }

  /// 取得該天該 event 的所有 reservation
  List<DocumentSnapshot> getReservationsForEventDay(
      String eventId, String day) {
    return reservations.where((r) {
      final data = r.data() as Map<String, dynamic>;
      print('data: $data');
      return data['eventId'] == eventId && data['day'] == day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    if (notFound)
      return Scaffold(
          body: Center(
              child: Text('404 Not Found', style: TextStyle(fontSize: 32))));
    final groupData = groupDoc!.data() as Map<String, dynamic>;

    final selectedDay = _selectedDay ?? _focusedDay;
    final eventsForSelectedDay = getEventsForDay(selectedDay);

    return Scaffold(
      appBar: AppBar(title: Text(groupData['name'] ?? 'Group')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('行事曆', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 16),
              TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime(2035),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) =>
                    _selectedDay != null &&
                    day.year == _selectedDay!.year &&
                    day.month == _selectedDay!.month &&
                    day.day == _selectedDay!.day,
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                eventLoader: (day) => getEventsForDay(day),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: events.map((event) {
                            return Container(
                              width: 6,
                              height: 6,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 0.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
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
              SizedBox(height: 32),
              Text(
                '當日活動',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ...eventsForSelectedDay.map((eventDoc) {
                final event = eventDoc.data() as Map<String, dynamic>;
                final eventId = eventDoc.id;
                final dayStr =
                    "${selectedDay.year}/${selectedDay.month.toString().padLeft(2, '0')}/${selectedDay.day.toString().padLeft(2, '0')}";

                print('eventId: $eventId, dayStr: $dayStr');
                final eventReservations =
                    getReservationsForEventDay(eventId, dayStr);

                return _EventCard(
                  event: event,
                  eventReservations: eventReservations,
                  imageUrl: event['imageUrl'] ?? '',
                  day: dayStr,
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatefulWidget {
  final Map<String, dynamic> event;
  final List<DocumentSnapshot> eventReservations;
  final String imageUrl;
  final String day;

  const _EventCard({
    required this.event,
    required this.eventReservations,
    required this.imageUrl,
    required this.day,
    Key? key,
  }) : super(key: key);

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    print('imageUrl: ${widget.imageUrl}');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: widget.imageUrl.isNotEmpty
                ? Image.network(
                    widget.imageUrl.startsWith('http')
                        ? widget.imageUrl
                        : 'https:${widget.imageUrl}',
                    width: 300,
                    height: 100,
                    fit: BoxFit.cover)
                : null,
            title: Text(event['title'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event['location'] != null) Text('地點：${event['location']}'),
                Text('參加人數：${widget.eventReservations.length}'),
              ],
            ),
            trailing: IconButton(
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  expanded = !expanded;
                });
              },
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.eventReservations.isEmpty
                    ? [Text('當日無預定')]
                    : widget.eventReservations.map((r) {
                        final data = r.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(data['character'] ?? '無角色'),
                          subtitle: Text('用戶: ${data['userId'] ?? ''}'),
                        );
                      }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
