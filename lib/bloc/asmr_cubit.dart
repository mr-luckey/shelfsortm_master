import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Discrete ASMR UI events — never emitted on the animation ticker.
class AsmrState extends Equatable {
  final int boxClears;
  final int plateClears;
  final String? praise;
  final int praiseSeq;

  const AsmrState({
    this.boxClears = 0,
    this.plateClears = 0,
    this.praise,
    this.praiseSeq = 0,
  });

  AsmrState copyWith({
    int? boxClears,
    int? plateClears,
    String? praise,
    bool clearPraise = false,
    int? praiseSeq,
  }) {
    return AsmrState(
      boxClears: boxClears ?? this.boxClears,
      plateClears: plateClears ?? this.plateClears,
      praise: clearPraise ? null : (praise ?? this.praise),
      praiseSeq: praiseSeq ?? this.praiseSeq,
    );
  }

  @override
  List<Object?> get props => [boxClears, plateClears, praise, praiseSeq];
}

class AsmrCubit extends Cubit<AsmrState> {
  AsmrCubit() : super(const AsmrState());

  void setScores({required int boxes, required int plates}) {
    if (state.boxClears == boxes && state.plateClears == plates) return;
    emit(state.copyWith(boxClears: boxes, plateClears: plates));
  }

  void showPraise(String label) {
    emit(state.copyWith(praise: label, praiseSeq: state.praiseSeq + 1));
  }

  void clearPraise() {
    if (state.praise == null) return;
    emit(state.copyWith(clearPraise: true));
  }
}
