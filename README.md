# AgroTech Ecosystem 2026 🚜🌱

![AgroTech Banner](https://img.shields.io/badge/AgroTech-Ecosystem%202026-1B4314?style=for-the-badge)

AgroTech Ecosystem es un sistema integral (Monorepo) diseñado para la gestión de parcelas agrícolas, control de telemetría IoT y administración de usuarios basado en roles (RBAC). El sistema cuenta con un backend robusto en Python (FastAPI), una aplicación móvil multiplataforma (Flutter) y se prepara para integrarse con simulaciones (Godot) y redes IoT.

---

## 📖 ¿Cómo funciona el proyecto? (Flujos y Roles)

El sistema opera bajo un modelo **RBAC (Role-Based Access Control)** con tres niveles de acceso:

1. **👑 Administrador (`admin`)**
   - **Flujo:** Tiene control total del sistema. Puede crear y eliminar usuarios, restablecer contraseñas y ver absolutamente todas las parcelas.
   - **Acción destacada:** Puede crear parcelas y asignarlas (o reasignarlas) a cualquier Farmer. Tiene acceso exclusivo a Reportes Globales y Gestión de Usuarios.

2. **👨‍🌾 Agricultor (`farmer`)**
   - **Flujo:** Es el dueño directo de la tierra. Al iniciar sesión, **solo ve las parcelas que el Admin le ha asignado**.
   - **Acción destacada:** Puede monitorear la telemetría (humedad, pH, temperatura) de sus propias parcelas y editar detalles físicos (nombre, ubicación), pero no puede borrar usuarios ni ver parcelas ajenas.

3. **👁️ Auditor / Visualizador (`viewer`)**
   - **Flujo:** Un rol de "solo lectura". Puede ver todas las parcelas de todos los farmers y acceder a los Reportes Globales, pero **no puede editar, crear, reasignar ni eliminar absolutamente nada**.

---

## 🚀 Guía de Instalación desde Cero (Para computadoras nuevas)

Si acabas de clonar este repositorio en una computadora nueva, sigue estos pasos al pie de la letra para levantar el sistema.

### Requisitos Previos
* **Python 3.11+** instalado (Asegúrate de marcar "Add Python to PATH" en la instalación).
* **Flutter SDK 3.19+** instalado y configurado en tus variables de entorno.
* **Git** instalado.

---

### Paso 1: Solucionar Permisos en Windows (Importante) ⚠️
En computadoras nuevas, Windows suele bloquear la ejecución de entornos virtuales por seguridad. Para evitar el error de *"no se puede cargar el archivo porque la ejecución de scripts está deshabilitada"*:
1. Abre **PowerShell como Administrador**.
2. Ejecuta el siguiente comando y acepta con la letra `O` o `Y`:
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

---

### Paso 2: Configurar el Backend (FastAPI)

El backend maneja la base de datos (SQLite) y provee la API RESTful.

1. Abre una terminal en la carpeta principal del proyecto y entra al backend:
   ```bash
   cd backend
   ```
2. Crea un entorno virtual para aislar las dependencias:
   ```bash
   python -m venv .venv
   ```
3. Activa el entorno virtual:
   * **Windows (PowerShell):** `.\.venv\Scripts\Activate.ps1`
   * **Mac/Linux:** `source .venv/bin/activate`
4. Instala las dependencias:
   ```bash
   pip install -r app/requirements.txt
   ```
5. Configura las variables de entorno:
   * En la raíz del proyecto, copia el archivo `.env.example` y renómbralo a `.env`.
   * (Opcional) Ejecuta el archivo de *seeding* si deseas crear un Admin por defecto al instante:
     ```bash
     python seed_db.py
     ```
6. Levanta el servidor:
   ```bash
   fastapi dev app/main.py
   ```
   *✅ El servidor estará corriendo en `http://127.0.0.1:8000`. Puedes ver la documentación de la API entrando a `http://127.0.0.1:8000/docs`.*

---

### Paso 3: Configurar la App Móvil (Flutter)

La aplicación es la interfaz visual donde los usuarios interactuarán con el sistema.

1. Abre **otra terminal** y entra a la carpeta mobile:
   ```bash
   cd mobile
   ```
2. Descarga los paquetes y dependencias de Flutter:
   ```bash
   flutter pub get
   ```
3. Ejecuta la aplicación en un emulador o en tu navegador web:
   ```bash
   flutter run
   ```
   *(Nota: Al ejecutar, selecciona tu Emulador de Android/iOS o Chrome).*

#### 🛑 Posibles errores en Flutter y cómo solucionarlos:
* **Si el backend rechaza la conexión desde el emulador Android:** Recuerda que Android Studio usa la IP `10.0.2.2` para referirse al `localhost` de tu computadora. Verifica que tu archivo de configuración de API en Flutter apunte a esa IP si estás en Android, o a `127.0.0.1` si estás en Web/iOS.
* **Error de dependencias al compilar:** Ejecuta `flutter clean` seguido de `flutter pub get` e intenta de nuevo.

---

## 📂 Estructura del Monorepo

```text
agrotech-ecosystem-2026/
├── backend/            # API RESTful (FastAPI, SQLAlchemy, JWT, Bcrypt)
│   ├── app/
│   │   ├── models/     # Modelos de Base de Datos
│   │   ├── routers/    # Endpoints (users, parcels, auth)
│   │   └── main.py     # Archivo principal de ejecución
├── mobile/             # Aplicación Móvil (Flutter)
│   ├── lib/
│   │   ├── screens/    # Interfaces de usuario (Login, ParcelList, UserManagement)
│   │   └── services/   # Cliente API HTTP (api_client.dart)
├── iot_industrial/     # Scripts de simulación IoT por MQTT
└── simulation_godot/   # (Próximamente) Entorno Gemelo Digital
```
