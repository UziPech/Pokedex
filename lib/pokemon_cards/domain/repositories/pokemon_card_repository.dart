import 'package:pokecard_dex/pokemon_cards/domain/entities/pokemon_card.dart';

abstract class PokemonCardRepository {
  /// Returns a page of cards. Page is 1-based.
  Future<List<PokemonCard>> getCards({required int page});
}
