### Eventos (`pokemon_card_event.dart`)

Los eventos son clases simples que representan las entradas al BLoC. Para la funcionalidad de lista infinita, solo se necesita un evento inicialmente.

Crea el archivo `lib/pokemon_cards/bloc/pokemon_card_event.dart`.

```dart
part of 'pokemon_card_bloc.dart';

sealed class PokemonCardEvent extends Equatable {
  const PokemonCardEvent();

  @override
  List<Object> get props => [];
}

final class CardsFetched extends PokemonCardEvent {}
```

La palabra clave `sealed` asegura que todos los posibles subtipos de `PokemonCardEvent` se definan dentro del mismo archivo, haciendo la lógica más robusta.

### Estados (`pokemon_card_state.dart`)

El estado representa los datos que la interfaz de usuario renderizará. Se utiliza una única clase de estado para modelar todos los posibles estados de la interfaz de usuario, desde la carga inicial hasta el éxito y el fracaso.

Crea el archivo lib/pokemon_cards/bloc/pokemon_card_state.dart.
part of 'pokemon_card_bloc.dart';

enum PokemonCardStatus { initial, success, failure }

final class PokemonCardState extends Equatable {
  const PokemonCardState({
    this.status = PokemonCardStatus.initial,
    this.cards = const <PokemonCard>[],
    this.hasReachedMax = false,
  });

  final PokemonCardStatus status;
  final List<PokemonCard> cards;
  final bool hasReachedMax;

