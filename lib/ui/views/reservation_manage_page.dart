import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/reservation.dart';
import '../../data/models/event.dart';
import '../../data/provider/reservation_provider.dart';
import '../../data/provider/events_provider.dart';

class ReservationManagePage extends ConsumerWidget {
  const ReservationManagePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(userReservationsProvider);
    final eventsAsync = ref.watch(eventsProvider);

    String _formatDateTime(DateTime dateTime) {
      return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
    }

    String _getIdentityText(IdentityType identity) {
      switch (identity) {
        case IdentityType.manager:
          return '主辦方';
        case IdentityType.photographer:
          return '攝影師';
        case IdentityType.coser:
          return 'Coser';
        case IdentityType.original:
          return '原創';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的預定'),
        elevation: 0,
      ),
      body: reservations.when(
        data: (reservationsList) {
          if (reservationsList.isEmpty) {
            return const Center(
              child: Text('目前沒有預定'),
            );
          }

          return eventsAsync.when(
            data: (events) {
              return ListView.builder(
                itemCount: reservationsList.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final reservation = reservationsList[index];
                  final event = events.firstWhere(
                    (e) => e.id == reservation.eventId,
                    orElse: () => Event(
                      id: '',
                      title: '找不到活動',
                      startDate: DateTime.now(),
                      endDate: DateTime.now(),
                      participants: [],
                    ),
                  );

                  if (event.id.isEmpty) return const SizedBox.shrink();

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
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
                                  event.title,
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
                                  '${_formatDateTime(event.startDate)} - ${_formatDateTime(event.endDate)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ref
                                    .read(userReservationsProvider.notifier)
                                    .removeReservation(reservation.eventId);
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
              child: Text('載入活動失敗：$error'),
            ),
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
