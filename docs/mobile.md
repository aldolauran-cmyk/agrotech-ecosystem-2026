# Mobile (Flutter)

## Vista general
La app móvil permite iniciar sesión contra el backend y visualizar la lista de parcelas en tiempo real (polling cada 15s). Guarda el token JWT en almacenamiento seguro y protege las llamadas.

## Estructura de carpetas
- `mobile/pubspec.yaml`: dependencias y configuración de Flutter.
- `mobile/analysis_options.yaml`: reglas de lint.
- `mobile/lib/main.dart`: punto de entrada y control de sesión.
- `mobile/lib/models/`: modelos de datos.
- `mobile/lib/screens/`: pantallas UI.
- `mobile/lib/services/`: comunicación HTTP y persistencia local.
- `mobile/lib/utils/`: constantes y utilidades.

## Archivos y responsabilidades

### `mobile/pubspec.yaml`
- Define el SDK y dependencias:
  - `http` para consumo de API.
  - `flutter_secure_storage` para guardar el JWT.
  - `flutter_lints` para reglas de estilo.

### `mobile/analysis_options.yaml`
- Incluye reglas de `flutter_lints`.
- Forza `avoid_print` para mantener el código limpio.

### `mobile/lib/main.dart`
- Inicializa Flutter y decide la primera pantalla según exista token.
- `_SessionGate` consulta `TokenStorage.readToken()`:
  - Si hay token → `ParcelListScreen`.
  - Si no hay token → `LoginScreen`.

**Conexiones:**
- Usa `TokenStorage` para leer el token.
- Navega a `LoginScreen` o `ParcelListScreen`.

### `mobile/lib/models/parcel.dart`
- Modelo `Parcel` usado en la UI.
- Mapea campos JSON (`soil_type`, `owner_id`) a propiedades Dart.

**Conexiones:**
- Usado por `ParcelListScreen` para renderizar la lista.
- Alimentado por `ApiClient.decodeJsonList`.

### `mobile/lib/screens/login_screen.dart`
- Formulario de login.
- Envía `username`/`password` al backend (`/token`).
- Guarda token con `TokenStorage.saveToken()`.
- Si el login es exitoso, navega a `ParcelListScreen`.

**Conexiones:**
- Usa `ApiClient.postForm()` para autenticación.
- Usa `TokenStorage` para persistir JWT.

### `mobile/lib/screens/parcel_list_screen.dart`
- Lista de parcelas del usuario.
- Polling cada 15s con `Timer.periodic`.
- Maneja estado de carga y errores.
- Si recibe `401`, borra token y vuelve a `LoginScreen`.

**Conexiones:**
- Usa `ApiClient.get('/parcels')`.
- Usa `TokenStorage` para leer/limpiar token.
- Convierte JSON a `Parcel` (modelo).

### `mobile/lib/services/api_client.dart`
- Encapsula `http.Client`.
- Construye URL base desde `ApiConstants.baseUrl`.
- `postForm` para login.
- `get` agrega `Authorization: Bearer <token>` si hay token.
- Helpers para parsear JSON (`decodeJson`, `decodeJsonList`).

**Conexiones:**
- Consumido por `LoginScreen` y `ParcelListScreen`.
- Usa `TokenStorage` para agregar el JWT.
- Usa `ApiConstants` para URL base.

### `mobile/lib/services/token_storage.dart`
- Guarda, lee y elimina el token JWT en `flutter_secure_storage`.

**Conexiones:**
- Usado por `main.dart`, `LoginScreen`, `ParcelListScreen`, `ApiClient`.

### `mobile/lib/utils/api_constants.dart`
- Define `API_BASE_URL` con `String.fromEnvironment`.
- Permite configurar el backend con `--dart-define`.

**Conexiones:**
- Consumido por `ApiClient`.

## Flujo principal (resumen)
1. La app arranca y revisa si hay token guardado.
2. Si no hay token → login con `/token`.
3. Si hay token → consulta `/parcels` con `Authorization: Bearer ...`.
4. La lista se refresca automáticamente cada 15s.
