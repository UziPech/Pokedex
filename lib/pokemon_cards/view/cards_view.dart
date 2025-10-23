import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pokecard_dex/pokemon_cards/bloc/pokemon_card_bloc.dart';
import 'package:pokecard_dex/pokemon_cards/widgets/bottom_loader.dart';
import 'package:pokecard_dex/pokemon_cards/widgets/card_list_item.dart';

class CardsView extends StatefulWidget {
  const CardsView({super.key});

  @override
  State<CardsView> createState() => _CardsViewState();
}

class _CardsViewState extends State<CardsView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PokéCard Dex')),
      body: BlocBuilder<PokemonCardBloc, PokemonCardState>(
        builder: (context, state) {
          switch (state.status) {
            case PokemonCardStatus.failure:
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - kToolbarHeight,
                    child: const Center(
                      child: Text('Fallo al obtener las cartas'),
                    ),
                  ),
                ),
              );
            case PokemonCardStatus.success:
              if (state.cards.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height:
                          MediaQuery.of(context).size.height - kToolbarHeight,
                      child: const Center(
                        child: Text('No se encontraron cartas'),
                      ),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: state.hasReachedMax
                      ? state.cards.length
                      : state.cards.length + 1,
                  itemBuilder: (BuildContext context, int index) {
                    return index >= state.cards.length
                        ? const BottomLoader()
                        : CardListItem(card: state.cards[index]);
                  },
                ),
              );
            case PokemonCardStatus.initial:
              return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<PokemonCardBloc>();
    bloc.add(CardsRefreshed());
    // Wait until bloc emits either success or failure after refresh
    await bloc.stream.firstWhere(
      (s) =>
          s.status == PokemonCardStatus.success ||
          s.status == PokemonCardStatus.failure,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) context.read<PokemonCardBloc>().add(CardsFetched());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    return currentScroll >= (maxScroll * 0.9);
  }
}
