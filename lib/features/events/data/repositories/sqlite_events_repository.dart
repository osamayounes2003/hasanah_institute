import '../../domain/entities/institute_event.dart';
import '../../domain/repositories/abstract_events_repository.dart';
import '../datasources/local_events_data_source.dart';

class SqliteEventsRepository implements AbstractEventsRepository {
  const SqliteEventsRepository(this._localDataSource);

  final LocalEventsDataSource _localDataSource;

  @override
  Future<List<InstituteEvent>> getUpcoming({
    required String fromUtcIso8601,
    InstituteEventType? type,
  }) async {
    final rows = await _localDataSource.upcoming(
      fromUtcIso8601: fromUtcIso8601,
      type: type?.name,
    );
    return rows.map(_eventFromRow).toList();
  }

  @override
  Future<void> saveEvent(InstituteEvent event) {
    return _localDataSource.save({
      'id': event.id,
      'title': event.title,
      'description': event.description,
      'event_type': event.type.name,
      'starts_at': event.startsAt,
      'ends_at': event.endsAt,
      'created_at': event.createdAt,
      'updated_at': event.updatedAt,
    });
  }

  InstituteEvent _eventFromRow(Map<String, Object?> row) {
    return InstituteEvent(
      id: row['id']! as String,
      title: row['title']! as String,
      description: row['description'] as String?,
      type: InstituteEventType.values.byName(row['event_type']! as String),
      startsAt: row['starts_at']! as String,
      endsAt: row['ends_at'] as String?,
      createdAt: row['created_at']! as String,
      updatedAt: row['updated_at']! as String,
    );
  }
}