  PokemonCardState copyWith({
    PokemonCardStatus? status,
    List<PokemonCard>? cards,
    bool? hasReachedMax,
  }) {
    return PokemonCardState(
      status: status ?? this.status,
      cards: cards ?? this.cards,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [
    status,
    cards,
    hasReachedMax,
  ];
}

Esta clase de estado contiene:

- Un `enum` `PokemonCardStatus` para rastrear el estado de carga actual.
- Una lista de entidades `PokemonCard` para mostrar.
- Un booleano `hasReachedMax` para saber cuándo dejar de buscar más datos.
- Un método `copyWith`. Esta es un
a parte crucial de la gestión de estado inmutable. En lugar de modificar el estado existente (lo que puede llevar a un comportamiento impredecible), se crea una nueva copia del estado con los valores actualizados.17

### Construyendo el Cerebro (El `PokemonCardBloc`)

El Bloc en sí es la pieza central que conecta eventos, estados y el repositorio. Contiene la lógica de negocio principal para la funcionalidad.

Crea el archivo `lib/pokemon_cards/bloc/pokemon_card_bloc.dart`.

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:pokecard_dex/pokemon_cards/domain/entities/pokemon_card.dart';
import 'package:pokecard_dex/pokemon_cards/domain/repositories/pokemon_card_repository.dart';
import 'package:stream_transform/stream_transform.dart';

part 'pokemon_card_event.dart';
part 'pokemon_card_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class PokemonCardBloc extends Bloc<PokemonCardEvent, PokemonCardState> {
  PokemonCardBloc({required PokemonCardRepository pokemonCardRepository})
      : _pokemonCardRepository = pokemonCardRepository,
        super(const PokemonCardState()) {
    on<CardsFetched>(
      _onCardsFetched,
      transformer: throttleDroppable(_throttleDuration),
    );
  }

  final PokemonCardRepository _pokemonCardRepository;
  int _currentPage = 1;

  Future<void> _onCardsFetched(
    CardsFetched event,
    Emitter<PokemonCardState> emit,
  ) async {
    if (state.hasReachedMax) return;
    try {
      if (state.status == PokemonCardStatus.initial) {
        final cards = await _pokemonCardRepository.getCards(page: _currentPage);
        _currentPage++;
        return emit(state.copyWith(
          status: PokemonCardStatus.success,
          cards: cards,
          hasReachedMax: false,
        ));
      }

      final cards = await _pokemonCardRepository.getCards(page: _currentPage);
      _currentPage++;
      if (cards.isEmpty) {
        emit(state.copyWith(hasReachedMax: true));
      } else {
        emit(state.copyWith(
          status: PokemonCardStatus.success,
          cards: List.of(state.cards)..addAll(cards),
          hasReachedMax: false,
        ));
      }
    } catch (_) {
      emit(state.copyWith(status: PokemonCardStatus.failure));
    }
  }
}
Elementos clave de esta implementación incluyen:

- **Inyección de Dependencias:** El `PokemonCardBloc` depende del `PokemonCardRepository` abstracto, no de la implementación concreta. Este repositorio se "inyecta" a través del constructor. Este desacoplamiento es la piedra angular de una arquitectura comprobable.
- **Manejador de Eventos:** El registro `on<CardsFetched>` vincula el evento `CardsFetched` con el método `_onCardsFetched`, que contiene la lógica para manejarlo.
- **Throttling:** El parámetro `transformer` se utiliza con una función `throttleDroppable` de `bloc_concurrency`. Esto evita que el usuario sature la API con eventos de scroll rápidos. Asegura que un nuevo evento `CardsFetched` se procese solo después de que haya pasado una corta duración desde el último, y descarta cualquier evento que llegue mientras uno ya se está procesando.
- **Emisión de Estado:** El `Emitter<PokemonCardState>` se utiliza para emitir nuevos estados. La lógica maneja la obtención inicial, las obtenciones posteriores, el caso en que se alcanza el final de la lista (la API devuelve una lista vacía) y cualquier error potencial del repositorio.

La decisión de hacer que el BLoC dependa de un repositorio *abstracto* es una aplicación práctica del Principio de Inversión de Dependencias (la "D" en SOLID). Esto no es simplemente un ejercicio académico; es lo que desbloquea las pruebas unitarias verdaderas y de nivel profesional. Para probar el `PokemonCardBloc` en completo aislamiento, se deben evitar las llamadas de red reales, que son lentas, poco fiables y una dependencia externa. Debido a que el constructor del BLoC acepta cualquier clase que se ajuste al contrato de `PokemonCardRepository`, se puede crear una versión "mock" o "falsa" del repositorio durante las pruebas utilizando una biblioteca como `mocktail`. Este repositorio mock se puede programar para devolver una lista predefinida de cartas o para lanzar un error a demanda. Esto permite la verificación de cada posible ruta lógica dentro del BLoC —la
obtención inicial, las obtenciones posteriores, alcanzar el número máximo de elementos y manejar un fallo de red— sin tocar nunca el paquete `dio` o internet. Esta elección arquitectónica habilita directamente la estrategia de pruebas profesional que es un principio fundamental de la filosofía de `very_good_cli`.

---

## Fase 4: Creando la Interfaz de Usuario

La capa de Presentación es donde el estado de la aplicación se traduce en píxeles en la pantalla. Con la lógica de negocio cuidadosamente encapsulada en el `PokemonCardBloc`, el código de la interfaz de usuario se vuelve declarativo y sencillo. Su única responsabilidad es construir widgets basados en el estado actual y despachar eventos en respuesta a las interacciones del usuario.

### Diseñando los Componentes (La Capa de Widgets)

Para mantener el código de la vista limpio y promover la reutilización, el elemento individual de la lista y el cargador inferior se extraen en sus propios widgets. Estos se colocarán en un directorio `lib/pokemon_cards/widgets/`.

### `card_list_item.dart`

Este es un `StatelessWidget` que recibe una entidad `PokemonCard` y es responsable de mostrar su información.

import 'package:flutter/material.dart';
import 'package:pokecard_dex/pokemon_cards/domain/entities/pokemon_card.dart';

class CardListItem extends StatelessWidget {
  const CardListItem({required this.card, super.key});

  final PokemonCard card;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Image.network(
          card.imageUrl,
          width: 50,
          fit: BoxFit.contain,
          // Añadir un loading builder para una mejor experiencia de usuario
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              width: 50,
              height: 50,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          // Añadir un error builder para fallos de red
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.error),
        ),
        title: Text(card.name),
        subtitle: Text('HP: ${card.hp?? 'N/A'} - ${card.supertype?? ''}'),
        dense: true,
      ),
    );
  }
}

