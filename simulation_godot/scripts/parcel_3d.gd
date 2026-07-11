extends MeshInstance3D

# Variables públicas con tipado explícito
var parcel_id: int = 0
var current_state: String = "OPTIMO"


# Función pública para actualizar las propiedades, comportamiento visual y textos en 3D
func update_properties(humidity: float, temperature: float, ph: float, alerta_estado: String, farmer_username: String) -> void:
	current_state = alerta_estado
	
	# 1. Buscar y actualizar el texto de Label3D para visualización en tiempo real
	var label = get_node_or_null("Label3D") as Label3D
	if label:
		# Formato multilínea redondeando floats a un decimal para limpieza visual
		label.text = "Parcela: %d\nFarmer: %s\nHumedad: %.1f%%\nTemp: %.1f°C\npH: %.1f" % [
			parcel_id,
			farmer_username,
			humidity,
			temperature,
			ph
		]
	
	# 2. Asegurar que el nodo tenga un material único asignado para poder cambiarle el color
	if material_override == null:
		material_override = StandardMaterial3D.new()
	
	var mat = material_override as StandardMaterial3D
	
	# 3. Evaluar de forma dinámica la alerta de red para cambiar el color del bloque (Albedo)
	match alerta_estado:
		"ESTRES_HIDRICO":
			print("[Parcel3D ID:", parcel_id, "] Modo SECO (Estrés Hídrico) -> Cambiando a Marrón")
			mat.albedo_color = Color.from_string("#8B5A2B", Color.BROWN)
			
		"OPTIMO":
			print("[Parcel3D ID:", parcel_id, "] Modo ÓPTIMO -> Cambiando a Verde")
			mat.albedo_color = Color.from_string("#2E8B57", Color.GREEN)
			
		"SATURADO":
			print("[Parcel3D ID:", parcel_id, "] Modo SATURADO (Hiperhúmedo) -> Cambiando a Azul")
			mat.albedo_color = Color.from_string("#4682B4", Color.BLUE)
			
		_:
			printerr("[Parcel3D ID:", parcel_id, "] Alerta no reconocida: ", alerta_estado)
