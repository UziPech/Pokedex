import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:pokecard_dex/pokemon_cards/domain/entities/pokemon_card.dart';
import 'package:pokecard_dex/pokemon_cards/domain/repositories/pokemon_card_repository.dart';

class PokemonCardRepositoryApi implements PokemonCardRepository {
  PokemonCardRepositoryApi({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  static const _baseUrl = 'https://api.pokemontcg.io/v2/cards';
  static const Duration _timeout = Duration(seconds: 5);
  static const int _maxRetries = 2;
  static const Duration _baseRetryDelay = Duration(milliseconds: 300);

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
    // The API supports filter expressions. For now we build a simple
    // comma-separated supertype expression when filters are present.
    if (filters != null && filters.isNotEmpty) {
      final existingQ = queryParameters['q'] ?? '';
      queryParameters['q'] = '$existingQ supertype:${filters.join(',')}';
    }

    final uriBase = Uri.parse(_baseUrl);
    final uri = uriBase.replace(
      queryParameters: queryParameters,
    );
    http.Response response;
    // Simple retry loop with timeout and exponential backoff.
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        response = await _client
            .get(uri, headers: {'Accept': 'application/json'})
            .timeout(_timeout);

        final status = response.statusCode;
        if (status != 200) {
          throw Exception('Failed to load cards: $status');
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
      } on Exception {
        if (attempt == _maxRetries) rethrow;
        final delay = Duration(
          milliseconds: _baseRetryDelay.inMilliseconds * (attempt + 1),
        );
        await Future<void>.delayed(delay);
      }
    }
    // Should never reach here, but return empty list as a fallback.
    return <PokemonCard>[];
  }
}