### `bottom_loader.dart`

Este es un `StatelessWidget` simple que proporciona retroalimentación visual al usuario de que se está cargando más contenido.

import 'package:flutter/material.dart';

class BottomLoader extends StatelessWidget {
  const BottomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      ),
    );
  }
}
Con estos componentes en su lugar, la interfaz de usuario está completa. Está totalmente desacoplada de la lógica de negocio y la obtención de datos, reaccionando solo a los estados emitidos por el `PokemonCardBloc`.

---

### Conectando la Interfaz de Usuario a la Lógica (La Capa de Vista)

Todos los archivos relacionados con la interfaz de usuario para esta funcionalidad se ubicarán en el directorio `lib/pokemon_cards/view/`. La estructura típicamente consiste en un widget de "página" que proporciona el BLoC y un widget de "vista" que construye la interfaz de usuario.

### La Vista (`cards_view.dart`)

El widget de vista es responsable de renderizar la interfaz de usuario real. Escucha los cambios de estado del `PokemonCardBloc` y construye los widgets apropiados.

Dart
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
              return const Center(child: Text('Fallo al obtener las cartas'));
            case PokemonCardStatus.success:
              if (state.cards.isEmpty) {
                return const Center(child: Text('No se encontraron cartas'));
              }
              // El ListView.builder irá aquí
              return ListView.builder(
                controller: _scrollController,
                itemCount: state.hasReachedMax
                    ? state.cards.length
                    : state.cards.length + 1,
                itemBuilder: (BuildContext context, int index) {
                  return index >= state.cards.length
                      ? const BottomLoader()
                      : CardListItem(card: state.cards[index]);
                },
              );
            case PokemonCardStatus.initial:
              return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
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

Este widget es un `StatefulWidget` porque necesita gestionar el ciclo de vida de un `ScrollController`. El controlador se inicializa en `initState`, se le añade un listener y se desecha correctamente en `dispose` para evitar fugas de memoria, una mejor práctica crítica.

### Construyendo el Scroll Infinito

El núcleo de la interfaz de usuario es el `BlocBuilder`, que reconstruye su árbol de widgets hijos en respuesta a nuevos estados del BLoC.

### Interfaz de Usuario Dirigida por el Estado

La función `builder` del `BlocBuilder` utilizará una declaración `switch` sobre el `state.status` para determinar qué mostrar. Esta es la esencia de una interfaz de usuario declarativa.

// Dentro de la función builder del BlocBuilder en cards_view.dart
switch (state.status) {
  case PokemonCardStatus.failure:
    return const Center(child: Text('Fallo al obtener las cartas'));
  case PokemonCardStatus.success:
    if (state.cards.isEmpty) {
      return const Center(child: Text('No se encontraron cartas'));
    }
    // El ListView.builder irá aquí
  case PokemonCardStatus.initial:
    return const Center(child: CircularProgressIndicator());
}

### El `ListView.builder`

Cuando el estado es `success`, se utiliza un `ListView.builder` para renderizar eficientemente la lista de cartas.

// Dentro del caso success de la declaración switch
return ListView.builder(
  controller: _scrollController,
  itemCount: state.hasReachedMax
    ? state.cards.length
      : state.cards.length + 1,
  itemBuilder: (BuildContext context, int index) {
    return index >= state.cards.length
      ? const BottomLoader()
        : CardListItem(card: state.cards[index]);
  },
);

Esta implementación contiene dos piezas clave de lógica:

1. `itemCount`: Un cálculo inteligente determina el número de elementos en la lista. Si `hasReachedMax` es verdadero, el conteo es simplemente el número de cartas. Si no, se añade un espacio extra al final de la lista para albergar el indicador de carga.17
2. `itemBuilder`: Para cada índice, comprueba si el índice es para una carta o para el espacio de carga extra. Si `index >= state.cards.length`, renderiza el widget `BottomLoader`. De lo contrario, renderiza un `CardListItem` para la carta en ese índice.

