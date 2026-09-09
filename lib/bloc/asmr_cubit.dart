import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Discrete ASMR UI events — never emitted on the animation ticker.
class AsmrState extends Equatable {
  final int boxClears;
  final int plateClears;
  final int score;
  final String? praise;
  final int praiseSeq;

  const AsmrState({
    this.boxClears = 0,
    this.plateClears = 0,
    this.score = 0,
    this.praise,
    this.praiseSeq = 0,
  });

  AsmrState copyWith({
    int? boxClears,
    int? plateClears,
    int? score,
    String? praise,
    bool clearPraise = false,
    int? praiseSeq,
  }) {
    return AsmrState(
      boxClears: boxClears ?? this.boxClears,
      plateClears: plateClears ?? this.plateClears,
      score: score ?? this.score,
      praise: clearPraise ? null : (praise ?? this.praise),
      praiseSeq: praiseSeq ?? this.praiseSeq,
    );
  }

  @override
  List<Object?> get props =>
      [boxClears, plateClears, score, praise, praiseSeq];
}

class AsmrCubit extends Cubit<AsmrState> {
  AsmrCubit() : super(const AsmrState());

  static const int boxPoints = 100;
  static const int trayPoints = 50;

  void setScores({required int boxes, required int plates}) {
    final score = boxes * boxPoints + plates * trayPoints;
    if (state.boxClears == boxes &&
        state.plateClears == plates &&
        state.score == score) {
      return;
    }
    emit(state.copyWith(boxClears: boxes, plateClears: plates, score: score));
  }

  void showPraise(String label) {
    emit(state.copyWith(praise: label, praiseSeq: state.praiseSeq + 1));
  }

  void clearPraise() {
    if (state.praise == null) return;
    emit(state.copyWith(clearPraise: true));
  }
}
