# AgroTech Ecosystem 2026 🚜🌱

![AgroTech Banner](https://img.shields.io/badge/AgroTech-Ecosystem%202026-1B4314?style=for-the-badge)

AgroTech Ecosystem es un sistema integral (Monorepo) diseñado para la gestión de parcelas agrícolas, control de telemetría IoT y administración de usuarios basado en roles (RBAC). El sistema cuenta con un backend robusto en Python (FastAPI), una aplicación móvil multiplataforma (Flutter) y se integra con simulaciones IoT (MQTT) para monitoreo en tiempo real.

Este documento sirve como guía oficial para desarrolladores, evaluadores o colaboradores externos que deseen clonar, configurar y ejecutar el proyecto desde cero en un entorno local.

---

## 📖 Arquitectura y Flujos de Usuario (RBAC)

El sistema opera bajo un modelo **RBAC (Role-Based Access Control)** con tres niveles de acceso principales:

1. **👑 Administrador (`admin`)**
   - **Alcance:** Control total del sistema.
   - **Acciones:** Puede crear, editar y eliminar usuarios, restablecer contraseñas y ver absolutamente todas las parcelas. Puede reasignar parcelas a cualquier usuario. Tiene acceso exclusivo a Reportes Globales y Gestión de Usuarios.

2. **👨‍🌾 Agricultor (`farmer`)**
   - **Alcance:** Dueño directo de la tierra.
   - **Acciones:** Al iniciar sesión, **solo ve las parcelas que le han sido asignadas**. Puede monitorear la telemetría (humedad, pH, temperatura) de sus propias parcelas y editar detalles físicos (nombre, ubicación). No tiene acceso a datos ajenos ni administración.

3. **👁️ Auditor / Visualizador (`viewer`)**
   - **Alcance:** Rol de "solo lectura".
   - **Acciones:** Puede ver todas las parcelas de todos los farmers y acceder a los Reportes Globales. **No puede editar, crear, reasignar ni eliminar absolutamente nada**.

---

## 📋 Requisitos Previos

Asegúrese de tener instalado el siguiente software en su equipo antes de continuar:

1. **Python 3.11+** -> [Descargar Python](https://www.python.org/downloads/)
   * *Importante (Windows)*: Durante la instalación, marque la casilla **"Add Python to PATH"**.
2. **Flutter SDK 3.19+** -> [Guía de Instalación de Flutter](https://docs.flutter.dev/get-started/install)
   * Configure un emulador Android/iOS o asegúrese de tener Google Chrome para compilación web.
3. **Git** -> [Descargar Git](https://git-scm.com/)

*(Nota: Este proyecto utiliza el Broker MQTT público de HiveMQ en la nube, por lo que **no** es necesario instalar Mosquitto ni ningún broker local en su equipo).*

---

## 🚀 Guía de Instalación y Ejecución

Siga estos pasos en orden para levantar todo el ecosistema (Broker, Backend, Simulador IoT y Frontend Móvil).

### Paso 1: Solucionar Permisos en Windows (Solo si es necesario) ⚠️
En Windows, PowerShell suele bloquear la activación de entornos virtuales por seguridad. Si recibe un error sobre "ejecución de scripts deshabilitada":
1. Abra **PowerShell como Administrador**.
2. Ejecute este comando y acepte con `Y` o `O`:
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

### Paso 2: Configurar y Ejecutar el Backend (FastAPI)
1. Abre una terminal en la raíz del proyecto.
2. Crea un entorno virtual limpio:
   ```powershell
   python -m venv .venv
   ```
3. Activa el entorno virtual:
   * **PowerShell**:
     ```powershell
     .\.venv\Scripts\Activate.ps1
     ```
   * **CMD (Símbolo del sistema)**:
     ```cmd
     .venv\Scripts\activate.bat
     ```

      💡 Nota de resolución de problemas: Si al intentar activar el entorno en PowerShell te aparece un error en letras rojas que indica que la ejecución de scripts está deshabilitada en este sistema, Windows ha bloqueado el archivo por seguridad. Para solucionarlo permanentemente:

        Abre una terminal de PowerShell como Administrador (clic derecho -> Ejecutar como administrador).

        Ejecuta el comando:
         ```
         Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
         ```

        Escribe S y presiona Enter. Cierra esa ventana y vuelve a tu terminal normal.


     
4. Instala todas las dependencias requeridas (FastAPI, Uvicorn, SQLAlchemy, Pydantic, Passlib, Cryptography, Paho-MQTT, Requests):
   ```powershell
   pip install -r backend/app/requirements.txt requests
   ```
5. Asegúrate de tener el archivo `.env` configurado en la raíz del proyecto. Si no existe, crea un archivo llamado `.env` con el siguiente contenido:
   ```env
   SECRET_KEY=FISI_2018
   ACCESS_TOKEN_EXPIRE_MINUTES=60
   API_V1_PREFIX=/api/v1
   PROJECT_NAME=AgroTech API
   VERSION=1.0.0
   DESCRIPTION=API para monitoreo agrícola con autenticación JWT y gestión de parcelas.
   ADMIN_USERNAME=admin
   ADMIN_PASSWORD=admin
   ADMIN_ROLE=admin
   ```
6. Inicia el servidor del backend:
   ```powershell
   python -m uvicorn backend.main:app --reload
   ```
   *El backend estará disponible en `http://127.0.0.1:8000`. Verás en los logs que se conecta automáticamente a tu Mosquitto local (`localhost`).*

---

### Paso 3: Configurar y Ejecutar el Simulador IoT
El simulador transmitirá datos de telemetría por MQTT.
1. Abre una **nueva terminal**, navega a la raíz del proyecto y activa el entorno virtual:
   ```powershell
   .\.venv\Scripts\Activate.ps1
   ```
2. Ejecuta el script del simulador:
   ```powershell
   python iot_industrial/main_sim.py
   ```
   *El simulador iniciará sesión de forma segura, creará de ser necesario la "Parcela Demostración 1" y empezará a enviar datos de sensores simulados cada 5 segundos al broker local.*

---

### Paso 4: Ejecutar la Aplicación Móvil (Flutter)
1. Abre una **tercera terminal** y navega al directorio del móvil:
   ```powershell
   cd mobile
   ```
2. Descarga y actualiza los paquetes de Flutter necesarios:
   ```powershell
   flutter pub get
   ```
3. Ejecuta la aplicación en tu emulador o navegador web:
   ```powershell
   flutter run
   ```
4. Inicia sesión en la aplicación móvil usando las credenciales del Administrador:
   * **Usuario**: `admin`
   * **Contraseña**: `admin123`

*(Nota para emuladores Android: Android Studio usa `10.0.2.2` para referirse al `localhost`. Si la app no conecta, verifique `api_constants.dart`).*

### Paso 5: Ejecutar el Gemelo Digital 3D (Godot Engine 4.x)
La simulación interactiva 3D permite visualizar en tiempo real las parcelas instanciadas en la grilla y agrupadas de manera reactiva por su dueño asignado.

1. **Requisitos de Software:**
   * Descarga e instala **Godot Engine 4.x** (versión 4.1 o posterior, recomendada 4.2+). [Descargar Godot Engine 4](https://godotengine.org/download/).
2. **Configuración e Importación:**
   * Abre el lanzador de Godot (Godot Project Manager).
   * Presiona el botón **Importar** (Import) y navega al directorio del monorepo.
   * Selecciona el archivo `project.godot` ubicado directamente en la raíz de la carpeta de simulación:
     `simulation_godot/project.godot`
   * Haz clic en **Importar y Editar** para abrir el proyecto en el editor.
3. **Ejecutar la Simulación:**
   * Asegúrate de tener levantado el backend FastAPI.
   * Asegúrate de ejecutar el simulador de telemetría IoT (`python iot_industrial/main_sim.py`) para transmitir tramas de datos MQTT por HiveMQ.
   * Presiona el botón **Play (F5)** o el icono de reproducción en la esquina superior derecha del editor de Godot.
4. **Funcionalidades del Entorno 3D:**
   * **Zonificación Dinámica por Agricultor:** Las parcelas se instancian y agrupan automáticamente en mini-tableros de 2x2 exclusivos para cada agricultor, ordenados alfabéticamente por su nombre de usuario en el eje Z. Los nombres de usuario se sincronizan dinámicamente del backend mediante peticiones REST cada 3 segundos.
   * **Navegación Interactiva de Cámara Libre (Free Camera):**
     * **`W` / `S`**: Acercarse o alejarse (zoom en profundidad local `basis.z`).
     * **`A` / `D`** o **Flecha Izquierda / Derecha**: Desplazarse lateralmente a los lados (eje local `basis.x`).
     * **Flecha Arriba / Abajo**: Desplazarse de forma vertical pura (subir o bajar la altura de la cámara en el eje vertical de pantalla `basis.y` sin alterar el zoom).
     * **Clic Derecho (Mantener presionado) + Arrastrar Mouse**: Rotar la dirección de la mirada (guiñada y cabeceo con tope de seguridad de 80°).
   * **Sincronización de Alertas y Materiales 3D:**
     * **🟤 Marrón**: Suelo con *Estrés Hídrico* (Humedad < 30.0%).
     * **🟢 Verde**: Suelo en estado *Óptimo* (Humedad entre 30.0% y 70.0%).
     * **🔵 Azul**: Suelo *Saturado / Inundado* (Humedad > 70.0%).
     * **Label3D Flotante**: Cada bloque muestra su ID de parcela, el nombre del agricultor dueño (ej. `Farmer: juan`), la humedad redondeada a un decimal (`%`), la temperatura (`°C`) y el pH.

---

## 🌐 Opciones de Arquitectura IoT (Cloud vs Edge)

Este ecosistema soporta dos modos de funcionamiento para adaptarse a las necesidades reales de conectividad en zonas agrícolas:

### 1. Modo Nube (Cloud Computing) - *Configuración por Defecto*
Ideal para demostraciones académicas o parcelas con conexión a internet (3G/4G/Starlink). 
- **Ventaja:** No requiere instalar nada extra. Se usa el broker público `broker.hivemq.com`.
- **Configuración:** En ambos archivos (`iot_industrial/main_sim.py` y `backend/app/core/mqtt.py`), la variable debe estar así: `BROKER = "broker.hivemq.com"`

### 2. Modo Desconectado (Edge Computing)
Diseñado para zonas rurales **sin acceso a internet**. El sistema funciona en una red local (ej. los sensores transmiten por radio a una Raspberry Pi en la granja).
- **Ventaja:** Privacidad total y funcionamiento 100% offline.
- **Configuración:** 
  1. Instalar [Mosquitto MQTT Broker](https://mosquitto.org/download/) en la computadora o servidor local.
  2. En **ambos** archivos (`iot_industrial/main_sim.py` y `backend/app/core/mqtt.py`), cambiar el código a: `BROKER = "localhost"`

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
└── simulation_godot/   # Entorno de Gemelo Digital 3D (Godot Engine)
    └── agrotech-simulation/
        ├── scenes/     # Escenas de simulación (.tscn)
        ├── scripts/    # Lógica de control en GDScript (cámara, red, parcelas)
        └── mqtt/       # Script conector MQTT para Godot
```

