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

### Paso 2: Configurar el Backend (FastAPI)
1. Abra una terminal en la raíz del proyecto y entre a la carpeta del backend:
   ```bash
   cd backend
   ```
2. Cree y active un entorno virtual limpio:
   * **Windows (PowerShell):**
     ```powershell
     python -m venv .venv
     .\.venv\Scripts\Activate.ps1
     ```
   * **Mac/Linux:**
     ```bash
     python -m venv .venv
     source .venv/bin/activate
     ```
3. Instale las dependencias requeridas:
   ```bash
   pip install -r app/requirements.txt requests
   ```
4. En la **raíz del proyecto**, copie el archivo `.env.example` y renómbrelo a `.env`. (Contiene las credenciales para sembrar el usuario admin por defecto).
5. Inicie el servidor:
   ```bash
   fastapi dev app/main.py
   ```
   *(También puede usar `python -m uvicorn backend.main:app --reload` desde la raíz). El backend estará disponible en `http://127.0.0.1:8000`.*

### Paso 3: Ejecutar el Simulador IoT
El simulador provee telemetría constante a las parcelas activas.
1. Abra una **nueva terminal**, active el entorno virtual (paso 3.2).
2. Ejecute el script del simulador:
   ```bash
   python iot_industrial/main_sim.py
   ```
   *El simulador iniciará sesión de forma segura y comenzará a enviar datos de humedad, pH y temperatura simulados cada 5 segundos a Mosquitto.*

### Paso 4: Ejecutar la App Móvil (Flutter)
1. Abra una **tercera terminal** y navega al directorio del móvil:
   ```bash
   cd mobile
   ```
2. Instale los paquetes y dependencias:
   ```bash
   flutter pub get
   ```
3. Ejecute la aplicación (seleccione su emulador o navegador web):
   ```bash
   flutter run
   ```
4. **Inicio de sesión por defecto:**
   * **Usuario**: `admin`
   * **Contraseña**: `admin`

*(Nota para emuladores Android: Android Studio usa `10.0.2.2` para referirse al `localhost`. Si la app no conecta, verifique `api_constants.dart`).*

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
