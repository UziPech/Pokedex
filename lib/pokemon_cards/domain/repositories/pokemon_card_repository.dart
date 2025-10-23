import 'package:pokecard_dex/pokemon_cards/domain/entities/pokemon_card.dart';

abstract class PokemonCardRepository {
  /// Returns a page of cards. Page is 1-based.
  /// Optionally accepts [query] and [filters] in the future for search/filtering.
  Future<List<PokemonCard>> getCards({
    required int page,
    String? query,
    Set<String>? filters,
  });
}
