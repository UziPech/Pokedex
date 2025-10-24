import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokecard_dex/pokemon_cards/bloc/pokemon_card_bloc.dart';
import 'package:pokecard_dex/pokemon_cards/domain/entities/pokemon_card.dart';
import 'package:pokecard_dex/pokemon_cards/domain/repositories/pokemon_card_repository.dart';

class _MockPokemonCardRepository extends Mock
    implements PokemonCardRepository {}

void main() {
  late PokemonCardRepository repository;

  setUp(() {
    repository = _MockPokemonCardRepository();
  });

  test('initial state is initial', () {
    final bloc = PokemonCardBloc(pokemonCardRepository: repository);
    expect(bloc.state, const PokemonCardState());
  });

  group('CardsFetched', () {
    const sampleCard = PokemonCard(
      id: '1',
      name: 'Bulbasaur',
      imageUrl: 'https://example.com/bulbasaur.png',
    );

    blocTest<PokemonCardBloc, PokemonCardState>(
      'emits [success] when repository returns cards on first fetch',
      build: () {
        when(
          () => repository.getCards(page: 1),
        ).thenAnswer((_) async => const [sampleCard]);
        return PokemonCardBloc(pokemonCardRepository: repository);
      },
      act: (bloc) => bloc.add(CardsFetched()),
      expect: () => const <PokemonCardState>[
        PokemonCardState(
          status: PokemonCardStatus.success,
          cards: [sampleCard],
        ),
      ],
    );

    blocTest<PokemonCardBloc, PokemonCardState>(
      'emits [initial, success] when refreshed',
      build: () {
        when(
          () => repository.getCards(page: 1),
        ).thenAnswer((_) async => const [sampleCard]);
        return PokemonCardBloc(pokemonCardRepository: repository);
      },
      act: (bloc) => bloc.add(CardsRefreshed()),
      expect: () => const <PokemonCardState>[
        PokemonCardState(),
        PokemonCardState(
          status: PokemonCardStatus.success,
          cards: [sampleCard],
        ),
      ],
    );

    blocTest<PokemonCardBloc, PokemonCardState>(
      'emits [failure] when repository throws on fetch',
      build: () {
        when(() => repository.getCards(page: 1)).thenThrow(Exception('oops'));
        return PokemonCardBloc(pokemonCardRepository: repository);
      },
      act: (bloc) => bloc.add(CardsFetched()),
      expect: () => const <PokemonCardState>[
        PokemonCardState(status: PokemonCardStatus.failure),
      ],
    );

    blocTest<PokemonCardBloc, PokemonCardState>(
      'emits [initial(query), success] when searching',
      build: () {
        when(
          () => repository.getCards(page: 1, query: 'bulba'),
        ).thenAnswer((_) async => const [sampleCard]);
        return PokemonCardBloc(pokemonCardRepository: repository);
      },
      act: (bloc) => bloc.add(const CardsSearched('bulba')),
      expect: () => const <PokemonCardState>[
        PokemonCardState(query: 'bulba'),
        PokemonCardState(
          status: PokemonCardStatus.success,
          cards: [sampleCard],
          query: 'bulba',
        ),
      ],
    );

    blocTest<PokemonCardBloc, PokemonCardState>(
      'emits [initial(filters), success] when filters change',
      build: () {
        when(
          () => repository.getCards(page: 1, filters: {'Pokémon'}),
        ).thenAnswer((_) async => const [sampleCard]);
        return PokemonCardBloc(pokemonCardRepository: repository);
      },
      act: (bloc) => bloc.add(const FilterChanged({'Pokémon'})),
      expect: () => const <PokemonCardState>[
        PokemonCardState(filters: {'Pokémon'}),
        PokemonCardState(
          status: PokemonCardStatus.success,
          cards: [sampleCard],
          filters: {'Pokémon'},
        ),
      ],
    );
  });
}
