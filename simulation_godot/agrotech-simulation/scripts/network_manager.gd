extends Node3D

# Señal personalizada con tipado explícito
signal telemetry_received(parcel_id: int, farmer_id: int, humidity: float, temperature: float, ph: float)

# Instancia del cliente MQTT
var mqtt_client: Node


func _ready() -> void:
	# Cargar e instanciar el script de MQTT
	var MQTTClass = load("res://mqtt/mqtt.gd")
	mqtt_client = MQTTClass.new()
	add_child(mqtt_client)  # Añadir al árbol para habilitar _process (procesamiento de sockets)
	
	# Conectar señales de eventos de MQTT
	mqtt_client.received_message.connect(_on_mqtt_message)
	mqtt_client.broker_connected.connect(_on_broker_connected)
	mqtt_client.broker_connection_failed.connect(_on_broker_connection_failed)
	
	# Iniciar conexión al Broker público de HiveMQ en puerto 1883
	var broker_url = "tcp://broker.hivemq.com:1883"
	print("[NetworkManager] Conectando al Broker MQTT: ", broker_url)
	mqtt_client.connect_to_broker(broker_url)


func _on_broker_connected() -> void:
	print("[NetworkManager] ¡ÉXITO! Conexión establecida con el Broker MQTT.")
	# Suscripción al tópico comodín para captar la telemetría de cualquier parcela
	var topic = "unmsm/agrotech/parcel/+/telemetry"
	mqtt_client.subscribe(topic)
	print("[NetworkManager] Solicitud de suscripción enviada para el tópico: ", topic)


func _on_broker_connection_failed() -> void:
	printerr("[NetworkManager] ERROR: No se pudo establecer conexión con el Broker MQTT.")


func _on_mqtt_message(topic: String, message: String) -> void:
	# Imprimir en consola para auditoría
	print("[NetworkManager] Mensaje recibido | Tópico: ", topic, " | Payload: ", message)
	
	# Extraer el ID de la parcela desde el tópico
	# Estructura del tópico: unmsm/agrotech/parcel/{parcel_id}/telemetry
	var topic_parts = topic.split("/")
	if topic_parts.size() >= 4:
		var parcel_id = int(topic_parts[3])
		
		# Deserializar el payload JSON del mensaje
		var json_data = JSON.parse_string(message)
		if json_data != null and json_data is Dictionary:
			# Controles de fallas: asignar valores por defecto si vienen nulos o vacíos
			var humidity = 0.0
			if json_data.has("humidity") and json_data["humidity"] != null:
				humidity = float(json_data["humidity"])
				
			var temperature = 0.0
			if json_data.has("temperature") and json_data["temperature"] != null:
				temperature = float(json_data["temperature"])
				
			var ph = 7.0
			if json_data.has("ph") and json_data["ph"] != null:
				ph = float(json_data["ph"])
			
			# Determinar el farmer_id de forma matemática (4 parcelas por mini-tablero de Farmer)
			var farmer_id = int((parcel_id - 1) / 4) + 1

			# Emitir la señal personalizada para notificar a los nodos 3D de la simulación
			telemetry_received.emit(parcel_id, farmer_id, humidity, temperature, ph)
			print("[NetworkManager] Señal telemetry_received emitida. ID: ", parcel_id, " | Farmer: ", farmer_id, " | H: ", humidity, "% | T: ", temperature, "°C | pH: ", ph)
		else:
			printerr("[NetworkManager] ERROR: Falló la deserialización JSON o el formato no es un diccionario.")
	else:
		printerr("[NetworkManager] ERROR: Estructura del tópico inesperada: ", topic)
