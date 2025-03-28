import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../models/reservation.dart';

class SharePageState {
  final String location;
  final IdentityType identity;
  final String name;
  final String note;
  final Map<int, File?> photos;
  final bool isLoading;
  final String? error;

  SharePageState({
    required this.location,
    required this.identity,
    required this.name,
    required this.note,
    required this.photos,
    this.isLoading = false,
    this.error,
  });

  SharePageState copyWith({
    String? location,
    IdentityType? identity,
    String? name,
    String? note,
    Map<int, File?>? photos,
    bool? isLoading,
    String? error,
  }) {
    return SharePageState(
      location: location ?? this.location,
      identity: identity ?? this.identity,
      name: name ?? this.name,
      note: note ?? this.note,
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SharePageNotifier extends StateNotifier<SharePageState> {
  SharePageNotifier()
      : super(SharePageState(
          location: '',
          identity: IdentityType.coser,
          name: '',
          note: '',
          photos: {},
        ));

  void setLocation(String location) {
    state = state.copyWith(location: location);
  }

  void setIdentity(IdentityType identity) {
    state = state.copyWith(identity: identity);
  }

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setNote(String note) {
    state = state.copyWith(note: note);
  }

  void setPhoto(int day, File? photo) {
    final newPhotos = Map<int, File?>.from(state.photos);
    newPhotos[day] = photo;
    state = state.copyWith(photos: newPhotos);
  }

  void initializeWithEvent(Event event, Reservation? reservation) {
    // 初始化照片上傳區域
    final Map<int, File?> initialPhotos = {};
    for (var i = 0; i < event.totalDays; i++) {
      initialPhotos[i] = null;
    }

    state = SharePageState(
      location: event.location,
      identity: reservation?.identity ?? IdentityType.coser,
      name: reservation?.character ?? '',
      note: reservation?.note ?? '',
      photos: initialPhotos,
    );
  }

  void reset() {
    final Map<int, File?> emptyPhotos = {};

    state = SharePageState(
      location: '',
      identity: IdentityType.coser,
      name: '',
      note: '',
      photos: emptyPhotos,
    );
  }
}

final sharePageProvider =
    StateNotifierProvider<SharePageNotifier, SharePageState>((ref) {
  return SharePageNotifier();
});
