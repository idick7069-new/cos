import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/reservation.dart';
import '../../data/provider/reservation_provider.dart';
import 'package:intl/intl.dart';

class ReservationManagePage extends ConsumerStatefulWidget {
  const ReservationManagePage({super.key});

  @override
  _ReservationManagePageState createState() => _ReservationManagePageState();
}

class _ReservationManagePageState extends ConsumerState<ReservationManagePage> {
  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    await ref.read(userReservationsProvider.notifier).loadUserReservations();
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.confirmed:
        return Colors.green;
      case ReservationStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return '待確認';
      case ReservationStatus.confirmed:
        return '已確認';
      case ReservationStatus.cancelled:
        return '已取消';
    }
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

  @override
  Widget build(BuildContext context) {
    final reservations = ref.watch(userReservationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的預定'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReservations,
            tooltip: '重新整理',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReservations,
          child: reservations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '目前沒有預定',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: reservations.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final reservation = reservations[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(reservation.status)
                              .withOpacity(0.2),
                          child: Icon(
                            Icons.event,
                            color: _getStatusColor(reservation.status),
                          ),
                        ),
                        title: Text(
                          reservation.eventId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                                '身份: ${_getIdentityText(reservation.identity)}'),
                            if (reservation.character != null &&
                                reservation.character!.isNotEmpty)
                              Text('角色: ${reservation.character}'),
                            Text(
                                '預定時間: ${_formatDateTime(reservation.createdAt)}'),
                            if (reservation.updatedAt != null)
                              Text(
                                  '更新時間: ${_formatDateTime(reservation.updatedAt!)}'),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(reservation.status)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(reservation.status),
                            style: TextStyle(
                              color: _getStatusColor(reservation.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () {
                          // TODO: 實現預定詳情查看功能
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
