import json
import logging
import paho.mqtt.client as mqtt
from pydantic import ValidationError
from sqlalchemy.orm import Session

from backend.app.core.database import SessionLocal
from backend.app.models.telemetry import Telemetry
from backend.app.schemas.telemetry import TelemetryCreate

logger = logging.getLogger("mqtt_subscriber")
logger.setLevel(logging.INFO)

# Configuración del Broker y Tópico
BROKER = "localhost"

PORT = 1883
TOPIC = "unmsm/agrotech/parcel/+/telemetry"

def on_connect(client, userdata, flags, rc, properties=None):
    if rc == 0:
        logger.info("--> Conectado con éxito al Broker MQTT")
        client.subscribe(TOPIC)
        logger.info(f"--> Suscrito al tópico de telemetría: {TOPIC}")
    else:
        logger.error(f"Error al conectar con Broker MQTT: Código {rc}")

def on_message(client, userdata, msg):
    try:
        raw_payload = msg.payload.decode()
        logger.info(f"[MQTT Recv] Mensaje recibido en '{msg.topic}': {raw_payload}")
        data = json.loads(raw_payload)

        # Extraer parcel_id del tópico si no viene incluido en el JSON
        # Estructura: unmsm/agrotech/parcel/{parcel_id}/telemetry
        topic_parts = msg.topic.split('/')
        if len(topic_parts) >= 4:
            try:
                parcel_id_from_topic = int(topic_parts[3])
                if "parcel_id" not in data:
                    data["parcel_id"] = parcel_id_from_topic
            except ValueError:
                pass

        # Validación con Pydantic schema
        telemetry_in = TelemetryCreate(**data)

        # Guardar en base de datos SQLite utilizando SessionLocal
        db: Session = SessionLocal()
        try:
            new_telemetry = Telemetry(
                humidity=telemetry_in.humidity,
                temperature=telemetry_in.temperature,
                ph=telemetry_in.ph,
                parcel_id=telemetry_in.parcel_id
            )
            db.add(new_telemetry)
            db.commit()
            db.refresh(new_telemetry)
            logger.info(f"[DB Guardado] Telemetría registrada para parcela {new_telemetry.parcel_id} (Humedad: {new_telemetry.humidity}%, Temp: {new_telemetry.temperature}°C, pH: {new_telemetry.ph})")
        except Exception as e:
            logger.error(f"Error guardando telemetría en BD: {e}")
            db.rollback()
        finally:
            db.close()

    except json.JSONDecodeError:
        logger.error("[MQTT Error] Payload no es un JSON válido.")
    except ValidationError as e:
        logger.error(f"[MQTT Error] Fallo de validación Pydantic: {e}")
    except Exception as e:
        logger.error(f"[MQTT Error] Error inesperado: {e}")

# Inicialización del cliente MQTT
mqtt_client = mqtt.Client(callback_api_version=mqtt.CallbackAPIVersion.VERSION2)
mqtt_client.on_connect = on_connect
mqtt_client.on_message = on_message

def start_mqtt_listener():
    try:
        logger.info(f"Conectando al Broker MQTT ({BROKER}:{PORT})...")
        mqtt_client.connect(BROKER, PORT, 60)
        mqtt_client.loop_start()
    except Exception as e:
        logger.error(f"Error al iniciar el Loop de MQTT: {e}")

def stop_mqtt_listener():
    try:
        logger.info("Desconectando del Broker MQTT...")
        mqtt_client.loop_stop()
        mqtt_client.disconnect()
        logger.info("Cliente MQTT desconectado.")
    except Exception as e:
        logger.error(f"Error al desconectar el Loop de MQTT: {e}")
