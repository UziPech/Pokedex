import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:pokecard_dex/pokemon_cards/data/pokemon_card_repository_api.dart';
import 'package:pokecard_dex/pokemon_cards/domain/entities/pokemon_card.dart';

class _MockClient extends Mock implements http.Client {}

void main() {
  late _MockClient client;
  late PokemonCardRepositoryApi repo;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.invalid'));
  });

  setUp(() {
    client = _MockClient();
    repo = PokemonCardRepositoryApi(client: client);
  });

  test('retries on exception and succeeds on later attempt', () async {
    var call = 0;

    // First two attempts throw, third returns valid response
    when(
      () => client.get(
        any<Uri>(),
        headers: any<Map<String, String>>(named: 'headers'),
      ),
    ).thenAnswer((_) async {
      call += 1;
      if (call < 3) throw Exception('network');
      return http.Response(
        json.encode({
          'data': [
            {
              'id': '1',
              'name': 'Testmon',
              'images': {'small': 'https://example.com/img.png'},
            },
          ],
        }),
        200,
      );
    });

    final cards = await repo.getCards(page: 1);
    expect(cards, isA<List<PokemonCard>>());
    expect(cards, isNotEmpty);
    expect(cards.first.name, equals('Testmon'));
  });

  test('throws after max retries when server returns 500', () async {
    when(
      () => client.get(
        any<Uri>(),
        headers: any<Map<String, String>>(named: 'headers'),
      ),
    ).thenAnswer((_) async => http.Response('error', 500));

    expect(() => repo.getCards(page: 1), throwsException);
  });
}