### La Lógica del `ScrollController`

El método `_onScroll`, adjunto al `ScrollController`, es el disparador para obtener más datos.

// En _CardsViewState
void _onScroll() {
  if (_isBottom) context.read<PokemonCardBloc>().add(CardsFetched());
}

bool get _isBottom {
  if (!_scrollController.hasClients) return false;
  final maxScroll = _scrollController.position.maxScrollExtent;
  final currentScroll = _scrollController.position.pixels;
  // Obtener cuando el usuario está al 90% del final
  return currentScroll >= (maxScroll * 0.9);
}

Esta lógica calcula si el usuario se ha desplazado cerca del final del contenido actual. Cuando se alcanza este umbral, utiliza `context.read<PokemonCardBloc>()` para acceder a la instancia del BLoC y añadir un nuevo evento `CardsFetched`, desencadenando la carga de la siguiente página de datos.

---

### La Página (`cards_page.dart`)

El widget de página es el punto de entrada para la interfaz de usuario de la funcionalidad. Es un `StatelessWidget` simple cuyo trabajo principal es crear y proporcionar el `PokemonCardBloc` a sus widgets hijos utilizando el widget `BlocProvider` del paquete `flutter_bloc`.

Dart

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
      create: (_) => PokemonCardBloc(
        pokemonCardRepository: PokemonCardRepositoryImpl(),
      )..add(CardsFetched()),
      child: const CardsView(),
    );
  }
}

En esta configuración, `BlocProvider` instancia el `PokemonCardBloc`, proporcionándole la implementación concreta `PokemonCardRepositoryImpl`. Crucialmente, añade inmediatamente el evento inicial `CardsFetched`. Esta acción inicia el proceso de carga de datos tan pronto como se construye la interfaz de usuario de la funcionalidad.

El proyecto generado por `very_good_cli` viene con una página de contador por defecto. El paso final es simplemente reemplazar esa página de contador con la `CardsPage` que hemos construido.

Aquí te muestro cómo hacerlo:

1. **Abre el archivo `lib/app/view/app.dart`**.
2. **Importa tu nueva `CardsPage`** en la parte superior del archivo.
3. **Reemplaza `CounterPage()` por `CardsPage()`** en la propiedad `home` del `MaterialApp`.

El archivo modificado debería verse así:

import 'package:flutter/material.dart';
import 'package:pokecard_dex/l10n/l10n.dart';
import 'package:pokecard_dex/pokemon_cards/view/cards_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const CardsPage(),
    );
  }
}


Preparemos nuestro proyecto para el lanzamiento
El proyecto generado por very_good_cli viene con una página de contador por defecto. El paso final es simplemente reemplazar esa página de contador con la CardsPage que hemos construido.
Aquí te muestro cómo hacerlo:
Abre el archivo lib/app/view/app.dart.
Importa tu nueva CardsPage en la parte superior del archivo.
Reemplaza CounterPage() por CardsPage() en la propiedad home del MaterialApp.
El archivo modificado debería verse así:
import 'package:flutter/material.dart';

### Ejecuta la aplicación

Finalmente ejecuta la aplicación, utilizando el siguiente comando:

## Fase 5: El Flujo de Trabajo Profesional - Calidad Asistida por IA y Próximos Pasos

El desarrollo de software profesional no se trata solo de escribir código que funcione; se trata de escribir código de alta calidad y mantenible y seguir un proceso disciplinado. Esta fase final se centra en integrar el copiloto de IA en el flujo de trabajo para reforzar la calidad y explorar futuras rutas de desarrollo.

### Comprobaciones previas al commit (alternativa reproducible a `/commit`)

Un commit en Git debe representar una unidad de trabajo clara y de alta calidad. Si no utilizas Gemini o una extensión similar, puedes seguir este checklist reproducible antes de hacer un commit. Si tienes Gemini configurado, más abajo hay una nota opcional.

Flujo recomendado (manual):

1. Formatea el código:

```powershell
dart format .
```

2. Aplica correcciones automáticas sugeridas (opcional):

```powershell
dart fix --apply
```

