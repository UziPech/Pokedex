import 'dart:async';

import 'package:pokecard_dex/pokemon_cards/domain/entities/pokemon_card.dart';
import 'package:pokecard_dex/pokemon_cards/domain/repositories/pokemon_card_repository.dart';

/// Simple in-memory implementation used for development and tests.
class PokemonCardRepositoryImpl implements PokemonCardRepository {
  PokemonCardRepositoryImpl();

  static const _pageSize = 20;
  static const _maxPages = 3;

  @override
  Future<List<PokemonCard>> getCards({
    required int page,
    String? query,
    Set<String>? filters,
  }) async {
    // Simulate network latency
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (page > _maxPages) return <PokemonCard>[];

    final startIndex = (page - 1) * _pageSize + 1;
    final cards = List<PokemonCard>.generate(_pageSize, (i) {
      final id = 'card_${startIndex + i}';
      return PokemonCard(
        id: id,
        name: 'Pokémon ${startIndex + i}',
        imageUrl:
            'https://via.placeholder.com/96x96.png?text=${startIndex + i}',
        hp: (50 + (i % 100)).toString(),
        supertype: 'Pokémon',
      );
    });

    return cards;
  }
}
