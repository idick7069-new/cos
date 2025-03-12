import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String image;
  final String type;
  final String date; // 原始日期字串
  final String startDate; // YYYY/MM/DD 格式
  final String endDate; // YYYY/MM/DD 格式
  final String location;
  final String content;
  final String organizer;
  final String updateDate;
  final String url;
  final List<String> participants;

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
  });

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
    };
  }

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
}
