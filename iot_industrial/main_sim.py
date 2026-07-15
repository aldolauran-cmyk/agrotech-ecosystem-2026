import random
import time
import requests
import json
import paho.mqtt.client as mqtt

BASE_URL = "http://127.0.0.1:8000/api/v1"
MQTT_BROKER = "broker.hivemq.com"
MQTT_PORT = 1883
MQTT_TOPIC_TEMPLATE = "unmsm/agrotech/parcel/{parcel_id}/telemetry"

# Diccionario global para mantener la máquina de estados de humedad y telemetría por parcela
# Estructura: { parcel_id: {"humidity": float, "state": str, "temperature": int, "ph": float} }
PARCEL_STATES = {}


def get_valid_token():
    print("Enviando credenciales de desarrollo ('admin' / 'admin123')...")
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
            print("--> ¡ÉXITO! Conexión establecida con el backend.")
            return response.json().get("access_token")
        else:
            print(f"Error en login: Código {response.status_code}")
            print(f"Detalle del servidor: {response.json()}")
            return None
    except requests.exceptions.Timeout:
        print("Error: El servidor tardó demasiado en responder (Timeout).")
        return None
    except Exception as e:
        print(f"Error de conexión con el backend: {e}")
        return None


def obtener_parcelas(headers):
    """Obtiene la lista de IDs de parcelas registradas en el sistema."""
    try:
        response = requests.get(f"{BASE_URL}/parcels", headers=headers, timeout=5)
        if response.status_code == 200:
            parcelas = response.json()
            ids = [p["id"] for p in parcelas]
            return ids
        elif response.status_code == 401:
            print("[Simulador] Token JWT expirado. Re-autenticando con el backend...")
            nuevo_token = get_valid_token()
            if nuevo_token:
                headers["Authorization"] = f"Bearer {nuevo_token}"
                # Re-intentar la petición con el nuevo token
                response = requests.get(f"{BASE_URL}/parcels", headers=headers, timeout=5)
                if response.status_code == 200:
                    return [p["id"] for p in response.json()]
            return []
        else:
            print(f"Error al obtener parcelas: {response.status_code}")
            return []
    except Exception as e:
        print(f"Error de conexión al obtener parcelas: {e}")
        return []


def garantizar_parcela_existente(headers):
    """Verifica si existen parcelas, de lo contrario crea la Parcela de demostración."""
    print("Verificando disponibilidad de parcelas en el sistema...")
    try:
        response = requests.get(f"{BASE_URL}/parcels", headers=headers, timeout=5)
        # Si la lista está vacía, creamos la primera parcela de prueba
        if response.status_code == 200 and len(response.json()) == 0:
            print("No se encontraron parcelas. Creando 'Parcela Demostración 1'...")
            # Mapeado a los campos oficiales del backend migrado (se usa "soil_type" para evitar 422)
            nueva_parcela = {
                "name": "Parcela Demostración 1",
                "ubicacion_grilla": "0,0",
                "ubicacion_referencial": "Santa Anita, Lima",
                "soil_type": "Arcilloso"
            }
            create_resp = requests.post(
                f"{BASE_URL}/parcels", 
                json=nueva_parcela, 
                headers=headers, 
                timeout=5
            )
            if create_resp.status_code == 201:
                print(f"--> ¡Parcela creada con éxito! ID: {create_resp.json().get('id')}")
            else:
                print(f"Alerta al crear parcela: {create_resp.text}")
        else:
            print("--> Conexión de parcelas verificada. Listo para transmitir.")
    except Exception as e:
        print(f"Advertencia al verificar parcelas: {e}. Se intentará el envío de igual modo.")


