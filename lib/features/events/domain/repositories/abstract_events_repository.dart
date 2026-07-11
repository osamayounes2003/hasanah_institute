import '../entities/institute_event.dart';

abstract interface class AbstractEventsRepository {
  Future<void> saveEvent(InstituteEvent event);
  Future<List<InstituteEvent>> getUpcoming({
    required String fromUtcIso8601,
    InstituteEventType? type,
  });
}
