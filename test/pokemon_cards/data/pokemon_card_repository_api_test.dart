import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:pokecard_dex/pokemon_cards/data/pokemon_card_repository_api.dart';
import 'package:pokecard_dex/pokemon_cards/domain/entities/pokemon_card.dart';

class _MockClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    // Register a fallback Uri instance for mocktail when using `any()`
    // on Uri parameters.
    registerFallbackValue(
      Uri.parse('https://example.com/'),
    );
  });

  late _MockClient client;
  late PokemonCardRepositoryApi repository;

  setUp(() {
    client = _MockClient();
    repository = PokemonCardRepositoryApi(client: client);
  });

  test('returns list of PokemonCard on 200 response', () async {
    final body = {
      'data': [
        {
          'id': 'xy1-1',
          'name': 'Testmon',
          'images': {
            'small': 'https://example.com/s.png',
            'large': 'https://example.com/l.png',
          },
          'hp': '60',
          'supertype': 'Pokémon',
        },
      ],
    };

    when(
      () => client.get(
        any(),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer((_) async => http.Response(jsonEncode(body), 200));

    final cards = await repository.getCards(page: 1);

    expect(cards, isA<List<PokemonCard>>());
    expect(cards, hasLength(1));
    expect(cards.first.id, 'xy1-1');
    expect(cards.first.name, 'Testmon');
    expect(cards.first.imageUrl, 'https://example.com/s.png');
  });

  test('throws exception on non-200 response', () async {
    when(
      () => client.get(
        any(),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer((_) async => http.Response('error', 500));

    expect(() => repository.getCards(page: 1), throwsException);
  });
}