def calcular_siguiente_telemetria(parcel_id):
    """Aplica la máquina de estados cíclica de humedad y genera variaciones leves en temperatura y pH."""
    # Inicialización de la parcela si no está en la máquina de estados
    if parcel_id not in PARCEL_STATES:
        initial_humidity = round(random.uniform(35.0, 65.0), 1)
        initial_state = random.choice(["SECANDO", "REGANDO", "DRENAJE"])
        # Valores base de temperatura y pH
        base_temp = random.randint(21, 29)
        base_ph = round(random.uniform(5.8, 7.2), 2)
        PARCEL_STATES[parcel_id] = {
            "humidity": initial_humidity,
            "state": initial_state,
            "temperature_base": base_temp,
            "ph_base": base_ph
        }

    state_info = PARCEL_STATES[parcel_id]
    current_humidity = state_info["humidity"]
    current_state = state_info["state"]
    base_temp = state_info["temperature_base"]
    base_ph = state_info["ph_base"]

    # Transiciones de la máquina de estados
    if current_state == "SECANDO":
        next_humidity = current_humidity - 2.5
        if next_humidity <= 20.0:
            next_state = "REGANDO"
        else:
            next_state = "SECANDO"
    elif current_state == "REGANDO":
        next_humidity = current_humidity + 6.0
        if next_humidity >= 85.0:
            next_state = "DRENAJE"
        else:
            next_state = "REGANDO"
    elif current_state == "DRENAJE":
        next_humidity = current_humidity - 1.5
        if next_humidity <= 50.0:
            next_state = "SECANDO"
        else:
            next_state = "DRENAJE"
    else:
        next_humidity = current_humidity
        next_state = "SECANDO"

    # Acotación matemática de humedad entre 0.0 y 100.0 con 1 decimal de precisión
    next_humidity = round(max(0.0, min(100.0, next_humidity)), 1)

    # Correlación agronómica (Humedad -> Temp y pH)
    temp_offset = 0.0
    ph_offset = 0.0

    if next_humidity < 30.0:
        # Suelo seco / Estrés hídrico: se calienta más rápido y se acidifica levemente
        temp_offset = 2.5
        ph_offset = -0.15
    elif next_state == "REGANDO":
        # Suelo recibiendo agua fresca: se enfría por evaporación y el pH se neutraliza
        temp_offset = -2.0
        ph_offset = 0.05
    elif next_humidity > 70.0:
        # Suelo sobresaturado (Drenaje): enfriamiento y dilución moderada
        temp_offset = -1.0
        ph_offset = 0.0

    # Variar la temperatura actual en un rango de +/- 0.5 respecto al valor base + offset
    temp_variation = random.uniform(-0.5, 0.5)
    next_temp = int(round(max(20.0, min(32.0, base_temp + temp_offset + temp_variation))))

    # Variar el pH actual en un rango de +/- 0.02 respecto al valor base + offset
    ph_variation = random.uniform(-0.02, 0.02)
    next_ph = round(max(5.5, min(7.5, base_ph + ph_offset + ph_variation)), 2)

    # Actualizar estado global
    PARCEL_STATES[parcel_id]["humidity"] = next_humidity
    PARCEL_STATES[parcel_id]["state"] = next_state

    return {
        "humidity": next_humidity,
        "temperature": next_temp,
        "ph": next_ph
    }


# Flujo principal de ejecución del simulador
if __name__ == "__main__":
    token = get_valid_token()

    if not token:
        print("\n[!] No se pudo obtener el token. Asegúrate de que el backend esté corriendo en la otra terminal.")
        exit()

    headers = {"Authorization": f"Bearer {token}"}
    
    # Aseguramos que exista la relación en la BD antes de mandar datos
    garantizar_parcela_existente(headers)
    
    # Inicializar y conectar Cliente MQTT
    print(f"Estableciendo conexión con el Broker MQTT ({MQTT_BROKER})...")
    mqtt_client = mqtt.Client(callback_api_version=mqtt.CallbackAPIVersion.VERSION2)
    try:
        mqtt_client.connect(MQTT_BROKER, MQTT_PORT, 60)
        mqtt_client.loop_start()
        print("--> ¡ÉXITO! Conectado al broker MQTT.")
    except Exception as e:
        print(f"Error de conexión al Broker MQTT: {e}")
        exit()

    print("\n¡Autenticación y entorno completados! Enviando telemetría cíclica cada 5 segundos...\n")

    try:
        while True:
            # Obtener dinámicamente todas las parcelas registradas
            parcel_ids = obtener_parcelas(headers)

            if not parcel_ids:
                print("[Advertencia] No hay parcelas registradas. Esperando...")
                time.sleep(5)
                continue

            for parcel_id in parcel_ids:
                topic = MQTT_TOPIC_TEMPLATE.format(parcel_id=parcel_id)
                
                # Obtener la telemetría calculada por la máquina de estados
                data = calcular_siguiente_telemetria(parcel_id)
                
                try:
                    # Publicar mediante MQTT con QoS 1 (Asegurar entrega)
                    # El payload NO contiene parcel_id (optimización de ancho de banda)
                    payload = json.dumps(data)
                    info = mqtt_client.publish(topic, payload, qos=1)
                    info.wait_for_publish()
                    print(f"[IoT MQTT Publish] Enviado a {topic}: {payload} | Estado: {PARCEL_STATES[parcel_id]['state']}")
                except Exception as e:
                    print(f"Error al transmitir telemetría por MQTT para parcela {parcel_id}: {e}")
                
            time.sleep(5)
    except KeyboardInterrupt:
        print("\nDeteniendo simulador IoT...")
    finally:
        mqtt_client.loop_stop()
        mqtt_client.disconnect()
        print("Simulador detenido con éxito.")