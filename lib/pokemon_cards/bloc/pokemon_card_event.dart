part of 'pokemon_card_bloc.dart';

sealed class PokemonCardEvent extends Equatable {
  const PokemonCardEvent();

  @override
  List<Object> get props => [];
}

final class CardsFetched extends PokemonCardEvent {}

final class CardsRefreshed extends PokemonCardEvent {}

final class CardsSearched extends PokemonCardEvent {
  const CardsSearched(this.query);
  final String query;

  @override
  List<Object> get props => [query];
}

final class FilterChanged extends PokemonCardEvent {
  const FilterChanged(this.filters);
  final Set<String> filters;

  @override
  List<Object> get props => [filters];
}
