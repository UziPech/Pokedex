import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pokecard_dex/pokemon_cards/bloc/pokemon_card_bloc.dart';
import 'package:pokecard_dex/pokemon_cards/data/pokemon_card_repository_api.dart';
import 'package:pokecard_dex/pokemon_cards/domain/repositories/pokemon_card_repository.dart';
import 'package:pokecard_dex/pokemon_cards/view/cards_view.dart';

class CardsPage extends StatelessWidget {
  const CardsPage({super.key, this.pokemonCardRepository});

  final PokemonCardRepository? pokemonCardRepository;

  @override
  Widget build(BuildContext context) {
    final repo = pokemonCardRepository ?? PokemonCardRepositoryApi();
    return BlocProvider(
      create: (_) =>
          PokemonCardBloc(pokemonCardRepository: repo)..add(CardsFetched()),
      child: const CardsView(),
    );
  }
}
