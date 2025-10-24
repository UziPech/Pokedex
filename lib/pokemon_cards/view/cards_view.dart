// ignore_for_file: cascade_invocations  // Reason: duplicate-receiver suggestions are
// low-value here due to repeated UI scaffolding; will refactor if actionable.

import 'dart:async';

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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // Debouncer placeholder kept for future shared config.

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    final bodyHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('PokéCard Dex'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              await showSearch<void>(
                context: context,
                delegate: _CardSearchDelegate(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      drawer: Drawer(
        child: _FilterDrawer(),
      ),
      body: BlocBuilder<PokemonCardBloc, PokemonCardState>(
        builder: (context, state) {
          switch (state.status) {
            case PokemonCardStatus.failure:
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: bodyHeight,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar las cartas',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.red[700],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Desliza hacia abajo para intentar de nuevo',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
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
                      height: bodyHeight,
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

class _CardSearchDelegate extends SearchDelegate<void> {
  Timer? _debounce;
  int get _debounceMs => 300;
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Dispatch search and close
    context.read<PokemonCardBloc>().add(CardsSearched(query));
    close(context, null);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Debounce search as the user types.
    _debounce?.cancel();
    if (query.isNotEmpty) {
      _debounce = Timer(Duration(milliseconds: _debounceMs), () {
        context.read<PokemonCardBloc>().add(CardsSearched(query));
      });
    }
    return const SizedBox.shrink();
  }

  @override
  void close(BuildContext context, void result) {
    _debounce?.cancel();
    super.close(context, result);
  }
}

class _FilterDrawer extends StatefulWidget {
  @override
  State<_FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<_FilterDrawer> {
  static const _options = <String>['Pokémon', 'Trainer', 'Energy'];
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    final bloc = context.read<PokemonCardBloc>();
    _selected.addAll(bloc.state.filters);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const ListTile(title: Text('Filtros')),
          Expanded(
            child: ListView(
              children: _options.map((o) {
                return CheckboxListTile(
                  title: Text(o),
                  value: _selected.contains(o),
                  onChanged: (v) {
                    setState(() {
                      if (v ?? false) {
                        _selected.add(o);
                      } else {
                        _selected.remove(o);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<PokemonCardBloc>().add(
                        FilterChanged(_selected),
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
