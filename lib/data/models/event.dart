import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String image;
  final String type;
  final String date; // 當天的日期 YYYY/MM/DD
  final String startDate; // 活動開始日期 YYYY/MM/DD
  final String endDate; // 活動結束日期 YYYY/MM/DD
  final String location;
  final String content;
  final String organizer;
  final String updateDate;
  final String url;
  final List<String> participants;
  final String? parentEventId; // 父活動ID
  final int? dayNumber; // 第幾天 (1, 2, 3...)
  final String displayTitle; // 顯示用標題 (包含第幾天)

  Event({
    required this.id,
    required this.title,
    required this.image,
    required this.type,
    required this.date,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.content,
    required this.organizer,
    required this.updateDate,
    required this.url,
    this.participants = const [],
    this.parentEventId,
    this.dayNumber,
    String? displayTitle,
  }) : displayTitle = displayTitle ??
            (dayNumber != null ? '$title Day$dayNumber' : title);

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] as String? ?? '',
      image: data['image'] as String? ?? '',
      type: data['type'] as String? ?? '',
      date: data['date'] as String? ?? '',
      startDate: data['startDate'] as String? ?? '',
      endDate: data['endDate'] as String? ?? '',
      location: data['location'] as String? ?? '',
      content: data['content'] as String? ?? '',
      organizer: data['organizer'] as String? ?? '',
      updateDate: data['updateDate'] as String? ?? '',
      url: data['url'] as String? ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      parentEventId: data['parentEventId'] as String?,
      dayNumber: data['dayNumber'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'image': image,
      'type': type,
      'date': date,
      'startDate': startDate,
      'endDate': endDate,
      'location': location,
      'content': content,
      'organizer': organizer,
      'updateDate': updateDate,
      'url': url,
      'participants': participants,
      'parentEventId': parentEventId,
      'dayNumber': dayNumber,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? image,
    String? type,
    String? date,
    String? startDate,
    String? endDate,
    String? location,
    String? content,
    String? organizer,
    String? updateDate,
    String? url,
    List<String>? participants,
    String? parentEventId,
    int? dayNumber,
    String? displayTitle,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
      type: type ?? this.type,
      date: date ?? this.date,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      content: content ?? this.content,
      organizer: organizer ?? this.organizer,
      updateDate: updateDate ?? this.updateDate,
      url: url ?? this.url,
      participants: participants ?? this.participants,
      parentEventId: parentEventId ?? this.parentEventId,
      dayNumber: dayNumber ?? this.dayNumber,
      displayTitle: displayTitle,
    );
  }

  // 解析日期字串為 DateTime
  DateTime get dateTime => _parseDate(date);
  DateTime get startDateTime => _parseDate(startDate);
  DateTime get endDateTime => _parseDate(endDate);

  DateTime _parseDate(String date) {
    try {
      final parts = date.split('/');
      return DateTime(
        int.parse(parts[0]), // year
        int.parse(parts[1]), // month
        int.parse(parts[2]), // day
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  // 檢查是否為多天活動
  bool get isMultiDayEvent => startDate != endDate;

  // 獲取活動天數
  int get totalDays {
    if (!isMultiDayEvent) return 1;
    return endDateTime.difference(startDateTime).inDays + 1;
  }

  // 生成特定天數的子活動
  Event generateDayEvent(int day) {
    if (!isMultiDayEvent || day > totalDays) return this;

    final eventDate = startDateTime.add(Duration(days: day - 1));
    final formattedDate =
        '${eventDate.year}/${eventDate.month.toString().padLeft(2, '0')}/${eventDate.day.toString().padLeft(2, '0')}';

    return Event(
      id: '${this.id}_D$day',
      title: this.title,
      image: this.image,
      type: this.type,
      date: formattedDate,
      startDate: this.startDate,
      endDate: this.endDate,
      location: this.location,
      content: this.content,
      organizer: this.organizer,
      updateDate: this.updateDate,
      url: this.url,
      participants: [],
      parentEventId: this.id,
      dayNumber: day,
    );
  }
}
