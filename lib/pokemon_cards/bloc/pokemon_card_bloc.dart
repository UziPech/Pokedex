import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:pokecard_dex/pokemon_cards/domain/entities/pokemon_card.dart';
import 'package:pokecard_dex/pokemon_cards/domain/repositories/pokemon_card_repository.dart';
import 'package:stream_transform/stream_transform.dart';

part 'pokemon_card_event.dart';
part 'pokemon_card_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class PokemonCardBloc extends Bloc<PokemonCardEvent, PokemonCardState> {
  PokemonCardBloc({required PokemonCardRepository pokemonCardRepository})
    : _pokemonCardRepository = pokemonCardRepository,
      super(const PokemonCardState()) {
    on<CardsFetched>(
      _onCardsFetched,
      transformer: throttleDroppable(_throttleDuration),
    );
    on<CardsRefreshed>(_onCardsRefreshed);
    on<CardsSearched>(_onCardsSearched);
    on<FilterChanged>(_onFilterChanged);
  }

  final PokemonCardRepository _pokemonCardRepository;
  int _currentPage = 1;

  Future<void> _onCardsFetched(
    CardsFetched event,
    Emitter<PokemonCardState> emit,
  ) async {
    if (state.hasReachedMax) return;
    try {
      if (state.status == PokemonCardStatus.initial) {
        final cards = await _pokemonCardRepository.getCards(
          page: _currentPage,
          query: state.query.isNotEmpty ? state.query : null,
          filters: state.filters.isNotEmpty ? state.filters : null,
        );
        _currentPage++;
        return emit(
          state.copyWith(
            status: PokemonCardStatus.success,
            cards: cards,
            hasReachedMax: false,
          ),
        );
      }
      final cards = await _pokemonCardRepository.getCards(
        page: _currentPage,
        query: state.query.isNotEmpty ? state.query : null,
        filters: state.filters.isNotEmpty ? state.filters : null,
      );
      _currentPage++;
      if (cards.isEmpty) {
        emit(state.copyWith(hasReachedMax: true));
      } else {
        emit(
          state.copyWith(
            status: PokemonCardStatus.success,
            cards: List.of(state.cards)..addAll(cards),
            hasReachedMax: false,
          ),
        );
      }
    } on Exception catch (_) {
      emit(state.copyWith(status: PokemonCardStatus.failure));
    }
  }

  Future<void> _onCardsRefreshed(
    CardsRefreshed event,
    Emitter<PokemonCardState> emit,
  ) async {
    // Reset pagination and fetch first page
    _currentPage = 1;
    try {
      emit(state.copyWith(status: PokemonCardStatus.initial));
      final cards = await _pokemonCardRepository.getCards(
        page: _currentPage,
        query: state.query.isNotEmpty ? state.query : null,
        filters: state.filters.isNotEmpty ? state.filters : null,
      );
      _currentPage++;
      emit(
        state.copyWith(
          status: PokemonCardStatus.success,
          cards: cards,
          hasReachedMax: false,
        ),
      );
    } on Exception catch (_) {
      emit(state.copyWith(status: PokemonCardStatus.failure));
    }
  }

  Future<void> _onCardsSearched(
    CardsSearched event,
    Emitter<PokemonCardState> emit,
  ) async {
    _currentPage = 1;
    try {
      emit(
        state.copyWith(status: PokemonCardStatus.initial, query: event.query),
      );
      final cards = await _pokemonCardRepository.getCards(
        page: _currentPage,
        query: event.query.isNotEmpty ? event.query : null,
        filters: state.filters.isNotEmpty ? state.filters : null,
      );
      _currentPage++;
      emit(
        state.copyWith(
          status: PokemonCardStatus.success,
          cards: cards,
          hasReachedMax: false,
          query: event.query,
        ),
      );
    } on Exception catch (_) {
      emit(state.copyWith(status: PokemonCardStatus.failure));
    }
  }

  Future<void> _onFilterChanged(
    FilterChanged event,
    Emitter<PokemonCardState> emit,
  ) async {
    _currentPage = 1;
    try {
      emit(
        state.copyWith(
          status: PokemonCardStatus.initial,
          filters: event.filters,
        ),
      );
      final cards = await _pokemonCardRepository.getCards(
        page: _currentPage,
        query: state.query.isNotEmpty ? state.query : null,
        filters: event.filters.isNotEmpty ? event.filters : null,
      );
      _currentPage++;
      emit(
        state.copyWith(
          status: PokemonCardStatus.success,
          cards: cards,
          hasReachedMax: false,
          filters: event.filters,
        ),
      );
    } on Exception catch (_) {
      emit(state.copyWith(status: PokemonCardStatus.failure));
    }
  }
}
