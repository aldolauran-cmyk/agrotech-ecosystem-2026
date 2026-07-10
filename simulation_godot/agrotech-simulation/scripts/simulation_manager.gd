extends Node

const PARCEL_SCENE = preload("res://scenes/parcel_3d.tscn")
const SPACING = 3.5

# Diccionario global de parcelas activas
# Estructura: { parcel_id (int): {"farmer_username": String, "humidity": float, "temperature": float, "ph": float, "alerta_estado": String, "node_instance": Node3D} }
var active_parcels: Dictionary = {}


func _ready() -> void:
	# Buscar al nodo 'NetworkManager' en la escena
	var network_manager: Node = null
	
	# Intento 1: Buscar como hijo de la escena actual o nodo raíz
	if get_tree().current_scene:
		network_manager = get_tree().current_scene.find_child("NetworkManager", true, false)
	
	# Intento 2: Buscar en la ruta absoluta /root si la escena actual no está disponible
	if not network_manager:
		network_manager = get_node_or_null("/root/NetworkManager")
		
	# Intento 3: Buscar en los hermanos del nodo
	if not network_manager and get_parent():
		network_manager = get_parent().find_child("NetworkManager", true, false)

	if network_manager:
		print("[SimulationManager] Nodo 'NetworkManager' encontrado. Conectando señal 'telemetry_received'...")
		network_manager.telemetry_received.connect(_on_parcel_telemetry_received)
	else:
		printerr("[SimulationManager] ERROR: No se pudo localizar el nodo 'NetworkManager' en el árbol de escenas.")


func _on_parcel_telemetry_received(parcel_id: int, farmer_username: String, humidity: float, temperature: float, ph: float) -> void:
	var alerta = _calcular_alerta(humidity)
	
	# Determinar el farmer_id de forma matemática para colocarlo en la cuadrícula de su respectiva zona
	var farmer_id = int((parcel_id - 1) / 4) + 1
	
	# Verificar si la parcela ya está registrada en el diccionario de simulación
	if not active_parcels.has(parcel_id):
		print("[SimulationManager] Nueva parcela detectada en red. Registrando ID: ", parcel_id, " (Farmer: ", farmer_username, ")")
		
		# Calcular índices locales para posicionar en un tablero de 2x2 por Farmer
		var local_index = (parcel_id - 1) % 4
		var col_local = local_index % 2
		var row_local = int(local_index / 2)
		
		# Separar los mini-tableros de cada Farmer por un pasillo de 10 unidades en el eje Z
		var zona_offset_z = (farmer_id - 1) * 10.0
		
		# Instanciar el bloque 3D en la grilla
		var nueva_parcela = PARCEL_SCENE.instantiate()
		nueva_parcela.parcel_id = parcel_id
		
		# Aplicar el posicionamiento en la grilla
		nueva_parcela.position.x = col_local * SPACING
		nueva_parcela.position.z = (row_local * SPACING) + zona_offset_z
		nueva_parcela.position.y = 0.0
		add_child(nueva_parcela)
		
		# Registrar en memoria
		active_parcels[parcel_id] = {
			"farmer_username": farmer_username,
			"humidity": humidity,
			"temperature": temperature,
			"ph": ph,
			"alerta_estado": alerta,
			"node_instance": nueva_parcela
		}
		
	else:
		# Si ya existe, simplemente actualizamos sus lecturas y estado de alerta
		active_parcels[parcel_id]["farmer_username"] = farmer_username
		active_parcels[parcel_id]["humidity"] = humidity
		active_parcels[parcel_id]["temperature"] = temperature
		active_parcels[parcel_id]["ph"] = ph
		active_parcels[parcel_id]["alerta_estado"] = alerta
		
	# Actualizar las propiedades físicas de la instancia 3D
	if active_parcels[parcel_id]["node_instance"] != null:
		active_parcels[parcel_id]["node_instance"].update_properties(humidity, temperature, ph, alerta, farmer_username)
		
	# Imprimir el estado actual en memoria RAM de la parcela para auditoría en consola
	print("[SimulationManager] Estado actualizado de Parcela ", parcel_id, " -> Humedad: ", humidity, "% | Temp: ", temperature, "°C | pH: ", ph, " | Alerta: [", alerta, "]")


# Función interna para evaluar los rangos de negocio agrícolas
func _calcular_alerta(humidity: float) -> String:
	if humidity < 30.0:
		return "ESTRES_HIDRICO"
	elif humidity >= 30.0 and humidity <= 70.0:
		return "OPTIMO"
	else:
		return "SATURADO"
