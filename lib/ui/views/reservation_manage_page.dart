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
  ReservationStatus? _selectedStatus;
  IdentityType? _selectedIdentity;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    await ref.read(userReservationsProvider.notifier).loadUserReservations();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
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

  List<Reservation> _getFilteredReservations(List<Reservation> reservations) {
    return reservations.where((reservation) {
      // 應用狀態篩選
      if (_selectedStatus != null && reservation.status != _selectedStatus) {
        return false;
      }

      // 應用身份篩選
      if (_selectedIdentity != null &&
          reservation.identity != _selectedIdentity) {
        return false;
      }

      // 應用日期範圍篩選
      if (_selectedDateRange != null) {
        final start = DateTime(_selectedDateRange!.start.year,
            _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        final end = DateTime(
            _selectedDateRange!.end.year,
            _selectedDateRange!.end.month,
            _selectedDateRange!.end.day,
            23,
            59,
            59);

        if (!reservation.createdAt.isAfter(start) ||
            !reservation.createdAt
                .isBefore(end.add(const Duration(seconds: 1)))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reservations = ref.watch(userReservationsProvider);
    final filteredReservations = _getFilteredReservations(reservations);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的預定'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => StatefulBuilder(
                  builder: (context, setState) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<ReservationStatus>(
                          isExpanded: true,
                          hint: const Text('選擇狀態'),
                          value: _selectedStatus,
                          items: ReservationStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(_getStatusText(status)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value;
                            });
                            this.setState(() {});
                          },
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<IdentityType>(
                          isExpanded: true,
                          hint: const Text('選擇身份'),
                          value: _selectedIdentity,
                          items: IdentityType.values.map((identity) {
                            return DropdownMenuItem(
                              value: identity,
                              child: Text(_getIdentityText(identity)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedIdentity = value;
                            });
                            this.setState(() {});
                          },
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          title: Text(
                            _selectedDateRange == null
                                ? '選擇日期範圍'
                                : '${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.end)}',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            await _selectDateRange();
                            setState(() {});
                            this.setState(() {});
                          },
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedStatus = null;
                              _selectedIdentity = null;
                              _selectedDateRange = null;
                            });
                            this.setState(() {});
                            Navigator.pop(context);
                          },
                          child: const Text('清除篩選'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            tooltip: '篩選',
          ),
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
          child: filteredReservations.isEmpty
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
                      Text(
                        _selectedStatus != null ||
                                _selectedIdentity != null ||
                                _selectedDateRange != null
                            ? '沒有符合篩選條件的預定'
                            : '目前沒有預定',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filteredReservations.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final reservation = filteredReservations[index];
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
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (reservation.status ==
                                      ReservationStatus.pending)
                                    ListTile(
                                      leading: const Icon(
                                          Icons.check_circle_outline),
                                      title: const Text('確認預定'),
                                      onTap: () async {
                                        await ref
                                            .read(userReservationsProvider
                                                .notifier)
                                            .updateStatus(reservation.id,
                                                ReservationStatus.confirmed);
                                        Navigator.pop(context);
                                      },
                                    ),
                                  if (reservation.status !=
                                      ReservationStatus.cancelled)
                                    ListTile(
                                      leading:
                                          const Icon(Icons.cancel_outlined),
                                      title: const Text('取消預定'),
                                      onTap: () async {
                                        await ref
                                            .read(userReservationsProvider
                                                .notifier)
                                            .cancelReservation(
                                                reservation.eventId);
                                        Navigator.pop(context);
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
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
