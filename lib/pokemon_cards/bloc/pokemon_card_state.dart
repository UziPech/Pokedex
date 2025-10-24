part of 'pokemon_card_bloc.dart';

enum PokemonCardStatus { initial, success, failure }

final class PokemonCardState extends Equatable {
  const PokemonCardState({
    this.status = PokemonCardStatus.initial,
    this.cards = const <PokemonCard>[],
    this.hasReachedMax = false,
    this.query = '',
    this.filters = const <String>{},
  });

  final PokemonCardStatus status;
  final List<PokemonCard> cards;
  final bool hasReachedMax;
  final String query;
  final Set<String> filters;

  PokemonCardState copyWith({
    PokemonCardStatus? status,
    List<PokemonCard>? cards,
    bool? hasReachedMax,
    String? query,
    Set<String>? filters,
  }) {
    return PokemonCardState(
      status: status ?? this.status,
      cards: cards ?? this.cards,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      query: query ?? this.query,
      filters: filters ?? this.filters,
    );
  }

  @override
  List<Object> get props => [status, cards, hasReachedMax, query, filters];
}
