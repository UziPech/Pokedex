part of 'pokemon_card_bloc.dart';

sealed class PokemonCardEvent extends Equatable {
  const PokemonCardEvent();

  @override
  List<Object> get props => [];
}

final class CardsFetched extends PokemonCardEvent {}
