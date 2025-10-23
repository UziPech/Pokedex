import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pokecard_dex/pokemon_cards/bloc/pokemon_card_bloc.dart';
import 'package:pokecard_dex/pokemon_cards/data/repositories/pokemon_card_repository_impl.dart';
import 'package:pokecard_dex/pokemon_cards/view/cards_view.dart';

class CardsPage extends StatelessWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PokemonCardBloc(pokemonCardRepository: PokemonCardRepositoryImpl())
            ..add(CardsFetched()),
      child: const CardsView(),
    );
  }
}
