# Instrucciones de Ejecución: AgroTech Ecosystem

Este documento describe los requisitos y pasos exactos para configurar y ejecutar este ecosistema (Backend, Simulador IoT y Aplicación Móvil) desde cero en cualquier otra computadora.

---

## 📋 Requisitos Previos

Asegúrate de tener instalado lo siguiente en la computadora de destino:

1. **Python 3.11** (o superior) -> [Descargar Python](https://www.python.org/downloads/)
   * *Importante*: Durante la instalación en Windows, marca la casilla **"Add Python to PATH"** (Agregar Python al PATH).
2. **Flutter SDK** -> [Guía de Instalación de Flutter](https://docs.flutter.dev/get-started/install)
   * Asegúrate de tener un emulador Android/iOS listo o usar Google Chrome para la web.
3. **Mosquitto MQTT Broker** (para mensajería local) -> [Descargar Mosquitto](https://mosquitto.org/download/)
   * Durante la instalación en Windows, se configurará automáticamente como un servicio.
4. **Git** (opcional, para clonar el repositorio) -> [Descargar Git](https://git-scm.com/)

---

## 🚀 Pasos para Configurar y Ejecutar

### Paso 1: Configurar y Ejecutar el Broker MQTT (Mosquitto)
El simulador y el backend necesitan comunicarse a través de un servidor MQTT.
* En **Windows**, tras la instalación de Mosquitto, el servicio arranca automáticamente.
* Para verificar si está escuchando en el puerto default `1883`, abre una terminal de PowerShell y corre:
  ```powershell
  Test-NetConnection -Port 1883 -ComputerName localhost
  ```
* Si el servicio está detenido, puedes abrir la aplicación **Servicios** de Windows (`services.msc`), buscar **"Mosquitto Broker"** y darle a **Iniciar**.

---

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
   * **Contraseña**: `admin`
5. ¡Listo! La lista de parcelas cargará y verás en tiempo real (actualización cada 15s) los datos de humedad, pH y temperatura simulados.
