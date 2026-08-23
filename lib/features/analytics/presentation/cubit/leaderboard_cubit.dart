import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/usecases/analytics_usecases.dart';

enum LeaderboardStatus { initial, loading, success, failure }

class LeaderboardState {
  const LeaderboardState({
    this.status = LeaderboardStatus.initial,
    this.entries = const [],
    this.circleId,
    this.month,
    this.errorMessage,
  });

  final LeaderboardStatus status;
  final List<LeaderboardEntry> entries;
  final String? circleId;
  final String? month;
  final String? errorMessage;

  LeaderboardState copyWith({
    LeaderboardStatus? status,
    List<LeaderboardEntry>? entries,
    String? circleId,
    String? month,
    String? errorMessage,
    bool clearCircleFilter = false,
    bool clearMonthFilter = false,
    bool clearError = false,
  }) {
    return LeaderboardState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      circleId: clearCircleFilter ? null : circleId ?? this.circleId,
      month: clearMonthFilter ? null : month ?? this.month,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit(this._getLeaderboard) : super(const LeaderboardState());

  final GetLeaderboardUseCase _getLeaderboard;

  Future<void> load({String? circleId, String? month}) async {
    emit(
      LeaderboardState(
        status: LeaderboardStatus.loading,
        circleId: circleId,
        month: month,
      ),
    );
    try {
      final entries = await _getLeaderboard(circleId: circleId, month: month);
      emit(
        LeaderboardState(
          status: LeaderboardStatus.success,
          entries: entries,
          circleId: circleId,
          month: month,
        ),
      );
    } on ArgumentError catch (error) {
      emit(
        state.copyWith(
          status: LeaderboardStatus.failure,
          errorMessage: error.message?.toString() ?? 'فلتر الشهر غير صالح.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: LeaderboardStatus.failure,
          errorMessage: 'تعذر تحميل لوحة الصدارة.',
        ),
      );
    }
  }
}
