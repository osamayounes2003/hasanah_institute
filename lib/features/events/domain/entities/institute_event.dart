enum InstituteEventType { event, competition }

class InstituteEvent {
  const InstituteEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.startsAt,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.endsAt,
  });

  final String id;
  final String title;
  final String? description;
  final InstituteEventType type;
  final String startsAt;
  final String? endsAt;
  final String createdAt;
  final String updatedAt;
}
