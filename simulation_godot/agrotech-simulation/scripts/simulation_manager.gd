extends Node

# Diccionario global de parcelas activas
# Estructura: { parcel_id (int): {"humidity": float, "temperature": float, "ph": float} }
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


func _on_parcel_telemetry_received(parcel_id: int, humidity: float, temperature: float, ph: float) -> void:
	# Verificar si la parcela ya está registrada en el diccionario de simulación
	if not active_parcels.has(parcel_id):
		print("[SimulationManager] Nueva parcela detectada en red. Registrando ID: ", parcel_id)
		
		# Registrar en memoria
		active_parcels[parcel_id] = {
			"humidity": humidity,
			"temperature": temperature,
			"ph": ph
		}
		
		# TODO: Instanciar el bloque 3D en la grilla
		
	else:
		# Si ya existe, simplemente actualizamos sus lecturas
		active_parcels[parcel_id]["humidity"] = humidity
		active_parcels[parcel_id]["temperature"] = temperature
		active_parcels[parcel_id]["ph"] = ph
		
	# Imprimir el estado actual en memoria RAM de la parcela para auditoría en consola
	print("[SimulationManager] Estado actualizado de Parcela ", parcel_id, " -> ", active_parcels[parcel_id])
