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
                  groupId: widget.groupId,
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
  final String groupId;
  const _EventCard({
    required this.event,
    required this.eventReservations,
    required this.imageUrl,
    required this.day,
    required this.groupId,
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  child: Text('我要出戰'),
                  onPressed: () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => _JoinDialog(
                        eventId: widget.event['id'] ?? '',
                        day: widget.day,
                      ),
                    );
                    if (result != null) {
                      // 新增 reservation
                      await FirebaseFirestore.instance
                          .collection('reservations')
                          .add({
                        'eventId': widget.event['id'] ?? '',
                        'day': widget.day,
                        'name': result['name'],
                        'identity': result['identity'],
                        'character': result['character'],
                        'createdAt': DateTime.now(),
                        'groupId': widget.groupId,
                      });
                      if (mounted) {
                        // 重新刷新頁面
                        (context as Element).markNeedsBuild();
                      }
                    }
                  },
                ),
                IconButton(
                  icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      expanded = !expanded;
                    });
                  },
                ),
              ],
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
                        final identityIndex = data['identity'] ?? 0;
                        final identity = IdentityType.values[identityIndex];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('參加者：${data['name'] ?? ''}'),
                            Text('身份：${getIdentityText(identity)}'),
                            if (identity == IdentityType.coser)
                              Text('角色：${data['character'] ?? ''}'),
                            Divider(),
                          ],
                        );
                      }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// 新增Dialog
class _JoinDialog extends StatefulWidget {
  final String eventId;
  final String day;
  const _JoinDialog({required this.eventId, required this.day, Key? key})
      : super(key: key);

  @override
  State<_JoinDialog> createState() => _JoinDialogState();
}

enum IdentityType { manager, photographer, coser, original }

String getIdentityText(IdentityType type) {
  switch (type) {
    case IdentityType.manager:
      return '馬內';
    case IdentityType.photographer:
      return '攝影師';
    case IdentityType.coser:
      return 'Coser';
    case IdentityType.original:
      return '本體';
  }
}

class _JoinDialogState extends State<_JoinDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _characterController = TextEditingController();
  IdentityType? _selectedIdentity;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('我要出戰'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: '名稱（CN）'),
              validator: (v) => v == null || v.isEmpty ? '必填' : null,
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<IdentityType>(
              value: _selectedIdentity,
              decoration: InputDecoration(labelText: '身份'),
              items: IdentityType.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(getIdentityText(type)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedIdentity = v),
              validator: (v) => v == null ? '必選' : null,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _characterController,
              decoration: InputDecoration(labelText: '角色（選填）'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text,
                'identity': _selectedIdentity!.index,
                'character': _characterController.text,
              });
            }
          },
          child: Text('完成'),
        ),
      ],
    );
  }
}
