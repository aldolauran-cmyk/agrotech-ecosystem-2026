extends Node3D

# Señal personalizada con tipado explícito
signal telemetry_received(parcel_id: int, farmer_username: String, humidity: float, temperature: float, ph: float)

# Instancia del cliente MQTT
var mqtt_client: Node

# Diccionario para almacenar el mapeo público de parcel_id (int) -> owner_username (String)
var parcel_owners: Dictionary = {}

# Nodo HTTPRequest único para consultas de dueños (evita fugas de memoria)
var http_owners_request: HTTPRequest


func _ready() -> void:
	# Cargar e instanciar el script de MQTT
	var MQTTClass = load("res://mqtt/mqtt.gd")
	mqtt_client = MQTTClass.new()
	add_child(mqtt_client)  # Añadir al árbol para habilitar _process (procesamiento de sockets)
	
	# Conectar señales de eventos de MQTT
	mqtt_client.received_message.connect(_on_mqtt_message)
	mqtt_client.broker_connected.connect(_on_broker_connected)
	mqtt_client.broker_connection_failed.connect(_on_broker_connection_failed)
	
	# Inicializar el nodo HTTPRequest único
	http_owners_request = HTTPRequest.new()
	add_child(http_owners_request)
	http_owners_request.request_completed.connect(self._on_owners_request_completed)
	
	# Consultar el mapeo inicial de agricultores/parcelas desde la API REST
	_fetch_owners_mapping()
	
	# Configurar un Timer para consultar periódicamente el mapeo (cada 3 segundos para reactividad rápida)
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.autostart = true
	timer.timeout.connect(_fetch_owners_mapping)
	add_child(timer)
	
	# Iniciar conexión al Broker público de HiveMQ en puerto 1883
	var broker_url = "tcp://broker.hivemq.com:1883"
	print("[NetworkManager] Conectando al Broker MQTT: ", broker_url)
	mqtt_client.connect_to_broker(broker_url)


func _fetch_owners_mapping() -> void:
	# Si hay una consulta HTTP en proceso, esperar a que termine para no saturar la red
	if http_owners_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
		
	var api_url = "http://127.0.0.1:8000/api/v1/parcels/public/owners"
	var err = http_owners_request.request(api_url)
	if err != OK:
		printerr("[NetworkManager] ERROR: No se pudo iniciar la petición HTTP a la API.")


func _on_owners_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var json = JSON.new()
		var parse_err = json.parse(body.get_string_from_utf8())
		if parse_err == OK and json.data is Dictionary:
			var dict = json.data as Dictionary
			for key in dict.keys():
				var pid = int(key)
				var username = str(dict[key])
				parcel_owners[pid] = username
		else:
			printerr("[NetworkManager] ERROR: Falló el parseo de datos de agricultores.")
	else:
		printerr("[NetworkManager] ERROR: API de agricultores respondió con código ", response_code)


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
			
			# Determinar el nombre de usuario del agricultor (resolución dinámica o matemática)
			var farmer_username = "farmer" + str(int((parcel_id - 1) / 4) + 1)
			if parcel_owners.has(parcel_id):
				farmer_username = parcel_owners[parcel_id]
			
			# Emitir la señal personalizada para notificar a los nodos 3D de la simulación
			telemetry_received.emit(parcel_id, farmer_username, humidity, temperature, ph)
			print("[NetworkManager] Señal telemetry_received emitida. ID: ", parcel_id, " | Farmer: ", farmer_username, " | H: ", humidity, "% | T: ", temperature, "°C | pH: ", ph)
		else:
			printerr("[NetworkManager] ERROR: Falló la deserialización JSON o el formato no es un diccionario.")
	else:
		printerr("[NetworkManager] ERROR: Estructura del tópico inesperada: ", topic)
