import 'package:equatable/equatable.dart';

class PokemonCard extends Equatable {
  const PokemonCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.hp,
    this.supertype,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String? hp;
  final String? supertype;

  @override
  List<Object?> get props => [id, name, imageUrl, hp, supertype];
}
