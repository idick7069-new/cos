import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/reservation.dart';
import '../../data/models/event.dart';
import '../../data/provider/reservation_provider.dart';
import '../../data/provider/events_notifier.dart';
import 'reservation_share_page.dart';
import 'model/event_view_model.dart';

class ReservationManagePage extends ConsumerStatefulWidget {
  const ReservationManagePage({Key? key}) : super(key: key);

  @override
  _ReservationManagePageState createState() => _ReservationManagePageState();
}

class _ReservationManagePageState extends ConsumerState<ReservationManagePage> {
  final Set<String> _selectedEventIds = {};

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }

  String _getIdentityText(IdentityType identity) {
    switch (identity) {
      case IdentityType.manager:
        return '馬內';
      case IdentityType.photographer:
        return '攝影師';
      case IdentityType.coser:
        return 'Coser';
      case IdentityType.original:
        return '原創';
    }
  }

  void _toggleSelection(String eventId) {
    setState(() {
      if (_selectedEventIds.contains(eventId)) {
        _selectedEventIds.remove(eventId);
      } else {
        _selectedEventIds.add(eventId);
      }
    });
  }

  void _shareSelectedEvents(
      List<EventViewModel> events, List<Reservation> reservations) {
    final selectedEvents =
        events.where((e) => _selectedEventIds.contains(e.event.id)).toList();
    final selectedReservations = reservations
        .where((r) => _selectedEventIds.contains(r.eventId))
        .toList();

    if (selectedEvents.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationSharePage(
          eventViewModels: selectedEvents,
          reservations: selectedReservations,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservations = ref.watch(userReservationsProvider);
    final events = ref.watch(eventsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的預定'),
        elevation: 0,
        actions: [
          if (_selectedEventIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                reservations.whenData((reservationsList) {
                  _shareSelectedEvents(events, reservationsList);
                });
              },
            ),
        ],
      ),
      body: reservations.when(
        data: (reservationsList) {
          if (reservationsList.isEmpty) {
            return const Center(
              child: Text('目前沒有預定'),
            );
          }

          final reservedEvents = events.where((eventViewModel) {
            return reservationsList.any((reservation) =>
                reservation.eventId == eventViewModel.event.id);
          }).toList();

          if (reservedEvents.isEmpty) {
            return const Center(
              child: Text('找不到相關活動'),
            );
          }

          return ListView.builder(
            itemCount: reservedEvents.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final eventViewModel = reservedEvents[index];
              final relatedReservations = reservationsList
                  .where((r) => r.eventId == eventViewModel.event.id)
                  .toList();

              if (relatedReservations.isEmpty) {
                return const SizedBox.shrink();
              }

              final reservation = relatedReservations.first;
              final isSelected =
                  _selectedEventIds.contains(eventViewModel.event.id);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onLongPress: () => _toggleSelection(eventViewModel.event.id),
                  onTap: _selectedEventIds.isNotEmpty
                      ? () => _toggleSelection(eventViewModel.event.id)
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (_selectedEventIds.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color:
                                        isSelected ? Colors.blue : Colors.grey,
                                  ),
                                ),
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
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getIdentityText(reservation.identity),
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (reservation.character != null &&
                              reservation.character!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              '角色：${reservation.character}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
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
                          if (!_selectedEventIds.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  for (var r in relatedReservations) {
                                    await ref
                                        .read(userReservationsProvider.notifier)
                                        .removeReservation(r.eventId);
                                  }
                                  ref
                                      .read(eventsNotifierProvider.notifier)
                                      .loadEvents();
                                },
                                icon: const Icon(Icons.cancel),
                                label: const Text('取消參加'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
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
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('載入預定失敗：$error'),
        ),
      ),
    );
  }
}
