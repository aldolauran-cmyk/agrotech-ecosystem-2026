# Backend (FastAPI)

## Vista general
El backend es una API REST en FastAPI con JWT para autenticación y SQLAlchemy para persistencia en SQLite. La API expone endpoints versionados en `/api/v1` y documenta todo en Swagger.

## Estructura de carpetas
- `backend/main.py`: punto de entrada de la aplicación.
- `backend/app/requirements.txt`: dependencias del backend.
- `backend/app/core/`: configuración, base de datos, seguridad y seed.
- `backend/app/models/`: modelos ORM.
- `backend/app/schemas/`: esquemas Pydantic para requests/responses.
- `backend/app/routers/`: endpoints agrupados por dominio.

## Archivos y responsabilidades

### `backend/main.py`
- Crea la instancia `FastAPI` con metadatos (título, versión, descripción y tags).
- Registra el evento `startup` para crear tablas y sembrar el admin.
- Importa modelos (`user`, `parcel`) para que SQLAlchemy registre las tablas.
- Incluye los routers: `auth`, `user`, `parcel`.
- Define un endpoint raíz (`/`) para verificar que la API está activa.

**Conexiones:**
- Usa `get_settings()` desde `core/config.py`.
- Usa `Base` y `engine` desde `core/database.py` para crear tablas.
- Usa `seed_admin()` desde `core/seed.py`.
- Conecta routers de `backend/app/routers/*`.

### `backend/app/requirements.txt`
- Lista las librerías clave: `fastapi`, `uvicorn`, `sqlalchemy`, `pydantic`, `python-jose`, `passlib`, `python-multipart`.

### `backend/app/core/config.py`
- Define `Settings` con `pydantic-settings`.
- Lee variables desde `.env` (ej. `SECRET_KEY`, `ADMIN_USERNAME`, `ADMIN_PASSWORD`).
- Centraliza parámetros como `api_v1_prefix`, `algorithm`, `access_token_expire_minutes`.

**Conexiones:**
- Consumido por `main.py`, `security.py`, `seed.py` y routers.

### `backend/app/core/database.py`
- Configura SQLite en `sqlite:///./agrotech.db`.
- Crea `engine`, `SessionLocal` y `Base`.
- Expone `get_db()` como dependencia para inyectar sesión en routers.

**Conexiones:**
- `models/*` usan `Base`.
- Routers usan `get_db()` para operar la base de datos.

### `backend/app/core/security.py`
- Encripta y verifica contraseñas con `passlib`.
- Autentica usuarios (`authenticate_user`).
- Genera JWT (`create_access_token`) con `python-jose`.
- Valida JWT con `get_current_user`.
- Verifica rol admin con `require_admin`.

**Conexiones:**
- Usado por `routers/auth.py` (login).
- Usado por `routers/user.py` (creación admin).
- Usado por `routers/parcel.py` (protección de endpoints).

### `backend/app/core/seed.py`
- Si existen `ADMIN_USERNAME` y `ADMIN_PASSWORD`, crea un usuario admin.
- Evita duplicar admin si ya existe.

**Conexiones:**
- Usa `get_settings()` y `hash_password()`.
- Usa `SessionLocal` y el modelo `User`.

### `backend/app/models/user.py`
- Tabla `users`.
- Campos: `id`, `username`, `password`, `role`.
- Relación 1:N con parcelas (`parcels`).

**Conexiones:**
- Referenciada por `Parcel.owner` (FK).
- Usada en routers (`user.py`, `parcel.py`) y seguridad.

### `backend/app/models/parcel.py`
- Tabla `parcels`.
- Campos: `id`, `name`, `location`, `soil_type`, `owner_id`.
- FK `owner_id` a `users.id`.

**Conexiones:**
- Relación inversa con `User.parcels`.
- Usada en `routers/parcel.py`.

### `backend/app/schemas/auth.py`
- `Token`: modelo de respuesta del login (`access_token`, `token_type`).

### `backend/app/schemas/user.py`
- `RoleEnum`: define roles (`admin`, `farmer`, `viewer`).
- `UserCreate`: payload para crear usuario.
- `UserResponse`: respuesta de usuario (excluye password).

### `backend/app/schemas/parcel.py`
- `ParcelCreate`: payload para crear parcela.
- `ParcelResponse`: respuesta de parcela.

### `backend/app/routers/auth.py`
- `POST /token`: recibe credenciales (OAuth2PasswordRequestForm).
- Retorna JWT si las credenciales son válidas.

**Conexiones:**
- Usa `authenticate_user()` y `create_access_token()` de `security.py`.
- Usa `Token` de `schemas/auth.py`.

### `backend/app/routers/user.py`
- `POST /users`: crea usuarios, solo admin.
- Valida duplicados por `username`.

**Conexiones:**
- Protegido con `require_admin()` de `security.py`.
- Usa `UserCreate`/`UserResponse` y `RoleEnum`.
- Persiste en `models/User`.

### `backend/app/routers/parcel.py`
- `GET /parcels`: lista parcelas. Admin ve todas, otros solo las propias.
- `POST /parcels`: crea parcela. Admin puede asignar `owner_id`.

**Conexiones:**
- Protegido con `get_current_user()` de `security.py`.
- Usa `ParcelCreate`/`ParcelResponse`.
- Persiste en `models/Parcel`.

## Flujo principal (resumen)
1. Cliente hace login (`/token`) → recibe JWT.
2. Cliente usa JWT en `Authorization: Bearer ...`.
3. Routers validan el token con `get_current_user()`.
4. Se ejecutan operaciones SQLAlchemy usando `get_db()`.
5. Respuestas se serializan con esquemas Pydantic.
