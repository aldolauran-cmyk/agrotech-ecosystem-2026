import time
import json
import logging
import threading
import requests
import paho.mqtt.client as mqtt
from pydantic import BaseModel, Field, ValidationError

# Configuración de URLs y Broker
BASE_URL = "http://127.0.0.1:8000/api/v1"
MQTT_BROKER = "broker.hivemq.com"
MQTT_PORT = 1883
MQTT_TOPIC = "unmsm/agrotech/parcel/+/telemetry"

# Configuración del validador Pydantic para límites físicos reales del suelo
class TelemetryValidator(BaseModel):
    humidity: float = Field(..., ge=0.0, le=100.0)      # Humedad entre 0% y 100%
    temperature: float = Field(..., ge=-10.0, le=60.0)  # Temperatura realista del suelo
    ph: float = Field(..., ge=0.0, le=14.0)             # pH entre 0 y 14

# Logger de errores de telemetría a un archivo local de diagnóstico
error_logger = logging.getLogger("telemetry_errors")
error_logger.setLevel(logging.ERROR)
file_handler = logging.FileHandler("iot_industrial/telemetry_errors.log", encoding="utf-8")
formatter = logging.Formatter("%(asctime)s - [MQTT-BRIDGE ERROR] - %(message)s")
file_handler.setFormatter(formatter)
error_logger.addHandler(file_handler)

# Variables globales para token y seguimiento de estado
access_token = None
last_seen = {}  # Estructura: { parcel_id: timestamp }
last_seen_lock = threading.Lock()

def get_valid_token():
    """Solicita un nuevo token JWT al backend usando credenciales de administrador."""
    global access_token
    print("[Bridge] Solicitando token de acceso JWT al backend...")
    try:
        response = requests.post(
            f"{BASE_URL}/token",
            data={
                "username": "admin",
                "password": "admin123"
            },
            timeout=5
        )
        if response.status_code == 200:
            access_token = response.json().get("access_token")
            print("--> [Bridge] JWT Token obtenido con éxito.")
            return access_token
        else:
            print(f"--> [Bridge] Error al obtener token: Código {response.status_code}")
            return None
    except Exception as e:
        print(f"--> [Bridge] Error de conexión con el backend para obtener token: {e}")
        return None

def forward_to_api(parcel_id: int, payload: dict):
    """Reenvía la lectura validada al backend mediante HTTP POST con autenticación JWT."""
    global access_token
    if not access_token:
        if not get_valid_token():
            print("[Bridge] Imposible reenviar lectura: Sin token de acceso.")
            return

    headers = {"Authorization": f"Bearer {access_token}"}
    data_to_send = {
        "humidity": payload["humidity"],
        "temperature": payload["temperature"],
        "ph": payload["ph"],
        "parcel_id": parcel_id
    }

    try:
        response = requests.post(f"{BASE_URL}/telemetry", json=data_to_send, headers=headers, timeout=5)
        
        # Si el token expiró (401), reautenticar una vez y reintentar
        if response.status_code == 401:
            print("[Bridge] Token JWT expirado. Reautenticando...")
            if get_valid_token():
                headers["Authorization"] = f"Bearer {access_token}"
                response = requests.post(f"{BASE_URL}/telemetry", json=data_to_send, headers=headers, timeout=5)

        if response.status_code in [200, 201]:
            print(f"✅ [Bridge HTTP POST] Telemetría de la parcela {parcel_id} persistida en la Base de Datos.")
        else:
            print(f"⚠️ [Bridge HTTP POST] Error en backend ({response.status_code}): {response.text}")
    except Exception as e:
        print(f"❌ [Bridge HTTP POST] Error de conexión al enviar POST al backend: {e}")

def on_connect(client, userdata, flags, rc, properties=None):
    """Callback de conexión con el Broker MQTT."""
    if rc == 0:
        print(f"--> [Bridge] Conectado al Broker MQTT ({MQTT_BROKER})")
        client.subscribe(MQTT_TOPIC)
        print(f"--> [Bridge] Suscrito al tópico: {MQTT_TOPIC}")
    else:
        print(f"--> [Bridge] Error al conectar con Broker MQTT. Código: {rc}")

def on_message(client, userdata, msg):
    """Callback de recepción de mensajes MQTT."""
    try:
        # Decodificar el payload JSON
        raw_payload = msg.payload.decode()
        data = json.loads(raw_payload)

        # Extraer el ID de la parcela desde el tópico (unmsm/agrotech/parcel/{parcel_id}/telemetry)
        topic_parts = msg.topic.split('/')
        if len(topic_parts) < 4:
            raise ValueError(f"Estructura de tópico inválida: {msg.topic}")
        
        parcel_id = int(topic_parts[3])

        # Validar la integridad de los datos de telemetría mediante Pydantic
        validated_data = TelemetryValidator(**data)
        
        # Actualizar el registro del Keep-Alive para esta parcela
        with last_seen_lock:
            last_seen[parcel_id] = time.time()

        # Enviar los datos validados a la base de datos a través de la API
        forward_to_api(parcel_id, validated_data.model_dump())

    except json.JSONDecodeError:
        error_msg = f"Payload no es un JSON válido recibido en {msg.topic}: {msg.payload}"
        print(f"❌ [Bridge Error] {error_msg}")
        error_logger.error(error_msg)
    except ValidationError as e:
        error_msg = f"Violación de integridad física de telemetría en {msg.topic}. Detalles: {e.errors()}"
        print(f"❌ [Bridge Error] {error_msg}")
        error_logger.error(f"Integridad rota en {msg.topic}. Payload: {msg.payload.decode()} | Errores: {e}")
    except Exception as e:
        error_msg = f"Error inesperado en mensaje MQTT: {e}"
        print(f"❌ [Bridge Error] {error_msg}")
        error_logger.error(error_msg)

def monitor_keep_alive():
    """Hilo demonio que revisa inactividad de las estaciones y lanza alertas offline."""
    print("[Bridge Keep-Alive] Monitoreo de inactividad de sensores iniciado.")
    while True:
        time.sleep(10)
        current_time = time.time()
        with last_seen_lock:
            for pid, timestamp in list(last_seen.items()):
                # Si una parcela no reporta datos por más de 30 segundos, se considera offline
                if current_time - timestamp > 30:
                    print(f"🚨 [ALERTA BRIDGE] La Estación/Parcela {pid} no responde. ¡ESTACIÓN OFFLINE! (Último reporte hace {int(current_time - timestamp)}s)")
                    # Opcionalmente aquí podríamos enviar un aviso de inactividad al backend

def main():
    # Obtener el token JWT inicial para verificar conectividad con la API
    get_valid_token()

    # Lanzar el hilo demonio de monitoreo de Keep-Alive
    keep_alive_thread = threading.Thread(target=monitor_keep_alive, daemon=True)
    keep_alive_thread.start()

    # Inicializar cliente MQTT con API moderna v2
    client = mqtt.Client(callback_api_version=mqtt.CallbackAPIVersion.VERSION2)
    client.on_connect = on_connect
    client.on_message = on_message

    print("[Bridge] Conectando al Broker...")
    try:
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
        print("[Bridge] Iniciando bucle síncrono infinito (loop_forever)...")
        client.loop_forever()
    except KeyboardInterrupt:
        print("\n[Bridge] Deteniendo el Bridge de forma segura...")
    finally:
        client.disconnect()
        print("[Bridge] Puente detenido.")

if __name__ == "__main__":
    main()
