import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GameplayUiState extends Equatable {
  final bool loseOfferShown;
  final String? praise;
  final int praiseSeq;

  const GameplayUiState({
    this.loseOfferShown = false,
    this.praise,
    this.praiseSeq = 0,
  });

  GameplayUiState copyWith({
    bool? loseOfferShown,
    String? praise,
    bool clearPraise = false,
    bool bumpPraiseSeq = false,
  }) {
    return GameplayUiState(
      loseOfferShown: loseOfferShown ?? this.loseOfferShown,
      praise: clearPraise ? null : (praise ?? this.praise),
      praiseSeq: bumpPraiseSeq ? praiseSeq + 1 : praiseSeq,
    );
  }

  @override
  List<Object?> get props => [loseOfferShown, praise, praiseSeq];
}

class GameplayUiCubit extends Cubit<GameplayUiState> {
  GameplayUiCubit() : super(const GameplayUiState());

  void showLoseOffer() {
    if (!state.loseOfferShown) {
      emit(state.copyWith(loseOfferShown: true));
    }
  }

  void hideLoseOffer() {
    if (state.loseOfferShown) {
      emit(state.copyWith(loseOfferShown: false));
    }
  }

  void showPraise(String label) {
    emit(
      state.copyWith(
        praise: label,
        clearPraise: false,
        bumpPraiseSeq: true,
      ),
    );
  }

  void clearPraiseIfSame(String label) {
    if (state.praise == label) {
      emit(state.copyWith(clearPraise: true));
    }
  }
}
