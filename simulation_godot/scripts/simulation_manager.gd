extends Node

const PARCEL_SCENE = preload("res://scenes/parcel_3d.tscn")
const SPACING = 3.5

# Diccionario global de parcelas activas
# Estructura: { parcel_id (int): {"farmer_username": String, "humidity": float, "temperature": float, "ph": float, "alerta_estado": String, "node_instance": Node3D} }
var active_parcels: Dictionary = {}

# Listado ordenado de agricultores únicos (para definir sus zonas Z)
var active_farmers: Array = []

# Mapeo de parcelas asignadas a cada agricultor para calcular su índice local 2x2
# Estructura: { "username": [parcel_id_1, parcel_id_2, ...] }
var farmer_parcels_map: Dictionary = {}


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
	var grillas_necesitan_reordenamiento = false
	
	# Verificar si la parcela ya está registrada en el diccionario de simulación
	if not active_parcels.has(parcel_id):
		print("[SimulationManager] Nueva parcela detectada. Registrando ID: ", parcel_id, " asignada a: ", farmer_username)
		
		# 1. Registrar agricultor si es nuevo y ordenar alfabéticamente para mantener zonas fijas
		if not active_farmers.has(farmer_username):
			active_farmers.append(farmer_username)
			active_farmers.sort()
		
		# 2. Registrar la parcela en la lista del agricultor y ordenar para posicionamiento secuencial
		if not farmer_parcels_map.has(farmer_username):
			farmer_parcels_map[farmer_username] = []
		
		if not farmer_parcels_map[farmer_username].has(parcel_id):
			farmer_parcels_map[farmer_username].append(parcel_id)
			farmer_parcels_map[farmer_username].sort()
		
		# Instanciar el bloque 3D en la escena
		var nueva_parcela = PARCEL_SCENE.instantiate()
		nueva_parcela.parcel_id = parcel_id
		add_child(nueva_parcela)
		
		# Registrar en memoria principal
		active_parcels[parcel_id] = {
			"farmer_username": farmer_username,
			"humidity": humidity,
			"temperature": temperature,
			"ph": ph,
			"alerta_estado": alerta,
			"node_instance": nueva_parcela
		}
		
		grillas_necesitan_reordenamiento = true
		
	else:
		# Si la parcela ya existe, validar si ha cambiado de dueño (reasignación de parcelas)
		var old_username = active_parcels[parcel_id]["farmer_username"]
		if old_username != farmer_username:
			print("[SimulationManager] ¡REASIGNACIÓN! Parcela ", parcel_id, " pasó de ", old_username, " a ", farmer_username)
			
			# Remover de la lista del dueño anterior
			if farmer_parcels_map.has(old_username):
				farmer_parcels_map[old_username].erase(parcel_id)
			
			# Registrar nuevo agricultor si no existe
			if not active_farmers.has(farmer_username):
				active_farmers.append(farmer_username)
				active_farmers.sort()
				
			# Añadir a la lista del nuevo dueño
			if not farmer_parcels_map.has(farmer_username):
				farmer_parcels_map[farmer_username] = []
			
			if not farmer_parcels_map[farmer_username].has(parcel_id):
				farmer_parcels_map[farmer_username].append(parcel_id)
				farmer_parcels_map[farmer_username].sort()
				
			active_parcels[parcel_id]["farmer_username"] = farmer_username
			grillas_necesitan_reordenamiento = true
			
		# Actualizar las métricas físicas y estado de alerta
		active_parcels[parcel_id]["humidity"] = humidity
		active_parcels[parcel_id]["temperature"] = temperature
		active_parcels[parcel_id]["ph"] = ph
		active_parcels[parcel_id]["alerta_estado"] = alerta
		
	# Si hubo cambios estructurales en la distribución, recalcular posiciones 3D
	if grillas_necesitan_reordenamiento:
		_reordenar_grillas()
		
	# Actualizar las propiedades físicas de la instancia 3D
	if active_parcels[parcel_id]["node_instance"] != null:
		active_parcels[parcel_id]["node_instance"].update_properties(humidity, temperature, ph, alerta, farmer_username)
		
	# Imprimir el estado actual en memoria RAM de la parcela para auditoría en consola
	print("[SimulationManager] Estado actualizado de Parcela ", parcel_id, " -> Humedad: ", humidity, "% | Temp: ", temperature, "°C | pH: ", ph, " | Alerta: [", alerta, "]")


# Función para reordenar las posiciones de todos los bloques 3D según agricultor y slot libre
func _reordenar_grillas() -> void:
	for parcel_id in active_parcels.keys():
		var data = active_parcels[parcel_id]
		var node = data["node_instance"] as Node3D
		if node == null:
			continue
			
		var username = data["farmer_username"]
		
		# Obtener la zona del agricultor (basado en el índice ordenado alfabéticamente)
		var farmer_zone_index = active_farmers.find(username)
		
		# Obtener el slot de la parcela dentro de su tablero 2x2 (0, 1, 2 o 3)
		var local_index = farmer_parcels_map[username].find(parcel_id)
		
		if farmer_zone_index != -1 and local_index != -1:
			var col_local = local_index % 2
			var row_local = int(local_index / 2)
			
			# Pasillo limpio de 10 unidades entre zonas de diferentes agricultores
			var zona_offset_z = farmer_zone_index * 10.0
			
			# Asignar la nueva posición física recalculada
			node.position.x = col_local * SPACING
			node.position.z = (row_local * SPACING) + zona_offset_z
			node.position.y = 0.0
			
			print("[SimulationManager] Bloque 3D ", parcel_id, " posicionado en Grilla de (", username, ") -> Pos: ", node.position)


# Función interna para evaluar los rangos de negocio agrícolas
func _calcular_alerta(humidity: float) -> String:
	if humidity < 30.0:
		return "ESTRES_HIDRICO"
	elif humidity >= 30.0 and humidity <= 70.0:
		return "OPTIMO"
	else:
		return "SATURADO"
