import 'package:pokecard_dex/app/app.dart';
import 'package:pokecard_dex/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
