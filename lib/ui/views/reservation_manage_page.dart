import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/reservation.dart';
import '../../data/models/event.dart';
import '../../data/provider/reservation_provider.dart';
import '../../data/provider/events_notifier.dart';

class ReservationManagePage extends ConsumerWidget {
  const ReservationManagePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(userReservationsProvider);
    final events = ref.watch(eventsNotifierProvider);

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
          return '本體';
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

          // 過濾出有預定的活動
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
              // 找出所有相關的預定
              final relatedReservations = reservationsList
                  .where((r) => r.eventId == eventViewModel.event.id)
                  .toList();

              // 如果沒有相關預定，跳過這個活動
              if (relatedReservations.isEmpty) {
                return const SizedBox.shrink();
              }

              // 使用第一個預定來顯示身份和角色
              final reservation = relatedReservations.first;

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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // 取消所有相關的預定
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
          child: Text('載入預定失敗：$error'),
        ),
      ),
    );
  }
}
