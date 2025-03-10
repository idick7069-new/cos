


import '../../../data/models/event.dart';

class EventViewModel {
    final Event event;
    final bool isParticipating;
    final String? reservationId;

    EventViewModel({
        required this.event,
        required this.isParticipating,
        this.reservationId,
    });
}
