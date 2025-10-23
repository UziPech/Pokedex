import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pokecard_dex/pokemon_cards/domain/entities/pokemon_card.dart';
import 'package:pokecard_dex/pokemon_cards/domain/repositories/pokemon_card_repository.dart';

class PokemonCardRepositoryApi implements PokemonCardRepository {
  PokemonCardRepositoryApi({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  static const _baseUrl = 'https://api.pokemontcg.io/v2/cards';

  @override
  Future<List<PokemonCard>> getCards({
    required int page,
    String? query,
    Set<String>? filters,
  }) async {
    final queryParameters = <String, String>{
      'page': page.toString(),
      'pageSize': '20',
    };
    if (query != null && query.isNotEmpty) {
      queryParameters['q'] = 'name:$query*';
    }
    // Note: the API supports filter expressions; for now we join types as a simple example.
    if (filters != null && filters.isNotEmpty) {
      queryParameters['q'] =
          (queryParameters['q'] ?? '') + ' supertype:${filters.join(',')}';
    }
    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParameters);
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load cards: ${response.statusCode}');
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>?;
    if (data == null) return <PokemonCard>[];

    return data.map((e) {
      final map = e as Map<String, dynamic>;
      final images = map['images'] as Map<String, dynamic>?;
      final imageUrl = images != null
          ? (images['small'] ?? images['large']) as String?
          : null;
      return PokemonCard(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        imageUrl: imageUrl ?? '',
        hp: map['hp']?.toString(),
        supertype: map['supertype'] as String?,
      );
    }).toList();
  }
}