3. Ejecuta el analizador estático:

```powershell
flutter analyze
```

4. Ejecuta los tests:

```powershell
flutter test
```

5. Revisa cambios, añade y prepara el commit:

```powershell
git status
git add .
git commit -m "Breve descripción del cambio"
```

Qué comprueba cada paso:
- `dart format`: homogenezar estilo.
- `dart fix --apply`: aplica correcciones automáticas sugeridas por el SDK.
- `flutter analyze`: detecta errores potenciales y violaciones de buenas prácticas.
- `flutter test`: asegura que las pruebas unitarias/integración no fallen.

Nota opcional — si tienes Gemini configurado:

- Gemini puede automatizar este flujo (por ejemplo `gemini /commit`). Si decides usarlo, considera revisar el mensaje de commit y los cambios que Gemini propone antes de confirmar. La guía conserva las referencias a Gemini como opción, pero el flujo anterior funciona en cualquier entorno sin dependencias adicionales.

Esta alternativa garantiza que cualquier colaborador (con o sin Gemini) pueda reproducir las comprobaciones de calidad.

### Modo Desafío: Expandiendo tu Universo

La mejor manera de consolidar nuevos conocimientos es aplicarlos a nuevos problemas. Los siguientes desafíos están diseñados para fomentar el aprendizaje autodirigido y construir sobre los conceptos cubiertos en esta guía.

Cuando un usuario toca una carta en la lista, debe ser llevado a una nueva pantalla que muestre más detalles sobre esa carta. Esto requerirá la integración del paquete `go_router`, con el que los estudiantes tienen experiencia previa. Necesitarán definir una nueva ruta, pasar el ID de la carta como parámetro y crear una nueva funcionalidad (o al menos una nueva página) para obtener y mostrar los detalles completos de una sola carta utilizando el endpoint `https://api.pokemontcg.io/v2/cards/<id>`.

puedes consultar más detalles en:

### Desafío 2: Pull-to-Refresh

Implementa la funcionalidad de "tirar para refrescar". Cuando el usuario tira hacia abajo desde la parte superior de la lista, la lista existente debe borrarse y la primera página de cartas debe obtenerse de nuevo. Esto implicará crear un nuevo evento, como `CardsRefreshed`, y añadir un manejador para él en el `PokemonCardBloc`. La interfaz de usuario necesitará ser envuelta en un widget `RefreshIndicator`.

### Desafío 3: Prueba tu Lógica

La plantilla de `very_good_cli` proporciona una excelente base para las pruebas.12 El siguiente paso lógico es escribir una prueba unitaria para el `PokemonCardBloc`. Esto refuerza directamente los beneficios arquitectónicos discutidos en la Fase 3. La prueba debe:

- Usar el paquete `mocktail` para crear una implementación mock del `PokemonCardRepository`.
- Usar el paquete `bloc_test` para escribir pruebas que verifiquen el comportamiento del BLoC.
- Probar el caso de éxito: cuando el repositorio mock devuelve una lista de cartas, afirmar que el BLoC emite estados `[success]` con los datos correctos.
- Probar el caso de fallo: cuando el repositorio mock lanza una excepción, afirmar que el BLoC emite un estado `[failure]`.

### Desafío 4: Refactorización guiada (con y sin IA)

La interfaz de usuario para el `CardListItem` es sencilla y es un buen candidato para una refactorización (p. ej. mostrar más metadatos como HP y tipo). A continuación hay dos flujos: uno reproducible manualmente y otro opcional que emplea Gemini si está disponible.

Flujo manual (recomendado cuando no hay Gemini):

1. Crea una rama para aislar el trabajo:

```powershell
git checkout -b feat/cardlistitem-hp-type
```

2. Crea un archivo `MODIFICATION_PLAN.md` en la raíz con el objetivo y los pasos (p. ej. añadir campos al widget, actualizar tests, actualizar BLoC si es necesario).

3. Implementa los cambios en `lib/pokemon_cards/widgets/card_list_item.dart`:
  - Mostrar HP y tipo debajo del nombre.
  - Añadir controles de null-safety y placeholders.

4. Añade o actualiza pruebas de widgets/unitarias si aplica.

5. Ejecuta el checklist de calidad (format, analyze, test) y crea un commit:

```powershell
dart format .
dart fix --apply
flutter analyze
flutter test
git add .
git commit -m "feat(card): show HP and type in CardListItem"
```

6. Abre un PR y solicita revisión.

Flujo asistido por Gemini (opcional):

- Si tienes Gemini instalado y prefieres un flujo asistido, `gemini /modify` puede generar un `MODIFICATION_PLAN.md`, sugerir cambios y hasta proponer commits. Aun cuando uses Gemini, revisa siempre el plan y el código propuesto antes de aplicar o fusionar.

Ambos enfoques fomentan un trabajo planificado: crea el plan, implementa, añade pruebas y automatiza las comprobaciones de calidad antes del commit.

### Desafío 5: Búsqueda por Nombre (Asistida por IA)

Mejora la aplicación añadiendo una barra de búsqueda para encontrar un Pokémon por su nombre. Este es un excelente caso de uso para la refactorización guiada por IA.

- **Objetivo:** Añadir un `TextField` en el `AppBar` para que los usuarios puedan escribir un nombre y ver los resultados.
- **Plan de Acción con IA:** Inicia una sesión de modificación con Gemini (`/modify`) para añadir un campo de búsqueda a la `CardsView`.
- **Implementación:**
    1. **Evento del BLoC:** Crea un nuevo evento, como `CardsSearched(String query)`, para manejar las búsquedas.
    2. **Lógica del BLoC:** En el `PokemonCardBloc`, maneja el nuevo evento. Deberás limpiar la lista actual de cartas, reiniciar el contador de página y llamar a un nuevo método en tu repositorio.
    3. **Capa de Datos:** Modifica la interfaz `PokemonCardRepository` para incluir un método como `searchCards({required String name, required int page})`. En la implementación, utiliza el parámetro de consulta `q` de la API con la sintaxis `name:el_nombre_buscado*` para

    3. **Capa de Datos:** Modifica la interfaz `PokemonCardRepository` para incluir un método como `searchCards({required String name, required int page})`. En la implementación, utiliza el parámetro de consulta `q` de la API con la sintaxis `name:el_nombre_buscado*` para permitir búsquedas parciales.

### Desafío 6: Filtrado Avanzado por Tipo (Asistida por IA)

Lleva la aplicación al siguiente nivel implementando un filtro por tipo de Pokémon usando un `Drawer`.

- **Objetivo:** Permitir a los usuarios abrir un menú lateral (Drawer) y seleccionar uno o más tipos de Pokémon (ej. "Fuego", "Agua") para filtrar la lista de cartas.
- **Plan de Acción con IA:** Usa el comando `/modify` de Gemini para añadir un `Drawer` al `Scaffold` en `CardsView`. Pídele que lo pueble con una lista de `CheckboxListTile` para los diferentes tipos de Pokémon.
- **Implementación:**
    1. **Estado del BLoC:** Amplía `PokemonCardState` para que pueda almacenar los filtros activos (ej. `final Set<String> activeFilters`). No olvides actualizar el método `copyWith`.
    2. **Evento del BLoC:** Crea un evento como `FilterChanged(Set<String> newFilters)`.
    3. **Lógica del BLoC:** Cuando se reciba el evento `FilterChanged`, actualiza el estado con los nuevos filtros, limpia la lista de cartas, reinicia la paginación y realiza una nueva llamada al repositorio con los filtros aplicados.
    4. **Capa de Datos:** Actualiza tu repositorio para aceptar una lista de tipos. La consulta a la API deberá construirse dinámicamente. Por ejemplo, si se seleccionan "Agua" y "Fuego", el parámetro `q` debería ser `types:(water OR fire)`.

    NOTA: Recuerda que es fundamental que tu app este personalizada con un icono y un splash adecuado a la aplicación; así como todo tu código debe encontrarse resguardado en un repositorio de Git.

